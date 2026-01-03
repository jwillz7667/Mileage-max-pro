//
//  DashboardView.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import SwiftUI
import SwiftData
import Charts
import CoreLocation

/// Main dashboard view showing mileage statistics and quick actions
struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        DashboardContentView(modelContext: modelContext)
    }
}

/// Internal content view with initialized ViewModel
private struct DashboardContentView: View {
    @StateObject private var viewModel: DashboardViewModel
    @EnvironmentObject private var locationService: LocationTrackingService

    @State private var showingVehiclePicker = false
    @State private var selectedVehicleId: UUID?

    init(modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: DashboardViewModel(modelContext: modelContext))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Active tracking banner
                    if viewModel.isTracking {
                        ActiveTrackingBanner(
                            trip: viewModel.currentTrip,
                            speed: locationService.speed,
                            onStop: {
                                Task {
                                    _ = await viewModel.endTrip()
                                }
                            }
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Active route card
                    if let route = viewModel.activeRoute {
                        ActiveRouteCard(route: route)
                            .transition(.scale.combined(with: .opacity))
                    }

                    // Period selector
                    PeriodSelector(selection: $viewModel.selectedPeriod)

                    // Stats grid
                    switch viewModel.dashboardState {
                    case .idle, .loading:
                        StatsGridSkeleton()

                    case .loaded(let data), .refreshing(let data):
                        StatsGrid(data: data)

                    case .error(let error):
                        ErrorStateView(error: error) {
                            Task { await viewModel.loadDashboard() }
                        }
                    }

                    // Quick actions
                    QuickActionsSection(
                        isTracking: viewModel.isTracking,
                        onStartTrip: { showingVehiclePicker = true },
                        onStopTrip: {
                            Task { _ = await viewModel.endTrip() }
                        },
                        onAddTrip: { viewModel.showingAddTrip = true },
                        onPlanRoute: { viewModel.showingRoutePlanner = true }
                    )

                    // Weekly chart
                    if !viewModel.weeklyStats.isEmpty {
                        WeeklyChartSection(data: viewModel.weeklyStats)
                    }

                    // Recent trips
                    RecentTripsSection(
                        trips: viewModel.recentTrips,
                        onSeeAll: { /* Navigate to trips */ }
                    )
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: Spacing.sm) {
                        // Sync status
                        if case .refreshing = viewModel.dashboardState {
                            ProgressView()
                                .scaleEffect(0.8)
                        }

                        // Notifications
                        GlassIconButton(icon: "bell.fill", style: .secondary, size: 36) {
                            // Show notifications
                        }
                    }
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadDashboard()
            }
            .sheet(isPresented: $showingVehiclePicker) {
                VehiclePickerSheet(selectedVehicleId: $selectedVehicleId) {
                    if let vehicleId = selectedVehicleId {
                        viewModel.startTrip(vehicleId: vehicleId)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddTrip) {
                ManualTripEntryView()
            }
            .sheet(isPresented: $viewModel.showingRoutePlanner) {
                RoutePlannerView()
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.isTracking)
        .animation(.easeInOut, value: viewModel.dashboardState)
    }
}

// MARK: - Period Selector

struct PeriodSelector: View {
    @Binding var selection: StatsPeriod

    var body: some View {
        GlassSegmentedControl(
            selection: $selection,
            options: [
                (.day, "Today", nil),
                (.week, "Week", nil),
                (.month, "Month", nil),
                (.year, "Year", nil)
            ]
        )
    }
}

// MARK: - Stats Grid

struct StatsGrid: View {
    let data: DashboardData

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: Spacing.cardGap),
            GridItem(.flexible(), spacing: Spacing.cardGap)
        ], spacing: Spacing.cardGap) {
            StatCard(
                title: "Total Miles",
                value: data.totalMiles.formatted(.number.precision(.fractionLength(1))),
                subtitle: "\(data.totalTrips) trips",
                icon: "car.fill",
                iconColor: ColorConstants.primary,
                trend: .up("+12%")
            )

            StatCard(
                title: "Business",
                value: data.businessMiles.formatted(.number.precision(.fractionLength(1))),
                subtitle: "\(Int(data.businessMiles / max(1, data.totalMiles) * 100))% of total",
                icon: "briefcase.fill",
                iconColor: .green,
                trend: .up("+8%")
            )

            StatCard(
                title: "Tax Savings",
                value: data.estimatedDeduction.asCurrency(),
                subtitle: "IRS @ $\(String(format: "%.3f", AppConstants.IRSMileageRates.current.business))/mi",
                icon: "dollarsign.circle.fill",
                iconColor: .orange,
                trend: .up("+$\(Int(data.estimatedDeduction * 0.1))")
            )

            StatCard(
                title: "Daily Avg",
                value: data.averageDailyMiles.formatted(.number.precision(.fractionLength(1))),
                subtitle: "miles per day",
                icon: "chart.line.uptrend.xyaxis",
                iconColor: .purple
            )
        }
    }
}

