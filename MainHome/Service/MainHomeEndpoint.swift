//
//  MainHomeEndpoint.swift
//  NFSportApp
//
//  Created by Willy Hsu 2026/5/23.
//

import Foundation

nonisolated enum MainHomeEndpoint: Sendable, Equatable {

    case games(date: String)
    case liveGames
    case gameDetail(id: Int)
    case standings(leagueID: Int, season: Int)

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
        case .games(let date):
            return [
                NetworkQueryItem(name: "date", value: date)
            ]

        case .liveGames:
            return [
                NetworkQueryItem(name: "live", value: "all")
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

