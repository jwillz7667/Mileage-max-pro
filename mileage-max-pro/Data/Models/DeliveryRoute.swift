//
//  DeliveryRoute.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import Foundation
import SwiftData

/// Delivery route model for multi-stop route optimization
@Model
final class DeliveryRoute {
    // MARK: - Primary Identifiers

    @Attribute(.unique)
    var id: UUID

    // MARK: - Route Info

    var name: String?
    var statusRaw: String
    var optimizationModeRaw: String

    // MARK: - Scheduling

    var scheduledDate: Date?
    var scheduledStartTime: Date?
    var actualStartTime: Date?
    var actualEndTime: Date?

    // MARK: - Stop Counts

    var totalStops: Int
    var completedStops: Int

    // MARK: - Distance & Duration (Estimated)

    var totalDistanceMeters: Int?
    var totalDurationSeconds: Int?

    // MARK: - Distance & Duration (Actual)

    var actualDistanceMeters: Int?
    var actualDurationSeconds: Int?

    // MARK: - Return Settings

    var returnToStart: Bool

    // MARK: - Optimized Order

    var optimizedOrder: [Int]?

    // MARK: - Route Display

    var routePolyline: String?

    // MARK: - Notes

    var notes: String?

    // MARK: - Vehicle Reference

    var vehicleId: UUID?

    // MARK: - Sync Status

    var syncStatusRaw: String?
    var lastSyncedAt: Date?

    // MARK: - Timestamps

    var createdAt: Date
    var updatedAt: Date

    // MARK: - Relationships

    var user: User?
    var startLocation: SavedLocation?
    var endLocation: SavedLocation?

    @Relationship(deleteRule: .cascade, inverse: \DeliveryStop.route)
    var stops: [DeliveryStop]

    // MARK: - Computed Properties

    var status: RouteStatus {
        get { RouteStatus(rawValue: statusRaw) ?? .planned }
        set { statusRaw = newValue.rawValue }
    }

    var optimizationMode: OptimizationMode {
        get { OptimizationMode(rawValue: optimizationModeRaw) ?? .fastest }
        set { optimizationModeRaw = newValue.rawValue }
    }

    var displayName: String {
        name ?? "Route \(createdAt.shortDateString)"
    }

    var totalDistanceMiles: Double? {
        totalDistanceMeters.map { Double($0) * 0.000621371 }
    }

    var actualDistanceMiles: Double? {
        actualDistanceMeters.map { Double($0) * 0.000621371 }
    }

    var formattedTotalDistance: String? {
        totalDistanceMiles?.formattedMiles
    }

    var formattedActualDistance: String? {
        actualDistanceMiles?.formattedMiles
    }

    var estimatedDuration: TimeInterval? {
        totalDurationSeconds.map { TimeInterval($0) }
    }

    var formattedEstimatedDuration: String? {
        estimatedDuration?.compactDuration
    }

    var actualDuration: TimeInterval? {
        actualDurationSeconds.map { TimeInterval($0) }
    }

    var formattedActualDuration: String? {
        actualDuration?.compactDuration
    }

    var completionPercentage: Double {
        guard totalStops > 0 else { return 0 }
        return Double(completedStops) / Double(totalStops)
    }

    var isActive: Bool {
        status == .inProgress
    }

    var isCompleted: Bool {
        status == .completed
    }

    var remainingStops: Int {
        totalStops - completedStops
    }

    /// Sorted stops by optimized order
    var sortedStops: [DeliveryStop] {
        if let order = optimizedOrder {
            return stops.sorted { stop1, stop2 in
                let index1 = order.firstIndex(of: stop1.sequenceOriginal) ?? Int.max
                let index2 = order.firstIndex(of: stop2.sequenceOriginal) ?? Int.max
                return index1 < index2
            }
        }
        return stops.sorted { $0.sequenceOriginal < $1.sequenceOriginal }
    }

    /// Next pending stop
    var nextStop: DeliveryStop? {
        sortedStops.first { $0.status == .pending || $0.status == .inTransit }
    }

    /// Current stop (arrived but not completed)
    var currentStop: DeliveryStop? {
        sortedStops.first { $0.status == .arrived }
    }

    /// Sync status computed from raw value
    var syncStatus: SyncStatus {
        get { SyncStatus(rawValue: syncStatusRaw ?? SyncStatus.pending.rawValue) ?? .pending }
        set { syncStatusRaw = newValue.rawValue }
    }

    /// Alias for actualStartTime for convenience
    var startedAt: Date? {
        get { actualStartTime }
        set { actualStartTime = newValue }
    }

    /// Alias for actualEndTime for convenience
    var completedAt: Date? {
        get { actualEndTime }
        set { actualEndTime = newValue }
    }

    /// Estimated distance in miles
    var estimatedDistance: Double? {
        totalDistanceMiles
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        name: String? = nil,
        optimizationMode: OptimizationMode = .fastest,
        returnToStart: Bool = true
    ) {
        self.id = id
        self.name = name
        self.statusRaw = RouteStatus.planned.rawValue
        self.optimizationModeRaw = optimizationMode.rawValue
        self.scheduledDate = nil
        self.scheduledStartTime = nil
        self.actualStartTime = nil
        self.actualEndTime = nil
        self.totalStops = 0
        self.completedStops = 0
        self.totalDistanceMeters = nil
        self.totalDurationSeconds = nil
        self.actualDistanceMeters = nil
        self.actualDurationSeconds = nil
        self.returnToStart = returnToStart
        self.optimizedOrder = nil
        self.routePolyline = nil
        self.notes = nil
        self.createdAt = Date()
        self.updatedAt = Date()
        self.user = nil
        self.startLocation = nil
        self.endLocation = nil
        self.stops = []
    }

