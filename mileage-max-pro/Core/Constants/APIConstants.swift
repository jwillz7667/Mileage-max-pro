//
//  APIConstants.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import Foundation

/// API configuration constants for MileageMax Pro backend
enum APIConstants {

    // MARK: - Base URLs

    #if DEBUG
    static let baseURL = URL(string: "https://api-staging.mileagemaxpro.com")!
    static let websocketURL = URL(string: "wss://api-staging.mileagemaxpro.com")!
    #else
    static let baseURL = URL(string: "https://api.mileagemaxpro.com")!
    static let websocketURL = URL(string: "wss://api.mileagemaxpro.com")!
    #endif

    // MARK: - API Versioning

    static let apiVersion = "v1"
    static let apiPath = "/api/\(apiVersion)"

    static var fullBaseURL: URL {
        baseURL.appendingPathComponent(apiPath)
    }

    // MARK: - Endpoints

    enum Endpoints {
        // Base paths for each resource
        static let Trips = "/trips"
        static let Vehicles = "/vehicles"
        static let Routes = "/routes"
        static let Expenses = "/expenses"
        static let Locations = "/locations"
        static let Reports = "/reports"

        // Auth namespace for authentication endpoints
        enum Auth {
            static let base = "/auth"
            static let appleSignIn = "/auth/apple"
            static let googleSignIn = "/auth/google"
            static let register = "/auth/register"
            static let login = "/auth/login"
            static let forgotPassword = "/auth/forgot-password"
            static let resetPassword = "/auth/reset-password"
            static let verifyEmail = "/auth/verify-email"
            static let resendVerification = "/auth/resend-verification"
            static let refreshToken = "/auth/refresh"
            static let revokeToken = "/auth/revoke"
            static let logout = "/auth/logout"
            static let me = "/auth/me"
            static let deleteAccount = "/auth/delete-account"
        }

        // Legacy authentication paths
        static let authApple = "/auth/apple"
        static let authGoogle = "/auth/google"
        static let authRefresh = "/auth/refresh"
        static let authLogout = "/auth/logout"
        static let authSessions = "/auth/sessions"

        // User
        static let userProfile = "/users/me"
        static let userSettings = "/users/me/settings"
        static let userDevices = "/users/me/devices"

        // Vehicles
        static let vehicles = "/vehicles"
        static func vehicle(id: String) -> String { "/vehicles/\(id)" }
        static func vehicleMaintenance(id: String) -> String { "/vehicles/\(id)/maintenance" }
        static func vehicleStats(id: String) -> String { "/vehicles/\(id)/stats" }

        // Trips
        static let trips = "/trips"
        static func trip(id: String) -> String { "/trips/\(id)" }
        static func tripWaypoints(id: String) -> String { "/trips/\(id)/waypoints" }
        static func tripComplete(id: String) -> String { "/trips/\(id)/complete" }

        // Routes
        static let routes = "/routes"
        static func route(id: String) -> String { "/routes/\(id)" }
        static func routeOptimize(id: String) -> String { "/routes/\(id)/optimize" }
        static func routeStart(id: String) -> String { "/routes/\(id)/start" }
        static func routeComplete(id: String) -> String { "/routes/\(id)/complete" }
        static func routeStop(routeId: String, stopId: String) -> String {
            "/routes/\(routeId)/stops/\(stopId)"
        }

        // Expenses
        static let expenses = "/expenses"
        static func expense(id: String) -> String { "/expenses/\(id)" }
        static let expenseReceipt = "/expenses/receipt"
        static let expenseFuel = "/expenses/fuel"

        // Locations
        static let locations = "/locations"
        static func location(id: String) -> String { "/locations/\(id)" }

        // Earnings
        static let earnings = "/earnings"
        static func earning(id: String) -> String { "/earnings/\(id)" }

        // Reports
        static let reports = "/reports"
        static func report(id: String) -> String { "/reports/\(id)" }
        static func reportDownload(id: String) -> String { "/reports/\(id)/download" }

        // Analytics
        static let analyticsDashboard = "/analytics/dashboard"
        static let analyticsTaxSummary = "/analytics/tax-summary"
        static let analyticsTrends = "/analytics/trends"

        // Sync
        static let sync = "/sync"
        static let syncPull = "/sync/pull"
        static let syncPush = "/sync/push"

        // Health
        static let health = "/health"
    }

    // MARK: - HTTP Headers

    enum Headers {
        static let contentType = "Content-Type"
        static let accept = "Accept"
        static let authorization = "Authorization"
        static let acceptLanguage = "Accept-Language"
        static let userAgent = "User-Agent"
        static let deviceId = "X-Device-ID"
        static let appVersion = "X-App-Version"
        static let apiVersion = "X-API-Version"
        static let platform = "X-Platform"
        static let timezone = "X-Timezone"
        static let requestId = "X-Request-ID"
        static let rateLimitLimit = "X-RateLimit-Limit"
        static let rateLimitRemaining = "X-RateLimit-Remaining"
        static let rateLimitReset = "X-RateLimit-Reset"
        static let retryAfter = "Retry-After"
    }

