//
//  RoutesViewModel.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import Foundation
import SwiftUI
import SwiftData
import Combine
import CoreLocation
import MapKit
import os

/// ViewModel for the Routes feature
@MainActor
final class RoutesViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var routes: [DeliveryRoute] = []
    @Published var loadState: LoadableState<[DeliveryRoute]> = .idle
    @Published var searchText = ""

    @Published var selectedRoute: DeliveryRoute?
    @Published var showingCreateRoute = false
    @Published var showingRouteDetail: DeliveryRoute?

    // Route Planning
    @Published var newRouteStops: [RouteStopDraft] = []
    @Published var isOptimizing = false
    @Published var optimizedOrder: [Int]?

    // MARK: - Properties

    private let modelContext: ModelContext
    private let apiClient = APIClient.shared
    private let locationService = LocationTrackingService.shared

    // MARK: - Computed Properties

    var filteredRoutes: [DeliveryRoute] {
        if searchText.isEmpty {
            return routes
        }

        let query = searchText.lowercased()
        return routes.filter { route in
            (route.name?.lowercased().contains(query) ?? false) ||
            route.stops.contains { stop in
                stop.recipientName?.lowercased().contains(query) == true ||
                stop.address.lowercased().contains(query)
            }
        }
    }

    var activeRoutes: [DeliveryRoute] {
        routes.filter { $0.status == .planned || $0.status == .inProgress }
    }

    var completedRoutes: [DeliveryRoute] {
        routes.filter { $0.status == .completed }
    }

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Data Loading

    func loadRoutes() async {
        loadState = .loading

        let descriptor = FetchDescriptor<DeliveryRoute>(
            sortBy: [
                SortDescriptor(\DeliveryRoute.createdAt, order: .reverse)
            ]
        )

        do {
            routes = try modelContext.fetch(descriptor)
            loadState = .loaded(routes)

            if NetworkMonitor.shared.isConnected {
                await syncRoutes()
            }
        } catch {
            loadState = .error(AppError.from(error))
            AppLogger.data.error("Failed to fetch routes: \(error.localizedDescription)")
        }
    }

    func refresh() async {
        guard case .loaded = loadState else {
            await loadRoutes()
            return
        }

        loadState = .refreshing(routes)
        await loadRoutes()
    }

    private func syncRoutes() async {
        do {
            let response: [RouteResponse] = try await apiClient.request(RouteEndpoints.list(pagination: PaginationParameters(), status: nil))

            for routeResponse in response {
                await mergeRoute(routeResponse)
            }

            try modelContext.save()
        } catch {
            AppLogger.sync.error("Failed to sync routes: \(error.localizedDescription)")
        }
    }

    private func mergeRoute(_ response: RouteResponse) async {
        let routeId = UUID(uuidString: response.id)!
        let descriptor = FetchDescriptor<DeliveryRoute>(
            predicate: #Predicate<DeliveryRoute> { $0.id == routeId }
        )

        do {
            let existing = try modelContext.fetch(descriptor)

            if let localRoute = existing.first {
                localRoute.syncStatus = .synced
                localRoute.lastSyncedAt = Date()
            } else {
                let route = DeliveryRoute(id: routeId, name: response.name)
                route.notes = response.notes
                route.status = RouteStatus(rawValue: response.status) ?? .planned
                route.totalDurationSeconds = response.totalDurationSeconds
                // Convert miles to meters for distance
                if let distanceMiles = response.totalDistanceMiles {
                    route.totalDistanceMeters = Int(distanceMiles / 0.000621371)
                }
                route.syncStatus = .synced
                route.lastSyncedAt = Date()

                modelContext.insert(route)
            }
        } catch {
            AppLogger.data.error("Failed to merge route: \(error.localizedDescription)")
        }
    }

    // MARK: - Route Creation

    func createRoute(name: String, notes: String?, vehicleId: UUID?) async -> DeliveryRoute? {
        let route = DeliveryRoute(name: name)
        route.notes = notes
        route.vehicleId = vehicleId
        route.status = .planned
        route.syncStatus = .pending

        // Add stops
        for (index, draft) in newRouteStops.enumerated() {
            let stop = DeliveryStop(
                sequenceOriginal: index,
                address: draft.address,
                latitude: draft.coordinate.latitude,
                longitude: draft.coordinate.longitude
            )
            stop.recipientName = draft.name
            stop.estimatedArrival = draft.estimatedArrival
            stop.deliveryNotes = draft.notes
            stop.route = route

            route.stops.append(stop)
            modelContext.insert(stop)
        }

        modelContext.insert(route)

        do {
            try modelContext.save()
            routes.insert(route, at: 0)

            // Sync to server
            if NetworkMonitor.shared.isConnected {
                await syncNewRoute(route)
            }

            // Clear draft
            newRouteStops = []

            return route
        } catch {
            AppLogger.data.error("Failed to create route: \(error.localizedDescription)")
            return nil
        }
    }

    private func syncNewRoute(_ route: DeliveryRoute) async {
        let stops = route.stops.map { stop in
            CreateStopRequest(
                name: stop.name ?? "",
                address: stop.address ?? "",
                latitude: stop.latitude,
                longitude: stop.longitude,
                notes: stop.notes,
                contactName: nil,
                contactPhone: nil,
                timeWindowStart: nil,
                timeWindowEnd: nil,
                estimatedDuration: nil,
                priority: nil
            )
        }

        let request = CreateRouteRequest(
            name: route.name ?? route.displayName,
            scheduledDate: nil,
            vehicleId: route.vehicleId?.uuidString,
            optimizationMode: nil,
            returnToStart: nil,
            stops: stops
        )

        do {
            let _: RouteResponse = try await apiClient.request(RouteEndpoints.create(route: request))
            route.syncStatus = .synced
            route.lastSyncedAt = Date()
            try? modelContext.save()
        } catch {
            AppLogger.sync.error("Failed to sync route: \(error.localizedDescription)")
        }
    }

    // MARK: - Route Management

    func deleteRoute(_ route: DeliveryRoute) async {
        // Delete stops first
        for stop in route.stops {
            modelContext.delete(stop)
        }

        modelContext.delete(route)

        do {
            try modelContext.save()
            routes.removeAll { $0.id == route.id }

            if NetworkMonitor.shared.isConnected {
                try await apiClient.requestVoid(RouteEndpoints.delete(id: route.id.uuidString))
            }
        } catch {
            AppLogger.data.error("Failed to delete route: \(error.localizedDescription)")
        }
    }

    func startRoute(_ route: DeliveryRoute) async {
        route.status = .inProgress
        route.startedAt = Date()
        route.syncStatus = .pending

        do {
            try modelContext.save()

            if NetworkMonitor.shared.isConnected {
                try await apiClient.requestVoid(RouteEndpoints.startRoute(id: route.id.uuidString))
                route.syncStatus = .synced
                try? modelContext.save()
            }
        } catch {
            AppLogger.data.error("Failed to start route: \(error.localizedDescription)")
        }
    }

    func completeRoute(_ route: DeliveryRoute) async {
        route.status = .completed
        route.completedAt = Date()
        route.syncStatus = .pending

        do {
            try modelContext.save()

            if NetworkMonitor.shared.isConnected {
                try await apiClient.requestVoid(RouteEndpoints.completeRoute(id: route.id.uuidString))
                route.syncStatus = .synced
                try? modelContext.save()
            }
        } catch {
            AppLogger.data.error("Failed to complete route: \(error.localizedDescription)")
        }
    }

    // MARK: - Route Optimization

    func optimizeRoute() async {
        guard newRouteStops.count >= 2 else { return }

        isOptimizing = true

        // Get current location as starting point
        let startLocation = locationService.currentLocation?.coordinate ?? newRouteStops[0].coordinate

        // Simple nearest-neighbor algorithm for optimization
        var optimized: [Int] = []
        var remaining = Array(0..<newRouteStops.count)
        var currentLocation = startLocation

        while !remaining.isEmpty {
            var nearestIndex = 0
            var nearestDistance = Double.infinity

            for (i, stopIndex) in remaining.enumerated() {
                let stop = newRouteStops[stopIndex]
                let distance = calculateDistance(from: currentLocation, to: stop.coordinate)

                if distance < nearestDistance {
                    nearestDistance = distance
                    nearestIndex = i
                }
            }

            let chosenIndex = remaining.remove(at: nearestIndex)
            optimized.append(chosenIndex)
            currentLocation = newRouteStops[chosenIndex].coordinate
        }

        // Reorder stops
        let reorderedStops = optimized.map { newRouteStops[$0] }
        newRouteStops = reorderedStops

        isOptimizing = false
    }

    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }

    // MARK: - Stop Management

    func addStop(_ stop: RouteStopDraft) {
        newRouteStops.append(stop)
    }

    func removeStop(at index: Int) {
        guard index < newRouteStops.count else { return }
        newRouteStops.remove(at: index)
    }

    func moveStop(from source: IndexSet, to destination: Int) {
        newRouteStops.move(fromOffsets: source, toOffset: destination)
    }

    func updateStopStatus(_ stop: RouteStop, status: StopStatus) {
        stop.status = status

        if status == .completed {
            stop.actualArrival = Date()
        }

        try? modelContext.save()
    }
}

// MARK: - Route Stop Draft

struct RouteStopDraft: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var address: String
    var coordinate: CLLocationCoordinate2D
    var estimatedArrival: Date?
    var notes: String?

    static func == (lhs: RouteStopDraft, rhs: RouteStopDraft) -> Bool {
        lhs.id == rhs.id
    }
}
