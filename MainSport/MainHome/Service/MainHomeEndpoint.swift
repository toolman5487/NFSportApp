//
//  MainHomeEndpoint.swift
//  NFSportApp
//
//  Created by Willy Hsu 2026/5/23.
//

import Foundation

// MARK: - MainHomeEndpoint

nonisolated enum MainHomeEndpoint: Sendable, Equatable {

    case games(date: String, timezone: String)
    case liveGames(timezone: String)
    case gameDetail(id: Int)
    case standings(leagueID: Int, season: Int)

    // MARK: - Properties

    var path: String {
        apiEndpoint.path
    }

    var queryItems: [NetworkQueryItem] {
        apiEndpoint.queryItems
    }

    private var apiEndpoint: APISportsEndpoint {
        switch self {
        case .games(let date, let timezone):
            return APISportsEndpoint(
                matchAPI: .games,
                queryItems: [
                    NetworkQueryItem(parameter: .date, value: date),
                    NetworkQueryItem(parameter: .timezone, value: timezone)
                ]
            )

        case .liveGames(let timezone):
            return APISportsEndpoint(
                matchAPI: .games,
                queryItems: [
                    NetworkQueryItem(parameter: .live, value: "all"),
                    NetworkQueryItem(parameter: .timezone, value: timezone)
                ]
            )

        case .gameDetail(let id):
            return APISportsEndpoint(
                matchAPI: .games,
                queryItems: [
                    NetworkQueryItem(
                        parameter: APISportsMatchAPI.games.detailIDQueryParameter,
                        value: "\(id)"
                    )
                ]
            )

        case .standings(let leagueID, let season):
            return APISportsEndpoint(
                resource: .standings,
                queryItems: [
                    NetworkQueryItem(parameter: .league, value: "\(leagueID)"),
                    NetworkQueryItem(parameter: .season, value: "\(season)")
                ]
            )
        }
    }
}
