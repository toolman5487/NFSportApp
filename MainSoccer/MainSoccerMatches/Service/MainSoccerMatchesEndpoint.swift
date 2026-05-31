//
//  MainSoccerMatchesEndpoint.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/25.
//

import Foundation

// MARK: - MainSoccerMatchesEndpoint

nonisolated enum MainSoccerMatchesEndpoint: Equatable, Sendable {

    case fixtures(date: String, timezone: String)

    var path: String {
        switch self {
        case .fixtures:
            return APISportsProduct.soccer.matchAPI.path
        }
    }

    var queryItems: [NetworkQueryItem] {
        switch self {
        case .fixtures(let date, let timezone):
            return [
                NetworkQueryItem(name: "date", value: date),
                NetworkQueryItem(name: "timezone", value: timezone)
            ]
        }
    }
}
