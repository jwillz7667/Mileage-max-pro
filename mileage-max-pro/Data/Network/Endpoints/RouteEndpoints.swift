//
//  RouteEndpoints.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import Foundation

/// Multi-stop route planning API endpoints
enum RouteEndpoints {

    // MARK: - CRUD Operations

    case list(pagination: PaginationParameters, status: RouteStatus?)
    case get(id: String)
    case create(route: CreateRouteRequest)
    case update(id: String, route: UpdateRouteRequest)
    case delete(id: String)

    // MARK: - Route Actions

    case startRoute(id: String)
    case completeRoute(id: String)
    case cancelRoute(id: String)

    // MARK: - Stop Management

    case addStop(routeId: String, stop: CreateStopRequest)
    case updateStop(routeId: String, stopId: String, stop: UpdateStopRequest)
    case deleteStop(routeId: String, stopId: String)
    case reorderStops(routeId: String, order: [String])

    // MARK: - Stop Actions

    case arriveAtStop(routeId: String, stopId: String)
    case completeStop(routeId: String, stopId: String, completion: CompleteStopRequest)
    case skipStop(routeId: String, stopId: String, reason: String?)
    case failStop(routeId: String, stopId: String, reason: String)

    // MARK: - Optimization

    case optimize(id: String, options: OptimizationOptions?)
    case getOptimizedOrder(id: String)

    // MARK: - Navigation

    case getDirections(routeId: String, fromStopId: String?, toStopId: String)
    case getRouteOverview(id: String)

    // MARK: - Templates

    case listTemplates
    case createTemplate(template: CreateTemplateRequest)
    case applyTemplate(templateId: String)
    case deleteTemplate(templateId: String)
}

extension RouteEndpoints: APIEndpoint {

    var method: HTTPMethod {
        switch self {
        case .list, .get, .listTemplates, .getOptimizedOrder, .getDirections, .getRouteOverview:
            return .get
        case .create, .addStop, .optimize, .createTemplate, .applyTemplate:
            return .post
        case .update, .updateStop, .reorderStops, .startRoute, .completeRoute, .arriveAtStop,
             .completeStop, .skipStop, .failStop:
            return .patch
        case .delete, .deleteStop, .cancelRoute, .deleteTemplate:
            return .delete
        }
    }

    var path: String {
        let base = APIConstants.Endpoints.Routes

        switch self {
        case .list, .create:
            return base
        case .get(let id), .update(let id, _), .delete(let id):
            return "\(base)/\(id)"
        case .startRoute(let id):
            return "\(base)/\(id)/start"
        case .completeRoute(let id):
            return "\(base)/\(id)/complete"
        case .cancelRoute(let id):
            return "\(base)/\(id)/cancel"
        case .addStop(let routeId, _):
            return "\(base)/\(routeId)/stops"
        case .updateStop(let routeId, let stopId, _), .deleteStop(let routeId, let stopId):
            return "\(base)/\(routeId)/stops/\(stopId)"
        case .reorderStops(let routeId, _):
            return "\(base)/\(routeId)/stops/reorder"
        case .arriveAtStop(let routeId, let stopId):
            return "\(base)/\(routeId)/stops/\(stopId)/arrive"
        case .completeStop(let routeId, let stopId, _):
            return "\(base)/\(routeId)/stops/\(stopId)/complete"
        case .skipStop(let routeId, let stopId, _):
            return "\(base)/\(routeId)/stops/\(stopId)/skip"
        case .failStop(let routeId, let stopId, _):
            return "\(base)/\(routeId)/stops/\(stopId)/fail"
        case .optimize(let id, _):
            return "\(base)/\(id)/optimize"
        case .getOptimizedOrder(let id):
            return "\(base)/\(id)/optimized-order"
        case .getDirections(let routeId, _, _):
            return "\(base)/\(routeId)/directions"
        case .getRouteOverview(let id):
            return "\(base)/\(id)/overview"
        case .listTemplates:
            return "\(base)/templates"
        case .createTemplate:
            return "\(base)/templates"
        case .applyTemplate(let templateId):
            return "\(base)/templates/\(templateId)/apply"
        case .deleteTemplate(let templateId):
            return "\(base)/templates/\(templateId)"
        }
    }

    var queryParameters: [String: String]? {
        switch self {
        case .list(let pagination, let status):
            var params = pagination.queryParameters
            if let status = status {
                params["status"] = status.rawValue
            }
            return params
        case .getDirections(_, let fromStopId, let toStopId):
            var params = ["to_stop_id": toStopId]
            if let fromStopId = fromStopId {
                params["from_stop_id"] = fromStopId
            }
            return params
        default:
            return nil
        }
    }

