//
//  AuthEndpoints.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import Foundation

/// Authentication-related API endpoints
enum AuthEndpoints {

    // MARK: - Sign In with Apple

    case signInWithApple(request: AppleSignInRequest)

    // MARK: - Sign In with Google

    case signInWithGoogle(request: GoogleSignInRequest)

    // MARK: - Email Authentication

    case registerWithEmail(email: String, password: String, firstName: String, lastName: String)
    case loginWithEmail(email: String, password: String)
    case forgotPassword(email: String)
    case resetPassword(token: String, newPassword: String)
    case verifyEmail(token: String)
    case resendVerificationEmail(email: String)

    // MARK: - Token Management

    case refreshToken(refreshToken: String, deviceId: String)
    case revokeToken

    // MARK: - Session

    case logout
    case getCurrentUser
    case deleteAccount(confirmation: String)
}

extension AuthEndpoints: APIEndpoint {

    var method: HTTPMethod {
        switch self {
        case .signInWithApple, .signInWithGoogle, .registerWithEmail, .loginWithEmail,
             .forgotPassword, .resetPassword, .refreshToken, .resendVerificationEmail:
            return .post
        case .verifyEmail, .getCurrentUser:
            return .get
        case .revokeToken, .logout, .deleteAccount:
            return .delete
        }
    }

    var path: String {
        switch self {
        case .signInWithApple:
            return APIConstants.Endpoints.Auth.appleSignIn
        case .signInWithGoogle:
            return APIConstants.Endpoints.Auth.googleSignIn
        case .registerWithEmail:
            return APIConstants.Endpoints.Auth.register
        case .loginWithEmail:
            return APIConstants.Endpoints.Auth.login
        case .forgotPassword:
            return APIConstants.Endpoints.Auth.forgotPassword
        case .resetPassword:
            return APIConstants.Endpoints.Auth.resetPassword
        case .verifyEmail:
            return APIConstants.Endpoints.Auth.verifyEmail
        case .resendVerificationEmail:
            return APIConstants.Endpoints.Auth.resendVerification
        case .refreshToken:
            return APIConstants.Endpoints.Auth.refreshToken
        case .revokeToken:
            return APIConstants.Endpoints.Auth.revokeToken
        case .logout:
            return APIConstants.Endpoints.Auth.logout
        case .getCurrentUser:
            return APIConstants.Endpoints.Auth.me
        case .deleteAccount:
            return APIConstants.Endpoints.Auth.deleteAccount
        }
    }

    var body: Encodable? {
        switch self {
        case .signInWithApple(let request):
            return request

        case .signInWithGoogle(let request):
            return request

        case .registerWithEmail(let email, let password, let firstName, let lastName):
            return EmailRegisterRequest(
                email: email,
                password: password,
                firstName: firstName,
                lastName: lastName
            )

        case .loginWithEmail(let email, let password):
            return EmailLoginRequest(email: email, password: password)

        case .forgotPassword(let email):
            return ForgotPasswordRequest(email: email)

        case .resetPassword(let token, let newPassword):
            return ResetPasswordRequest(token: token, newPassword: newPassword)

        case .resendVerificationEmail(let email):
            return ResendVerificationRequest(email: email)

        case .refreshToken(let refreshToken, let deviceId):
            return RefreshTokenRequest(refreshToken: refreshToken, deviceId: deviceId)

        case .deleteAccount(let confirmation):
            return DeleteAccountRequest(confirmation: confirmation)

        default:
            return nil
        }
    }

    var queryParameters: [String: String]? {
        switch self {
        case .verifyEmail(let token):
            return ["token": token]
        default:
            return nil
        }
    }

    var requiresAuthentication: Bool {
        switch self {
        case .signInWithApple, .signInWithGoogle, .registerWithEmail, .loginWithEmail,
             .forgotPassword, .resetPassword, .verifyEmail, .resendVerificationEmail, .refreshToken:
            return false
        default:
            return true
        }
    }
}

// MARK: - Request Models

struct AppleSignInRequest: Codable {
    let identityToken: String
    let authorizationCode: String
    let user: AppleUserInfo?
    let deviceId: String
    let deviceName: String?
    let deviceModel: String?
    let osVersion: String?
    let appVersion: String?
    let pushToken: String?

    struct AppleUserInfo: Codable {
        let email: String?
        let name: AppleName?

        struct AppleName: Codable {
            let firstName: String?
            let lastName: String?
        }
    }
}

struct GoogleSignInRequest: Codable {
    let idToken: String
    let accessToken: String
    let deviceId: String
    let deviceName: String?
    let deviceModel: String?
    let osVersion: String?
    let appVersion: String?
    let pushToken: String?
}

struct EmailRegisterRequest: Codable {
    let email: String
    let password: String
    let firstName: String
    let lastName: String
}

struct EmailLoginRequest: Codable {
    let email: String
    let password: String
}

struct ForgotPasswordRequest: Codable {
    let email: String
}

struct ResetPasswordRequest: Codable {
    let token: String
    let newPassword: String
}

struct ResendVerificationRequest: Codable {
    let email: String
}

struct RefreshTokenRequest: Codable {
    let refreshToken: String
    let deviceId: String
}

struct DeleteAccountRequest: Codable {
    let confirmation: String
}

// MARK: - Response Models

struct AuthResponse: Codable {
    let user: UserDTO
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
}

struct MessageResponse: Codable {
    let message: String
    let success: Bool
}
