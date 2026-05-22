//
//  NetworkClient.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/22.
//

import Foundation

nonisolated struct NetworkConfiguration: Sendable {
    let baseURL: URL
    let defaultHeaders: [String: String]
    let timeoutInterval: TimeInterval

    init(
        baseURL: URL,
        defaultHeaders: [String: String] = [:],
        timeoutInterval: TimeInterval = 30
    ) {
        self.baseURL = baseURL
        self.defaultHeaders = defaultHeaders
        self.timeoutInterval = timeoutInterval
    }
}

nonisolated struct EmptyResponse: Decodable, Sendable {}

nonisolated protocol NetworkServicing: Sendable {
    func send(_ request: NetworkRequest) async throws -> Data
    func send<Response: Decodable & Sendable>(_ request: NetworkRequest, as type: Response.Type) async throws -> Response
    func get<Response: Decodable & Sendable>(
        _ path: String,
        queryItems: [NetworkQueryItem],
        headers: [String: String],
        as type: Response.Type
    ) async throws -> Response
    func post<Body: Encodable & Sendable, Response: Decodable & Sendable>(
        _ path: String,
        body: Body,
        queryItems: [NetworkQueryItem],
        headers: [String: String],
        as type: Response.Type
    ) async throws -> Response
    func put<Body: Encodable & Sendable, Response: Decodable & Sendable>(
        _ path: String,
        body: Body,
        queryItems: [NetworkQueryItem],
        headers: [String: String],
        as type: Response.Type
    ) async throws -> Response
    func patch<Body: Encodable & Sendable, Response: Decodable & Sendable>(
        _ path: String,
        body: Body,
        queryItems: [NetworkQueryItem],
        headers: [String: String],
        as type: Response.Type
    ) async throws -> Response
    func delete<Response: Decodable & Sendable>(
        _ path: String,
        queryItems: [NetworkQueryItem],
        headers: [String: String],
        as type: Response.Type
    ) async throws -> Response
}

