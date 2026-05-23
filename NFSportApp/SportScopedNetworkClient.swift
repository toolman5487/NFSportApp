//
//  SportScopedNetworkClient.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/23.
//

import Foundation

actor SportScopedNetworkClient: NetworkServicing {

    // MARK: - Dependencies

    private let sportSessionStore: SportSessionStoring
    private let defaultHeadersProvider: @Sendable () throws -> [String: String]
    private let timeoutInterval: TimeInterval
    private let session: URLSession

    // MARK: - Initialization

    init(
        sportSessionStore: SportSessionStoring,
        defaultHeadersProvider: @escaping @Sendable () throws -> [String: String] = { [:] },
        timeoutInterval: TimeInterval = 30,
        session: URLSession = .shared
    ) {
        self.sportSessionStore = sportSessionStore
        self.defaultHeadersProvider = defaultHeadersProvider
        self.timeoutInterval = timeoutInterval
        self.session = session
    }

    // MARK: - Request

    func send(_ request: NetworkRequest) async throws -> Data {
        let networkClient = try await makeNetworkClient()
        return try await networkClient.send(request)
    }

    func send<Response: Decodable & Sendable>(
        _ request: NetworkRequest,
        as type: Response.Type
    ) async throws -> Response {
        let networkClient = try await makeNetworkClient()
        return try await networkClient.send(request, as: type)
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

    private func makeNetworkClient() async throws -> NetworkClient {
        let baseURL = try await sportSessionStore.selectedBaseURL()
        let defaultHeaders = try defaultHeadersProvider()
        let configuration = NetworkConfiguration(
            baseURL: baseURL,
            defaultHeaders: defaultHeaders,
            timeoutInterval: timeoutInterval
        )

        return NetworkClient(configuration: configuration, session: session)
    }
}
