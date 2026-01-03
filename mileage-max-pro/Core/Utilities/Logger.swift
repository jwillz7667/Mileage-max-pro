//
//  Logger.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import Foundation
import os.log

/// Centralized logging system for MileageMax Pro
/// Uses Apple's unified logging system (os_log) for optimal performance
final class Logger {

    // MARK: - Singleton

    static let shared = Logger()

    // MARK: - Log Categories

    private let generalLog: OSLog
    private let networkLog: OSLog
    private let locationLog: OSLog
    private let syncLog: OSLog
    private let authLog: OSLog
    private let tripLog: OSLog
    private let uiLog: OSLog
    private let dataLog: OSLog

    // MARK: - Configuration

    private let subsystem: String
    private let dateFormatter: DateFormatter

    #if DEBUG
    private let isDebugMode = true
    #else
    private let isDebugMode = false
    #endif

    // MARK: - Initialization

    private init() {
        subsystem = Bundle.main.bundleIdentifier ?? "com.mileagemaxpro.app"

        generalLog = OSLog(subsystem: subsystem, category: "General")
        networkLog = OSLog(subsystem: subsystem, category: "Network")
        locationLog = OSLog(subsystem: subsystem, category: "Location")
        syncLog = OSLog(subsystem: subsystem, category: "Sync")
        authLog = OSLog(subsystem: subsystem, category: "Auth")
        tripLog = OSLog(subsystem: subsystem, category: "Trip")
        uiLog = OSLog(subsystem: subsystem, category: "UI")
        dataLog = OSLog(subsystem: subsystem, category: "Data")

        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    }

    // MARK: - Public Logging Methods

    /// Log debug message (only in DEBUG builds)
    func debug(
        _ message: String,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        guard isDebugMode else { return }
        log(message, level: .debug, category: category, file: file, function: function, line: line)
    }

    /// Log info message
    func info(
        _ message: String,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .info, category: category, file: file, function: function, line: line)
    }

    /// Log notice message
    func notice(
        _ message: String,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .notice, category: category, file: file, function: function, line: line)
    }

    /// Log warning message
    func warning(
        _ message: String,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .warning, category: category, file: file, function: function, line: line)
    }

    /// Log error message
    func error(
        _ message: String,
        error: Error? = nil,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        var fullMessage = message
        if let error = error {
            fullMessage += " | Error: \(error.localizedDescription)"
            if let nsError = error as NSError? {
                fullMessage += " (Code: \(nsError.code), Domain: \(nsError.domain))"
            }
        }
        log(fullMessage, level: .error, category: category, file: file, function: function, line: line)
    }

    /// Log critical/fault message
    func critical(
        _ message: String,
        error: Error? = nil,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        var fullMessage = message
        if let error = error {
            fullMessage += " | Error: \(error.localizedDescription)"
        }
        log(fullMessage, level: .fault, category: category, file: file, function: function, line: line)
    }

    // MARK: - Specialized Logging Methods

    /// Log network request
    func logNetworkRequest(
        method: String,
        url: String,
        headers: [String: String]? = nil,
        body: Data? = nil
    ) {
        var message = "[\(method)] \(url)"
        if isDebugMode {
            if let headers = headers {
                let safeHeaders = headers.filter { !$0.key.lowercased().contains("authorization") }
                message += " | Headers: \(safeHeaders)"
            }
            if let body = body, let bodyString = String(data: body, encoding: .utf8) {
                let truncated = bodyString.prefix(500)
                message += " | Body: \(truncated)"
            }
        }
        debug(message, category: .network)
    }

    /// Log network response
    func logNetworkResponse(
        url: String,
        statusCode: Int,
        duration: TimeInterval,
        responseSize: Int? = nil
    ) {
        var message = "[\(statusCode)] \(url) | Duration: \(String(format: "%.2f", duration * 1000))ms"
        if let size = responseSize {
            message += " | Size: \(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file))"
        }

        let level: LogLevel = statusCode >= 400 ? .error : .debug
        log(message, level: level, category: .network)
    }

    /// Log location update
    func logLocation(
        latitude: Double,
        longitude: Double,
        accuracy: Double,
        speed: Double? = nil,
        source: String = "Unknown"
    ) {
        var message = "Location: (\(String(format: "%.6f", latitude)), \(String(format: "%.6f", longitude)))"
        message += " | Accuracy: \(String(format: "%.1f", accuracy))m"
        if let speed = speed {
            message += " | Speed: \(String(format: "%.1f", speed * 2.23694)) mph"
        }
        message += " | Source: \(source)"
        debug(message, category: .location)
    }

    /// Log trip event
    func logTripEvent(_ event: TripLogEvent, tripId: String? = nil) {
        var message = "Trip Event: \(event.rawValue)"
        if let tripId = tripId {
            message += " | TripID: \(tripId.prefix(8))"
        }
        info(message, category: .trip)
    }

    /// Log sync event
    func logSync(
        operation: String,
        recordType: String,
        count: Int,
        success: Bool
    ) {
        let status = success ? "SUCCESS" : "FAILED"
        let message = "[\(status)] \(operation) \(recordType) | Count: \(count)"
        log(message, level: success ? .info : .error, category: .sync)
    }

    /// Log authentication event
    func logAuth(event: AuthLogEvent, userId: String? = nil) {
        var message = "Auth: \(event.rawValue)"
        if let userId = userId {
            message += " | UserID: \(userId.prefix(8))..."
        }
        info(message, category: .auth)
    }

    // MARK: - Private Methods

    private func log(
        _ message: String,
        level: LogLevel,
        category: LogCategory,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let osLog = logForCategory(category)
        let fileName = (file as NSString).lastPathComponent
        let timestamp = dateFormatter.string(from: Date())

        let formattedMessage: StaticString
        let logMessage = "[\(timestamp)] [\(fileName):\(line)] \(function) | \(message)"

        // Use os_log for system integration
        switch level {
        case .debug:
            os_log(.debug, log: osLog, "%{public}@", logMessage)
        case .info:
            os_log(.info, log: osLog, "%{public}@", logMessage)
        case .notice:
            os_log(.default, log: osLog, "%{public}@", logMessage)
        case .warning:
            os_log(.error, log: osLog, "%{public}@", logMessage)
        case .error:
            os_log(.error, log: osLog, "%{public}@", logMessage)
        case .fault:
            os_log(.fault, log: osLog, "%{public}@", logMessage)
        }

        // Also print to console in debug mode
        #if DEBUG
        let emoji = level.emoji
        print("\(emoji) [\(category.rawValue)] \(logMessage)")
        #endif
    }

    private func logForCategory(_ category: LogCategory) -> OSLog {
        switch category {
        case .general: return generalLog
        case .network: return networkLog
        case .location: return locationLog
        case .sync: return syncLog
        case .auth: return authLog
        case .trip: return tripLog
        case .ui: return uiLog
        case .data: return dataLog
        }
    }
}

