//
//  Trip.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import Foundation
import SwiftData
import CoreLocation
import SwiftUI

/// Trip model for MileageMax Pro - Core mileage tracking entity
@Model
final class Trip {
    // MARK: - Primary Identifiers

    @Attribute(.unique)
    var id: UUID

    // MARK: - Status

    var statusRaw: String
    var categoryRaw: String

    // MARK: - Trip Details

    var purpose: String?
    var clientName: String?
    var projectName: String?
    var tags: [String]
    var notes: String?

    // MARK: - Timing

    var startTime: Date
    var endTime: Date?

    // MARK: - Start Location

    var startAddress: String?
    var startPlaceName: String?
    var startLatitude: Double
    var startLongitude: Double

    // MARK: - End Location

    var endAddress: String?
    var endPlaceName: String?
    var endLatitude: Double?
    var endLongitude: Double?

    // MARK: - Distance & Duration

    var distanceMeters: Int
    var durationSeconds: Int
    var idleTimeSeconds: Int

    // MARK: - Speed Statistics

    var maxSpeedMPH: Double?
    var avgSpeedMPH: Double?

    // MARK: - Fuel & Emissions

    var fuelConsumedGallons: Double?
    var fuelCost: Decimal?
    var carbonEmissionsKg: Double?

    // MARK: - Route Data

    var routePolyline: String?
    var routeGeoJSON: Data?

    // MARK: - Weather

    var weatherConditionsData: Data?

    // MARK: - Detection

    var detectionMethodRaw: String
    var autoClassified: Bool
    var classificationConfidence: Double?
    var userVerified: Bool
    var irsCompliant: Bool

    // MARK: - Sync Status

    var syncStatusRaw: String?
    var lastSyncedAt: Date?

    // MARK: - Timestamps

    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    // MARK: - Relationships

    var user: User?
    var vehicle: Vehicle?

    @Relationship(deleteRule: .cascade, inverse: \TripWaypoint.trip)
    var waypoints: [TripWaypoint]

    // MARK: - Computed Properties

    var status: TripStatus {
        get { TripStatus(rawValue: statusRaw) ?? .recording }
        set { statusRaw = newValue.rawValue }
    }

    var category: TripCategory {
        get { TripCategory(rawValue: categoryRaw) ?? .business }
        set { categoryRaw = newValue.rawValue }
    }

    var detectionMethod: TripDetectionMethod {
        get { TripDetectionMethod(rawValue: detectionMethodRaw) ?? .automatic }
        set { detectionMethodRaw = newValue.rawValue }
    }

    var syncStatus: SyncStatus {
        get { SyncStatus(rawValue: syncStatusRaw ?? "") ?? .pending }
        set { syncStatusRaw = newValue.rawValue }
    }

    /// Computed vehicleId for backward compatibility
    var vehicleId: UUID? {
        vehicle?.id
    }

    /// Distance in miles (computed from meters)
    var distanceMiles: Double {
        Double(distanceMeters) * 0.000621371
    }

    /// Duration as TimeInterval
    var duration: TimeInterval {
        TimeInterval(durationSeconds)
    }

    /// Formatted distance string
    var formattedDistance: String {
        distanceMiles.formattedMiles
    }

    /// Formatted duration string
    var formattedDuration: String {
        duration.compactDuration
    }

