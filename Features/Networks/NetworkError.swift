//
//  NetworkError.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/22.
//

import Foundation

nonisolated enum NetworkError: Error, Equatable, LocalizedError, Sendable {
    case invalidBaseURL
    case invalidURL
    case invalidResponse
    case rateLimited(retryAfterSeconds: Int?)
    case unacceptableStatusCode(Int)
    case encodingFailed(String)
    case decodingFailed(String)
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidBaseURL:
            return "Base URL is invalid."
        case .invalidURL:
            return "Request URL is invalid."
        case .invalidResponse:
            return "Server response is invalid."
        case .rateLimited(let retryAfterSeconds):
            if let retryAfterSeconds {
                return "API rate limit reached. Try again in \(retryAfterSeconds) seconds."
            }

            return "API rate limit reached. Please try again later."
        case .unacceptableStatusCode(let statusCode):
            return "Server returned status code \(statusCode)."
        case .encodingFailed(let message):
            return "Request encoding failed: \(message)"
        case .decodingFailed(let message):
            return "Response decoding failed: \(message)"
        case .requestFailed(let message):
            return "Request failed: \(message)"
        }
    }

    var isRateLimited: Bool {
        guard case .rateLimited = self else {
            return false
        }

        return true
    }
}
