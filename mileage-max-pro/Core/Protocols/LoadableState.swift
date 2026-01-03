//
//  LoadableState.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import Foundation

/// Represents the loading state of async data operations
enum LoadableState<T> {
    /// Initial state, no data loaded yet
    case idle

    /// Currently loading data
    case loading

    /// Data loaded successfully
    case loaded(T)

    /// Error occurred during loading
    case error(AppError)

    /// Refreshing with existing data
    case refreshing(T)
}

// MARK: - Computed Properties

extension LoadableState {
    /// Returns the loaded data if available
    var data: T? {
        switch self {
        case .loaded(let data), .refreshing(let data):
            return data
        default:
            return nil
        }
    }

    /// Returns true if currently loading
    var isLoading: Bool {
        switch self {
        case .loading, .refreshing:
            return true
        default:
            return false
        }
    }

    /// Returns true if in idle state
    var isIdle: Bool {
        if case .idle = self { return true }
        return false
    }

    /// Returns true if data is loaded
    var isLoaded: Bool {
        if case .loaded = self { return true }
        return false
    }

    /// Returns true if in error state
    var isError: Bool {
        if case .error = self { return true }
        return false
    }

    /// Returns the error if in error state
    var error: AppError? {
        if case .error(let error) = self { return error }
        return nil
    }

    /// Returns true if has any data (loaded or refreshing)
    var hasData: Bool {
        data != nil
    }
}

// MARK: - Transformations

extension LoadableState {
    /// Map the loaded data to a new type
    func map<U>(_ transform: (T) -> U) -> LoadableState<U> {
        switch self {
        case .idle:
            return .idle
        case .loading:
            return .loading
        case .loaded(let data):
            return .loaded(transform(data))
        case .error(let error):
            return .error(error)
        case .refreshing(let data):
            return .refreshing(transform(data))
        }
    }

    /// FlatMap the loaded data
    func flatMap<U>(_ transform: (T) -> LoadableState<U>) -> LoadableState<U> {
        switch self {
        case .idle:
            return .idle
        case .loading:
            return .loading
        case .loaded(let data):
            return transform(data)
        case .error(let error):
            return .error(error)
        case .refreshing(let data):
            let result = transform(data)
            if case .loaded(let newData) = result {
                return .refreshing(newData)
            }
            return result
        }
    }
}

// MARK: - Equatable

extension LoadableState: Equatable where T: Equatable {
    static func == (lhs: LoadableState<T>, rhs: LoadableState<T>) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.loading, .loading):
            return true
        case (.loaded(let lhsData), .loaded(let rhsData)):
            return lhsData == rhsData
        case (.refreshing(let lhsData), .refreshing(let rhsData)):
            return lhsData == rhsData
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

// MARK: - App Error

/// Unified error type for the application
enum AppError: LocalizedError, Equatable {
    // Network errors
    case networkUnavailable
    case requestFailed(statusCode: Int, message: String)
    case requestTimeout
    case serverError(message: String)

    // Authentication errors
    case unauthorized
    case tokenExpired
    case sessionInvalid

    // Data errors
    case decodingError(String)
    case encodingError(String)
    case dataNotFound
    case dataCorrupted

    // Location errors
    case locationPermissionDenied
    case locationUnavailable
    case locationAccuracyInsufficient

    // Validation errors
    case validationFailed(String)
    case missingRequiredField(String)

    // Storage errors
    case storageError(String)
    case syncFailed(String)

    // Subscription errors
    case subscriptionRequired
    case featureNotAvailable

    // Generic errors
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "No internet connection available"
        case .requestFailed(let statusCode, let message):
            return "Request failed (\(statusCode)): \(message)"
        case .requestTimeout:
            return "Request timed out"
        case .serverError(let message):
            return "Server error: \(message)"
        case .unauthorized:
            return "Authentication required"
        case .tokenExpired:
            return "Session expired. Please log in again"
        case .sessionInvalid:
            return "Invalid session. Please log in again"
        case .decodingError(let detail):
            return "Failed to process response: \(detail)"
        case .encodingError(let detail):
            return "Failed to prepare request: \(detail)"
        case .dataNotFound:
            return "Data not found"
        case .dataCorrupted:
            return "Data is corrupted"
        case .locationPermissionDenied:
            return "Location permission denied"
        case .locationUnavailable:
            return "Location unavailable"
        case .locationAccuracyInsufficient:
            return "Location accuracy insufficient"
        case .validationFailed(let message):
            return message
        case .missingRequiredField(let field):
            return "\(field) is required"
        case .storageError(let detail):
            return "Storage error: \(detail)"
        case .syncFailed(let detail):
            return "Sync failed: \(detail)"
        case .subscriptionRequired:
            return "This feature requires a subscription"
        case .featureNotAvailable:
            return "This feature is not available on your current plan"
        case .unknown(let message):
            return message
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Please check your internet connection and try again"
        case .requestTimeout:
            return "Please try again"
        case .tokenExpired, .sessionInvalid, .unauthorized:
            return "Please log in again"
        case .locationPermissionDenied:
            return "Enable location access in Settings"
        case .subscriptionRequired, .featureNotAvailable:
            return "Upgrade your subscription to access this feature"
        default:
            return nil
        }
    }

    var isRetryable: Bool {
        switch self {
        case .networkUnavailable, .requestTimeout, .serverError:
            return true
        default:
            return false
        }
    }

    /// Create AppError from any Error
    static func from(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        return .unknown(error.localizedDescription)
    }
}

// MARK: - Pagination State

/// Represents paginated data state
struct PaginatedState<T> {
    var items: [T]
    var currentPage: Int
    var totalPages: Int
    var totalItems: Int
    var isLoadingMore: Bool
    var hasMorePages: Bool

    init(
        items: [T] = [],
        currentPage: Int = 0,
        totalPages: Int = 1,
        totalItems: Int = 0,
        isLoadingMore: Bool = false
    ) {
        self.items = items
        self.currentPage = currentPage
        self.totalPages = totalPages
        self.totalItems = totalItems
        self.isLoadingMore = isLoadingMore
        self.hasMorePages = currentPage < totalPages
    }

    var isEmpty: Bool {
        items.isEmpty
    }

    mutating func appendPage(_ newItems: [T], page: Int, totalPages: Int, totalItems: Int) {
        items.append(contentsOf: newItems)
        currentPage = page
        self.totalPages = totalPages
        self.totalItems = totalItems
        hasMorePages = page < totalPages
        isLoadingMore = false
    }

    mutating func reset() {
        items = []
        currentPage = 0
        totalPages = 1
        totalItems = 0
        isLoadingMore = false
        hasMorePages = true
    }
}

// MARK: - Form State

/// Represents form field validation state
struct FormFieldState<T> {
    var value: T
    var error: String?
    var isValid: Bool
    var isDirty: Bool

    init(value: T, isValid: Bool = true) {
        self.value = value
        self.error = nil
        self.isValid = isValid
        self.isDirty = false
    }

    mutating func validate(_ validator: (T) -> String?) {
        error = validator(value)
        isValid = error == nil
        isDirty = true
    }
}
