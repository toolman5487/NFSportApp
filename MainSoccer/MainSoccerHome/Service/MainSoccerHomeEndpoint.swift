//
//  MainSoccerHomeEndpoint.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/25.
//

import Foundation

// MARK: - MainSoccerHomeEndpoint

nonisolated enum MainSoccerHomeEndpoint: Equatable, Sendable {

    case liveFixtures(timezone: String)
    case fixtures(date: String, timezone: String)

    var path: String {
        switch self {
        case .liveFixtures, .fixtures:
            return "fixtures"
        }
    }

    var queryItems: [NetworkQueryItem] {
        switch self {
        case .liveFixtures(let timezone):
            return [
                NetworkQueryItem(name: "live", value: "all"),
                NetworkQueryItem(name: "timezone", value: timezone)
            ]

        case .fixtures(let date, let timezone):
            return [
                NetworkQueryItem(name: "date", value: date),
                NetworkQueryItem(name: "timezone", value: timezone)
            ]
        }
    }
}
