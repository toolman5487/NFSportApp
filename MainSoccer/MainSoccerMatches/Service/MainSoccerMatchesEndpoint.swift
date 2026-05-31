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
        apiEndpoint.path
    }

    var queryItems: [NetworkQueryItem] {
        apiEndpoint.queryItems
    }

    private var apiEndpoint: APISportsEndpoint {
        switch self {
        case .fixtures(let date, let timezone):
            return APISportsEndpoint(
                matchAPI: APISportsProduct.soccer.matchAPI,
                queryItems: [
                    NetworkQueryItem(parameter: .date, value: date),
                    NetworkQueryItem(parameter: .timezone, value: timezone)
                ]
            )
        }
    }
}
