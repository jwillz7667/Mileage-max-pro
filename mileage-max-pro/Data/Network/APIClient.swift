//
//  APIClient.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import Foundation
import Combine
import os

/// Main API client for network requests
@MainActor
final class APIClient: ObservableObject {

    // MARK: - Singleton

    static let shared = APIClient()

    // MARK: - Properties

    private let session: URLSession
    private let baseURL: URL
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    @Published private(set) var isAuthenticated = false

    private var accessToken: String? {
        didSet {
            isAuthenticated = accessToken != nil
        }
    }

    private var refreshToken: String?
    private var tokenRefreshTask: Task<String, Error>?

    private let maxRetries = 3
    private let retryDelay: TimeInterval = 1.0

    // MARK: - Initialization

    private init(
        session: URLSession = .shared,
        baseURL: URL = APIConstants.fullBaseURL
    ) {
        self.session = session
        self.baseURL = baseURL

        // Configure decoder
        self.decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            // Try ISO8601 with fractional seconds
            let iso8601Formatter = ISO8601DateFormatter()
            iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }

            // Try ISO8601 without fractional seconds
            iso8601Formatter.formatOptions = [.withInternetDateTime]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }

            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format: \(dateString)")
        }
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        // Configure encoder
        self.encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        // Note: Backend expects camelCase, so don't convert to snake_case

        // Load stored tokens
        loadStoredTokens()
    }

    // MARK: - Token Management

    func setTokens(accessToken: String, refreshToken: String?) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        storeTokens()
    }

    func clearTokens() {
        accessToken = nil
        refreshToken = nil
        clearStoredTokens()
    }

    private func loadStoredTokens() {
        // Load from Keychain
        if let accessTokenData = KeychainHelper.shared.read(service: "com.mileagemaxpro.auth", account: "accessToken"),
           let accessToken = String(data: accessTokenData, encoding: .utf8) {
            self.accessToken = accessToken
        }

        if let refreshTokenData = KeychainHelper.shared.read(service: "com.mileagemaxpro.auth", account: "refreshToken"),
           let refreshToken = String(data: refreshTokenData, encoding: .utf8) {
            self.refreshToken = refreshToken
        }
    }

    private func storeTokens() {
        if let accessToken = accessToken,
           let data = accessToken.data(using: .utf8) {
            KeychainHelper.shared.save(data, service: "com.mileagemaxpro.auth", account: "accessToken")
        }

        if let refreshToken = refreshToken,
           let data = refreshToken.data(using: .utf8) {
            KeychainHelper.shared.save(data, service: "com.mileagemaxpro.auth", account: "refreshToken")
        }
    }

    private func clearStoredTokens() {
        KeychainHelper.shared.delete(service: "com.mileagemaxpro.auth", account: "accessToken")
        KeychainHelper.shared.delete(service: "com.mileagemaxpro.auth", account: "refreshToken")
    }

    // MARK: - Request Methods

    /// Perform a request and decode the response (unwraps from API envelope)
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        let data = try await performRequest(endpoint)
        // Backend wraps all responses in { success: bool, data: T }
        let envelope: APIEnvelope<T> = try decode(data)
        return envelope.data
    }

    /// Perform a request and return raw data
    func requestData(_ endpoint: APIEndpoint) async throws -> Data {
        try await performRequest(endpoint)
    }

    /// Perform a request with no response body
    func requestVoid(_ endpoint: APIEndpoint) async throws {
        _ = try await performRequest(endpoint)
    }

    /// Perform a request and decode a paginated response
    func requestPaginated<T: Decodable>(_ endpoint: APIEndpoint) async throws -> PaginatedResponse<T> {
        let data = try await performRequest(endpoint)
        return try decode(data)
    }

    // MARK: - Core Request Handler

    private func performRequest(_ endpoint: APIEndpoint, retryCount: Int = 0) async throws -> Data {
        // Check authentication requirement
        if endpoint.requiresAuthentication && accessToken == nil {
            throw APIError.authenticationRequired
        }

        // Build request
        let request: URLRequest
        do {
            request = try endpoint.asURLRequest(baseURL: baseURL, accessToken: accessToken)
        } catch {
            throw APIError.encodingError(error.localizedDescription)
        }

        // Log request
        AppLogger.network.debug("Request: \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "")")

        // Perform request
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            let apiError = APIError.from(urlError: urlError)
            AppLogger.network.error("Request failed: \(apiError.localizedDescription)")
            throw apiError
        } catch {
            throw APIError.unknown(error.localizedDescription)
        }

        // Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        // Log response
        AppLogger.network.debug("Response: \(httpResponse.statusCode) - \(data.count) bytes")

        // Handle response status
        switch httpResponse.statusCode {
        case 200...299:
            return data

        case 401:
            // Try token refresh
            if endpoint.requiresAuthentication, refreshToken != nil {
                do {
                    try await refreshAccessToken()
                    // Retry original request
                    return try await performRequest(endpoint, retryCount: retryCount)
                } catch {
                    clearTokens()
                    throw APIError.refreshTokenExpired
                }
            }
            throw APIError.unauthorized

        case 429:
            // Rate limiting - check if we should retry
            if retryCount < maxRetries {
                let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After").flatMap { Int($0) } ?? Int(retryDelay)
                try await Task.sleep(nanoseconds: UInt64(retryAfter) * 1_000_000_000)
                return try await performRequest(endpoint, retryCount: retryCount + 1)
            }
            throw APIError.from(httpStatusCode: httpResponse.statusCode, body: data)

        case 500...599:
            // Server error - retry if possible
            if retryCount < maxRetries {
                try await Task.sleep(nanoseconds: UInt64(retryDelay * pow(2, Double(retryCount))) * 1_000_000_000)
                return try await performRequest(endpoint, retryCount: retryCount + 1)
            }
            throw APIError.from(httpStatusCode: httpResponse.statusCode, body: data)

        default:
            throw APIError.from(httpStatusCode: httpResponse.statusCode, body: data)
        }
    }

    // MARK: - Token Refresh

    private func refreshAccessToken() async throws {
        // Prevent multiple simultaneous refresh attempts
        if let existingTask = tokenRefreshTask {
            _ = try await existingTask.value
            return
        }

        guard let refreshToken = refreshToken else {
            throw APIError.refreshTokenExpired
        }

        tokenRefreshTask = Task {
            defer { tokenRefreshTask = nil }

            let endpoint = AuthEndpoints.refreshToken(refreshToken: refreshToken, deviceId: DeviceInfo.deviceId)
            let request = try endpoint.asURLRequest(baseURL: baseURL, accessToken: nil)

            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw APIError.refreshTokenExpired
            }

            let tokenResponse: TokenResponse = try decode(data)
            setTokens(accessToken: tokenResponse.accessToken, refreshToken: tokenResponse.refreshToken)

            return tokenResponse.accessToken
        }

        _ = try await tokenRefreshTask!.value
    }

    // MARK: - Decoding

    private func decode<T: Decodable>(_ data: Data) throws -> T {
        do {
            return try decoder.decode(T.self, from: data)
        } catch let decodingError as DecodingError {
            let message: String
            switch decodingError {
            case .keyNotFound(let key, _):
                message = "Missing key: \(key.stringValue)"
            case .typeMismatch(let type, let context):
                message = "Type mismatch for \(type) at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            case .valueNotFound(let type, let context):
                message = "Missing value for \(type) at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            case .dataCorrupted(let context):
                message = "Data corrupted: \(context.debugDescription)"
            @unknown default:
                message = decodingError.localizedDescription
            }
            AppLogger.network.error("Decoding error: \(message)")
            throw APIError.decodingError(message)
        }
    }

    // MARK: - File Upload

    func upload<T: Decodable>(
        _ endpoint: APIEndpoint,
        fileData: Data,
        filename: String,
        mimeType: String,
        fieldName: String = "file"
    ) async throws -> T {
        var request = try endpoint.asURLRequest(baseURL: baseURL, accessToken: accessToken)

        var formData = MultipartFormData()
        formData.append(name: fieldName, data: fileData, filename: filename, mimeType: mimeType)

        request.httpBody = formData.encode()
        request.setValue(formData.contentTypeHeader, forHTTPHeaderField: APIConstants.Headers.contentType)

        AppLogger.network.debug("Request: \(request.httpMethod ?? "POST") \(request.url?.absoluteString ?? "")")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        AppLogger.network.debug("Response: \(httpResponse.statusCode) - \(data.count) bytes")

        guard 200...299 ~= httpResponse.statusCode else {
            throw APIError.from(httpStatusCode: httpResponse.statusCode, body: data)
        }

        return try decode(data)
    }

    // MARK: - Download

    func download(_ url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.setValue(accessToken.map { "Bearer \($0)" }, forHTTPHeaderField: APIConstants.Headers.authorization)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw APIError.serverError((response as? HTTPURLResponse)?.statusCode ?? 500, nil)
        }

        return data
    }
}

// MARK: - Response Types

/// Backend wraps all responses in this envelope
struct APIEnvelope<T: Decodable>: Decodable {
    let success: Bool
    let data: T
}

struct TokenResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int
    let tokenType: String
}

struct PaginatedResponse<T: Decodable>: Decodable {
    let data: [T]
    let pagination: Pagination

    struct Pagination: Decodable {
        let page: Int
        let limit: Int
        let totalItems: Int
        let totalPages: Int
        let hasNextPage: Bool
        let hasPreviousPage: Bool
    }
}

struct EmptyResponse: Decodable {}

// MARK: - Keychain Helper

final class KeychainHelper {
    static let shared = KeychainHelper()

    private init() {}

    func save(_ data: Data, service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    func read(service: String, account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        guard status == errSecSuccess else { return nil }
        return dataTypeRef as? Data
    }

    func delete(service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        SecItemDelete(query as CFDictionary)
    }
}
