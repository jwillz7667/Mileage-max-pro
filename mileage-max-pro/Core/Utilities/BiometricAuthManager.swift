//
//  BiometricAuthManager.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import Foundation
import Combine
import LocalAuthentication

/// Manages biometric authentication (Face ID / Touch ID)
@MainActor
final class BiometricAuthManager: ObservableObject {

    // MARK: - Singleton

    static let shared = BiometricAuthManager()

    // MARK: - Published Properties

    @Published private(set) var biometricType: BiometricType = .none
    @Published private(set) var isAvailable: Bool = false
    @Published private(set) var isAuthenticated: Bool = false
    @Published private(set) var lastAuthenticationDate: Date?

    // MARK: - Private Properties

    private let context = LAContext()
    private let authenticationTimeout: TimeInterval = 300 // 5 minutes

    // MARK: - Initialization

    private init() {
        checkBiometricAvailability()
    }

    // MARK: - Public Methods

    /// Check what biometric authentication is available
    func checkBiometricAvailability() {
        var error: NSError?
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        if canEvaluate {
            isAvailable = true
            switch context.biometryType {
            case .faceID:
                biometricType = .faceID
            case .touchID:
                biometricType = .touchID
            case .opticID:
                biometricType = .opticID
            case .none:
                biometricType = .none
                isAvailable = false
            @unknown default:
                biometricType = .none
                isAvailable = false
            }
        } else {
            isAvailable = false
            biometricType = .none

            if let error = error {
                handleBiometricError(error)
            }
        }

        Logger.shared.debug("Biometric availability: \(isAvailable), type: \(biometricType)")
    }

    /// Authenticate with biometrics
    /// - Parameters:
    ///   - reason: Reason shown to user for authentication
    ///   - fallbackTitle: Title for fallback button (nil to hide)
    /// - Returns: True if authentication succeeded
    func authenticate(
        reason: String = "Authenticate to access MileageMax Pro",
        fallbackTitle: String? = "Use Passcode"
    ) async -> AuthenticationResult {
        // Check if recently authenticated
        if let lastAuth = lastAuthenticationDate,
           Date().timeIntervalSince(lastAuth) < authenticationTimeout {
            Logger.shared.debug("Using cached authentication")
            return .success
        }

        // Create fresh context for each authentication attempt
        let authContext = LAContext()
        authContext.localizedFallbackTitle = fallbackTitle
        authContext.localizedCancelTitle = "Cancel"

        var error: NSError?
        guard authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let error = error {
                Logger.shared.warning("Biometric not available: \(error.localizedDescription)")
                return handleBiometricError(error)
            }
            return .notAvailable
        }

        do {
            let success = try await authContext.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )

            if success {
                isAuthenticated = true
                lastAuthenticationDate = Date()
                Logger.shared.logAuth(event: .biometricSuccess)
                return .success
            } else {
                isAuthenticated = false
                Logger.shared.logAuth(event: .biometricFailed)
                return .failed
            }
        } catch {
            isAuthenticated = false
            Logger.shared.error("Biometric authentication failed", error: error)
            Logger.shared.logAuth(event: .biometricFailed)
            return handleAuthenticationError(error as NSError)
        }
    }

    /// Authenticate with device passcode as fallback
    func authenticateWithPasscode(
        reason: String = "Authenticate to access MileageMax Pro"
    ) async -> AuthenticationResult {
        let authContext = LAContext()

        var error: NSError?
        guard authContext.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            if let error = error {
                return handleBiometricError(error)
            }
            return .notAvailable
        }

        do {
            let success = try await authContext.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )

            if success {
                isAuthenticated = true
                lastAuthenticationDate = Date()
                return .success
            } else {
                isAuthenticated = false
                return .failed
            }
        } catch {
            isAuthenticated = false
            return handleAuthenticationError(error as NSError)
        }
    }

    /// Clear authentication state
    func clearAuthentication() {
        isAuthenticated = false
        lastAuthenticationDate = nil
        context.invalidate()
        Logger.shared.debug("Authentication state cleared")
    }

    /// Check if re-authentication is needed
    var needsReauthentication: Bool {
        guard let lastAuth = lastAuthenticationDate else { return true }
        return Date().timeIntervalSince(lastAuth) >= authenticationTimeout
    }

    // MARK: - Private Methods

    @discardableResult
    private func handleBiometricError(_ error: NSError) -> AuthenticationResult {
        switch error.code {
        case LAError.biometryNotAvailable.rawValue:
            Logger.shared.warning("Biometry not available on this device")
            return .notAvailable

        case LAError.biometryNotEnrolled.rawValue:
            Logger.shared.warning("No biometric enrolled")
            return .notEnrolled

        case LAError.biometryLockout.rawValue:
            Logger.shared.warning("Biometry locked out due to too many attempts")
            return .lockedOut

        case LAError.passcodeNotSet.rawValue:
            Logger.shared.warning("Passcode not set on device")
            return .passcodeNotSet

        default:
            Logger.shared.error("Unknown biometric error", error: error)
            return .error(error.localizedDescription)
        }
    }

    private func handleAuthenticationError(_ error: NSError) -> AuthenticationResult {
        switch error.code {
        case LAError.userCancel.rawValue:
            return .cancelled

        case LAError.userFallback.rawValue:
            return .fallbackRequested

        case LAError.systemCancel.rawValue:
            return .systemCancelled

        case LAError.appCancel.rawValue:
            return .appCancelled

        case LAError.authenticationFailed.rawValue:
            return .failed

        case LAError.invalidContext.rawValue:
            return .invalidContext

        default:
            return .error(error.localizedDescription)
        }
    }
}

// MARK: - Biometric Type

enum BiometricType: String {
    case none = "None"
    case faceID = "Face ID"
    case touchID = "Touch ID"
    case opticID = "Optic ID"

    var iconName: String {
        switch self {
        case .none: return "person.crop.circle"
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .opticID: return "opticid"
        }
    }

    var displayName: String {
        rawValue
    }
}

// MARK: - Authentication Result

enum AuthenticationResult: Equatable {
    case success
    case failed
    case cancelled
    case fallbackRequested
    case systemCancelled
    case appCancelled
    case notAvailable
    case notEnrolled
    case lockedOut
    case passcodeNotSet
    case invalidContext
    case error(String)

    var isSuccess: Bool {
        self == .success
    }

    var localizedDescription: String {
        switch self {
        case .success:
            return "Authentication successful"
        case .failed:
            return "Authentication failed"
        case .cancelled:
            return "Authentication cancelled"
        case .fallbackRequested:
            return "Fallback authentication requested"
        case .systemCancelled:
            return "Authentication cancelled by system"
        case .appCancelled:
            return "Authentication cancelled by app"
        case .notAvailable:
            return "Biometric authentication not available"
        case .notEnrolled:
            return "No biometric data enrolled"
        case .lockedOut:
            return "Biometric authentication locked"
        case .passcodeNotSet:
            return "Device passcode not set"
        case .invalidContext:
            return "Invalid authentication context"
        case .error(let message):
            return message
        }
    }
}
