//
//  AuthenticationService.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import Foundation
import AuthenticationServices
import SwiftUI
import Combine
import os

/// Handles all authentication operations
@MainActor
final class AuthenticationService: NSObject, ObservableObject {

    // MARK: - Singleton

    static let shared = AuthenticationService()

    // MARK: - Published Properties

    @Published private(set) var currentUser: User?
    @Published private(set) var authState: AuthState = .unknown
    @Published private(set) var isLoading = false

    // MARK: - Properties

    private let apiClient = APIClient.shared
    private var cancellables = Set<AnyCancellable>()
    private var appleSignInContinuation: CheckedContinuation<ASAuthorization, Error>?

    // MARK: - Auth State

    enum AuthState: Equatable {
        case unknown
        case authenticated
        case unauthenticated
        case onboarding
    }

    // MARK: - Initialization

    private override init() {
        super.init()
        checkAuthenticationStatus()
    }

    // MARK: - Authentication Check

    func checkAuthenticationStatus() {
        Task {
            do {
                let response: UserDTO = try await apiClient.request(AuthEndpoints.getCurrentUser)
                currentUser = User.from(dto: response)
                authState = .authenticated
                AppLogger.auth.info("Session restored")
            } catch {
                authState = .unauthenticated
                currentUser = nil
            }
        }
    }

    // MARK: - Sign In with Apple

    func signInWithApple() async throws {
        isLoading = true
        defer { isLoading = false }

        let authorization = try await performAppleSignIn()

        guard let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityTokenData = appleCredential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8),
              let authorizationCodeData = appleCredential.authorizationCode,
              let authorizationCode = String(data: authorizationCodeData, encoding: .utf8)
        else {
            throw AuthError.invalidCredentials
        }

        // Get name and email if available (only on first sign in)
        let firstName = appleCredential.fullName?.givenName
        let lastName = appleCredential.fullName?.familyName
        let email = appleCredential.email

        // Build user info if we have any data
        var userInfo: AppleSignInRequest.AppleUserInfo? = nil
        if email != nil || firstName != nil || lastName != nil {
            let name = (firstName != nil || lastName != nil)
                ? AppleSignInRequest.AppleUserInfo.AppleName(firstName: firstName, lastName: lastName)
                : nil
            userInfo = AppleSignInRequest.AppleUserInfo(email: email, name: name)
        }

        // Build request with device info
        let request = AppleSignInRequest(
            identityToken: identityToken,
            authorizationCode: authorizationCode,
            user: userInfo,
            deviceId: DeviceInfo.deviceId,
            deviceName: DeviceInfo.deviceName,
            deviceModel: DeviceInfo.deviceModel,
            osVersion: DeviceInfo.osVersion,
            appVersion: AppConstants.appVersion,
            pushToken: PushNotificationManager.shared.currentToken
        )

        let endpoint = AuthEndpoints.signInWithApple(request: request)
        let response: AuthResponse = try await apiClient.request(endpoint)

