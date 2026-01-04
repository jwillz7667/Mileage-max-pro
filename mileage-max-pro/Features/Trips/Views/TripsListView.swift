//
//  TripsListView.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import SwiftUI
import SwiftData
import os

/// List view displaying all trips with filtering and search
struct TripsListView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TripsListContentView(modelContext: modelContext)
    }
}

/// Internal content view with initialized ViewModel
private struct TripsListContentView: View {
    @StateObject private var viewModel: TripsListViewModel

    @State private var selectedTrips = Set<UUID>()
    @State private var isSelecting = false
    @State private var showingBatchClassify = false

    init(modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: TripsListViewModel(modelContext: modelContext))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Summary header
                TripsSummaryHeader(
                    totalMiles: viewModel.totalMiles,
                    businessMiles: viewModel.businessMiles,
                    tripCount: viewModel.filteredTrips.count,
                    deduction: viewModel.estimatedDeduction
                )

                // Content
                switch viewModel.loadState {
                case .idle, .loading:
                    TripsListSkeleton()

                case .loaded, .refreshing:
                    if viewModel.filteredTrips.isEmpty {
                        emptyState
                    } else {
                        tripsList
                    }

                case .error(let error):
                    ErrorStateView(error: error) {
                        Task { await viewModel.loadTrips() }
                    }
                }
            }
            .navigationTitle("Trips")
            .searchable(text: $viewModel.searchText, prompt: "Search trips...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: Spacing.sm) {
                        // Filter button
                        Button {
                            viewModel.showingFilters = true
                        } label: {
                            Image(systemName: viewModel.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                                .foregroundStyle(viewModel.hasActiveFilters ? ColorConstants.primary : ColorConstants.Text.secondary)
                        }

                        // Select/Edit button
                        Button {
                            withAnimation {
                                isSelecting.toggle()
                                if !isSelecting {
                                    selectedTrips.removeAll()
                                }
                            }
                        } label: {
                            Text(isSelecting ? "Done" : "Select")
                        }

                        // Add button
                        Button {
                            viewModel.showingAddTrip = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }

                if isSelecting && !selectedTrips.isEmpty {
                    ToolbarItem(placement: .bottomBar) {
                        HStack {
                            Text("\(selectedTrips.count) selected")
                                .font(Typography.subheadline)
                                .foregroundStyle(ColorConstants.Text.secondary)

                            Spacer()

                            Button("Classify") {
                                showingBatchClassify = true
                            }
                            .disabled(selectedTrips.isEmpty)

                            Button("Delete", role: .destructive) {
                                Task {
                                    for tripId in selectedTrips {
                                        if let trip = viewModel.filteredTrips.first(where: { $0.id == tripId }) {
                                            await viewModel.deleteTrip(trip)
                                        }
                                    }
                                    selectedTrips.removeAll()
                                    isSelecting = false
                                }
                            }
                            .disabled(selectedTrips.isEmpty)
                        }
                    }
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadTrips()
            }
            .sheet(isPresented: $viewModel.showingFilters) {
                TripFiltersSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showingAddTrip) {
                ManualTripEntrySheet()
            }
            .sheet(isPresented: $showingBatchClassify) {
                BatchClassifySheet(tripIds: Array(selectedTrips)) { category in
                    Task {
                        await viewModel.classifyTrips(Array(selectedTrips), category: category)
                        selectedTrips.removeAll()
                        isSelecting = false
                    }
                }
            }
            .sheet(item: $viewModel.showingTripDetail) { trip in
                TripDetailView(trip: trip)
            }
        }
    }

    // MARK: - Trips List

    private var tripsList: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.md, pinnedViews: [.sectionHeaders]) {
                ForEach(viewModel.sortedDates, id: \.self) { date in
                    Section {
                        ForEach(viewModel.tripsByDate[date] ?? []) { trip in
                            TripRowView(
                                trip: trip,
                                isSelected: selectedTrips.contains(trip.id),
                                isSelecting: isSelecting,
                                onTap: {
                                    if isSelecting {
                                        toggleSelection(trip.id)
                                    } else {
                                        viewModel.showingTripDetail = trip
                                    }
                                },
                                onDelete: {
                                    Task { await viewModel.deleteTrip(trip) }
                                }
                            )
                        }
                    } header: {
                        DateSectionHeader(date: date, tripCount: viewModel.tripsByDate[date]?.count ?? 0)
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack {
            if viewModel.hasActiveFilters {
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "No Matching Trips",
                    message: "Try adjusting your filters or search terms",
                    actionTitle: "Clear Filters"
                ) {
                    viewModel.clearFilters()
                }
            } else {
                EmptyStateView.noTrips {
                    viewModel.showingAddTrip = true
                }
            }
        }
    }

    private func toggleSelection(_ tripId: UUID) {
        if selectedTrips.contains(tripId) {
            selectedTrips.remove(tripId)
        } else {
            selectedTrips.insert(tripId)
        }
    }
}

