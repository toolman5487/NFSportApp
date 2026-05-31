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
            return APISportsProduct.soccer.matchAPI.path

        case .statistics:
            return APISportsAPIResource.fixtureStatistics.path

        case .events:
            return APISportsAPIResource.fixtureEvents.path

        case .lineups:
            return APISportsAPIResource.fixtureLineups.path
        }
    }

    var queryItems: [NetworkQueryItem] {
        switch self {
        case .fixture(let id):
            return [
                NetworkQueryItem(
                    name: APISportsProduct.soccer.matchAPI.detailIDQueryName,
                    value: "\(id)"
                )
            ]

        case .statistics(let fixtureID),
             .events(let fixtureID),
             .lineups(let fixtureID):
            return [
                NetworkQueryItem(
                    name: APISportsProduct.soccer.matchAPI.relatedDetailQueryName,
                    value: "\(fixtureID)"
                )
            ]
        }
    }
}
