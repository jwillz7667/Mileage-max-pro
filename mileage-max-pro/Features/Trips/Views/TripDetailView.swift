//
//  TripDetailView.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import SwiftUI
import SwiftData
import MapKit
import os

/// Detailed view for a single trip
struct TripDetailView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let trip: Trip

    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var showingFullMap = false
    @State private var isDeleting = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Map Preview
                mapSection

                // Trip Info Card
                tripInfoCard

                // Stats Card
                statsCard

                // Location Details
                locationCard

                // Notes & Purpose
                if trip.purpose != nil || trip.notes != nil {
                    notesCard
                }

                // Sync Status
                syncStatusCard

                // Actions
                actionButtons
            }
            .padding()
        }
        .background(ColorConstants.Surface.grouped)
        .navigationTitle("Trip Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("Edit Trip", systemImage: "pencil")
                    }

                    Button {
                        shareTrip()
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }

                    Divider()

                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete Trip", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            TripEditSheet(trip: trip)
        }
        .fullScreenCover(isPresented: $showingFullMap) {
            TripFullMapView(trip: trip)
        }
        .confirmationDialog(
            "Delete Trip",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteTrip()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }

    // MARK: - Map Section

    private var mapSection: some View {
        Button {
            showingFullMap = true
        } label: {
            ZStack(alignment: .bottomTrailing) {
                TripMapPreview(trip: trip)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.caption)
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .padding(8)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Trip Info Card

    private var tripInfoCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    CategoryBadge(category: trip.category)

                    Spacer()

                    StatusBadge(status: trip.status)
                }

                Divider()

                // Date & Time
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundStyle(.secondary)
                        Text(trip.startTime.formatted(date: .long, time: .omitted))
                            .font(.headline)
                    }

                    HStack {
                        Image(systemName: "clock")
                            .foregroundStyle(.secondary)
                        Text("\(trip.startTime.formatted(date: .omitted, time: .shortened)) - \(trip.endTime?.formatted(date: .omitted, time: .shortened) ?? "In Progress")")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                // Vehicle
                if let vehicleId = trip.vehicleId {
                    VehicleLabel(vehicleId: vehicleId)
                }
            }
            .padding()
        }
    }

    // MARK: - Stats Card

    private var statsCard: some View {
        GlassCard {
            VStack(spacing: 16) {
                Text("Trip Statistics")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    StatBox(
                        title: "Distance",
                        value: String(format: "%.1f", trip.distanceMiles),
                        unit: "miles",
                        icon: "road.lanes"
                    )

                    StatBox(
                        title: "Duration",
                        value: formatDuration(trip.durationSeconds),
                        unit: "",
                        icon: "timer"
                    )

                    StatBox(
                        title: "Avg Speed",
                        value: String(format: "%.0f", trip.avgSpeedMPH ?? 0),
                        unit: "mph",
                        icon: "speedometer"
                    )

                    StatBox(
                        title: "Deduction",
                        value: formatCurrency(calculateDeduction()),
                        unit: "",
                        icon: "dollarsign.circle"
                    )
                }
            }
            .padding()
        }
    }

    // MARK: - Location Card

    private var locationCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Route")
                    .font(.headline)

                // Start Location
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(ColorConstants.success.opacity(0.2))
                            .frame(width: 32, height: 32)
                        Circle()
                            .fill(ColorConstants.success)
                            .frame(width: 12, height: 12)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Start")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(trip.startAddress ?? "Unknown location")
                            .font(.subheadline)
                    }

                    Spacer()
                }

                // Connector Line
                Rectangle()
                    .fill(ColorConstants.Border.standard)
                    .frame(width: 2, height: 24)
                    .padding(.leading, 15)

                // End Location
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(ColorConstants.error.opacity(0.2))
                            .frame(width: 32, height: 32)
                        Circle()
                            .fill(ColorConstants.error)
                            .frame(width: 12, height: 12)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("End")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(trip.endAddress ?? "Unknown location")
                            .font(.subheadline)
                    }

                    Spacer()
                }
            }
            .padding()
        }
    }

    // MARK: - Notes Card

    private var notesCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                if let purpose = trip.purpose, !purpose.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Purpose")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(purpose)
                            .font(.subheadline)
                    }
                }

                if let notes = trip.notes, !notes.isEmpty {
                    if trip.purpose != nil {
                        Divider()
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(notes)
                            .font(.subheadline)
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Sync Status Card

    private var syncStatusCard: some View {
        GlassCard {
            HStack {
                Image(systemName: syncStatusIcon)
                    .foregroundStyle(syncStatusColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(syncStatusText)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if let lastSynced = trip.lastSyncedAt {
                        Text("Last synced: \(lastSynced.formatted(.relative(presentation: .named)))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if trip.syncStatus == .pending {
                    Button("Sync Now") {
                        syncTrip()
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                showingEditSheet = true
            } label: {
                Label("Edit Trip", systemImage: "pencil")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(GlassButtonStyleWrapper())

            HStack(spacing: 12) {
                Button {
                    duplicateTrip()
                } label: {
                    Label("Duplicate", systemImage: "plus.square.on.square")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyleWrapper(variant: .secondary))

                Button {
                    shareTrip()
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyleWrapper(variant: .secondary))
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Helpers

    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) min"
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    private func calculateDeduction() -> Double {
        let rate = AppConstants.IRSMileageRates.current
        switch trip.category {
        case .business:
            return trip.distanceMiles * rate.business
        case .medical:
            return trip.distanceMiles * rate.medical
        case .charity:
            return trip.distanceMiles * rate.charity
        default:
            return 0
        }
    }

    private var syncStatusIcon: String {
        switch trip.syncStatus {
        case .synced:
            return "checkmark.icloud"
        case .pending:
            return "icloud.and.arrow.up"
        case .failed:
            return "exclamationmark.icloud"
        }
    }

    private var syncStatusColor: Color {
        switch trip.syncStatus {
        case .synced:
            return ColorConstants.success
        case .pending:
            return ColorConstants.warning
        case .failed:
            return ColorConstants.error
        }
    }

    private var syncStatusText: String {
        switch trip.syncStatus {
        case .synced:
            return "Synced to cloud"
        case .pending:
            return "Pending sync"
        case .failed:
            return "Sync failed"
        }
    }

    // MARK: - Actions

    private func deleteTrip() {
        isDeleting = true
        modelContext.delete(trip)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            AppLogger.data.error("Failed to delete trip: \(error.localizedDescription)")
        }
    }

    private func syncTrip() {
        Task {
            // Trigger sync
            trip.syncStatus = .pending
            try? modelContext.save()

            // Would call API here
        }
    }

    private func duplicateTrip() {
        let newTrip = Trip(
            startLatitude: trip.startLatitude,
            startLongitude: trip.startLongitude,
            startTime: Date(),
            category: trip.category
        )
        newTrip.endLatitude = trip.endLatitude
        newTrip.endLongitude = trip.endLongitude
        newTrip.startAddress = trip.startAddress
        newTrip.endAddress = trip.endAddress
        newTrip.purpose = trip.purpose
        newTrip.vehicle = trip.vehicle
        newTrip.status = TripStatus.completed
        newTrip.distanceMeters = trip.distanceMeters
        newTrip.durationSeconds = trip.durationSeconds

        modelContext.insert(newTrip)

        do {
            try modelContext.save()
        } catch {
            AppLogger.data.error("Failed to duplicate trip: \(error.localizedDescription)")
        }
    }

    private func shareTrip() {
        // Create share content
        let text = """
        Trip Details - MileageMax Pro

        Date: \(trip.startTime.formatted(date: .long, time: .shortened))
        From: \(trip.startAddress ?? "Unknown")
        To: \(trip.endAddress ?? "Unknown")
        Distance: \(String(format: "%.1f", trip.distanceMiles)) miles
        Category: \(trip.category.rawValue)
        """

        let activityVC = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Supporting Views

struct StatBox: View {
    let title: String
    let value: String
    let unit: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(ColorConstants.primary)

            VStack(spacing: 2) {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
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
        .frame(maxWidth: .infinity)
        .padding()
        .background(ColorConstants.Surface.secondaryGrouped)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct CategoryBadge: View {
    let category: TripCategory

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: categoryIcon)
            Text(category.rawValue)
        }
        .font(.caption)
        .fontWeight(.medium)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(categoryColor.opacity(0.15))
        .foregroundStyle(categoryColor)
        .clipShape(Capsule())
    }

    private var categoryIcon: String {
        switch category {
        case .business:
            return "briefcase"
        case .personal:
            return "car"
        case .medical:
            return "cross.case"
        case .charity:
            return "heart"
        case .commute:
            return "building.2"
        case .moving:
            return "box.truck"
        }
    }

    private var categoryColor: Color {
        category.color
    }
}

struct StatusBadge: View {
    let status: TripStatus

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(status.rawValue)
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(ColorConstants.Surface.tertiaryGrouped)
        .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch status {
        case .recording:
            return ColorConstants.success
        case .processing:
            return ColorConstants.warning
        case .completed:
            return ColorConstants.primary
        case .verified:
            return ColorConstants.info
        }
    }
}

struct VehicleLabel: View {
    @Environment(\.modelContext) private var modelContext
    let vehicleId: UUID

    @State private var vehicle: Vehicle?

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "car.fill")
                .foregroundStyle(.secondary)

            if let vehicle = vehicle {
                Text("\(vehicle.year) \(vehicle.make) \(vehicle.model)")
                    .font(.subheadline)
            } else {
                Text("Unknown Vehicle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .task {
            loadVehicle()
        }
    }

    private func loadVehicle() {
        let descriptor = FetchDescriptor<Vehicle>(
            predicate: #Predicate<Vehicle> { $0.id == vehicleId }
        )
        vehicle = try? modelContext.fetch(descriptor).first
    }
}

// MARK: - Trip Map Preview

struct TripMapPreview: View {
    let trip: Trip

    var body: some View {
        Map {
            // Start marker
            Annotation("Start", coordinate: CLLocationCoordinate2D(
                latitude: trip.startLatitude,
                longitude: trip.startLongitude
            )) {
                ZStack {
                    Circle()
                        .fill(ColorConstants.Map.startMarker)
                        .frame(width: 24, height: 24)
                    Image(systemName: "flag.fill")
                        .font(.caption2)
                        .foregroundStyle(ColorConstants.Text.inverse)
                }
            }

            // End marker
            if let endLat = trip.endLatitude, let endLon = trip.endLongitude, endLat != 0 && endLon != 0 {
                Annotation("End", coordinate: CLLocationCoordinate2D(
                    latitude: endLat,
                    longitude: endLon
                )) {
                    ZStack {
                        Circle()
                            .fill(ColorConstants.Map.endMarker)
                            .frame(width: 24, height: 24)
                        Image(systemName: "mappin")
                            .font(.caption2)
                            .foregroundStyle(ColorConstants.Text.inverse)
                    }
                }
            }

            // Route polyline if available
            if let routeString = trip.routePolyline,
               let routeData = routeString.data(using: .utf8),
               let coordinates = decodePolyline(routeData) {
                MapPolyline(coordinates: coordinates)
                    .stroke(ColorConstants.Map.route, lineWidth: 4)
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControlVisibility(.hidden)
    }

    private func decodePolyline(_ data: Data) -> [CLLocationCoordinate2D]? {
        // Decode route polyline data
        guard let json = try? JSONDecoder().decode([[Double]].self, from: data) else {
            return nil
        }
        return json.map { CLLocationCoordinate2D(latitude: $0[0], longitude: $0[1]) }
    }
}

// MARK: - Trip Edit Sheet

struct TripEditSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let trip: Trip

    @State private var category: TripCategory
    @State private var purpose: String
    @State private var notes: String
    @State private var isSaving = false

    init(trip: Trip) {
        self.trip = trip
        _category = State(initialValue: trip.category)
        _purpose = State(initialValue: trip.purpose ?? "")
        _notes = State(initialValue: trip.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(TripCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Purpose") {
                    TextField("Trip purpose", text: $purpose)
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }

                Section {
                    HStack {
                        Text("Distance")
                        Spacer()
                        Text(String(format: "%.1f miles", trip.distanceMiles))
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Duration")
                        Spacer()
                        Text(formatDuration(trip.durationSeconds))
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Date")
                        Spacer()
                        Text(trip.startTime.formatted(date: .abbreviated, time: .shortened))
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Trip Details")
                } footer: {
                    Text("Distance and duration cannot be edited after a trip is completed.")
                }
            }
            .navigationTitle("Edit Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(isSaving)
                }
            }
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) min"
        }
    }

    private func saveChanges() {
        isSaving = true

        trip.category = category
        trip.purpose = purpose.isEmpty ? nil : purpose
        trip.notes = notes.isEmpty ? nil : notes
        trip.syncStatus = .pending

        do {
            try modelContext.save()
            dismiss()
        } catch {
            AppLogger.data.error("Failed to save trip: \(error.localizedDescription)")
            isSaving = false
        }
    }
}

// MARK: - Full Map View

struct TripFullMapView: View {
    @Environment(\.dismiss) private var dismiss

    let trip: Trip

    @State private var mapStyle: MapStyle = .standard(elevation: .realistic)
    @State private var camera: MapCameraPosition = .automatic

    var body: some View {
        NavigationStack {
            Map(position: $camera) {
                // Start marker
                Annotation("Start", coordinate: startCoordinate) {
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(ColorConstants.Map.startMarker)
                                .frame(width: 32, height: 32)
                            Image(systemName: "flag.fill")
                                .font(.caption)
                                .foregroundStyle(ColorConstants.Text.inverse)
                        }
                        Text("Start")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                }

                // End marker
                if let endLat = trip.endLatitude, let endLon = trip.endLongitude, endLat != 0 && endLon != 0 {
                    Annotation("End", coordinate: CLLocationCoordinate2D(latitude: endLat, longitude: endLon)) {
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(ColorConstants.Map.endMarker)
                                    .frame(width: 32, height: 32)
                                Image(systemName: "mappin")
                                    .font(.caption)
                                    .foregroundStyle(ColorConstants.Text.inverse)
                            }
                            Text("End")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                        }
                    }
                }

                // Route polyline
                if let routeString = trip.routePolyline,
                   let routeData = routeString.data(using: .utf8),
                   let coordinates = decodePolyline(routeData) {
                    MapPolyline(coordinates: coordinates)
                        .stroke(ColorConstants.Map.route, lineWidth: 5)
                }
            }
            .mapStyle(mapStyle)
            .mapControls {
                MapCompass()
                MapScaleView()
                MapUserLocationButton()
            }
            .navigationTitle("Trip Route")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            mapStyle = .standard(elevation: .realistic)
                        } label: {
                            Label("Standard", systemImage: "map")
                        }

                        Button {
                            mapStyle = .hybrid(elevation: .realistic)
                        } label: {
                            Label("Satellite", systemImage: "globe")
                        }

                        Button {
                            mapStyle = .imagery(elevation: .realistic)
                        } label: {
                            Label("Imagery", systemImage: "photo")
                        }
                    } label: {
                        Image(systemName: "map")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                tripInfoBar
            }
        }
    }

    private var startCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: trip.startLatitude, longitude: trip.startLongitude)
    }

    private var endCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: trip.endLatitude ?? 0, longitude: trip.endLongitude ?? 0)
    }

    private var tripInfoBar: some View {
        HStack(spacing: 24) {
            VStack(spacing: 2) {
                Text(String(format: "%.1f", trip.distanceMiles))
                    .font(.title2)
                    .fontWeight(.bold)
                Text("miles")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()
                .frame(height: 32)

            VStack(spacing: 2) {
                Text(formatDuration(trip.durationSeconds))
                    .font(.title2)
                    .fontWeight(.bold)
                Text("duration")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()
                .frame(height: 32)

            VStack(spacing: 2) {
                Text(String(format: "%.0f", trip.avgSpeedMPH ?? 0))
                    .font(.title2)
                    .fontWeight(.bold)
                Text("avg mph")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
    }

    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    private func decodePolyline(_ data: Data) -> [CLLocationCoordinate2D]? {
        guard let json = try? JSONDecoder().decode([[Double]].self, from: data) else {
            return nil
        }
        return json.map { CLLocationCoordinate2D(latitude: $0[0], longitude: $0[1]) }
    }
}

#Preview {
    NavigationStack {
        Text("Trip Detail Preview")
    }
}