// MARK: - Premium Summary Header

struct TripsSummaryHeader: View {
    let totalMiles: Double
    let businessMiles: Double
    let tripCount: Int
    let deduction: Double

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                PremiumSummaryChip(
                    icon: "road.lanes",
                    value: totalMiles.formatted(.number.precision(.fractionLength(1))),
                    label: "Total Miles",
                    color: ColorConstants.primary
                )

                PremiumSummaryChip(
                    icon: "briefcase.fill",
                    value: businessMiles.formatted(.number.precision(.fractionLength(1))),
                    label: "Business",
                    color: ColorConstants.TripCategory.business
                )

                PremiumSummaryChip(
                    icon: "location.fill",
                    value: "\(tripCount)",
                    label: "Trips",
                    color: ColorConstants.success
                )

                PremiumSummaryChip(
                    icon: "dollarsign.circle.fill",
                    value: deduction.asCurrency(),
                    label: "Deduction",
                    color: ColorConstants.warning
                )
            }
            .padding(.horizontal)
            .padding(.vertical, Spacing.sm)
        }
        .background(
            ColorConstants.Surface.card
                .shadow(color: ColorConstants.Neomorphic.darkShadow, radius: 4, x: 0, y: 2)
        )
    }
}

struct PremiumSummaryChip: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: Spacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.12))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(Typography.subheadlineBold)
                    .foregroundStyle(ColorConstants.Text.primary)
                    .monospacedDigit()

                Text(label)
                    .font(Typography.caption2)
                    .foregroundStyle(ColorConstants.Text.tertiary)
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
                .fill(ColorConstants.Surface.elevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
                .stroke(ColorConstants.Border.standard, lineWidth: 0.5)
        )
    }
}

// MARK: - Premium Date Section Header

struct DateSectionHeader: View {
    let date: Date
    let tripCount: Int

    var body: some View {
        HStack {
            Text(date.sectionHeaderFormatted)
                .font(Typography.subheadlineBold)
                .foregroundStyle(ColorConstants.Text.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            Spacer()

            Text("\(tripCount) trips")
                .font(Typography.caption1)
                .fontWeight(.medium)
                .foregroundStyle(ColorConstants.Text.tertiary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(ColorConstants.Surface.elevated)
                )
        }
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, Spacing.sm)
        .background(ColorConstants.Surface.grouped.opacity(0.95))
    }
}

// MARK: - Trip Row View

struct TripRowView: View {
    let trip: Trip
    let isSelected: Bool
    let isSelecting: Bool
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Selection indicator
            if isSelecting {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? ColorConstants.primary : ColorConstants.Text.tertiary)
                    .transition(.scale.combined(with: .opacity))
            }

            // Trip content
            TripListRow(
                startLocation: trip.startAddress ?? "Unknown location",
                endLocation: trip.endAddress ?? "Unknown location",
                distance: trip.distanceMiles.asMiles(),
                date: trip.startTime.timeFormatted,
                category: trip.category,
                action: onTap
            )
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelecting)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                // Quick classify as business
            } label: {
                Label("Business", systemImage: "briefcase")
            }
            .tint(ColorConstants.success)
        }
    }
}

// MARK: - Skeleton

struct TripsListSkeleton: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                ForEach(0..<8, id: \.self) { _ in
                    SkeletonCard()
                }
            }
            .padding()
        }
    }
}

// MARK: - Filters Sheet

struct TripFiltersSheet: View {
    @ObservedObject var viewModel: TripsListViewModel
    @Environment(\.dismiss) private var dismiss
    @Query private var vehicles: [Vehicle]

