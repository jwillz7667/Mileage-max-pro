//
//  TripEndpoints.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import Foundation

/// Trip-related API endpoints
enum TripEndpoints {

    // MARK: - CRUD Operations

    case list(pagination: PaginationParameters, filters: TripFilters?)
    case get(id: String)
    case create(trip: CreateTripRequest)
    case update(id: String, trip: UpdateTripRequest)
    case delete(id: String)

    // MARK: - Batch Operations

    case batchCreate(trips: [CreateTripRequest])
    case batchUpdate(trips: [BatchUpdateTrip])
    case batchDelete(ids: [String])

    // MARK: - Trip Actions

    case startTrip(request: StartTripRequest)
    case endTrip(id: String, request: EndTripRequest)
    case pauseTrip(id: String)
    case resumeTrip(id: String)
    case cancelTrip(id: String)

    // MARK: - Trip Data

    case addWaypoints(tripId: String, waypoints: [CreateWaypointRequest])
    case getWaypoints(tripId: String)
    case getRoutePolyline(tripId: String)

    // MARK: - Classification

    case classify(id: String, category: String)
    case batchClassify(classifications: [TripClassification])
    case suggestClassification(id: String)

    // MARK: - Attachments

    case uploadReceipt(tripId: String)
    case getReceipts(tripId: String)
    case deleteReceipt(tripId: String, receiptId: String)

    // MARK: - Statistics

    case statistics(period: StatsPeriod, filters: TripFilters?)
    case summary(startDate: Date, endDate: Date)
}

extension TripEndpoints: APIEndpoint {

    var method: HTTPMethod {
        switch self {
        case .list, .get, .getWaypoints, .getRoutePolyline, .statistics, .summary, .getReceipts, .suggestClassification:
            return .get
        case .create, .batchCreate, .startTrip, .addWaypoints, .uploadReceipt, .batchClassify:
            return .post
        case .update, .batchUpdate, .endTrip, .pauseTrip, .resumeTrip, .classify:
            return .patch
        case .delete, .batchDelete, .cancelTrip, .deleteReceipt:
            return .delete
        }
    }

    var path: String {
        let base = APIConstants.Endpoints.Trips

        switch self {
        case .list, .create:
            return base
        case .get(let id), .update(let id, _), .delete(let id):
            return "\(base)/\(id)"
        case .batchCreate:
            return "\(base)/batch"
        case .batchUpdate:
            return "\(base)/batch"
        case .batchDelete:
            return "\(base)/batch"
        case .startTrip:
            return "\(base)/start"
        case .endTrip(let id, _):
            return "\(base)/\(id)/end"
        case .pauseTrip(let id):
            return "\(base)/\(id)/pause"
        case .resumeTrip(let id):
            return "\(base)/\(id)/resume"
        case .cancelTrip(let id):
            return "\(base)/\(id)/cancel"
        case .addWaypoints(let tripId, _), .getWaypoints(let tripId):
            return "\(base)/\(tripId)/waypoints"
        case .getRoutePolyline(let tripId):
            return "\(base)/\(tripId)/polyline"
        case .classify(let id, _):
            return "\(base)/\(id)/classify"
        case .batchClassify:
            return "\(base)/classify/batch"
        case .suggestClassification(let id):
            return "\(base)/\(id)/suggest-classification"
        case .uploadReceipt(let tripId), .getReceipts(let tripId):
            return "\(base)/\(tripId)/receipts"
        case .deleteReceipt(let tripId, let receiptId):
            return "\(base)/\(tripId)/receipts/\(receiptId)"
        case .statistics:
            return "\(base)/statistics"
        case .summary:
            return "\(base)/summary"
        }
    }

    var queryParameters: [String: String]? {
        switch self {
        case .list(let pagination, let filters):
            var params = pagination.queryParameters
            if let filters = filters {
                params.merge(filters.queryParameters) { _, new in new }
            }
            return params

        case .statistics(let period, let filters):
            var params = ["period": period.rawValue]
            if let filters = filters {
                params.merge(filters.queryParameters) { _, new in new }
            }
            return params

        case .summary(let startDate, let endDate):
            let formatter = ISO8601DateFormatter()
            return [
                "start_date": formatter.string(from: startDate),
                "end_date": formatter.string(from: endDate)
            ]

        default:
            return nil
        }
    }

    var body: Encodable? {
        switch self {
        case .create(let trip):
            return trip
        case .update(_, let trip):
            return trip
        case .batchCreate(let trips):
            return BatchCreateTripsRequest(trips: trips)
        case .batchUpdate(let trips):
            return BatchUpdateTripsRequest(trips: trips)
        case .batchDelete(let ids):
            return BatchDeleteRequest(ids: ids)
        case .startTrip(let request):
            return request
        case .endTrip(_, let request):
            return request
        case .addWaypoints(_, let waypoints):
            return AddWaypointsRequest(waypoints: waypoints)
        case .classify(_, let category):
            return ClassifyTripRequest(category: category)
        case .batchClassify(let classifications):
            return BatchClassifyRequest(classifications: classifications)
        default:
            return nil
        }
    }
}

// MARK: - Request Models