    /// Start coordinate
    var startCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: startLatitude, longitude: startLongitude)
    }

    /// End coordinate (if available)
    var endCoordinate: CLLocationCoordinate2D? {
        guard let lat = endLatitude, let lon = endLongitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    /// Check if trip is currently recording
    var isRecording: Bool {
        status == .recording
    }

    /// Check if trip is completed
    var isCompleted: Bool {
        status == .completed || status == .verified
    }

    /// Check if trip is a business trip
    var isBusiness: Bool {
        category == .business
    }

    /// Check if trip is tax deductible
    var isTaxDeductible: Bool {
        category == .business || category == .medical || category == .charity
    }

    /// Calculate IRS deduction amount
    var irsDeduction: Decimal? {
        guard isTaxDeductible else { return nil }
        let rate: Decimal
        let year = startTime.year

        switch category {
        case .business:
            rate = AppConstants.IRSRates.businessRate(for: year)
        case .medical:
            rate = AppConstants.IRSRates.medicalRate(for: year)
        case .charity:
            rate = AppConstants.IRSRates.charityRate(for: year)
        default:
            return nil
        }

        return Decimal(distanceMiles) * rate
    }

    /// Formatted IRS deduction
    var formattedDeduction: String? {
        irsDeduction?.formattedCurrency
    }

    /// Display location (end address or start address)
    var displayLocation: String {
        endAddress ?? startAddress ?? "Unknown Location"
    }

    /// Short display location
    var shortLocation: String {
        endPlaceName ?? startPlaceName ?? displayLocation.components(separatedBy: ",").first ?? "Unknown"
    }

    /// Weather conditions decoded
    var weatherConditions: WeatherConditions? {
        get {
            guard let data = weatherConditionsData else { return nil }
            return try? JSONDecoder().decode(WeatherConditions.self, from: data)
        }
        set {
            weatherConditionsData = try? JSONEncoder().encode(newValue)
        }
    }

    /// Sorted waypoints by sequence
    var sortedWaypoints: [TripWaypoint] {
        waypoints.sorted { $0.sequenceNumber < $1.sequenceNumber }
    }

    /// Number of stops during trip
    var stopCount: Int {
        waypoints.filter { $0.isStop }.count
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        startLatitude: Double,
        startLongitude: Double,
        startTime: Date = Date(),
        category: TripCategory = .business,
        detectionMethod: TripDetectionMethod = .automatic
    ) {
        self.id = id
        self.statusRaw = TripStatus.recording.rawValue
        self.categoryRaw = category.rawValue
        self.purpose = nil
        self.clientName = nil
        self.projectName = nil
        self.tags = []
        self.notes = nil
        self.startTime = startTime
        self.endTime = nil
        self.startAddress = nil
        self.startPlaceName = nil
        self.startLatitude = startLatitude
        self.startLongitude = startLongitude
        self.endAddress = nil
        self.endPlaceName = nil
        self.endLatitude = nil
        self.endLongitude = nil
        self.distanceMeters = 0
        self.durationSeconds = 0
        self.idleTimeSeconds = 0
        self.maxSpeedMPH = nil
        self.avgSpeedMPH = nil
        self.fuelConsumedGallons = nil
        self.fuelCost = nil
        self.carbonEmissionsKg = nil
        self.routePolyline = nil
        self.routeGeoJSON = nil
        self.weatherConditionsData = nil
        self.detectionMethodRaw = detectionMethod.rawValue
        self.autoClassified = false
        self.classificationConfidence = nil
        self.userVerified = false
        self.irsCompliant = false
        self.createdAt = Date()
        self.updatedAt = Date()
        self.deletedAt = nil
        self.user = nil
        self.vehicle = nil
        self.waypoints = []
    }

    // MARK: - Methods

    func update() {
        updatedAt = Date()
    }

    func complete(
        endLatitude: Double,
        endLongitude: Double,
        endTime: Date = Date()
    ) {
        self.endLatitude = endLatitude
        self.endLongitude = endLongitude
        self.endTime = endTime
        self.status = .completed
        self.durationSeconds = Int(endTime.timeIntervalSince(startTime))
        update()
    }

    func addWaypoint(_ waypoint: TripWaypoint) {
        waypoint.sequenceNumber = waypoints.count
        waypoint.trip = self
        waypoints.append(waypoint)

        // Update distance
        if let lastWaypoint = sortedWaypoints.dropLast().last {
            let lastLocation = CLLocation(
                latitude: lastWaypoint.latitude,
                longitude: lastWaypoint.longitude
            )
            let newLocation = CLLocation(
                latitude: waypoint.latitude,
                longitude: waypoint.longitude
            )
            distanceMeters += Int(newLocation.distance(from: lastLocation))
        }

        // Update max speed
        if let speed = waypoint.speedMPS {
            let speedMPH = speed * 2.23694
            if maxSpeedMPH == nil || speedMPH > maxSpeedMPH! {
                maxSpeedMPH = speedMPH
            }
        }

        update()
    }

    func verify() {
        userVerified = true
        status = .verified
        checkIRSCompliance()
        update()
    }

    func checkIRSCompliance() {
        // IRS requires: date, destination, business purpose, miles
        irsCompliant = isBusiness &&
                       endAddress != nil &&
                       (purpose != nil || clientName != nil) &&
                       distanceMiles > 0
    }

    func calculateFuelConsumption() {
        guard let vehicle = vehicle,
              let mpg = vehicle.combinedFuelEconomy,
              mpg > 0 else { return }

        fuelConsumedGallons = distanceMiles / mpg
        carbonEmissionsKg = fuelConsumedGallons.map { $0 * vehicle.fuelType.co2PerUnit }
    }

    func softDelete() {
        deletedAt = Date()
        update()
    }
}