    var body: some View {
        NavigationStack {
            Form {
                // Date range
                Section("Date Range") {
                    Picker("Period", selection: $viewModel.dateRange) {
                        ForEach(TripsListViewModel.DateRange.allCases) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                }

                // Category
                Section("Category") {
                    Picker("Category", selection: $viewModel.selectedCategory) {
                        Text("All Categories").tag(nil as TripCategory?)
                        ForEach(TripCategory.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: category.icon)
                                .tag(category as TripCategory?)
                        }
                    }
                }

                // Vehicle
                Section("Vehicle") {
                    Picker("Vehicle", selection: $viewModel.selectedVehicle) {
                        Text("All Vehicles").tag(nil as Vehicle?)
                        ForEach(vehicles) { vehicle in
                            Text(vehicle.name).tag(vehicle as Vehicle?)
                        }
                    }
                }

                // Sort order
                Section("Sort By") {
                    Picker("Sort", selection: $viewModel.sortOrder) {
                        ForEach(TripsListViewModel.TripSortOrder.allCases) { order in
                            Text(order.rawValue).tag(order)
                        }
                    }
                }

                // Clear filters
                if viewModel.hasActiveFilters {
                    Section {
                        Button("Clear All Filters", role: .destructive) {
                            viewModel.clearFilters()
                        }
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Batch Classify Sheet

struct BatchClassifySheet: View {
    let tripIds: [UUID]
    let onClassify: (TripCategory) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(TripCategory.allCases, id: \.self) { category in
                    Button {
                        onClassify(category)
                        dismiss()
                    } label: {
                        Label {
                            VStack(alignment: .leading) {
                                Text(category.rawValue)
                                    .font(Typography.body)
                                    .foregroundStyle(ColorConstants.Text.primary)

                                if category.isTaxDeductible {
                                    Text("Tax deductible")
                                        .font(Typography.caption2)
                                        .foregroundStyle(ColorConstants.success)
                                }
                            }
                        } icon: {
                            Image(systemName: category.icon)
                                .foregroundStyle(category.color)
                        }
                    }
                }
            }
            .navigationTitle("Classify \(tripIds.count) Trips")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Manual Trip Entry Sheet

struct ManualTripEntrySheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var vehicles: [Vehicle]

    @State private var startAddress = ""
    @State private var endAddress = ""
    @State private var distance = ""
    @State private var date = Date()
    @State private var category: TripCategory = .business
    @State private var selectedVehicle: Vehicle?
    @State private var purpose = ""
    @State private var notes = ""
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Route") {
                    GlassTextField(
                        "Start Location",
                        text: $startAddress,
                        placeholder: "Enter starting address",
                        icon: "location.fill"
                    )

                    GlassTextField(
                        "End Location",
                        text: $endAddress,
                        placeholder: "Enter destination address",
                        icon: "mappin"
                    )

                    GlassTextField(
                        "Distance (miles)",
                        text: $distance,
                        placeholder: "0.0",
                        icon: "road.lanes",
                        keyboardType: .decimalPad,
                        validation: TextValidators.numeric
                    )
                }

                Section("Details") {
                    DatePicker("Date & Time", selection: $date)

                    Picker("Category", selection: $category) {
                        ForEach(TripCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }

                    Picker("Vehicle", selection: $selectedVehicle) {
                        Text("Select Vehicle").tag(nil as Vehicle?)
                        ForEach(vehicles) { vehicle in
                            Text(vehicle.name).tag(vehicle as Vehicle?)
                        }
                    }
                }

                Section("Notes") {
                    TextField("Purpose", text: $purpose)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveTrip()
                    }
                    .disabled(startAddress.isEmpty || endAddress.isEmpty || distance.isEmpty || selectedVehicle == nil)
                }
            }
        }
    }

    private func saveTrip() {
        guard let distanceValue = Double(distance),
              let vehicle = selectedVehicle else { return }

        isSaving = true

        let trip = Trip(
            startLatitude: 0,
            startLongitude: 0,
            startTime: date,
            category: category,
            detectionMethod: TripDetectionMethod.manual
        )
        trip.startAddress = startAddress
        trip.endAddress = endAddress
        trip.distanceMeters = Int(distanceValue / 0.000621371)
        trip.endTime = date
        trip.vehicle = vehicle
        trip.purpose = purpose.isEmpty ? nil : purpose
        trip.notes = notes.isEmpty ? nil : notes
        trip.status = TripStatus.completed
        trip.syncStatus = SyncStatus.pending

        modelContext.insert(trip)

        do {
            try modelContext.save()
            HapticManager.shared.success()
            dismiss()
        } catch {
            AppLogger.data.error("Failed to save trip: \(error.localizedDescription)")
            isSaving = false
        }
    }
}

// MARK: - Date Extensions

extension Date {
    var sectionHeaderFormatted: String {
        let calendar = Calendar.current

        if calendar.isDateInToday(self) {
            return "Today"
        } else if calendar.isDateInYesterday(self) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMMM d"
            return formatter.string(from: self)
        }
    }

    var timeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: self)
    }
}
