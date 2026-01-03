//
//  APIError.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import Foundation

/// Comprehensive API error handling
enum APIError: LocalizedError, Equatable {
    // MARK: - Network Errors
    case networkUnavailable
    case timeout
    case connectionLost
    case serverUnreachable

    // MARK: - HTTP Errors
    case badRequest(String?)
    case unauthorized
    case forbidden
    case notFound
    case conflict(String?)
    case unprocessableEntity(ValidationErrors?)
    case tooManyRequests(retryAfter: Int?)
    case serverError(Int, String?)

    // MARK: - Authentication Errors
    case tokenExpired
    case tokenInvalid
    case refreshTokenExpired
    case authenticationRequired

    // MARK: - Data Errors
    case decodingError(String)
    case encodingError(String)
    case invalidResponse
    case emptyResponse

    // MARK: - Business Logic Errors
    case subscriptionRequired(feature: String)
    case quotaExceeded(resource: String)
    case duplicateEntry(String)
    case operationNotAllowed(String)

    // MARK: - Generic
    case unknown(String?)
    case cancelled

    // MARK: - Error Description

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "No internet connection available"
        case .timeout:
            return "The request timed out"
        case .connectionLost:
            return "Connection was lost during the request"
        case .serverUnreachable:
            return "Unable to reach the server"

        case .badRequest(let message):
            return message ?? "Invalid request"
        case .unauthorized:
            return "Please sign in to continue"
        case .forbidden:
            return "You don't have permission to access this"
        case .notFound:
            return "The requested resource was not found"
        case .conflict(let message):
            return message ?? "A conflict occurred with the current state"
        case .unprocessableEntity(let errors):
            return errors?.firstError ?? "The submitted data is invalid"
        case .tooManyRequests(let retryAfter):
            if let seconds = retryAfter {
                return "Too many requests. Please try again in \(seconds) seconds"
            }
            return "Too many requests. Please try again later"
        case .serverError(let code, let message):
            return message ?? "Server error (\(code))"

        case .tokenExpired:
            return "Your session has expired"
        case .tokenInvalid:
            return "Invalid authentication token"
        case .refreshTokenExpired:
            return "Please sign in again"
        case .authenticationRequired:
            return "Authentication is required"

        case .decodingError(let message):
            return "Failed to process response: \(message)"
        case .encodingError(let message):
            return "Failed to prepare request: \(message)"
        case .invalidResponse:
            return "Received an invalid response from the server"
        case .emptyResponse:
            return "No data received from the server"

        case .subscriptionRequired(let feature):
            return "Upgrade to Pro to access \(feature)"
        case .quotaExceeded(let resource):
            return "You've reached the limit for \(resource)"
        case .duplicateEntry(let message):
            return message
        case .operationNotAllowed(let message):
            return message