    var body: Encodable? {
        switch self {
        case .create(let route):
            return route
        case .update(_, let route):
            return route
        case .addStop(_, let stop):
            return stop
        case .updateStop(_, _, let stop):
            return stop
        case .reorderStops(_, let order):
            return ReorderStopsRequest(stopIds: order)
        case .completeStop(_, _, let completion):
            return completion
        case .skipStop(_, _, let reason):
            return reason.map { SkipStopRequest(reason: $0) }
        case .failStop(_, _, let reason):
            return FailStopRequest(reason: reason)
        case .optimize(_, let options):
            return options
        case .createTemplate(let template):
            return template
        default:
            return nil
        }
    }
}

// MARK: - Request Models

struct CreateRouteRequest: Codable {
    let name: String
    let scheduledDate: Date?
    let vehicleId: String?
    let optimizationMode: String?
    let returnToStart: Bool?
    let stops: [CreateStopRequest]?
}

struct UpdateRouteRequest: Codable {
    let name: String?
    let scheduledDate: Date?
    let vehicleId: String?
    let notes: String?
}

struct CreateStopRequest: Codable {
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let notes: String?
    let contactName: String?
    let contactPhone: String?
    let timeWindowStart: Date?
    let timeWindowEnd: Date?
    let estimatedDuration: Int?
    let priority: Int?
}

struct UpdateStopRequest: Codable {
    let name: String?
    let address: String?
    let notes: String?
    let contactName: String?
    let contactPhone: String?
    let timeWindowStart: Date?
    let timeWindowEnd: Date?
    let estimatedDuration: Int?
    let priority: Int?
}

struct ReorderStopsRequest: Codable {
    let stopIds: [String]
}

struct CompleteStopRequest: Codable {
    let signature: String?
    let photoUrls: [String]?
    let notes: String?
    let actualArrivalTime: Date?
    let actualDepartureTime: Date?
}

struct SkipStopRequest: Codable {
    let reason: String
}

struct FailStopRequest: Codable {
    let reason: String
}

struct OptimizationOptions: Codable {
    let mode: String?
    let returnToStart: Bool?
    let avoidHighways: Bool?
    let avoidTolls: Bool?
    let departureTime: Date?
}

struct CreateTemplateRequest: Codable {
    let name: String
    let description: String?
    let stops: [CreateStopRequest]
    let defaultOptimizationMode: String?
}

// MARK: - Response Models

struct RouteResponse: Codable {
    let id: String
    let userId: String
    let name: String
    let status: String
    let scheduledDate: Date?
    let startedAt: Date?
    let completedAt: Date?
    let vehicleId: String?
    let totalDistanceMiles: Double?
    let totalDurationSeconds: Int?
    let optimizationMode: String
    let optimizedAt: Date?
    let notes: String?
    let stops: [StopResponse]
    let createdAt: Date
    let updatedAt: Date
}

struct StopResponse: Codable {
    let id: String
    let routeId: String
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let status: String
    let originalOrder: Int
    let optimizedOrder: Int?
    let notes: String?
    let contactName: String?
    let contactPhone: String?
    let timeWindowStart: Date?
    let timeWindowEnd: Date?
    let estimatedArrival: Date?
    let actualArrival: Date?
    let actualDeparture: Date?
    let estimatedDuration: Int?
    let distanceFromPrevious: Double?
    let durationFromPrevious: Int?
    let failureReason: String?
    let signature: String?
    let createdAt: Date
}

struct OptimizedRouteResponse: Codable {
    let routeId: String
    let originalOrder: [String]
    let optimizedOrder: [String]
    let originalDistance: Double
    let optimizedDistance: Double
    let distanceSaved: Double
    let originalDuration: Int
    let optimizedDuration: Int
    let timeSaved: Int
    let stops: [OptimizedStopInfo]

    struct OptimizedStopInfo: Codable {
        let stopId: String
        let originalPosition: Int
        let optimizedPosition: Int
        let estimatedArrival: Date
        let distanceFromPrevious: Double
        let durationFromPrevious: Int
    }
}

struct DirectionsResponse: Codable {
    let fromStop: StopResponse?
    let toStop: StopResponse
    let distanceMiles: Double
    let durationSeconds: Int
    let polyline: String
    let steps: [DirectionStep]

    struct DirectionStep: Codable {
        let instruction: String
        let distanceMiles: Double
        let durationSeconds: Int
        let maneuver: String?
    }
}

struct RouteOverviewResponse: Codable {
    let routeId: String
    let totalStops: Int
    let completedStops: Int
    let skippedStops: Int
    let failedStops: Int
    let pendingStops: Int
    let totalDistanceMiles: Double
    let coveredDistanceMiles: Double
    let remainingDistanceMiles: Double
    let estimatedTimeRemaining: Int
    let currentStopId: String?
    let nextStopId: String?
    let progress: Double
}

struct RouteTemplateResponse: Codable {
    let id: String
    let userId: String
    let name: String
    let description: String?
    let stopCount: Int
    let defaultOptimizationMode: String?
    let usageCount: Int
    let lastUsedAt: Date?
    let createdAt: Date
}
