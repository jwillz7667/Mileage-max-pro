//
//  AppConstants.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import Foundation
import CoreLocation

/// Application-wide constants for MileageMax Pro
enum AppConstants {

    // MARK: - App Identification

    static let appName = "MileageMax Pro"
    static let appBundleIdentifier = "com.mileagemaxpro.app"
    static let appGroupIdentifier = "group.com.mileagemaxpro.shared"
    static let keychainServiceIdentifier = "com.mileagemaxpro.keychain"

    // MARK: - Version Information

    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    static var fullVersionString: String {
        "\(appVersion) (\(buildNumber))"
    }

    // MARK: - Minimum Requirements

    static let minimumIOSVersion = "26.1"

    // MARK: - Trip Detection Thresholds

    enum TripDetection {
        /// Minimum speed to consider as driving (meters per second)
        static let minimumDrivingSpeed: CLLocationSpeed = 2.235 // ~5 mph

        /// Speed threshold to confirm driving (meters per second)
        static let confirmDrivingSpeed: CLLocationSpeed = 4.47 // ~10 mph

        /// Duration of sustained speed before trip starts (seconds)
        static let speedConfirmationDuration: TimeInterval = 30

        /// Default stop detection delay (seconds)
        static let defaultStopDetectionDelay: TimeInterval = 180

        /// Minimum trip distance to record (meters)
        static let minimumTripDistance: CLLocationDistance = 200

        /// Minimum trip duration to record (seconds)
        static let minimumTripDuration: TimeInterval = 120

        /// Geofence radius for saved locations (meters)
        static let defaultGeofenceRadius: CLLocationDistance = 100

        /// Maximum time gap between waypoints before considering trip ended (seconds)
        static let maximumWaypointGap: TimeInterval = 300

        /// Interval for location updates during active tracking (seconds)
        static let activeTrackingInterval: TimeInterval = 5

        /// Interval for background monitoring (seconds)
        static let backgroundMonitoringInterval: TimeInterval = 60
    }

    // MARK: - Location Accuracy

    enum LocationAccuracy {
        /// Best accuracy for trip start/end points
        static let preciseAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest

        /// Balanced accuracy during active trip
        static let balancedAccuracy: CLLocationAccuracy = kCLLocationAccuracyNearestTenMeters

        /// Reduced accuracy for background monitoring
        static let reducedAccuracy: CLLocationAccuracy = kCLLocationAccuracyHundredMeters

        /// Maximum acceptable horizontal accuracy (meters)
        static let maximumAcceptableAccuracy: CLLocationAccuracy = 100

        /// Minimum acceptable horizontal accuracy for waypoints (meters)
        static let waypointAccuracyThreshold: CLLocationAccuracy = 50
    }

    // MARK: - Subscription Tiers

    enum SubscriptionTier: String, CaseIterable, Codable {
        case free = "free"
        case pro = "pro"
        case business = "business"
        case enterprise = "enterprise"

        var displayName: String {
            switch self {
            case .free: return "Free"
            case .pro: return "Pro"
            case .business: return "Business"
            case .enterprise: return "Enterprise"
            }
        }

        var monthlyPrice: Decimal {
            switch self {
            case .free: return 0
            case .pro: return 9.99
            case .business: return 24.99
            case .enterprise: return 99.99
            }
        }

        var maxVehicles: Int {
            switch self {
            case .free: return 1
            case .pro: return 5
            case .business: return Int.max
            case .enterprise: return Int.max
            }
        }

        var tripHistoryDays: Int {
            switch self {
            case .free: return 90
            case .pro: return 730 // 2 years
            case .business: return Int.max
            case .enterprise: return Int.max
            }
        }

        var maxRouteStops: Int {
            switch self {
            case .free: return 5
            case .pro: return 15
            case .business: return 50
            case .enterprise: return Int.max
            }
        }

        var hasIRSExport: Bool {
            self != .free
        }

        var hasExpenseTracking: Bool {
            self != .free
        }

        var hasReceiptOCR: Bool {
            self != .free
        }

