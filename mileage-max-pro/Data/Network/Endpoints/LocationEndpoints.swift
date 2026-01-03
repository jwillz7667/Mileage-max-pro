//
//  LocationEndpoints.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import Foundation

/// Saved locations and geofencing API endpoints
enum LocationEndpoints {

    // MARK: - CRUD Operations

    case list(pagination: PaginationParameters)
    case get(id: String)
    case create(location: CreateLocationRequest)
    case update(id: String, location: UpdateLocationRequest)
    case delete(id: String)

    // MARK: - Search & Lookup

    case search(query: String, limit: Int?)
    case reverseGeocode(latitude: Double, longitude: Double)
    case autocomplete(query: String, latitude: Double?, longitude: Double?)

    // MARK: - Nearby

    case nearby(latitude: Double, longitude: Double, radiusMiles: Double?)

    // MARK: - Batch Operations

    case batchCreate(locations: [CreateLocationRequest])
    case batchDelete(ids: [String])

    // MARK: - Visit Tracking

    case recordVisit(locationId: String, arrivalTime: Date, departureTime: Date?)
    case getVisitHistory(locationId: String, pagination: PaginationParameters)

    // MARK: - Classification Rules

    case getClassificationRules
    case updateClassificationRules(rules: [ClassificationRule])
}

extension LocationEndpoints: APIEndpoint {

    var method: HTTPMethod {
        switch self {
        case .list, .get, .search, .reverseGeocode, .autocomplete, .nearby, .getVisitHistory, .getClassificationRules:
            return .get
        case .create, .batchCreate, .recordVisit:
            return .post
        case .update, .updateClassificationRules:
            return .patch
        case .delete, .batchDelete:
            return .delete
        }
    }

    var path: String {
        let base = APIConstants.Endpoints.Locations

        switch self {
        case .list, .create:
            return base
        case .get(let id), .update(let id, _), .delete(let id):
            return "\(base)/\(id)"
        case .search:
            return "\(base)/search"
        case .reverseGeocode:
            return "\(base)/geocode/reverse"
        case .autocomplete:
            return "\(base)/autocomplete"
        case .nearby:
            return "\(base)/nearby"
        case .batchCreate:
            return "\(base)/batch"
        case .batchDelete:
            return "\(base)/batch"
        case .recordVisit(let locationId, _, _):
            return "\(base)/\(locationId)/visits"
        case .getVisitHistory(let locationId, _):
            return "\(base)/\(locationId)/visits"
        case .getClassificationRules, .updateClassificationRules:
            return "\(base)/classification-rules"
        }
    }

    var queryParameters: [String: String]? {
        switch self {
        case .list(let pagination):
            return pagination.queryParameters

        case .search(let query, let limit):
            var params = ["q": query]
            if let limit = limit {
                params["limit"] = String(limit)
            }
            return params

        case .reverseGeocode(let latitude, let longitude):
            return [
                "latitude": String(latitude),
                "longitude": String(longitude)
            ]

        case .autocomplete(let query, let latitude, let longitude):
            var params = ["q": query]
            if let lat = latitude {
                params["latitude"] = String(lat)
            }
            if let lng = longitude {
                params["longitude"] = String(lng)
            }
            return params

        case .nearby(let latitude, let longitude, let radiusMiles):
            var params = [
                "latitude": String(latitude),
                "longitude": String(longitude)
            ]
            if let radius = radiusMiles {
                params["radius_miles"] = String(radius)
            }
            return params

        case .getVisitHistory(_, let pagination):
            return pagination.queryParameters

        default:
            return nil
        }
    }

    var body: Encodable? {
        switch self {
        case .create(let location):
            return location
        case .update(_, let location):
            return location
        case .batchCreate(let locations):
            return BatchCreateLocationsRequest(locations: locations)
        case .batchDelete(let ids):
            return BatchDeleteRequest(ids: ids)
        case .recordVisit(_, let arrivalTime, let departureTime):
            return RecordVisitRequest(arrivalTime: arrivalTime, departureTime: departureTime)
        case .updateClassificationRules(let rules):
            return UpdateClassificationRulesRequest(rules: rules)
        default:
            return nil
        }
    }
}

// MARK: - Request Models

struct CreateLocationRequest: Codable {
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let type: String
    let category: String?
    let radiusMeters: Double?
    let isAutoClassify: Bool?
    let notes: String?
}

struct UpdateLocationRequest: Codable {
    let name: String?
    let address: String?
    let type: String?
    let category: String?
    let radiusMeters: Double?
    let isAutoClassify: Bool?
    let notes: String?
}

struct BatchCreateLocationsRequest: Codable {
    let locations: [CreateLocationRequest]
}

struct RecordVisitRequest: Codable {
    let arrivalTime: Date
    let departureTime: Date?
}

struct ClassificationRule: Codable {
    let id: String?
    let locationId: String?
    let locationType: String?
    let dayOfWeek: [Int]?
    let timeRange: TimeRange?
    let assignedCategory: String
    let priority: Int

    struct TimeRange: Codable {
        let start: String
        let end: String
    }
}

struct UpdateClassificationRulesRequest: Codable {
    let rules: [ClassificationRule]
}

// MARK: - Response Models

struct LocationResponse: Codable {
    let id: String
    let userId: String
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let type: String
    let category: String?
    let radiusMeters: Double
    let isAutoClassify: Bool
    let visitCount: Int
    let lastVisitedAt: Date?
    let notes: String?
    let createdAt: Date
    let updatedAt: Date
}

struct GeocodingResponse: Codable {
    let address: String
    let streetNumber: String?
    let street: String?
    let city: String?
    let state: String?
    let postalCode: String?
    let country: String?
    let formattedAddress: String
    let placeId: String?
}

struct AutocompleteResponse: Codable {
    let predictions: [Prediction]

    struct Prediction: Codable {
        let placeId: String
        let description: String
        let mainText: String
        let secondaryText: String?
        let types: [String]
        let distanceMeters: Double?
    }
}

struct NearbyLocationsResponse: Codable {
    let locations: [NearbyLocation]

    struct NearbyLocation: Codable {
        let id: String
        let name: String
        let address: String
        let latitude: Double
        let longitude: Double
        let type: String
        let distanceMiles: Double
        let visitCount: Int
    }
}

struct VisitResponse: Codable {
    let id: String
    let locationId: String
    let arrivalTime: Date
    let departureTime: Date?
    let durationMinutes: Int?
    let associatedTripId: String?
    let createdAt: Date
}

struct ClassificationRulesResponse: Codable {
    let rules: [ClassificationRule]
    let defaultCategory: String
}