// MARK: - Log Level

enum LogLevel {
    case debug
    case info
    case notice
    case warning
    case error
    case fault

    var emoji: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .notice: return "📝"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .fault: return "🔥"
        }
    }
}

// MARK: - Log Category

enum LogCategory: String {
    case general = "General"
    case network = "Network"
    case location = "Location"
    case sync = "Sync"
    case auth = "Auth"
    case trip = "Trip"
    case ui = "UI"
    case data = "Data"
}

// MARK: - Trip Log Events

enum TripLogEvent: String {
    case detectionStarted = "Detection Started"
    case tripStarted = "Trip Started"
    case tripPaused = "Trip Paused"
    case tripResumed = "Trip Resumed"
    case tripCompleted = "Trip Completed"
    case tripCancelled = "Trip Cancelled"
    case waypointRecorded = "Waypoint Recorded"
    case stopDetected = "Stop Detected"
    case routeProcessed = "Route Processed"
    case addressResolved = "Address Resolved"
    case syncCompleted = "Sync Completed"
}

// MARK: - Auth Log Events

enum AuthLogEvent: String {
    case loginAttempt = "Login Attempt"
    case loginSuccess = "Login Success"
    case loginFailed = "Login Failed"
    case tokenRefreshed = "Token Refreshed"
    case tokenExpired = "Token Expired"
    case logoutRequested = "Logout Requested"
    case logoutCompleted = "Logout Completed"
    case sessionRevoked = "Session Revoked"
    case biometricSuccess = "Biometric Success"
    case biometricFailed = "Biometric Failed"
}

// MARK: - Global Logging Functions

/// Convenience function for debug logging
func logDebug(_ message: String, category: LogCategory = .general) {
    Logger.shared.debug(message, category: category)
}

/// Convenience function for info logging
func logInfo(_ message: String, category: LogCategory = .general) {
    Logger.shared.info(message, category: category)
}

/// Convenience function for warning logging
func logWarning(_ message: String, category: LogCategory = .general) {
    Logger.shared.warning(message, category: category)
}

/// Convenience function for error logging
func logError(_ message: String, error: Error? = nil, category: LogCategory = .general) {
    Logger.shared.error(message, error: error, category: category)
}