struct StatsGridSkeleton: View {
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: Spacing.cardGap),
            GridItem(.flexible(), spacing: Spacing.cardGap)
        ], spacing: Spacing.cardGap) {
            ForEach(0..<4, id: \.self) { _ in
                SkeletonCard()
            }
        }
    }
}

// MARK: - Active Tracking Banner

struct ActiveTrackingBanner: View {
    let trip: LocationTrackingService.ActiveTrip?
    let speed: CLLocationSpeed
    let onStop: () -> Void

    var body: some View {
        TintedGlassCard(tint: ColorConstants.success) {
            VStack(spacing: Spacing.md) {
                // Header
                HStack {
                    HStack(spacing: Spacing.sm) {
                        Circle()
                            .fill(ColorConstants.success)
                            .frame(width: 10, height: 10)
                            .pulsing()

                        Text("Trip in Progress")
                            .font(Typography.headline)
                            .foregroundStyle(ColorConstants.Text.primary)
                    }

                    Spacer()

                    Text(formatDuration(trip?.durationSeconds ?? 0))
                        .font(Typography.subheadlineBold)
                        .foregroundStyle(ColorConstants.Text.secondary)
                        .monospacedDigit()
                }

                // Stats row
                HStack(spacing: Spacing.xl) {
                    TripStatItem(
                        value: String(format: "%.1f", trip?.distanceMiles ?? 0),
                        unit: "mi",
                        icon: "road.lanes"
                    )

                    TripStatItem(
                        value: String(format: "%.0f", speed * 2.23694),
                        unit: "mph",
                        icon: "speedometer"
                    )

                    TripStatItem(
                        value: String(format: "%.1f", (trip?.distanceMiles ?? 0) / max(0.0167, Double(trip?.durationSeconds ?? 1) / 3600)),
                        unit: "avg",
                        icon: "gauge.with.needle"
                    )
                }

                // Stop button
                GlassButton("Stop Trip", icon: "stop.fill", style: .destructive, size: .fullWidth) {
                    HapticManager.shared.warning()
                    onStop()
                }
            }
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }
}

struct TripStatItem: View {
    let value: String
    let unit: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(ColorConstants.Text.tertiary)

            Text(value)
                .font(Typography.statMedium)
                .foregroundStyle(ColorConstants.Text.primary)
                .monospacedDigit()

            Text(unit)
                .font(Typography.caption2)
                .foregroundStyle(ColorConstants.Text.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Active Route Card

struct ActiveRouteCard: View {
    let route: DeliveryRoute

    var completedStops: Int {
        route.stops.filter { $0.status == .completed }.count
    }

    var progress: Double {
        guard route.stops.count > 0 else { return 0 }
        return Double(completedStops) / Double(route.stops.count)
    }

    var body: some View {
        NavigationLink(destination: ActiveNavigationView(route: route)) {
            TintedGlassCard(tint: ColorConstants.secondary) {
                VStack(spacing: Spacing.md) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Active Route")
                                .font(Typography.caption1)
                                .foregroundStyle(ColorConstants.Text.secondary)

                            Text(route.name ?? "Unnamed Route")
                                .font(Typography.headline)
                                .foregroundStyle(ColorConstants.Text.primary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(ColorConstants.Text.tertiary)
                    }

                    // Progress bar
                    VStack(spacing: 6) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(ColorConstants.secondary.opacity(0.2))
                                    .frame(height: 8)

                                Capsule()
                                    .fill(ColorConstants.secondary)
                                    .frame(width: geometry.size.width * progress, height: 8)
                            }
                        }
                        .frame(height: 8)

                        HStack {
                            Text("\(completedStops) of \(route.stops.count) stops")
                                .font(Typography.caption1)
                                .foregroundStyle(ColorConstants.Text.secondary)

                            Spacer()

                            if let nextStop = route.stops.first(where: { $0.status == .pending }) {
                                Text("Next: \(nextStop.name)")
                                    .font(Typography.caption1)
                                    .foregroundStyle(ColorConstants.secondary)
                            }
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Quick Actions Section

struct QuickActionsSection: View {
    let isTracking: Bool
    let onStartTrip: () -> Void
    let onStopTrip: () -> Void
    let onAddTrip: () -> Void
    let onPlanRoute: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Quick Actions")
                .font(Typography.subheadlineBold)
                .foregroundStyle(ColorConstants.Text.secondary)

            HStack(spacing: Spacing.md) {
                QuickActionButton(
                    icon: isTracking ? "stop.fill" : "play.fill",
                    title: isTracking ? "Stop" : "Start",
                    color: isTracking ? ColorConstants.error : ColorConstants.success,
                    action: isTracking ? onStopTrip : onStartTrip
                )

                QuickActionButton(
                    icon: "plus",
                    title: "Add Trip",
                    color: ColorConstants.primary,
                    action: onAddTrip
                )

                QuickActionButton(
                    icon: "map",
                    title: "Route",
                    color: ColorConstants.secondary,
                    action: onPlanRoute
                )

                QuickActionButton(
                    icon: "doc.text",
                    title: "Report",
                    color: .orange,
                    action: { /* Navigate to reports */ }
                )
            }
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            HapticManager.shared.lightImpact()
            action()
        }) {
            VStack(spacing: Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(color)
                }
                .scaleEffect(isPressed ? 0.92 : 1.0)

                Text(title)
                    .font(Typography.caption1)
                    .fontWeight(.medium)
                    .foregroundStyle(ColorConstants.Text.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeOut(duration: 0.1)) { isPressed = true }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { isPressed = false }
                }
        )
    }
}

// MARK: - Weekly Chart Section

struct WeeklyChartSection: View {
    let data: [DailyMileage]

