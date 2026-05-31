//
//  APISportsMediaEndpoint.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/31.
//

import Foundation

// MARK: - APISportsMediaSport

nonisolated enum APISportsMediaSport: String, Codable, Equatable, Hashable, Sendable {

    case americanFootball = "american-football"
    case soccer = "football"
    case basketball
    case baseball
    case hockey
    case volleyball
    case handball
    case rugby

    var pathComponent: String {
        rawValue
    }
}

// MARK: - APISportsMediaEndpoint

nonisolated enum APISportsMediaEndpoint: Equatable, Sendable {

    case player(sport: APISportsMediaSport, id: Int)
    case footballPlayer(id: Int)

    var url: URL? {
        guard let baseURL = APISportsBaseURL.media.url else {
            return nil
        }

        switch self {
        case .player(let sport, let id):
            return makeImageURL(
                baseURL: baseURL,
                sport: sport,
                collection: "players",
                id: id
            )

        case .footballPlayer(let id):
            return APISportsMediaEndpoint
                .player(sport: .soccer, id: id)
                .url
        }
    }

    private func makeImageURL(
        baseURL: URL,
        sport: APISportsMediaSport,
        collection: String,
        id: Int
    ) -> URL {
        baseURL
            .appending(path: sport.pathComponent)
            .appending(path: collection)
            .appending(path: "\(id).png")
    }
}
