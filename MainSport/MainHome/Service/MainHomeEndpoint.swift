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
        switch self {
        case .games, .liveGames, .gameDetail:
            return "games"

        case .standings:
            return "standings"
        }
    }

    var queryItems: [NetworkQueryItem] {
        switch self {
        case .games(let date, let timezone):
            return [
                NetworkQueryItem(name: "date", value: date),
                NetworkQueryItem(name: "timezone", value: timezone)
            ]

        case .liveGames(let timezone):
            return [
                NetworkQueryItem(name: "live", value: "all"),
                NetworkQueryItem(name: "timezone", value: timezone)
            ]

        case .gameDetail(let id):
            return [
                NetworkQueryItem(name: "id", value: "\(id)")
            ]

        case .standings(let leagueID, let season):
            return [
                NetworkQueryItem(name: "league", value: "\(leagueID)"),
                NetworkQueryItem(name: "season", value: "\(season)")
            ]
        }
    }
}
