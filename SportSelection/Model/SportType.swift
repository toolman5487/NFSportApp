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
            id: "football",
            title: "Football",
            subtitle: "Games, schedules, and standings",
            systemImageName: "football",
            apiHost: "v1.american-football.api-sports.io"
        ),
        SportType(
            id: "basketball",
            title: "Basketball",
            subtitle: "Games, schedules, and standings",
            systemImageName: "basketball",
            apiHost: "v1.basketball.api-sports.io"
        ),
        SportType(
            id: "baseball",
            title: "Baseball",
            subtitle: "Games, schedules, and standings",
            systemImageName: "baseball",
            apiHost: "v1.baseball.api-sports.io"
        ),
        SportType(
            id: "hockey",
            title: "Hockey",
            subtitle: "Games, schedules, and standings",
            systemImageName: "hockey.puck",
            apiHost: "v1.hockey.api-sports.io"
        ),
        SportType(
            id: "volleyball",
            title: "Volleyball",
            subtitle: "Games, schedules, and standings",
            systemImageName: "figure.volleyball",
            apiHost: "v1.volleyball.api-sports.io"
        ),
        SportType(
            id: "handball",
            title: "Handball",
            subtitle: "Games, schedules, and standings",
            systemImageName: "figure.handball",
            apiHost: "v1.handball.api-sports.io"
        ),
        SportType(
            id: "rugby",
            title: "Rugby",
            subtitle: "Games, schedules, and standings",
            systemImageName: "figure.rugby",
            apiHost: "v1.rugby.api-sports.io"
        )
    ]
}
