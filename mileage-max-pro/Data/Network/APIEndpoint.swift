//
//  APIEndpoint.swift
//  MileageMaxPro
//
//  Enterprise iOS Mileage Tracking Application
//

import Foundation

/// Protocol defining an API endpoint
protocol APIEndpoint {
    /// HTTP method for the request
    var method: HTTPMethod { get }

    /// Path component of the URL (without base URL)
    var path: String { get }

    /// Query parameters
    var queryParameters: [String: String]? { get }

    /// Request body (for POST, PUT, PATCH)
    var body: Encodable? { get }

    /// Additional headers for this request
    var headers: [String: String]? { get }

    /// Whether this endpoint requires authentication
    var requiresAuthentication: Bool { get }

    /// Cache policy for this request
    var cachePolicy: CachePolicy { get }

    /// Timeout interval override
    var timeoutInterval: TimeInterval? { get }

    /// Content type for the request body
    var contentType: ContentType { get }
}

// MARK: - Default Implementations

extension APIEndpoint {
    var queryParameters: [String: String]? { nil }
    var body: Encodable? { nil }
    var headers: [String: String]? { nil }
    var requiresAuthentication: Bool { true }
    var cachePolicy: CachePolicy { .reloadIgnoringLocalCacheData }
    var timeoutInterval: TimeInterval? { nil }
    var contentType: ContentType { .json }
}

// MARK: - HTTP Method

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

// MARK: - Cache Policy

enum CachePolicy {
    case useProtocolCachePolicy
    case reloadIgnoringLocalCacheData
    case returnCacheDataElseLoad
    case returnCacheDataDontLoad

    var urlCachePolicy: URLRequest.CachePolicy {
        switch self {
        case .useProtocolCachePolicy:
            return .useProtocolCachePolicy
        case .reloadIgnoringLocalCacheData:
            return .reloadIgnoringLocalCacheData
        case .returnCacheDataElseLoad:
            return .returnCacheDataElseLoad
        case .returnCacheDataDontLoad:
            return .returnCacheDataDontLoad
        }
    }
}

// MARK: - Content Type

enum ContentType: String {
    case json = "application/json"
    case formUrlEncoded = "application/x-www-form-urlencoded"
    case multipartFormData = "multipart/form-data"
}

// MARK: - URL Request Builder

extension APIEndpoint {
    /// Builds a URLRequest from the endpoint
    func asURLRequest(baseURL: URL, accessToken: String?) throws -> URLRequest {
        // Construct URL with path
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: true)

        // Add query parameters
        if let queryParameters = queryParameters, !queryParameters.isEmpty {
            urlComponents?.queryItems = queryParameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        }

        guard let url = urlComponents?.url else {
            throw APIError.encodingError("Failed to construct URL")
        }

        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.cachePolicy = cachePolicy.urlCachePolicy

        // Set timeout
        if let timeout = timeoutInterval {
            request.timeoutInterval = timeout
        }

        // Set default headers
        request.setValue(contentType.rawValue, forHTTPHeaderField: APIConstants.Headers.contentType)
        request.setValue(APIConstants.HeaderValues.accept, forHTTPHeaderField: APIConstants.Headers.accept)
        request.setValue(APIConstants.HeaderValues.userAgent, forHTTPHeaderField: APIConstants.Headers.userAgent)
        request.setValue(APIConstants.HeaderValues.apiVersion, forHTTPHeaderField: APIConstants.Headers.apiVersion)
        request.setValue(Locale.current.identifier, forHTTPHeaderField: APIConstants.Headers.acceptLanguage)