    // MARK: - Methods

    func update() {
        updatedAt = Date()
    }

    func addStop(_ stop: DeliveryStop) {
        stop.sequenceOriginal = stops.count
        stop.route = self
        stops.append(stop)
        totalStops = stops.count
        update()
    }

    func removeStop(_ stop: DeliveryStop) {
        stops.removeAll { $0.id == stop.id }
        totalStops = stops.count
        // Re-sequence remaining stops
        for (index, remainingStop) in stops.sorted(by: { $0.sequenceOriginal < $1.sequenceOriginal }).enumerated() {
            remainingStop.sequenceOriginal = index
        }
        update()
    }

    func start() {
        status = .inProgress
        actualStartTime = Date()
        update()
    }

    func complete() {
        status = .completed
        actualEndTime = Date()
        if let start = actualStartTime {
            actualDurationSeconds = Int(Date().timeIntervalSince(start))
        }
        update()
    }

    func cancel() {
        status = .canceled
        update()
    }

    func applyOptimization(order: [Int], distance: Int, duration: Int) {
        optimizedOrder = order
        totalDistanceMeters = distance
        totalDurationSeconds = duration

        // Update optimized sequence on stops
        for (optimizedIndex, originalIndex) in order.enumerated() {
            if let stop = stops.first(where: { $0.sequenceOriginal == originalIndex }) {
                stop.sequenceOptimized = optimizedIndex
            }
        }

        update()
    }

    func updateCompletedCount() {
        completedStops = stops.filter { $0.status == .completed }.count
        update()
    }
}

// MARK: - Route Status

enum RouteStatus: String, Codable, CaseIterable {
    case planned = "planned"
    case inProgress = "in_progress"
    case completed = "completed"
    case canceled = "canceled"

    var displayName: String {
        switch self {
        case .planned: return "Planned"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .canceled: return "Canceled"
        }
    }

    var iconName: String {
        switch self {
        case .planned: return "calendar"
        case .inProgress: return "location.fill"
        case .completed: return "checkmark.circle.fill"
        case .canceled: return "xmark.circle.fill"
        }
    }
}

// MARK: - Optimization Mode

enum OptimizationMode: String, Codable, CaseIterable {
    case fastest = "fastest"
    case shortest = "shortest"
    case balanced = "balanced"

    var displayName: String {
        switch self {
        case .fastest: return "Fastest"
        case .shortest: return "Shortest"
        case .balanced: return "Balanced"
        }
    }

    var modeDescription: String {
        switch self {
        case .fastest: return "Minimize driving time"
        case .shortest: return "Minimize distance"
        case .balanced: return "Balance time and distance"
        }
    }
}

// MARK: - Delivery Route DTO

struct DeliveryRouteDTO: Codable, Identifiable, Equatable {
    let id: UUID
    let name: String?
    let status: String
    let optimizationMode: String
    let scheduledDate: Date?
    let scheduledStartTime: Date?
    let actualStartTime: Date?
    let actualEndTime: Date?
    let totalStops: Int
    let completedStops: Int
    let totalDistanceMeters: Int?
    let totalDurationSeconds: Int?
    let returnToStart: Bool
    let optimizedOrder: [Int]?
    let routePolyline: String?
    let startLocationId: UUID?
    let endLocationId: UUID?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, status
        case optimizationMode = "optimization_mode"
        case scheduledDate = "scheduled_date"
        case scheduledStartTime = "scheduled_start_time"
        case actualStartTime = "actual_start_time"
        case actualEndTime = "actual_end_time"
        case totalStops = "total_stops"
        case completedStops = "completed_stops"
        case totalDistanceMeters = "total_distance_meters"
        case totalDurationSeconds = "total_duration_seconds"
        case returnToStart = "return_to_start"
        case optimizedOrder = "optimized_order"
        case routePolyline = "route_polyline"
        case startLocationId = "start_location_id"
        case endLocationId = "end_location_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    func toModel() -> DeliveryRoute {
        let route = DeliveryRoute(
            id: id,
            name: name,
            optimizationMode: OptimizationMode(rawValue: optimizationMode) ?? .fastest,
            returnToStart: returnToStart
        )
        route.statusRaw = status
        route.scheduledDate = scheduledDate
        route.scheduledStartTime = scheduledStartTime
        route.actualStartTime = actualStartTime
        route.actualEndTime = actualEndTime
        route.totalStops = totalStops
        route.completedStops = completedStops
        route.totalDistanceMeters = totalDistanceMeters
        route.totalDurationSeconds = totalDurationSeconds
        route.optimizedOrder = optimizedOrder
        route.routePolyline = routePolyline
        route.createdAt = createdAt
        route.updatedAt = updatedAt
        return route
    }
}

extension DeliveryRoute {
    func toDTO() -> DeliveryRouteDTO {
        DeliveryRouteDTO(
            id: id,
            name: name,
            status: statusRaw,
            optimizationMode: optimizationModeRaw,
            scheduledDate: scheduledDate,
            scheduledStartTime: scheduledStartTime,
            actualStartTime: actualStartTime,
            actualEndTime: actualEndTime,
            totalStops: totalStops,
            completedStops: completedStops,
            totalDistanceMeters: totalDistanceMeters,
            totalDurationSeconds: totalDurationSeconds,
            returnToStart: returnToStart,
            optimizedOrder: optimizedOrder,
            routePolyline: routePolyline,
            startLocationId: startLocation?.id,
            endLocationId: endLocation?.id,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
