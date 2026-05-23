//
//  SportType.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/23.
//

import Foundation

nonisolated struct SportType: Codable, Equatable, Hashable, Sendable {

    let id: String
    let title: String
    let subtitle: String
    let systemImageName: String
    let apiHost: String
}

// MARK: - API

extension SportType {

    nonisolated var apiBaseURL: URL? {
        URL(string: "https://\(apiHost)")
    }
}

// MARK: - Local Catalog

extension SportType {

    nonisolated static let localCatalog: [SportType] = [
        SportType(
            id: "nfl",
            title: "NFL",
            subtitle: "NFL teams, games, standings, injuries",
            systemImageName: "football",
            apiHost: "v1.american-football.api-sports.io"
        ),
        SportType(
            id: "nba",
            title: "NBA",
            subtitle: "NBA teams, games, standings",
            systemImageName: "basketball",
            apiHost: "v2.nba.api-sports.io"
        ),
        SportType(
            id: "baseball",
            title: "MLB",
            subtitle: "MLB teams, games, standings",
            systemImageName: "baseball",
            apiHost: "v1.baseball.api-sports.io"
        ),
        SportType(
            id: "hockey",
            title: "NHL",
            subtitle: "NHL teams, games, standings",
            systemImageName: "hockey.puck",
            apiHost: "v1.hockey.api-sports.io"
        )
    ]
}
