//
//  SoccerMatchDetailEndpoint.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/26.
//

import Foundation

// MARK: - SoccerMatchDetailEndpoint

nonisolated enum SoccerMatchDetailEndpoint: Equatable, Sendable {

    case fixture(id: Int)
    case statistics(fixtureID: Int)
    case events(fixtureID: Int)
    case lineups(fixtureID: Int)

    var path: String {
        switch self {
        case .fixture:
            return "fixtures"

        case .statistics:
            return "fixtures/statistics"

        case .events:
            return "fixtures/events"

        case .lineups:
            return "fixtures/lineups"
        }
    }

    var queryItems: [NetworkQueryItem] {
        switch self {
        case .fixture(let id):
            return [
                NetworkQueryItem(name: "id", value: "\(id)")
            ]

        case .statistics(let fixtureID),
             .events(let fixtureID),
             .lineups(let fixtureID):
            return [
                NetworkQueryItem(name: "fixture", value: "\(fixtureID)")
            ]
        }
    }
}
