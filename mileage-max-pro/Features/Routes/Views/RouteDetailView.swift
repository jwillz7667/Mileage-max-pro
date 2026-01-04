//
//  RouteDetailView.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import SwiftUI
import SwiftData
import MapKit

/// Detailed view for a delivery route
struct RouteDetailView: View {

    @Environment(\.dismiss) private var dismiss

    let route: DeliveryRoute
    @ObservedObject var viewModel: RoutesViewModel

    @State private var showingFullMap = false
    @State private var showingDeleteConfirmation = false
    @State private var selectedStop: RouteStop?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Map Section
                mapSection

                // Route Status & Actions
                statusSection

                // Route Stats
                statsSection

                // Stops List
                stopsSection

                // Notes
                if let notes = route.notes, !notes.isEmpty {
                    notesSection(notes)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(route.name ?? route.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if route.status == .planned {
                        Button {
                            Task {
                                await viewModel.startRoute(route)
                            }
                        } label: {
                            Label("Start Route", systemImage: "play.fill")
                        }
                    }

                    if route.status == .inProgress {
                        Button {
                            Task {
                                await viewModel.completeRoute(route)
                            }
                        } label: {
                            Label("Complete Route", systemImage: "checkmark.circle")
                        }
                    }

                    Divider()

                    Button {
                        openInMaps()
                    } label: {
                        Label("Open in Maps", systemImage: "map")
                    }

                    Button {
                        shareRoute()
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }

                    Divider()

                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete Route", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .fullScreenCover(isPresented: $showingFullMap) {
            RouteNavigationView(route: route, viewModel: viewModel)
        }
        .sheet(item: $selectedStop) { stop in
            StopDetailSheet(stop: stop, viewModel: viewModel)
        }
        .confirmationDialog(
            "Delete Route",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteRoute(route)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Map Section

    private var mapSection: some View {
        Button {
            showingFullMap = true
        } label: {
            ZStack(alignment: .bottomTrailing) {
                Map {
                    ForEach(Array(route.stops.enumerated()), id: \.element.id) { index, stop in
                        Annotation("\(index + 1)", coordinate: CLLocationCoordinate2D(
                            latitude: stop.latitude,
                            longitude: stop.longitude
                        )) {
                            StopMarker(index: index + 1, status: stop.status)
                        }
                    }

                    if route.stops.count > 1 {
                        MapPolyline(coordinates: route.stops
                            .sorted { $0.orderIndex < $1.orderIndex }
                            .map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
                        )
                        .stroke(ColorConstants.Map.route, lineWidth: 4)
                    }
                }
                .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                    Text("Navigate")
                }
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .padding(8)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Status Section

    private var statusSection: some View {
        GlassCard {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Status")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 8) {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 12, height: 12)
                            Text(route.status.rawValue)
                                .font(.headline)
                        }
                    }

                    Spacer()

                    if route.status == .planned {
                        Button {
                            Task {
                                await viewModel.startRoute(route)
                            }
                        } label: {
                            Label("Start", systemImage: "play.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    } else if route.status == .inProgress {
                        Button {
                            showingFullMap = true
                        } label: {
                            Label("Continue", systemImage: "location.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                // Progress bar for in-progress routes
                if route.status == .inProgress {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Progress")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(completedStops)/\(route.stops.count) stops")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(ColorConstants.Surface.elevated)
                                    .frame(height: 8)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(ColorConstants.success)
                                    .frame(width: geometry.size.width * progressPercentage, height: 8)
                            }
                        }
                        .frame(height: 8)
                    }
                }

                // Timestamps
                VStack(spacing: 8) {
                    if let started = route.startedAt {
                        HStack {
                            Text("Started")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(started.formatted(date: .abbreviated, time: .shortened))
                        }
                        .font(.caption)
                    }

                    if let completed = route.completedAt {
                        HStack {
                            Text("Completed")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(completed.formatted(date: .abbreviated, time: .shortened))
                        }
                        .font(.caption)
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            RouteStatItem(
                icon: "mappin.circle",
                value: "\(route.stops.count)",
                label: "Stops"
            )

            RouteStatItem(
                icon: "road.lanes",
                value: route.estimatedDistance.map { String(format: "%.1f", $0) } ?? "--",
                label: "Miles"
            )

            RouteStatItem(
                icon: "clock",
                value: route.estimatedDuration.map { "\($0)" } ?? "--",
                label: "Minutes"
            )
        }
    }

    // MARK: - Stops Section

    private var stopsSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Stops")
                    .font(.headline)

                ForEach(Array(route.stops.sorted { $0.orderIndex < $1.orderIndex }.enumerated()), id: \.element.id) { index, stop in
                    Button {
                        selectedStop = stop
                    } label: {
                        StopRow(
                            stop: stop,
                            index: index + 1,
                            isLast: index == route.stops.count - 1
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }

    // MARK: - Notes Section

    private func notesSection(_ notes: String) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Label("Notes", systemImage: "note.text")
                    .font(.headline)

                Text(notes)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Helpers

    private var statusColor: Color {
        switch route.status {
        case .planned: return ColorConstants.primary
        case .inProgress: return ColorConstants.success
        case .completed: return ColorConstants.secondary
        case .canceled: return ColorConstants.error
        }
    }

    private var completedStops: Int {
        route.stops.filter { $0.status == .completed }.count
    }

    private var progressPercentage: Double {
        guard !route.stops.isEmpty else { return 0 }
        return Double(completedStops) / Double(route.stops.count)
    }

    private func openInMaps() {
        let mapItems = route.stops.map { stop in
            let placemark = MKPlacemark(coordinate: CLLocationCoordinate2D(
                latitude: stop.latitude,
                longitude: stop.longitude
            ))
            let mapItem = MKMapItem(placemark: placemark)
            mapItem.name = stop.name ?? "Stop \(stop.orderIndex + 1)"
            return mapItem
        }

        MKMapItem.openMaps(with: mapItems, launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }

    private func shareRoute() {
        var text = "Route: \(route.name)\n"
        text += "\(route.stops.count) stops"

        if let distance = route.estimatedDistance {
            text += " • \(String(format: "%.1f", distance)) mi"
        }

        text += "\n\nStops:\n"

        for (index, stop) in route.stops.sorted(by: { $0.orderIndex < $1.orderIndex }).enumerated() {
            text += "\(index + 1). \(stop.name ?? stop.address ?? "Unknown")\n"
        }

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

// MARK: - Stop Marker

struct StopMarker: View {
    let index: Int
    let status: StopStatus

    var body: some View {
        ZStack {
            Circle()
                .fill(statusColor)
                .frame(width: 32, height: 32)

            if status == .completed {
                Image(systemName: "checkmark")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            } else {
                Text("\(index)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
        }
        .shadow(radius: 2)
    }

    private var statusColor: Color {
        switch status {
        case .pending: return ColorConstants.primary
        case .inTransit: return ColorConstants.warning
        case .arrived: return ColorConstants.warning
        case .completed: return ColorConstants.success
        case .failed: return ColorConstants.error
        case .skipped: return ColorConstants.secondary
        }
    }
}

// MARK: - Route Stat Item

struct RouteStatItem: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(ColorConstants.primary)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(ColorConstants.Surface.secondaryGrouped)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Stop Row

struct StopRow: View {
    let stop: RouteStop
    let index: Int
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Index circle with connector
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.15))
                        .frame(width: 36, height: 36)

                    if stop.status == .completed {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(statusColor)
                    } else {
                        Text("\(index)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(statusColor)
                    }
                }

                if !isLast {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 2, height: 32)
                }
            }

            // Stop details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(stop.name ?? "Stop \(index)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    Spacer()

                    Text(stop.status.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(statusColor.opacity(0.15))
                        .foregroundStyle(statusColor)
                        .clipShape(Capsule())
                }

                if !stop.address.isEmpty {
                    Text(stop.address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let arrival = stop.actualArrival ?? stop.estimatedArrival {
                    Text(stop.actualArrival != nil ? "Arrived: " : "ETA: ")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    +
                    Text(arrival.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom, isLast ? 0 : 16)
        }
    }

    private var statusColor: Color {
        switch stop.status {
        case .pending: return ColorConstants.primary
        case .inTransit: return ColorConstants.warning
        case .arrived: return ColorConstants.warning
        case .completed: return ColorConstants.success
        case .failed: return ColorConstants.error
        case .skipped: return ColorConstants.secondary
        }
    }
}

// MARK: - Stop Detail Sheet

struct StopDetailSheet: View {
    @Environment(\.dismiss) private var dismiss

    let stop: RouteStop
    @ObservedObject var viewModel: RoutesViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Map
                Map {
                    Marker(stop.name ?? "Stop", coordinate: CLLocationCoordinate2D(
                        latitude: stop.latitude,
                        longitude: stop.longitude
                    ))
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Details
                VStack(alignment: .leading, spacing: 16) {
                    if let name = stop.name {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Name")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(name)
                                .font(.headline)
                        }
                    }

                    if !stop.address.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Address")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(stop.address)
                                .font(.subheadline)
                        }
                    }

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Status")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(stop.status.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }

                        Spacer()

                        if let arrival = stop.actualArrival ?? stop.estimatedArrival {
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(stop.actualArrival != nil ? "Arrived" : "ETA")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(arrival.formatted(date: .omitted, time: .shortened))
                                    .font(.subheadline)
                            }
                        }
                    }

                    if let notes = stop.notes {
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
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Spacer()

                // Actions
                VStack(spacing: 12) {
                    if stop.status == .pending {
                        Button {
                            viewModel.updateStopStatus(stop, status: .arrived)
                            dismiss()
                        } label: {
                            Label("Mark as Arrived", systemImage: "location.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    if stop.status == .arrived || stop.status == .pending {
                        Button {
                            viewModel.updateStopStatus(stop, status: .completed)
                            dismiss()
                        } label: {
                            Label("Mark as Complete", systemImage: "checkmark.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(GlassButtonStyleWrapper())
                    }

                    Button {
                        navigateToStop()
                    } label: {
                        Label("Navigate Here", systemImage: "arrow.triangle.turn.up.right.diamond")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(GlassButtonStyleWrapper(variant: .secondary))
                }
            }
            .padding()
            .navigationTitle("Stop Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func navigateToStop() {
        let coordinate = CLLocationCoordinate2D(
            latitude: stop.latitude,
            longitude: stop.longitude
        )

        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = stop.name ?? "Destination"

        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

// MARK: - Route Navigation View

struct RouteNavigationView: View {
    @Environment(\.dismiss) private var dismiss

    let route: DeliveryRoute
    @ObservedObject var viewModel: RoutesViewModel

    @State private var currentStopIndex = 0
    @State private var camera: MapCameraPosition = .automatic

    var body: some View {
        ZStack {
            // Full-screen map
            Map(position: $camera) {
                UserAnnotation()

                ForEach(Array(sortedStops.enumerated()), id: \.element.id) { index, stop in
                    Annotation("", coordinate: CLLocationCoordinate2D(
                        latitude: stop.latitude,
                        longitude: stop.longitude
                    )) {
                        StopMarker(index: index + 1, status: stop.status)
                    }
                }

                if sortedStops.count > 1 {
                    MapPolyline(coordinates: sortedStops.map {
                        CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                    })
                    .stroke(ColorConstants.Map.route, lineWidth: 5)
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .mapControls {
                MapCompass()
                MapUserLocationButton()
            }

            VStack {
                // Top bar
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }

                    Spacer()

                    Text(route.name ?? route.displayName)
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())

                    Spacer()

                    Button {
                        openCurrentStopInMaps()
                    } label: {
                        Image(systemName: "arrow.triangle.turn.up.right.diamond")
                            .font(.headline)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding()

                Spacer()

                // Bottom card - current stop
                if let currentStop = currentStop {
                    NavigationStopCard(
                        stop: currentStop,
                        index: currentStopIndex + 1,
                        total: sortedStops.count,
                        onComplete: {
                            completeCurrentStop()
                        },
                        onSkip: {
                            skipCurrentStop()
                        },
                        onNavigate: {
                            openCurrentStopInMaps()
                        }
                    )
                    .padding()
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .onAppear {
            updateCurrentStop()
        }
    }

    private var sortedStops: [RouteStop] {
        route.stops.sorted { $0.orderIndex < $1.orderIndex }
    }

    private var currentStop: RouteStop? {
        guard currentStopIndex < sortedStops.count else { return nil }
        return sortedStops[currentStopIndex]
    }

    private func updateCurrentStop() {
        // Find first non-completed stop
        for (index, stop) in sortedStops.enumerated() {
            if stop.status != .completed && stop.status != .skipped {
                currentStopIndex = index
                focusOnStop(stop)
                return
            }
        }
    }

    private func focusOnStop(_ stop: RouteStop) {
        withAnimation {
            camera = .camera(MapCamera(
                centerCoordinate: CLLocationCoordinate2D(
                    latitude: stop.latitude,
                    longitude: stop.longitude
                ),
                distance: 1000
            ))
        }
    }

    private func completeCurrentStop() {
        guard let stop = currentStop else { return }
        viewModel.updateStopStatus(stop, status: .completed)

        // Move to next stop
        if currentStopIndex < sortedStops.count - 1 {
            currentStopIndex += 1
            if let nextStop = currentStop {
                focusOnStop(nextStop)
            }
        } else {
            // All stops completed
            Task {
                await viewModel.completeRoute(route)
                dismiss()
            }
        }
    }

    private func skipCurrentStop() {
        guard let stop = currentStop else { return }
        viewModel.updateStopStatus(stop, status: .skipped)

        // Move to next stop
        if currentStopIndex < sortedStops.count - 1 {
            currentStopIndex += 1
            if let nextStop = currentStop {
                focusOnStop(nextStop)
            }
        }
    }

    private func openCurrentStopInMaps() {
        guard let stop = currentStop else { return }

        let coordinate = CLLocationCoordinate2D(
            latitude: stop.latitude,
            longitude: stop.longitude
        )

        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = stop.name ?? "Destination"

        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

// MARK: - Navigation Stop Card

struct NavigationStopCard: View {
    let stop: RouteStop
    let index: Int
    let total: Int
    let onComplete: () -> Void
    let onSkip: () -> Void
    let onNavigate: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Stop \(index) of \(total)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(stop.status.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.15))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
            }

            // Stop info
            VStack(alignment: .leading, spacing: 4) {
                Text(stop.name ?? "Stop \(index)")
                    .font(.headline)

                if !stop.address.isEmpty {
                    Text(stop.address)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Actions
            HStack(spacing: 12) {
                Button {
                    onSkip()
                } label: {
                    Text("Skip")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyleWrapper(variant: .secondary))

                Button {
                    onNavigate()
                } label: {
                    Label("Navigate", systemImage: "location.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyleWrapper())

                Button {
                    onComplete()
                } label: {
                    Image(systemName: "checkmark")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: DeliveryRoute.self, configurations: config)

    let route = DeliveryRoute()
    route.name = "Test Route"
    route.status = .planned

    container.mainContext.insert(route)

    return NavigationStack {
        RouteDetailView(
            route: route,
            viewModel: RoutesViewModel(modelContext: container.mainContext)
        )
    }
    .modelContainer(container)
}