        case .unknown(let message):
            return message ?? "An unexpected error occurred"
        case .cancelled:
            return "Request was cancelled"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable, .connectionLost:
            return "Check your internet connection and try again"
        case .timeout, .serverUnreachable:
            return "Please try again in a moment"
        case .unauthorized, .tokenExpired, .refreshTokenExpired:
            return "Sign in to continue"
        case .tooManyRequests:
            return "Wait a moment before trying again"
        case .subscriptionRequired:
            return "Upgrade your subscription to access this feature"
        case .quotaExceeded:
            return "Upgrade to Pro for unlimited access"
        default:
            return nil
        }
    }

    var isRetryable: Bool {
        switch self {
        case .networkUnavailable, .timeout, .connectionLost, .serverUnreachable:
            return true
        case .serverError(let code, _):
            return code >= 500 && code < 600
        case .tooManyRequests:
            return true
        default:
            return false
        }
    }

    var requiresReauthentication: Bool {
        switch self {
        case .unauthorized, .tokenExpired, .tokenInvalid, .refreshTokenExpired, .authenticationRequired:
            return true
        default:
            return false
        }
    }

    var errorCode: Int {
        switch self {
        case .networkUnavailable: return APIErrorCode.networkUnavailable
        case .timeout: return APIErrorCode.timeout
        case .connectionLost: return APIErrorCode.connectionLost
        case .serverUnreachable: return APIErrorCode.serverUnreachable
        case .badRequest: return APIErrorCode.badRequest
        case .unauthorized: return APIErrorCode.unauthorized
        case .forbidden: return APIErrorCode.forbidden
        case .notFound: return APIErrorCode.notFound
        case .conflict: return APIErrorCode.conflict
        case .unprocessableEntity: return APIErrorCode.unprocessableEntity
        case .tooManyRequests: return APIErrorCode.tooManyRequests
        case .serverError(let code, _): return code
        case .tokenExpired: return APIErrorCode.tokenExpired
        case .tokenInvalid: return APIErrorCode.tokenInvalid
        case .refreshTokenExpired: return APIErrorCode.refreshTokenExpired
        case .authenticationRequired: return APIErrorCode.authenticationRequired
        case .decodingError: return APIErrorCode.decodingError
        case .encodingError: return APIErrorCode.encodingError
        case .invalidResponse: return APIErrorCode.invalidResponse
        case .emptyResponse: return APIErrorCode.emptyResponse
        case .subscriptionRequired: return APIErrorCode.subscriptionRequired
        case .quotaExceeded: return APIErrorCode.quotaExceeded
        case .duplicateEntry: return APIErrorCode.duplicateEntry
        case .operationNotAllowed: return APIErrorCode.operationNotAllowed
        case .unknown: return APIErrorCode.unknown
        case .cancelled: return APIErrorCode.cancelled
        }
    }

    // MARK: - Factory Methods

    static func from(urlError: URLError) -> APIError {
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .networkUnavailable
        case .timedOut:
            return .timeout
        case .cannotConnectToHost, .cannotFindHost:
            return .serverUnreachable
        case .cancelled:
            return .cancelled
        default:
            return .unknown(urlError.localizedDescription)
        }
    }

    static func from(httpStatusCode: Int, body: Data?) -> APIError {
        let message = body.flatMap { try? JSONDecoder().decode(ErrorResponse.self, from: $0) }?.message

        switch httpStatusCode {
        case 400:
            return .badRequest(message)
        case 401:
            return .unauthorized
        case 403:
            return .forbidden
        case 404:
            return .notFound
        case 409:
            return .conflict(message)
        case 422:
            let validationErrors = body.flatMap { try? JSONDecoder().decode(ValidationErrors.self, from: $0) }
            return .unprocessableEntity(validationErrors)
        case 429:
            let retryAfter = body.flatMap { try? JSONDecoder().decode(RateLimitResponse.self, from: $0) }?.retryAfter
            return .tooManyRequests(retryAfter: retryAfter)
        case 500...599:
            return .serverError(httpStatusCode, message)
        default:
            return .unknown(message)
        }
    }
}

// MARK: - Equatable

extension APIError {
    static func == (lhs: APIError, rhs: APIError) -> Bool {
        lhs.errorCode == rhs.errorCode
    }
}

// MARK: - Supporting Types

struct ValidationErrors: Codable, Equatable {
    let errors: [FieldError]

    struct FieldError: Codable, Equatable {
        let field: String
        let message: String
        let code: String?
    }

    var firstError: String? {
        errors.first?.message
    }

    func error(for field: String) -> String? {
        errors.first { $0.field == field }?.message
    }
}

struct ErrorResponse: Codable {
    let message: String
    let code: String?
    let details: [String: String]?
}

struct RateLimitResponse: Codable {
    let retryAfter: Int
    let limit: Int
    let remaining: Int
    let reset: Date
}

// MARK: - Error Codes

enum APIErrorCode {
    // Network (1xxx)
    static let networkUnavailable = 1001
    static let timeout = 1002
    static let connectionLost = 1003
    static let serverUnreachable = 1004

    // HTTP (standard codes)
    static let badRequest = 400
    static let unauthorized = 401
    static let forbidden = 403
    static let notFound = 404
    static let conflict = 409
    static let unprocessableEntity = 422
    static let tooManyRequests = 429

    // Authentication (2xxx)
    static let tokenExpired = 2001
    static let tokenInvalid = 2002
    static let refreshTokenExpired = 2003
    static let authenticationRequired = 2004

    // Data (3xxx)
    static let decodingError = 3001
    static let encodingError = 3002
    static let invalidResponse = 3003
    static let emptyResponse = 3004

    // Business Logic (4xxx)
    static let subscriptionRequired = 4001
    static let quotaExceeded = 4002
    static let duplicateEntry = 4003
    static let operationNotAllowed = 4004

    // Generic (9xxx)
    static let unknown = 9001
    static let cancelled = 9002
}
