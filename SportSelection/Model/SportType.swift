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
    let apiBaseURL: APISportsBaseURL
}

// MARK: - API

extension SportType {

    nonisolated var apiURL: URL? {
        apiBaseURL.url
    }
}

// MARK: - Local Catalog

extension SportType {

    nonisolated static let localCatalog: [SportType] = [
        SportType(
            id: "football",
            title: "Football",
            subtitle: "Games, schedules, and standings",
            systemImageName: "football.fill",
            apiBaseURL: .americanFootball
        ),
        SportType(
            id: "soccer",
            title: "Soccer",
            subtitle: "Fixtures, scores, and leagues",
            systemImageName: "soccerball.inverse",
            apiBaseURL: .soccer
        ),
        SportType(
            id: "basketball",
            title: "Basketball",
            subtitle: "Games, schedules, and standings",
            systemImageName: "basketball.fill",
            apiBaseURL: .basketball
        ),
        SportType(
            id: "baseball",
            title: "Baseball",
            subtitle: "Games, schedules, and standings",
            systemImageName: "baseball.fill",
            apiBaseURL: .baseball
        ),
        SportType(
            id: "hockey",
            title: "Hockey",
            subtitle: "Games, schedules, and standings",
            systemImageName: "hockey.puck.fill",
            apiBaseURL: .hockey
        ),
        SportType(
            id: "volleyball",
            title: "Volleyball",
            subtitle: "Games, schedules, and standings",
            systemImageName: "volleyball.fill",
            apiBaseURL: .volleyball
        ),
        SportType(
            id: "handball",
            title: "Handball",
            subtitle: "Games, schedules, and standings",
            systemImageName: "figure.handball",
            apiBaseURL: .handball
        ),
        SportType(
            id: "rugby",
            title: "Rugby",
            subtitle: "Games, schedules, and standings",
            systemImageName: "rugbyball.fill",
            apiBaseURL: .rugby
        )
    ]
}
