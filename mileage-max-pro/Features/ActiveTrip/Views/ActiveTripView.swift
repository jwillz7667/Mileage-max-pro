//
//  ActiveTripView.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import SwiftUI
import SwiftData
import MapKit

/// Active trip tracking view with live map and stats
struct ActiveTripView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel = ActiveTripViewModel()

    @State private var showingEndTripConfirmation = false
    @State private var showingCategoryPicker = false
    @State private var showingPurposeSheet = false
    @State private var mapCameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)

    var body: some View {
        ZStack {
            // Full-screen map
            mapView

            // Overlay controls
            VStack {
                // Top bar
                topBar
                    .padding(.horizontal)
                    .padding(.top, 8)

                Spacer()

                // Bottom panel with stats and controls
                bottomPanel
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarHidden(true)
        .sheet(isPresented: $showingCategoryPicker) {
            CategoryPickerSheet(
                selectedCategory: $viewModel.tripCategory,
                onSave: { viewModel.updateCategory() }
            )
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingPurposeSheet) {
            PurposeEntrySheet(
                purpose: $viewModel.tripPurpose,
                notes: $viewModel.tripNotes,
                onSave: { viewModel.updatePurpose() }
            )
            .presentationDetents([.medium])
        }
        .confirmationDialog(
            "End Trip",
            isPresented: $showingEndTripConfirmation,
            titleVisibility: .visible
        ) {
            Button("End & Save") {
                endTrip()
            }

            Button("Discard Trip", role: .destructive) {
                discardTrip()
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("What would you like to do with this trip?")
        }
        .onAppear {
            viewModel.startUpdates()
        }
        .onDisappear {
            viewModel.stopUpdates()
        }
    }

    // MARK: - Map View

    private var mapView: some View {
        Map(position: $mapCameraPosition) {
            // User location
            UserAnnotation()

            // Start location marker
            if let startLocation = viewModel.startLocation {
                Annotation("Start", coordinate: startLocation) {
                    ZStack {
                        Circle()
                            .fill(.green)
                            .frame(width: 28, height: 28)
                        Image(systemName: "flag.fill")
                            .font(.caption2)
                            .foregroundStyle(.white)
                    }
                    .shadow(radius: 4)
                }
            }

            // Route polyline
            if viewModel.routeCoordinates.count > 1 {
                MapPolyline(coordinates: viewModel.routeCoordinates)
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 5
                    )
            }
        }
        .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
        .mapControls {
            MapCompass()
                .mapControlVisibility(.visible)
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button {
                showingEndTripConfirmation = true
            } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }

            Spacer()

            // Status indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(viewModel.isPaused ? .orange : .green)
                    .frame(width: 10, height: 10)
                    .overlay {
                        if !viewModel.isPaused {
                            Circle()
                                .stroke(.green.opacity(0.5), lineWidth: 2)
                                .scaleEffect(1.5)
                                .opacity(viewModel.pulseAnimation ? 0 : 1)
                        }
                    }

                Text(viewModel.isPaused ? "Paused" : "Recording")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())

            Spacer()

            Button {
                centerOnUser()
            } label: {
                Image(systemName: "location.fill")
                    .font(.headline)
                    .foregroundStyle(.blue)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
        }
    }

    // MARK: - Bottom Panel

    private var bottomPanel: some View {
        VStack(spacing: 0) {
            // Drag indicator
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 16)

            // Stats grid
            statsGrid
                .padding(.horizontal)

            Divider()
                .padding(.vertical, 16)

            // Quick actions
            quickActions
                .padding(.horizontal)
                .padding(.bottom, 8)

            // Main control button
            mainControlButton
                .padding(.horizontal)
                .padding(.bottom, 24)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 20, y: -5)
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            LiveStatItem(
                title: "Distance",
                value: String(format: "%.1f", viewModel.distanceMiles),
                unit: "mi"
            )

            LiveStatItem(
                title: "Duration",
                value: viewModel.formattedDuration,
                unit: ""
            )

            LiveStatItem(
                title: "Speed",
                value: String(format: "%.0f", viewModel.currentSpeed),
                unit: "mph"
            )
        }
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        HStack(spacing: 12) {
            TripQuickActionButton(
                icon: "tag",
                title: viewModel.tripCategory.rawValue,
                color: .blue
            ) {
                showingCategoryPicker = true
            }

            TripQuickActionButton(
                icon: "text.quote",
                title: viewModel.tripPurpose?.isEmpty == false ? "Edit Purpose" : "Add Purpose",
                color: .purple
            ) {
                showingPurposeSheet = true
            }

            TripQuickActionButton(
                icon: "arrow.triangle.turn.up.right.diamond",
                title: "Navigate",
                color: .green
            ) {
                openNavigation()
            }
        }
    }

    // MARK: - Main Control Button

    private var mainControlButton: some View {
        HStack(spacing: 16) {
            // Pause/Resume button
            Button {
                viewModel.togglePause()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                    Text(viewModel.isPaused ? "Resume" : "Pause")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(viewModel.isPaused ? Color.green : Color.orange)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            // End Trip button
            Button {
                showingEndTripConfirmation = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "stop.fill")
                    Text("End Trip")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.red)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    // MARK: - Actions

    private func centerOnUser() {
        withAnimation {
            mapCameraPosition = .userLocation(fallback: .automatic)
        }
    }

    private func endTrip() {
        Task {
            if let trip = await viewModel.endTrip() {
                modelContext.insert(trip)
                try? modelContext.save()
            }
            dismiss()
        }
    }

    private func discardTrip() {
        viewModel.discardTrip()
        dismiss()
    }

    private func openNavigation() {
        guard let currentLocation = viewModel.currentLocation else { return }

        let placemark = MKPlacemark(coordinate: currentLocation)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = "Current Location"

        MKMapItem.openMaps(with: [mapItem], launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

// MARK: - Live Stat Item

struct LiveStatItem: View {
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .monospacedDigit()

                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Trip Quick Action Button

private struct TripQuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)

                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Category Picker Sheet

struct CategoryPickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var selectedCategory: TripCategory
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(TripCategory.allCases, id: \.self) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        HStack {
                            Image(systemName: categoryIcon(category))
                                .foregroundStyle(categoryColor(category))
                                .frame(width: 32)

                            Text(category.rawValue)
                                .foregroundStyle(.primary)

                            Spacer()

                            if selectedCategory == category {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Trip Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                }
            }
        }
    }

    private func categoryIcon(_ category: TripCategory) -> String {
        switch category {
        case .business: return "briefcase.fill"
        case .personal: return "car.fill"
        case .medical: return "cross.case.fill"
        case .charity: return "heart.fill"
        case .moving: return "box.truck.fill"
        case .commute: return "building.2.fill"
        }
    }

    private func categoryColor(_ category: TripCategory) -> Color {
        switch category {
        case .business: return .blue
        case .personal: return .purple
        case .medical: return .red
        case .charity: return .green
        case .moving: return .brown
        case .commute: return .orange
        }
    }
}

// MARK: - Purpose Entry Sheet

struct PurposeEntrySheet: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var purpose: String?
    @Binding var notes: String?
    let onSave: () -> Void

    @State private var purposeText: String = ""
    @State private var notesText: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Purpose") {
                    TextField("e.g., Client meeting, Delivery", text: $purposeText)
                }

                Section("Notes") {
                    TextEditor(text: $notesText)
                        .frame(minHeight: 100)
                }

                Section {
                    // Common purposes
                    ForEach(commonPurposes, id: \.self) { purpose in
                        Button {
                            purposeText = purpose
                        } label: {
                            HStack {
                                Text(purpose)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if purposeText == purpose {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Common Purposes")
                }
            }
            .navigationTitle("Trip Purpose")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        purpose = purposeText.isEmpty ? nil : purposeText
                        notes = notesText.isEmpty ? nil : notesText
                        onSave()
                        dismiss()
                    }
                }
            }
            .onAppear {
                purposeText = purpose ?? ""
                notesText = notes ?? ""
            }
        }
    }

    private var commonPurposes: [String] {
        [
            "Client meeting",
            "Site visit",
            "Delivery",
            "Sales call",
            "Training",
            "Conference",
            "Airport trip",
            "Office commute"
        ]
    }
}

#Preview {
    ActiveTripView()
}
