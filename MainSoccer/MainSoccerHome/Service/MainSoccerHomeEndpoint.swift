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
    case currentLeagues
    case standings(leagueID: Int, season: Int)

    var path: String {
        switch self {
        case .liveFixtures, .fixtures:
            return "fixtures"

        case .currentLeagues:
            return "leagues"

        case .standings:
            return "standings"
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

        case .currentLeagues:
            return [
                NetworkQueryItem(name: "current", value: "true")
            ]

        case .standings(let leagueID, let season):
            return [
                NetworkQueryItem(name: "league", value: "\(leagueID)"),
                NetworkQueryItem(name: "season", value: "\(season)")
            ]
        }
    }
}
