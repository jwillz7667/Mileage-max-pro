//
//  SavedLocation.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import Foundation
import SwiftData
import CoreLocation

/// Saved location model for geofencing and quick trip entry
@Model
final class SavedLocation {
    // MARK: - Primary Identifiers

    @Attribute(.unique)
    var id: UUID

    // MARK: - Location Info

    var name: String
    var locationTypeRaw: String
    var address: String
    var latitude: Double
    var longitude: Double
    var radiusMeters: Int

    // MARK: - Auto Classification

    var autoClassifyAsRaw: String?

    // MARK: - Usage Stats

    var visitCount: Int
    var lastVisitedAt: Date?

    // MARK: - Preferences

    var isFavorite: Bool
    var notes: String?

    // MARK: - Timestamps

    var createdAt: Date
    var updatedAt: Date

    // MARK: - Relationships

    var user: User?

    // Note: These are simple back-references, not managed relationships
    // to avoid SwiftData inverse relationship conflicts
    @Transient
    var routeStarts: [DeliveryRoute] = []

    @Transient
    var routeEnds: [DeliveryRoute] = []

    // MARK: - Computed Properties

    var locationType: LocationType {
        get { LocationType(rawValue: locationTypeRaw) ?? .other }
        set { locationTypeRaw = newValue.rawValue }
    }

    var autoClassifyAs: TripCategory? {
        get {
            guard let raw = autoClassifyAsRaw else { return nil }
            return TripCategory(rawValue: raw)
        }
        set { autoClassifyAsRaw = newValue?.rawValue }
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }

    var radiusMiles: Double {
        Double(radiusMeters) * 0.000621371
    }

    var shortAddress: String {
        // Return just city, state or first line
        let components = address.components(separatedBy: ",")
        if components.count >= 2 {
            return components[0...1].joined(separator: ",").trimmingCharacters(in: .whitespaces)
        }
        return address
    }

    var displayName: String {
        name.isEmpty ? shortAddress : name
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        name: String,
        locationType: LocationType = .other,
        address: String,
        latitude: Double,
        longitude: Double,
        radiusMeters: Int = 100
    ) {
        self.id = id
        self.name = name
        self.locationTypeRaw = locationType.rawValue
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.radiusMeters = radiusMeters
        self.autoClassifyAsRaw = nil
        self.visitCount = 0
        self.lastVisitedAt = nil
        self.isFavorite = false
        self.notes = nil
        self.createdAt = Date()
        self.updatedAt = Date()
        self.user = nil
    }

    // MARK: - Methods

    func update() {
        updatedAt = Date()
    }

    func recordVisit() {
        visitCount += 1
        lastVisitedAt = Date()
        update()
    }

    func toggleFavorite() {
        isFavorite.toggle()
        update()
    }

    /// Check if a coordinate is within this location's geofence
    func contains(coordinate: CLLocationCoordinate2D) -> Bool {
        let targetLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let distance = location.distance(from: targetLocation)
        return distance <= Double(radiusMeters)
    }

    /// Check if a location is within this location's geofence
    func contains(location: CLLocation) -> Bool {
        let distance = self.location.distance(from: location)
        return distance <= Double(radiusMeters)
    }

    /// Distance from this location to another coordinate
    func distance(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        let targetLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return location.distance(from: targetLocation)
    }

    /// Create a CLCircularRegion for geofencing
    func createRegion() -> CLCircularRegion {
        let region = CLCircularRegion(
            center: coordinate,
            radius: Double(radiusMeters),
            identifier: id.uuidString
        )
        region.notifyOnEntry = true
        region.notifyOnExit = true
        return region
    }
}

// MARK: - Location Type

enum LocationType: String, Codable, CaseIterable {
    case home = "home"
    case work = "work"
    case client = "client"
    case warehouse = "warehouse"
    case restaurant = "restaurant"
    case store = "store"
    case gasStation = "gas_station"
    case other = "other"

    var displayName: String {
        switch self {
        case .home: return "Home"
        case .work: return "Work"
        case .client: return "Client"
        case .warehouse: return "Warehouse"
        case .restaurant: return "Restaurant"
        case .store: return "Store"
        case .gasStation: return "Gas Station"
        case .other: return "Other"
        }
    }

    var iconName: String {
        switch self {
        case .home: return "house.fill"
        case .work: return "building.2.fill"
        case .client: return "person.crop.circle.fill"
        case .warehouse: return "shippingbox.fill"
        case .restaurant: return "fork.knife"
        case .store: return "bag.fill"
        case .gasStation: return "fuelpump.fill"
        case .other: return "mappin.circle.fill"
        }
    }

    var defaultAutoClassify: TripCategory? {
        switch self {
        case .home: return .personal
        case .work: return .commute
        case .client, .warehouse: return .business
        default: return nil
        }
    }
}

// MARK: - Saved Location DTO

struct SavedLocationDTO: Codable, Identifiable, Equatable {
    let id: UUID
    let name: String
    let locationType: String
    let address: String
    let latitude: Double
    let longitude: Double
    let radiusMeters: Int
    let autoClassifyAs: String?
    let visitCount: Int
    let lastVisitedAt: Date?
    let isFavorite: Bool
    let notes: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, address, latitude, longitude, notes
        case locationType = "location_type"
        case radiusMeters = "radius_meters"
        case autoClassifyAs = "auto_classify_as"
        case visitCount = "visit_count"
        case lastVisitedAt = "last_visited_at"
        case isFavorite = "is_favorite"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    func toModel() -> SavedLocation {
        let location = SavedLocation(
            id: id,
            name: name,
            locationType: LocationType(rawValue: locationType) ?? .other,
            address: address,
            latitude: latitude,
            longitude: longitude,
            radiusMeters: radiusMeters
        )
        location.autoClassifyAsRaw = autoClassifyAs
        location.visitCount = visitCount
        location.lastVisitedAt = lastVisitedAt
        location.isFavorite = isFavorite
        location.notes = notes
        location.createdAt = createdAt
        location.updatedAt = updatedAt
        return location
    }
}

extension SavedLocation {
    func toDTO() -> SavedLocationDTO {
        SavedLocationDTO(
            id: id,
            name: name,
            locationType: locationTypeRaw,
            address: address,
            latitude: latitude,
            longitude: longitude,
            radiusMeters: radiusMeters,
            autoClassifyAs: autoClassifyAsRaw,
            visitCount: visitCount,
            lastVisitedAt: lastVisitedAt,
            isFavorite: isFavorite,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