        // Store tokens
        apiClient.setTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)

        // Store Apple user identifier for credential state checks
        UserDefaults.standard.set(appleCredential.user, forKey: "appleUserIdentifier")

        // Update state
        currentUser = User.from(dto: response.user)
        authState = .authenticated

        AppLogger.auth.info("Signed in with Apple")
        HapticManager.shared.success()
    }

    private func performAppleSignIn() async throws -> ASAuthorization {
        try await withCheckedThrowingContinuation { continuation in
            appleSignInContinuation = continuation

            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    // MARK: - Sign In with Google

    func signInWithGoogle() async throws {
        isLoading = true
        defer { isLoading = false }

        // Note: Google Sign-In implementation requires GoogleSignIn SDK
        // This is a placeholder that would be implemented with the SDK

        throw AuthError.notImplemented
    }

    // MARK: - Email Authentication

    func signInWithEmail(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }

        let endpoint = AuthEndpoints.loginWithEmail(email: email, password: password)
        let response: AuthResponse = try await apiClient.request(endpoint)

        apiClient.setTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
        currentUser = User.from(dto: response.user)
        authState = .authenticated

        AppLogger.auth.info("Signed in with email")
        HapticManager.shared.success()
    }

    func registerWithEmail(email: String, password: String, firstName: String, lastName: String) async throws {
        isLoading = true
        defer { isLoading = false }

        let endpoint = AuthEndpoints.registerWithEmail(
            email: email,
            password: password,
            firstName: firstName,
            lastName: lastName
        )
        let response: AuthResponse = try await apiClient.request(endpoint)

        apiClient.setTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
        currentUser = User.from(dto: response.user)
        authState = .authenticated

        AppLogger.auth.info("Registered with email")
        HapticManager.shared.success()
    }

    func forgotPassword(email: String) async throws {
        isLoading = true
        defer { isLoading = false }

        let endpoint = AuthEndpoints.forgotPassword(email: email)
        let _: MessageResponse = try await apiClient.request(endpoint)

        AppLogger.auth.info("Password reset requested")
    }

    func resetPassword(token: String, newPassword: String) async throws {
        isLoading = true
        defer { isLoading = false }

        let endpoint = AuthEndpoints.resetPassword(token: token, newPassword: newPassword)
        let _: MessageResponse = try await apiClient.request(endpoint)

        AppLogger.auth.info("Password reset completed")
    }

    // MARK: - Sign Out

    func signOut() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await apiClient.requestVoid(AuthEndpoints.logout)
        } catch {
            AppLogger.auth.error("Logout request failed: \(error.localizedDescription)")
        }

        // Clear local state regardless of server response
        apiClient.clearTokens()
        currentUser = nil
        authState = .unauthenticated

        AppLogger.auth.info("Signed out")
    }

    // MARK: - Account Management

    func deleteAccount(confirmation: String) async throws {
        isLoading = true
        defer { isLoading = false }

        let endpoint = AuthEndpoints.deleteAccount(confirmation: confirmation)
        try await apiClient.requestVoid(endpoint)

        apiClient.clearTokens()
        currentUser = nil
        authState = .unauthenticated

        AppLogger.auth.info("Account deleted")
    }

    func refreshCurrentUser() async throws {
        let response: UserDTO = try await apiClient.request(AuthEndpoints.getCurrentUser)
        currentUser = User.from(dto: response)
    }

    // MARK: - Biometric Authentication

    func authenticateWithBiometrics() async throws -> Bool {
        let result = await BiometricAuthManager.shared.authenticate(
            reason: "Authenticate to access MileageMax Pro"
        )
        return result == .success
    }

    // MARK: - Apple ID Credential State

    func checkAppleCredentialState() async {
        guard let userIdentifier = UserDefaults.standard.string(forKey: "appleUserIdentifier") else {
            return
        }

        let provider = ASAuthorizationAppleIDProvider()

        do {
            let credentialState = try await provider.credentialState(forUserID: userIdentifier)

            switch credentialState {
            case .authorized:
                AppLogger.auth.info("Apple ID credential is still valid")
            case .revoked, .notFound:
                AppLogger.auth.warning("Apple ID credential revoked or not found")
                await signOut()
            case .transferred:
                AppLogger.auth.info("Apple ID credential transferred")
            @unknown default:
                break
            }
        } catch {
            AppLogger.auth.error("Failed to check Apple credential state: \(error.localizedDescription)")
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthenticationService: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        Task { @MainActor in
            appleSignInContinuation?.resume(returning: authorization)
            appleSignInContinuation = nil
        }
    }

    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Task { @MainActor in
            appleSignInContinuation?.resume(throwing: AuthError.appleSignInFailed(error.localizedDescription))
            appleSignInContinuation = nil
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AuthenticationService: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first
        else {
            return UIWindow()
        }
        return window
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case invalidCredentials
    case appleSignInFailed(String)
    case googleSignInFailed(String)
    case emailNotVerified
    case accountDisabled
    case networkError
    case notImplemented
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid credentials provided"
        case .appleSignInFailed(let message):
            return "Apple Sign In failed: \(message)"
        case .googleSignInFailed(let message):
            return "Google Sign In failed: \(message)"
        case .emailNotVerified:
            return "Please verify your email address"
        case .accountDisabled:
            return "This account has been disabled"
        case .networkError:
            return "Network connection error"
        case .notImplemented:
            return "This feature is not yet implemented"
        case .unknown(let message):
            return message
        }
    }
}

// MARK: - User Extension

extension User {
    static func from(dto: UserDTO) -> User {
        dto.toModel()
    }
}

// MARK: - Environment Key

private struct AuthenticationServiceKey: EnvironmentKey {
    static let defaultValue: AuthenticationService = .shared
}

extension EnvironmentValues {
    var authService: AuthenticationService {
        get { self[AuthenticationServiceKey.self] }
        set { self[AuthenticationServiceKey.self] = newValue }
    }
}