// MARK: - Trip Status

enum TripStatus: String, Codable, CaseIterable {
    case recording = "recording"
    case completed = "completed"
    case processing = "processing"
    case verified = "verified"

    var displayName: String {
        switch self {
        case .recording: return "Recording"
        case .completed: return "Completed"
        case .processing: return "Processing"
        case .verified: return "Verified"
        }
    }

    var iconName: String {
        switch self {
        case .recording: return "record.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .processing: return "gearshape.fill"
        case .verified: return "checkmark.seal.fill"
        }
    }
}

// MARK: - Trip Category

enum TripCategory: String, Codable, CaseIterable {
    case business = "business"
    case personal = "personal"
    case medical = "medical"
    case charity = "charity"
    case moving = "moving"
    case commute = "commute"

    var displayName: String {
        switch self {
        case .business: return "Business"
        case .personal: return "Personal"
        case .medical: return "Medical"
        case .charity: return "Charity"
        case .moving: return "Moving"
        case .commute: return "Commute"
        }
    }

    var iconName: String {
        switch self {
        case .business: return "briefcase.fill"
        case .personal: return "person.fill"
        case .medical: return "cross.case.fill"
        case .charity: return "heart.fill"
        case .moving: return "box.truck.fill"
        case .commute: return "building.2.fill"
        }
    }

    /// Alias for iconName for backward compatibility
    var icon: String { iconName }

    /// Category color for UI display
    var color: Color {
        switch self {
        case .business: return .blue
        case .personal: return .purple
        case .medical: return .red
        case .charity: return .pink
        case .moving: return .orange
        case .commute: return .gray
        }
    }

    var isTaxDeductible: Bool {
        self == .business || self == .medical || self == .charity
    }

    /// IRS category description
    var irsDescription: String {
        switch self {
        case .business: return "Business Use"
        case .personal: return "Personal Use (Non-Deductible)"
        case .medical: return "Medical/Moving (Limited Deduction)"
        case .charity: return "Charitable Service"
        case .moving: return "Moving (Limited Deduction)"
        case .commute: return "Commute (Non-Deductible)"
        }
    }
}

// MARK: - Trip Detection Method

enum TripDetectionMethod: String, Codable, CaseIterable {
    case automatic = "automatic"
    case manual = "manual"
    case widget = "widget"
    case shortcut = "shortcut"

    var displayName: String {
        switch self {
        case .automatic: return "Automatic"
        case .manual: return "Manual"
        case .widget: return "Widget"
        case .shortcut: return "Siri Shortcut"
        }
    }
}

// MARK: - Sync Status

enum SyncStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case synced = "synced"
    case failed = "failed"

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .synced: return "Synced"
        case .failed: return "Failed"
        }
    }

    var iconName: String {
        switch self {
        case .pending: return "icloud.and.arrow.up"
        case .synced: return "checkmark.icloud"
        case .failed: return "exclamationmark.icloud"
        }
    }
}

// MARK: - Weather Conditions