struct CreateTripRequest: Codable {
    let startLatitude: Double
    let startLongitude: Double
    let startAddress: String?
    let startPlaceName: String?
    let vehicleId: String
    let category: String?
    let purpose: String?
    let notes: String?
}

struct UpdateTripRequest: Codable {
    let endLatitude: Double?
    let endLongitude: Double?
    let endAddress: String?
    let endPlaceName: String?
    let category: String?
    let purpose: String?
    let notes: String?
    let distanceMiles: Double?
    let odometerStart: Double?
    let odometerEnd: Double?
    let isBusinessRelated: Bool?
}

struct StartTripRequest: Codable {
    let vehicleId: String
    let latitude: Double
    let longitude: Double
    let address: String?
    let placeName: String?
    let detectionMethod: String
}

struct EndTripRequest: Codable {
    let latitude: Double
    let longitude: Double
    let address: String?
    let placeName: String?
    let distanceMiles: Double?
    let routePolyline: String?
}

struct CreateWaypointRequest: Codable {
    let latitude: Double
    let longitude: Double
    let altitude: Double?
    let speed: Double?
    let heading: Double?
    let horizontalAccuracy: Double?
    let verticalAccuracy: Double?
    let timestamp: Date
}

struct AddWaypointsRequest: Codable {
    let waypoints: [CreateWaypointRequest]
}

struct BatchCreateTripsRequest: Codable {
    let trips: [CreateTripRequest]
}

struct BatchUpdateTrip: Codable {
    let id: String
    let category: String?
    let purpose: String?
    let notes: String?
}

struct BatchUpdateTripsRequest: Codable {
    let trips: [BatchUpdateTrip]
}

struct BatchDeleteRequest: Codable {
    let ids: [String]
}

struct ClassifyTripRequest: Codable {
    let category: String
}

struct TripClassification: Codable {
    let tripId: String
    let category: String
}

struct BatchClassifyRequest: Codable {
    let classifications: [TripClassification]
}

// MARK: - Response Models

struct TripResponse: Codable {
    let id: String
    let userId: String
    let vehicleId: String
    let startLatitude: Double
    let startLongitude: Double
    let startAddress: String?
    let startPlaceName: String?
    let endLatitude: Double?
    let endLongitude: Double?
    let endAddress: String?
    let endPlaceName: String?
    let distanceMiles: Double
    let durationSeconds: Int
    let startTime: Date
    let endTime: Date?
    let category: String
    let status: String
    let purpose: String?
    let notes: String?
    let routePolyline: String?
    let maxSpeedMph: Double?
    let averageSpeedMph: Double?
    let isBusinessRelated: Bool
    let detectionMethod: String
    let createdAt: Date
    let updatedAt: Date
}

struct TripStatisticsResponse: Codable {
    let totalTrips: Int
    let totalMiles: Double
    let totalDurationSeconds: Int
    let businessMiles: Double
    let personalMiles: Double
    let medicalMiles: Double
    let charityMiles: Double
    let averageTripDistance: Double
    let averageTripDuration: Int
    let estimatedDeduction: Double
    let byCategory: [CategoryStats]
    let byVehicle: [VehicleStats]

    struct CategoryStats: Codable {
        let category: String
        let trips: Int
        let miles: Double
        let durationSeconds: Int
    }

    struct VehicleStats: Codable {
        let vehicleId: String
        let vehicleName: String
        let trips: Int
        let miles: Double
    }
}

struct TripSummaryResponse: Codable {
    let period: String
    let startDate: Date
    let endDate: Date
    let totalMiles: Double
    let totalTrips: Int
    let businessMiles: Double
    let personalMiles: Double
    let estimatedDeduction: Double
    let dailyBreakdown: [DailyStats]

    struct DailyStats: Codable {
        let date: Date
        let trips: Int
        let miles: Double
    }
}

struct ClassificationSuggestion: Codable {
    let suggestedCategory: String
    let confidence: Double
    let reason: String
    let alternativeCategories: [AlternativeCategory]

    struct AlternativeCategory: Codable {
        let category: String
        let confidence: Double
    }
}

// MARK: - Filter Types

struct TripFilters {
    var category: TripCategory?
    var vehicleId: String?
    var startDate: Date?
    var endDate: Date?
    var minDistance: Double?
    var maxDistance: Double?
    var status: TripStatus?
    var searchQuery: String?

    var queryParameters: [String: String] {
        var params: [String: String] = [:]
        let formatter = ISO8601DateFormatter()

        if let category = category {
            params["category"] = category.rawValue
        }
        if let vehicleId = vehicleId {
            params["vehicle_id"] = vehicleId
        }
        if let startDate = startDate {
            params["start_date"] = formatter.string(from: startDate)
        }
        if let endDate = endDate {
            params["end_date"] = formatter.string(from: endDate)
        }
        if let minDistance = minDistance {
            params["min_distance"] = String(minDistance)
        }
        if let maxDistance = maxDistance {
            params["max_distance"] = String(maxDistance)
        }
        if let status = status {
            params["status"] = status.rawValue
        }
        if let searchQuery = searchQuery {
            params["q"] = searchQuery
        }

        return params
    }
}

enum StatsPeriod: String {
    case day
    case week
    case month
    case quarter
    case year
    case custom
}
