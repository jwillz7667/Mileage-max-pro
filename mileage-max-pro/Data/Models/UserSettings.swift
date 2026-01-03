//
//  UserSettings.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import Foundation
import SwiftData

/// User settings model for app preferences
@Model
final class UserSettings {
    // MARK: - Relationships

    @Attribute(.unique)
    var userId: UUID

    var user: User?

    // MARK: - Auto Tracking

    var autoTrackingEnabled: Bool
    var autoTrackingSensitivityRaw: String
    var motionActivityRequired: Bool
    var minimumTripDistanceMeters: Int
    var minimumTripDurationSeconds: Int
    var stopDetectionDelaySeconds: Int

    // MARK: - Classification

    var defaultTripCategoryRaw: String
    var workHoursStart: Date?
    var workHoursEnd: Date?
    var workDays: [Int]
    var classifyWorkHoursBusiness: Bool

    // MARK: - Units

    var distanceUnitRaw: String
    var currency: String
    var fuelUnitRaw: String
    var fuelEconomyUnitRaw: String

    // MARK: - Map

    var mapTypeRaw: String

    // MARK: - Feedback

    var navigationVoiceEnabled: Bool
    var hapticFeedbackEnabled: Bool

    // MARK: - Notifications

    var notificationTripStart: Bool
    var notificationTripEnd: Bool
    var notificationWeeklySummary: Bool
    var notificationMaintenanceDue: Bool

    // MARK: - Features

    var liveActivityEnabled: Bool
    var widgetEnabled: Bool
    var iCloudSyncEnabled: Bool
    var backgroundAppRefresh: Bool

    // MARK: - Power Management

    var lowPowerModeBehaviorRaw: String

    // MARK: - Export

    var dataExportFormatRaw: String

    // MARK: - Timestamps

    var createdAt: Date
    var updatedAt: Date

    // MARK: - Computed Properties

    var autoTrackingSensitivity: TrackingSensitivity {
        get { TrackingSensitivity(rawValue: autoTrackingSensitivityRaw) ?? .balanced }
        set { autoTrackingSensitivityRaw = newValue.rawValue }
    }

    var defaultTripCategory: TripCategory {
        get { TripCategory(rawValue: defaultTripCategoryRaw) ?? .business }
        set { defaultTripCategoryRaw = newValue.rawValue }
    }

    var distanceUnit: DistanceUnit {
        get { DistanceUnit(rawValue: distanceUnitRaw) ?? .miles }
        set { distanceUnitRaw = newValue.rawValue }
    }

    var fuelUnit: FuelUnit {
        get { FuelUnit(rawValue: fuelUnitRaw) ?? .gallons }
        set { fuelUnitRaw = newValue.rawValue }
    }

    var fuelEconomyUnit: FuelEconomyUnit {
        get { FuelEconomyUnit(rawValue: fuelEconomyUnitRaw) ?? .mpg }
        set { fuelEconomyUnitRaw = newValue.rawValue }
    }

    var mapType: MapDisplayType {
        get { MapDisplayType(rawValue: mapTypeRaw) ?? .standard }
        set { mapTypeRaw = newValue.rawValue }
    }

    var lowPowerModeBehavior: LowPowerBehavior {
        get { LowPowerBehavior(rawValue: lowPowerModeBehaviorRaw) ?? .reduceAccuracy }
        set { lowPowerModeBehaviorRaw = newValue.rawValue }
    }

    var dataExportFormat: ExportFormat {
        get { ExportFormat(rawValue: dataExportFormatRaw) ?? .pdf }
        set { dataExportFormatRaw = newValue.rawValue }
    }

    /// Check if current time is within work hours
    var isWithinWorkHours: Bool {
        let now = Date()
        let calendar = Calendar.current

        // Check if today is a work day
        let weekday = calendar.component(.weekday, from: now)
        guard workDays.contains(weekday) else { return false }

        // Check time
        guard let start = workHoursStart, let end = workHoursEnd else { return true }

        let nowComponents = calendar.dateComponents([.hour, .minute], from: now)
        let startComponents = calendar.dateComponents([.hour, .minute], from: start)
        let endComponents = calendar.dateComponents([.hour, .minute], from: end)

        let nowMinutes = (nowComponents.hour ?? 0) * 60 + (nowComponents.minute ?? 0)
        let startMinutes = (startComponents.hour ?? 0) * 60 + (startComponents.minute ?? 0)
        let endMinutes = (endComponents.hour ?? 0) * 60 + (endComponents.minute ?? 0)

        return nowMinutes >= startMinutes && nowMinutes <= endMinutes
    }

    // MARK: - Initialization