struct WeatherConditions: Codable, Equatable {
    let temperature: Double
    let temperatureUnit: String
    let condition: String
    let conditionCode: Int
    let humidity: Int
    let windSpeed: Double
    let visibility: Double
    let precipitation: Double?

    var formattedTemperature: String {
        "\(Int(temperature))°\(temperatureUnit)"
    }

    var weatherIcon: String {
        switch conditionCode {
        case 200...232: return "cloud.bolt.rain.fill"
        case 300...321: return "cloud.drizzle.fill"
        case 500...531: return "cloud.rain.fill"
        case 600...622: return "cloud.snow.fill"
        case 700...781: return "cloud.fog.fill"
        case 800: return "sun.max.fill"
        case 801...804: return "cloud.fill"
        default: return "questionmark.circle"
        }
    }
}

// MARK: - Trip DTO

struct TripDTO: Codable, Identifiable, Equatable {
    let id: UUID
    let status: String
    let category: String
    let purpose: String?
    let clientName: String?
    let projectName: String?
    let tags: [String]
    let notes: String?
    let startTime: Date
    let endTime: Date?
    let startAddress: String?
    let startPlaceName: String?
    let startLatitude: Double
    let startLongitude: Double
    let endAddress: String?
    let endPlaceName: String?
    let endLatitude: Double?
    let endLongitude: Double?
    let distanceMeters: Int
    let durationSeconds: Int
    let detectionMethod: String
    let userVerified: Bool
    let irsCompliant: Bool
    let vehicleId: UUID?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, status, category, purpose, tags, notes
        case clientName = "client_name"
        case projectName = "project_name"
        case startTime = "start_time"
        case endTime = "end_time"
        case startAddress = "start_address"
        case startPlaceName = "start_place_name"
        case startLatitude = "start_latitude"
        case startLongitude = "start_longitude"
        case endAddress = "end_address"
        case endPlaceName = "end_place_name"
        case endLatitude = "end_latitude"
        case endLongitude = "end_longitude"
        case distanceMeters = "distance_meters"
        case durationSeconds = "duration_seconds"
        case detectionMethod = "detection_method"
        case userVerified = "user_verified"
        case irsCompliant = "irs_compliant"
        case vehicleId = "vehicle_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    func toModel() -> Trip {
        let trip = Trip(
            id: id,
            startLatitude: startLatitude,
            startLongitude: startLongitude,
            startTime: startTime,
            category: TripCategory(rawValue: category) ?? .business,
            detectionMethod: TripDetectionMethod(rawValue: detectionMethod) ?? .automatic
        )
        trip.statusRaw = status
        trip.purpose = purpose
        trip.clientName = clientName
        trip.projectName = projectName
        trip.tags = tags
        trip.notes = notes
        trip.endTime = endTime
        trip.startAddress = startAddress
        trip.startPlaceName = startPlaceName
        trip.endAddress = endAddress
        trip.endPlaceName = endPlaceName
        trip.endLatitude = endLatitude
        trip.endLongitude = endLongitude
        trip.distanceMeters = distanceMeters
        trip.durationSeconds = durationSeconds
        trip.userVerified = userVerified
        trip.irsCompliant = irsCompliant
        trip.createdAt = createdAt
        trip.updatedAt = updatedAt
        return trip
    }
}

extension Trip {
    func toDTO() -> TripDTO {
        TripDTO(
            id: id,
            status: statusRaw,
            category: categoryRaw,
            purpose: purpose,
            clientName: clientName,
            projectName: projectName,
            tags: tags,
            notes: notes,
            startTime: startTime,
            endTime: endTime,
            startAddress: startAddress,
            startPlaceName: startPlaceName,
            startLatitude: startLatitude,
            startLongitude: startLongitude,
            endAddress: endAddress,
            endPlaceName: endPlaceName,
            endLatitude: endLatitude,
            endLongitude: endLongitude,
            distanceMeters: distanceMeters,
            durationSeconds: durationSeconds,
            detectionMethod: detectionMethodRaw,
            userVerified: userVerified,
            irsCompliant: irsCompliant,
            vehicleId: vehicle?.id,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
