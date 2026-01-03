//
//  RoutesListView.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import SwiftUI
import SwiftData
import MapKit

/// List view for managing delivery routes
struct RoutesListView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        RoutesListContentView(modelContext: modelContext)
    }
}

/// Internal content view with initialized ViewModel
private struct RoutesListContentView: View {
    @StateObject private var viewModel: RoutesViewModel

    @State private var showingCreateRoute = false
    @State private var routeToDelete: DeliveryRoute?
    @State private var showingDeleteConfirmation = false

    init(modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: RoutesViewModel(modelContext: modelContext))
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.loadState {
                case .idle, .loading:
                    loadingView

                case .loaded, .refreshing:
                    if viewModel.routes.isEmpty {
                        emptyStateView
                    } else {
                        routesList
                    }

                case .error(let error):
                    errorView(error)
                }
            }
            .navigationTitle("Routes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreateRoute = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Search routes")
            .refreshable {
                await viewModel.refresh()
            }
            .sheet(isPresented: $showingCreateRoute) {
                CreateRouteView(viewModel: viewModel)
            }
            .confirmationDialog(
                "Delete Route",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let route = routeToDelete {
                        Task {
                            await viewModel.deleteRoute(route)
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete this route and all its stops.")
            }
            .task {
                await viewModel.loadRoutes()
            }
        }
    }

    // MARK: - Routes List

    private var routesList: some View {
        List {
            // Active Routes
            if !viewModel.activeRoutes.isEmpty {
                Section {
                    ForEach(viewModel.activeRoutes) { route in
                        NavigationLink(value: route) {
                            RouteRowView(route: route)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                routeToDelete = route
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            if route.status == .planned {
                                Button {
                                    Task {
                                        await viewModel.startRoute(route)
                                    }
                                } label: {
                                    Label("Start", systemImage: "play.fill")
                                }
                                .tint(.green)
                            }
                        }
                    }
                } header: {
                    Text("Active Routes")
                }
            }

            // Completed Routes
            if !viewModel.completedRoutes.isEmpty {
                Section {
                    ForEach(viewModel.completedRoutes) { route in
                        NavigationLink(value: route) {
                            RouteRowView(route: route)
                                .opacity(0.7)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                routeToDelete = route
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    Text("Completed")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationDestination(for: DeliveryRoute.self) { route in
            RouteDetailView(route: route, viewModel: viewModel)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading routes...")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Routes", systemImage: "map")
        } description: {
            Text("Create a route to plan and optimize your trips")
        } actions: {
            Button {
                showingCreateRoute = true
            } label: {
                Text("Create Route")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Error View

    private func errorView(_ error: AppError) -> some View {
        ContentUnavailableView {
            Label("Error Loading Routes", systemImage: "exclamationmark.triangle")
        } description: {
            Text(error.localizedDescription)
        } actions: {
            Button("Retry") {
                Task {
                    await viewModel.loadRoutes()
                }
            }
            .buttonStyle(.bordered)
        }
    }
}

// MARK: - Route Row View

struct RouteRowView: View {
    let route: DeliveryRoute

    var body: some View {
        HStack(spacing: 16) {
            // Route Icon
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: statusIcon)
                    .font(.title2)
                    .foregroundStyle(statusColor)
            }

            // Route Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(route.name ?? route.displayName)
                        .font(.headline)

                    Spacer()

                    StatusChip(status: route.status)
                }

                HStack(spacing: 8) {
                    Label("\(route.stops.count) stops", systemImage: "mappin.circle")

                    if let distance = route.estimatedDistance {
                        Text("•")
                        Text(String(format: "%.1f mi", distance))
                    }

                    if let duration = route.estimatedDuration {
                        Text("•")
                        Text("\(duration) min")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var statusColor: Color {
        switch route.status {
        case .planned: return .blue
        case .inProgress: return .green
        case .completed: return .gray
        case .canceled: return .red
        }
    }

    private var statusIcon: String {
        switch route.status {
        case .planned: return "calendar"
        case .inProgress: return "location.fill"
        case .completed: return "checkmark.circle"
        case .canceled: return "xmark.circle"
        }
    }
}

// MARK: - Status Chip

struct StatusChip: View {
    let status: RouteStatus

    var body: some View {
        Text(status.rawValue)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(statusColor.opacity(0.15))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch status {
        case .planned: return .blue
        case .inProgress: return .green
        case .completed: return .gray
        case .canceled: return .red
        }
    }
}

// MARK: - Create Route View

struct CreateRouteView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: RoutesViewModel

    @State private var name = ""
    @State private var notes = ""
    @State private var showingAddStop = false
    @State private var isCreating = false

    var body: some View {
        NavigationStack {
            Form {
                // Route Info
                Section("Route Information") {
                    TextField("Route Name", text: $name)

                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                // Stops
                Section {
                    if viewModel.newRouteStops.isEmpty {
                        ContentUnavailableView {
                            Label("No Stops", systemImage: "mappin.slash")
                        } description: {
                            Text("Add stops to create your route")
                        } actions: {
                            Button("Add Stop") {
                                showingAddStop = true
                            }
                            .buttonStyle(.bordered)
                        }
                    } else {
                        ForEach(viewModel.newRouteStops) { stop in
                            StopDraftRow(stop: stop)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                viewModel.removeStop(at: index)
                            }
                        }
                        .onMove { source, destination in
                            viewModel.moveStop(from: source, to: destination)
                        }

                        Button {
                            showingAddStop = true
                        } label: {
                            Label("Add Stop", systemImage: "plus.circle")
                        }
                    }
                } header: {
                    HStack {
                        Text("Stops")
                        Spacer()
                        if viewModel.newRouteStops.count >= 2 {
                            Button {
                                Task {
                                    await viewModel.optimizeRoute()
                                }
                            } label: {
                                if viewModel.isOptimizing {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Label("Optimize", systemImage: "wand.and.stars")
                                }
                            }
                            .font(.caption)
                            .disabled(viewModel.isOptimizing)
                        }
                    }
                }

                // Map Preview
                if !viewModel.newRouteStops.isEmpty {
                    Section("Preview") {
                        RoutePreviewMap(stops: viewModel.newRouteStops)
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .listRowInsets(EdgeInsets())
                    }
                }
            }
            .navigationTitle("Create Route")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.newRouteStops = []
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createRoute()
                    }
                    .disabled(!canCreate || isCreating)
                }

                ToolbarItem(placement: .keyboard) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingAddStop) {
                AddStopSheet { stop in
                    viewModel.addStop(stop)
                }
            }
        }
    }

    private var canCreate: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !viewModel.newRouteStops.isEmpty
    }

    private func createRoute() {
        isCreating = true

        Task {
            if await viewModel.createRoute(
                name: name.trimmingCharacters(in: .whitespaces),
                notes: notes.isEmpty ? nil : notes,
                vehicleId: nil
            ) != nil {
                dismiss()
            }

            isCreating = false
        }
    }
}

// MARK: - Stop Draft Row

struct StopDraftRow: View {
    let stop: RouteStopDraft

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !stop.name.isEmpty {
                Text(stop.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            Text(stop.address)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Route Preview Map

struct RoutePreviewMap: View {
    let stops: [RouteStopDraft]

    var body: some View {
        Map {
            ForEach(Array(stops.enumerated()), id: \.element.id) { index, stop in
                Annotation("\(index + 1)", coordinate: stop.coordinate) {
                    ZStack {
                        Circle()
                            .fill(.blue)
                            .frame(width: 28, height: 28)
                        Text("\(index + 1)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                }
            }

            if stops.count > 1 {
                MapPolyline(coordinates: stops.map { $0.coordinate })
                    .stroke(.blue, lineWidth: 3)
            }
        }
        .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
    }
}

// MARK: - Add Stop Sheet

struct AddStopSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onAdd: (RouteStopDraft) -> Void

    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    @State private var selectedItem: MKMapItem?

    @State private var stopName = ""
    @State private var stopNotes = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField("Search for a location", text: $searchText)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            searchLocations()
                        }

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            searchResults = []
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))

                if let selected = selectedItem {
                    // Selected location details
                    Form {
                        Section {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(selected.name ?? "Unknown Location")
                                    .font(.headline)

                                if let address = selected.placemark.formattedAddress {
                                    Text(address)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }

                        Section("Stop Details") {
                            TextField("Stop Name (optional)", text: $stopName)

                            TextField("Notes (optional)", text: $stopNotes, axis: .vertical)
                                .lineLimit(2...4)
                        }

                        Section {
                            // Mini map
                            Map {
                                Marker(selected.name ?? "", coordinate: selected.placemark.coordinate)
                            }
                            .frame(height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .disabled(true)
                            .listRowInsets(EdgeInsets())
                        }
                    }
                } else {
                    // Search results
                    if isSearching {
                        VStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else if searchResults.isEmpty && !searchText.isEmpty {
                        ContentUnavailableView {
                            Label("No Results", systemImage: "mappin.slash")
                        } description: {
                            Text("Try a different search term")
                        }
                    } else {
                        List(searchResults, id: \.self) { item in
                            Button {
                                selectedItem = item
                                stopName = item.name ?? ""
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name ?? "Unknown")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)

                                    if let address = item.placemark.formattedAddress {
                                        Text(address)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("Add Stop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addStop()
                    }
                    .disabled(selectedItem == nil)
                }
            }
        }
    }

    private func searchLocations() {
        guard !searchText.isEmpty else { return }

        isSearching = true

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.resultTypes = [.address, .pointOfInterest]

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            isSearching = false

            if let items = response?.mapItems {
                searchResults = items
            }
        }
    }

    private func addStop() {
        guard let item = selectedItem else { return }

        let stop = RouteStopDraft(
            name: stopName.isEmpty ? (item.name ?? "") : stopName,
            address: item.placemark.formattedAddress ?? "",
            coordinate: item.placemark.coordinate,
            estimatedArrival: nil,
            notes: stopNotes.isEmpty ? nil : stopNotes
        )

        onAdd(stop)
        dismiss()
    }
}

// MARK: - MKPlacemark Extension

extension MKPlacemark {
    var formattedAddress: String? {
        var components: [String] = []

        if let street = thoroughfare {
            if let number = subThoroughfare {
                components.append("\(number) \(street)")
            } else {
                components.append(street)
            }
        }

        if let city = locality {
            components.append(city)
        }

        if let state = administrativeArea {
            if let postalCode = postalCode {
                components.append("\(state) \(postalCode)")
            } else {
                components.append(state)
            }
        }

        return components.isEmpty ? nil : components.joined(separator: ", ")
    }
}

#Preview {
    NavigationStack {
        Text("Routes Preview")
    }
}