        var hasProofOfDelivery: Bool {
            self != .free
        }

        var hasTeamFeatures: Bool {
            self == .business || self == .enterprise
        }

        var hasAPIAccess: Bool {
            self == .business || self == .enterprise
        }

        var hasPrioritySupport: Bool {
            self == .business || self == .enterprise
        }
    }

    // MARK: - IRS Mileage Rates

    enum IRSRates {
        /// Standard mileage rate for business (per mile)
        static let business2024: Decimal = 0.67
        static let business2025: Decimal = 0.70
        static let business2026: Decimal = 0.70 // Projected

        /// Medical/moving rate (per mile)
        static let medical2024: Decimal = 0.21
        static let medical2025: Decimal = 0.22
        static let medical2026: Decimal = 0.22 // Projected

        /// Charity rate (per mile)
        static let charity2024: Decimal = 0.14
        static let charity2025: Decimal = 0.14
        static let charity2026: Decimal = 0.14 // Projected

        static func businessRate(for year: Int) -> Decimal {
            switch year {
            case 2024: return business2024
            case 2025: return business2025
            default: return business2026
            }
        }

        static func medicalRate(for year: Int) -> Decimal {
            switch year {
            case 2024: return medical2024
            case 2025: return medical2025
            default: return medical2026
            }
        }

        static func charityRate(for year: Int) -> Decimal {
            switch year {
            case 2024: return charity2024
            case 2025: return charity2025
            default: return charity2026
            }
        }
    }

    // MARK: - IRS Mileage Rates (Double-based for calculations)

    enum IRSMileageRates {
        struct Rate {
            let business: Double
            let medical: Double
            let charity: Double
            let year: Int
        }

        static var current: Rate {
            let year = Calendar.current.component(.year, from: Date())
            return rate(for: year)
        }

        static func rate(for year: Int) -> Rate {
            switch year {
            case 2024:
                return Rate(business: 0.67, medical: 0.21, charity: 0.14, year: 2024)
            case 2025:
                return Rate(business: 0.70, medical: 0.22, charity: 0.14, year: 2025)
            default:
                return Rate(business: 0.70, medical: 0.22, charity: 0.14, year: year)
            }
        }
    }

    // MARK: - Data Limits

    enum DataLimits {
        /// Maximum waypoints per trip upload batch
        static let waypointBatchSize = 100

        /// Maximum receipt image size (bytes)
        static let maxReceiptImageSize = 10 * 1024 * 1024 // 10MB

        /// Maximum report PDF size (bytes)
        static let maxReportSize = 50 * 1024 * 1024 // 50MB

        /// Default pagination page size
        static let defaultPageSize = 20

        /// Maximum pagination page size
        static let maxPageSize = 100

        /// Cache expiration for dashboard data (seconds)
        static let dashboardCacheExpiration: TimeInterval = 300 // 5 minutes

        /// Offline data retention period (days)
        static let offlineDataRetentionDays = 30
    }

    // MARK: - Sync Configuration

    enum SyncConfiguration {
        /// Minimum interval between syncs (seconds)
        static let minimumSyncInterval: TimeInterval = 30

        /// Background sync interval (seconds)
        static let backgroundSyncInterval: TimeInterval = 900 // 15 minutes

        /// Maximum retry attempts for failed sync
        static let maxRetryAttempts = 5

        /// Base retry delay (seconds)
        static let baseRetryDelay: TimeInterval = 5

        /// Sync timeout (seconds)
        static let syncTimeout: TimeInterval = 60
    }

    // MARK: - Animation Durations

    enum AnimationDuration {
        static let quick: Double = 0.2
        static let standard: Double = 0.3
        static let slow: Double = 0.5
        static let loading: Double = 1.0
    }

    // MARK: - Haptic Patterns

    enum HapticPattern: String {
        case buttonTap = "light_impact"
        case selection = "selection"
        case toggle = "medium_impact"
        case success = "success_notification"
        case error = "error_notification"
        case warning = "warning_notification"
        case dragThreshold = "rigid_impact"
        case delete = "heavy_impact"
    }
}