    init(userId: UUID) {
        self.userId = userId
        self.user = nil

        // Auto Tracking defaults
        self.autoTrackingEnabled = true
        self.autoTrackingSensitivityRaw = TrackingSensitivity.balanced.rawValue
        self.motionActivityRequired = true
        self.minimumTripDistanceMeters = 200
        self.minimumTripDurationSeconds = 120
        self.stopDetectionDelaySeconds = 180

        // Classification defaults
        self.defaultTripCategoryRaw = TripCategory.business.rawValue
        self.workHoursStart = nil
        self.workHoursEnd = nil
        self.workDays = [2, 3, 4, 5, 6] // Monday to Friday
        self.classifyWorkHoursBusiness = true

        // Unit defaults
        self.distanceUnitRaw = DistanceUnit.miles.rawValue
        self.currency = "USD"
        self.fuelUnitRaw = FuelUnit.gallons.rawValue
        self.fuelEconomyUnitRaw = FuelEconomyUnit.mpg.rawValue

        // Map defaults
        self.mapTypeRaw = MapDisplayType.standard.rawValue

        // Feedback defaults
        self.navigationVoiceEnabled = true
        self.hapticFeedbackEnabled = true

        // Notification defaults
        self.notificationTripStart = true
        self.notificationTripEnd = true
        self.notificationWeeklySummary = true
        self.notificationMaintenanceDue = true

        // Feature defaults
        self.liveActivityEnabled = true
        self.widgetEnabled = true
        self.iCloudSyncEnabled = true
        self.backgroundAppRefresh = true

        // Power defaults
        self.lowPowerModeBehaviorRaw = LowPowerBehavior.reduceAccuracy.rawValue

        // Export defaults
        self.dataExportFormatRaw = ExportFormat.pdf.rawValue

        // Timestamps
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Methods

    func update() {
        updatedAt = Date()
    }

    func setWorkHours(start: Date, end: Date, days: [Int]) {
        workHoursStart = start
        workHoursEnd = end
        workDays = days
        update()
    }

    func resetToDefaults() {
        autoTrackingEnabled = true
        autoTrackingSensitivity = .balanced
        motionActivityRequired = true
        minimumTripDistanceMeters = 200
        minimumTripDurationSeconds = 120
        stopDetectionDelaySeconds = 180
        defaultTripCategory = .business
        hapticFeedbackEnabled = true
        liveActivityEnabled = true
        widgetEnabled = true
        update()
    }
}

// MARK: - Tracking Sensitivity

enum TrackingSensitivity: String, Codable, CaseIterable {
    case low = "low"
    case balanced = "balanced"
    case high = "high"

    var displayName: String {
        switch self {
        case .low: return "Low"
        case .balanced: return "Balanced"
        case .high: return "High"
        }
    }

    var sensitivityDescription: String {
        switch self {
        case .low: return "Fewer false starts, may miss short trips"
        case .balanced: return "Good balance of accuracy and battery"
        case .high: return "Catches more trips, uses more battery"
        }
    }

    var speedThresholdMPS: Double {
        switch self {
        case .low: return 5.0 // ~11 mph
        case .balanced: return 3.0 // ~7 mph
        case .high: return 2.0 // ~4.5 mph
        }
    }

    var confirmationDuration: TimeInterval {
        switch self {
        case .low: return 45
        case .balanced: return 30
        case .high: return 15
        }
    }
}

// MARK: - Map Display Type

enum MapDisplayType: String, Codable, CaseIterable {
    case standard = "standard"
    case satellite = "satellite"
    case hybrid = "hybrid"

    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .satellite: return "Satellite"
        case .hybrid: return "Hybrid"
        }
    }
}

// MARK: - Low Power Behavior

enum LowPowerBehavior: String, Codable, CaseIterable {
    case normal = "normal"
    case reduceAccuracy = "reduce_accuracy"
    case pause = "pause"

    var displayName: String {
        switch self {
        case .normal: return "Normal"
        case .reduceAccuracy: return "Reduce Accuracy"
        case .pause: return "Pause Tracking"
        }
    }

    var behaviorDescription: String {
        switch self {
        case .normal: return "Continue tracking normally"
        case .reduceAccuracy: return "Use less precise location to save battery"
        case .pause: return "Pause automatic tracking until charged"
        }
    }
}

// MARK: - Export Format

enum ExportFormat: String, Codable, CaseIterable {
    case pdf = "pdf"
    case csv = "csv"
    case both = "both"

    var displayName: String {
        switch self {
        case .pdf: return "PDF"
        case .csv: return "CSV"
        case .both: return "PDF & CSV"
        }
    }
}

// MARK: - User Settings DTO

struct UserSettingsDTO: Codable, Equatable {
    let autoTrackingEnabled: Bool
    let autoTrackingSensitivity: String
    let minimumTripDistanceMeters: Int
    let minimumTripDurationSeconds: Int
    let stopDetectionDelaySeconds: Int
    let defaultTripCategory: String
    let distanceUnit: String
    let currency: String
    let fuelUnit: String
    let mapType: String
    let hapticFeedbackEnabled: Bool
    let notificationTripStart: Bool
    let notificationTripEnd: Bool
    let notificationWeeklySummary: Bool
    let liveActivityEnabled: Bool
    let widgetEnabled: Bool
    let iCloudSyncEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case autoTrackingEnabled = "auto_tracking_enabled"
        case autoTrackingSensitivity = "auto_tracking_sensitivity"
        case minimumTripDistanceMeters = "minimum_trip_distance_meters"
        case minimumTripDurationSeconds = "minimum_trip_duration_seconds"
        case stopDetectionDelaySeconds = "stop_detection_delay_seconds"
        case defaultTripCategory = "default_trip_category"
        case distanceUnit = "distance_unit"
        case currency
        case fuelUnit = "fuel_unit"
        case mapType = "map_type"
        case hapticFeedbackEnabled = "haptic_feedback_enabled"
        case notificationTripStart = "notification_trip_start"
        case notificationTripEnd = "notification_trip_end"
        case notificationWeeklySummary = "notification_weekly_summary"
        case liveActivityEnabled = "live_activity_enabled"
        case widgetEnabled = "widget_enabled"
        case iCloudSyncEnabled = "icloud_sync_enabled"
    }
}