actor NetworkClient: NetworkServicing {

    // MARK: - Properties

    private let configuration: NetworkConfiguration
    private let session: URLSession

    // MARK: - Initialization

    init(
        configuration: NetworkConfiguration,
        session: URLSession = .shared
    ) {
        self.configuration = configuration
        self.session = session
    }

    // MARK: - Request

    func send(_ request: NetworkRequest) async throws -> Data {
        let urlRequest = try makeURLRequest(from: request)

        do {
            let (data, response) = try await session.data(for: urlRequest)
            try validate(response)
            return data
        } catch let error as NetworkError {
            AppLogger.shared.error(
                error,
                context: LogErrorContext("Network request failed"),
                metadata: request.logMetadata
            )
            throw error
        } catch {
            let networkError = NetworkError.requestFailed(error.localizedDescription)
            AppLogger.shared.error(
                networkError,
                context: LogErrorContext("Network request failed"),
                metadata: request.logMetadata
            )
            throw networkError
        }
    }

    func send<Response: Decodable & Sendable>(
        _ request: NetworkRequest,
        as type: Response.Type
    ) async throws -> Response {
        let data = try await send(request)

        if data.isEmpty, let emptyResponse = EmptyResponse() as? Response {
            return emptyResponse
        }

        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            let networkError = NetworkError.decodingFailed(error.localizedDescription)
            AppLogger.shared.error(
                networkError,
                context: LogErrorContext("Network response decoding failed"),
                metadata: request.logMetadata
            )
            throw networkError
        }
    }

    func get<Response: Decodable & Sendable>(
        _ path: String,
        queryItems: [NetworkQueryItem] = [],
        headers: [String: String] = [:],
        as type: Response.Type
    ) async throws -> Response {
        let request = NetworkRequest(
            path: path,
            method: .get,
            queryItems: queryItems,
            headers: headers
        )

        return try await send(request, as: type)
    }

    func post<Body: Encodable & Sendable, Response: Decodable & Sendable>(
        _ path: String,
        body: Body,
        queryItems: [NetworkQueryItem] = [],
        headers: [String: String] = [:],
        as type: Response.Type
    ) async throws -> Response {
        try await sendJSONRequest(
            path,
            method: .post,
            body: body,
            queryItems: queryItems,
            headers: headers,
            as: type
        )
    }

    func put<Body: Encodable & Sendable, Response: Decodable & Sendable>(
        _ path: String,
        body: Body,
        queryItems: [NetworkQueryItem] = [],
        headers: [String: String] = [:],
        as type: Response.Type
    ) async throws -> Response {
        try await sendJSONRequest(
            path,
            method: .put,
            body: body,
            queryItems: queryItems,
            headers: headers,
            as: type
        )
    }

    func patch<Body: Encodable & Sendable, Response: Decodable & Sendable>(
        _ path: String,
        body: Body,
        queryItems: [NetworkQueryItem] = [],
        headers: [String: String] = [:],
        as type: Response.Type
    ) async throws -> Response {
        try await sendJSONRequest(
            path,
            method: .patch,
            body: body,
            queryItems: queryItems,
            headers: headers,
            as: type
        )
    }

    func delete<Response: Decodable & Sendable>(
        _ path: String,
        queryItems: [NetworkQueryItem] = [],
        headers: [String: String] = [:],
        as type: Response.Type
    ) async throws -> Response {
        let request = NetworkRequest(
            path: path,
            method: .delete,
            queryItems: queryItems,
            headers: headers
        )

        return try await send(request, as: type)
    }

    // MARK: - Private Methods

    private func sendJSONRequest<Body: Encodable & Sendable, Response: Decodable & Sendable>(
        _ path: String,
        method: HTTPMethod,
        body: Body,
        queryItems: [NetworkQueryItem],
        headers: [String: String],
        as type: Response.Type
    ) async throws -> Response {
        let encodedBody: Data

        do {
            encodedBody = try JSONEncoder().encode(body)
        } catch {
            throw NetworkError.encodingFailed(error.localizedDescription)
        }

        let request = NetworkRequest(
            path: path,
            method: method,
            queryItems: queryItems,
            headers: headers,
            body: encodedBody,
            contentType: "application/json"
        )

        return try await send(request, as: type)
    }

    private func makeURLRequest(from request: NetworkRequest) throws -> URLRequest {
        guard var components = makeURLComponents(for: request) else {
            throw NetworkError.invalidURL
        }

        components.queryItems = request.queryItems.isEmpty
            ? nil
            : request.queryItems.map(\.urlQueryItem)

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.timeoutInterval = request.timeoutInterval ?? configuration.timeoutInterval
        urlRequest.httpBody = request.body

        let headers = configuration.defaultHeaders.merging(request.headers) { _, requestHeader in
            requestHeader
        }

        headers.forEach { key, value in
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        if let contentType = request.contentType {
            urlRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }

        return urlRequest
    }

    private func makeURLComponents(for request: NetworkRequest) -> URLComponents? {
        let trimmedPath = request.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let url = trimmedPath.isEmpty
            ? configuration.baseURL
            : configuration.baseURL.appendingPathComponent(trimmedPath)

        return URLComponents(url: url, resolvingAgainstBaseURL: false)
    }

    private func validate(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        switch HTTPStatusCategory(statusCode: httpResponse.statusCode) {
        case .success:
            return
        case .informational, .redirection, .clientError, .serverError, .unexpected:
            throw NetworkError.unacceptableStatusCode(httpResponse.statusCode)
        }
    }
}

private nonisolated enum HTTPStatusCategory {
    case informational
    case success
    case redirection
    case clientError
    case serverError
    case unexpected

    init(statusCode: Int) {
        switch statusCode {
        case 100...199:
            self = .informational
        case 200...299:
            self = .success
        case 300...399:
            self = .redirection
        case 400...499:
            self = .clientError
        case 500...599:
            self = .serverError
        default:
            self = .unexpected
        }
    }
}

private nonisolated extension NetworkRequest {

    var logMetadata: [String: String] {
        [
            "method": method.rawValue,
            "path": path
        ]
    }
}