    var maxMiles: Double {
        data.map { $0.totalMiles }.max() ?? 100
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("This Week")
                .font(Typography.subheadlineBold)
                .foregroundStyle(ColorConstants.Text.secondary)

            GlassMorphicCard {
                VStack(spacing: Spacing.md) {
                    Chart {
                        ForEach(data) { day in
                            BarMark(
                                x: .value("Day", day.dayAbbreviation),
                                y: .value("Miles", day.totalMiles)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [ColorConstants.primary, ColorConstants.secondary],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .cornerRadius(4)

                            // Business miles overlay
                            BarMark(
                                x: .value("Day", day.dayAbbreviation),
                                y: .value("Business", day.businessMiles)
                            )
                            .foregroundStyle(ColorConstants.primary.opacity(0.8))
                            .cornerRadius(4)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisValueLabel {
                                if let miles = value.as(Double.self) {
                                    Text("\(Int(miles))")
                                        .font(Typography.caption2)
                                        .foregroundStyle(ColorConstants.Text.tertiary)
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks { value in
                            AxisValueLabel {
                                if let day = value.as(String.self) {
                                    Text(day)
                                        .font(Typography.caption2)
                                        .foregroundStyle(ColorConstants.Text.secondary)
                                }
                            }
                        }
                    }
                    .frame(height: 180)

                    // Legend
                    HStack(spacing: Spacing.lg) {
                        LegendItem(color: ColorConstants.primary, label: "Business")
                        LegendItem(color: ColorConstants.secondary, label: "Personal")
                    }
                }
            }
        }
    }
}

struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .font(Typography.caption1)
                .foregroundStyle(ColorConstants.Text.secondary)
        }
    }
}

// MARK: - Recent Trips Section

struct RecentTripsSection: View {
    let trips: [Trip]
    let onSeeAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            GlassSectionHeader("Recent Trips", actionTitle: "See All", action: onSeeAll)

            if trips.isEmpty {
                EmptyStateView(
                    icon: "car.fill",
                    title: "No Recent Trips",
                    message: "Start tracking to see your trips here"
                )
                .frame(height: 150)
            } else {
                VStack(spacing: Spacing.sm) {
                    ForEach(trips.prefix(3)) { trip in
                        TripListRow(
                            startLocation: trip.startAddress ?? "Unknown",
                            endLocation: trip.endAddress ?? "Unknown",
                            distance: trip.distanceMiles.asMiles(),
                            date: trip.startTime.smartFormatted,
                            category: trip.category,
                            action: { /* Navigate to trip detail */ }
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Vehicle Picker Sheet

struct VehiclePickerSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedVehicleId: UUID?
    let onSelect: () -> Void

    @Query(sort: \Vehicle.nickname) private var vehicles: [Vehicle]

    var body: some View {
        NavigationStack {
            List {
                if vehicles.isEmpty {
                    ContentUnavailableView(
                        "No Vehicles",
                        systemImage: "car.2.fill",
                        description: Text("Add a vehicle to start tracking trips")
                    )
                } else {
                    ForEach(vehicles) { vehicle in
                        Button {
                            selectedVehicleId = vehicle.id
                            dismiss()
                            onSelect()
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(vehicle.name)
                                        .font(Typography.body)
                                        .foregroundStyle(ColorConstants.Text.primary)

                                    Text("\(vehicle.year) \(vehicle.make) \(vehicle.model)")
                                        .font(Typography.caption1)
                                        .foregroundStyle(ColorConstants.Text.secondary)
                                }

                                Spacer()

                                if vehicle.isActive {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(ColorConstants.success)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Vehicle")
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

// MARK: - Placeholder Views

struct ManualTripEntryView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Text("Manual Trip Entry")
                .navigationTitle("Add Trip")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") { dismiss() }
                    }
                }
        }
    }
}

struct RoutePlannerView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Text("Route Planner")
                .navigationTitle("Plan Route")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") { dismiss() }
                    }
                }
        }
    }
}

struct ActiveNavigationView: View {
    let route: DeliveryRoute

    var body: some View {
        Text("Active Navigation for \(route.name)")
            .navigationTitle("Navigation")
    }
}