        // Add authentication header
        if requiresAuthentication, let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: APIConstants.Headers.authorization)
        }

        // Add custom headers
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }

        // Encode body
        if let body = body {
            switch contentType {
            case .json:
                request.httpBody = try encodeJSON(body)
            case .formUrlEncoded:
                request.httpBody = try encodeFormURLEncoded(body)
            case .multipartFormData:
                // Multipart encoding is handled separately
                break
            }
        }

        return request
    }

    private func encodeJSON(_ encodable: Encodable) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        // Backend expects camelCase keys, NOT snake_case

        do {
            return try encoder.encode(AnyEncodable(encodable))
        } catch {
            throw APIError.encodingError("Failed to encode request body: \(error.localizedDescription)")
        }
    }

    private func encodeFormURLEncoded(_ encodable: Encodable) throws -> Data {
        guard let dictionary = try? JSONSerialization.jsonObject(with: JSONEncoder().encode(AnyEncodable(encodable))) as? [String: Any] else {
            throw APIError.encodingError("Failed to convert to dictionary")
        }

        let formString = dictionary
            .compactMapValues { $0 as? CustomStringConvertible }
            .map { "\($0.key)=\($0.value.description.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")

        guard let data = formString.data(using: .utf8) else {
            throw APIError.encodingError("Failed to encode form data")
        }

        return data
    }
}

// MARK: - Type Eraser for Encodable

struct AnyEncodable: Encodable {
    private let encode: (Encoder) throws -> Void

    init(_ encodable: Encodable) {
        encode = encodable.encode(to:)
    }

    func encode(to encoder: Encoder) throws {
        try encode(encoder)
    }
}

// MARK: - Pagination Parameters

struct PaginationParameters {
    let page: Int
    let limit: Int
    let sortBy: String?
    let sortOrder: SortOrder?

    init(page: Int = 1, limit: Int = 20, sortBy: String? = nil, sortOrder: SortOrder? = nil) {
        self.page = page
        self.limit = limit
        self.sortBy = sortBy
        self.sortOrder = sortOrder
    }

    var queryParameters: [String: String] {
        var params: [String: String] = [
            "page": "\(page)",
            "limit": "\(limit)"
        ]
        if let sortBy = sortBy {
            params["sort_by"] = sortBy
        }
        if let sortOrder = sortOrder {
            params["sort_order"] = sortOrder.rawValue
        }
        return params
    }
}

enum SortOrder: String {
    case ascending = "asc"
    case descending = "desc"
}

// MARK: - Filter Parameters

struct FilterParameters {
    var filters: [String: String] = [:]

    mutating func add(_ key: String, value: String?) {
        if let value = value {
            filters[key] = value
        }
    }

    mutating func add(_ key: String, value: Date?, format: String = "yyyy-MM-dd") {
        if let value = value {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            filters[key] = formatter.string(from: value)
        }
    }

    mutating func add<T: RawRepresentable>(_ key: String, value: T?) where T.RawValue == String {
        if let value = value {
            filters[key] = value.rawValue
        }
    }

    var queryParameters: [String: String] { filters }
}

// MARK: - Multipart Form Data

struct MultipartFormData {
    private(set) var boundary: String
    private var parts: [Part] = []

    struct Part {
        let name: String
        let data: Data
        let filename: String?
        let mimeType: String?
    }

    init(boundary: String = UUID().uuidString) {
        self.boundary = boundary
    }

    mutating func append(name: String, value: String) {
        if let data = value.data(using: .utf8) {
            parts.append(Part(name: name, data: data, filename: nil, mimeType: nil))
        }
    }

    mutating func append(name: String, data: Data, filename: String, mimeType: String) {
        parts.append(Part(name: name, data: data, filename: filename, mimeType: mimeType))
    }

    func encode() -> Data {
        var data = Data()

        for part in parts {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)

            if let filename = part.filename, let mimeType = part.mimeType {
                data.append("Content-Disposition: form-data; name=\"\(part.name)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
                data.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
            } else {
                data.append("Content-Disposition: form-data; name=\"\(part.name)\"\r\n\r\n".data(using: .utf8)!)
            }

            data.append(part.data)
            data.append("\r\n".data(using: .utf8)!)
        }

        data.append("--\(boundary)--\r\n".data(using: .utf8)!)

        return data
    }

    var contentTypeHeader: String {
        "multipart/form-data; boundary=\(boundary)"
    }
}