    enum HeaderValues {
        static let applicationJSON = "application/json"
        static let accept = "application/json"
        static let apiVersion = "v1"
        static let multipartFormData = "multipart/form-data"
        static let bearer = "Bearer"
        static let platformiOS = "iOS"

        static var userAgent: String {
            let appVersion = AppConstants.appVersion
            let buildNumber = AppConstants.buildNumber
            let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
            return "MileageMaxPro/\(appVersion) (\(buildNumber)) iOS/\(osVersion)"
        }
    }

    // MARK: - Request Configuration

    enum RequestConfiguration {
        /// Default request timeout (seconds)
        static let defaultTimeout: TimeInterval = 30

        /// Upload timeout for large files (seconds)
        static let uploadTimeout: TimeInterval = 120

        /// Download timeout for reports (seconds)
        static let downloadTimeout: TimeInterval = 300

        /// Maximum concurrent requests
        static let maxConcurrentRequests = 4

        /// Retry delay base (seconds)
        static let retryBaseDelay: TimeInterval = 1.0

        /// Maximum retry attempts
        static let maxRetryAttempts = 3

        /// Retryable status codes
        static let retryableStatusCodes: Set<Int> = [408, 429, 500, 502, 503, 504]
    }

    // MARK: - Token Configuration

    enum TokenConfiguration {
        /// Access token expiry margin (seconds)
        /// Refresh token before it expires by this margin
        static let accessTokenExpiryMargin: TimeInterval = 60

        /// Minimum time between token refresh attempts (seconds)
        static let minimumRefreshInterval: TimeInterval = 5

        /// Maximum token refresh retries
        static let maxRefreshRetries = 3
    }

    // MARK: - Rate Limiting

    enum RateLimiting {
        /// Requests per minute for free tier
        static let freeRPM = 60

        /// Requests per minute for pro tier
        static let proRPM = 120

        /// Requests per minute for business tier
        static let businessRPM = 300

        /// Requests per minute for enterprise tier
        static let enterpriseRPM = 600
    }

    // MARK: - Cache Keys

    enum CacheKeys {
        static let dashboardData = "dashboard_data"
        static let userProfile = "user_profile"
        static let vehicles = "vehicles"
        static let recentTrips = "recent_trips"
        static let savedLocations = "saved_locations"
        static let taxSummary = "tax_summary"

        static func tripDetail(id: String) -> String { "trip_\(id)" }
        static func vehicleDetail(id: String) -> String { "vehicle_\(id)" }
        static func routeDetail(id: String) -> String { "route_\(id)" }
    }

    // MARK: - Error Codes

    enum ErrorCodes {
        // Authentication errors (1xxx)
        static let invalidCredentials = 1001
        static let tokenExpired = 1002
        static let tokenRevoked = 1003
        static let sessionExpired = 1004
        static let accountLocked = 1005
        static let accountDeleted = 1006

        // Validation errors (2xxx)
        static let validationFailed = 2001
        static let missingRequiredField = 2002
        static let invalidFormat = 2003
        static let valueTooLong = 2004
        static let valueTooShort = 2005

        // Resource errors (3xxx)
        static let notFound = 3001
        static let alreadyExists = 3002
        static let resourceLocked = 3003
        static let resourceDeleted = 3004

        // Permission errors (4xxx)
        static let unauthorized = 4001
        static let forbidden = 4002
        static let subscriptionRequired = 4003
        static let featureNotAvailable = 4004
        static let quotaExceeded = 4005

        // Server errors (5xxx)
        static let internalError = 5001
        static let serviceUnavailable = 5002
        static let databaseError = 5003
        static let externalServiceError = 5004

        // Client errors (6xxx)
        static let networkError = 6001
        static let requestCancelled = 6002
        static let requestTimeout = 6003
        static let decodingError = 6004
        static let encodingError = 6005
    }

    // MARK: - WebSocket Events

    enum WebSocketEvents {
        // Connection events
        static let connect = "connect"
        static let disconnect = "disconnect"
        static let reconnect = "reconnect"
        static let error = "error"

        // Trip events
        static let tripStarted = "trip:started"
        static let tripUpdated = "trip:updated"
        static let tripCompleted = "trip:completed"

        // Route events
        static let routeOptimized = "route:optimized"
        static let stopUpdated = "stop:updated"

        // Sync events
        static let syncRequired = "sync:required"
        static let syncCompleted = "sync:completed"

        // Notification events
        static let notification = "notification"
    }
}
