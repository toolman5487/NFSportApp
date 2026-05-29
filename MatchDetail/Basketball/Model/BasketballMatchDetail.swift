//
//  BasketballMatchDetail.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/27.
//

import Foundation

// MARK: - Match Detail

nonisolated struct BasketballMatchDetail: Equatable, Sendable {

    let fixture: BasketballMatchFixtureDetail
    let playersByTeam: [BasketballMatchTeamPlayers]
}

// MARK: - Fixture

nonisolated struct BasketballMatchFixtureDetail: Equatable, Sendable {

    let id: Int
    let leagueName: String
    let leagueLogoURL: URL?
    let venueName: String?
    let scheduledStartDate: Date?
    let scheduledStartText: String?
    let statusLong: String?
    let statusShort: String?
    let elapsedMinute: Int?
    let homeTeam: BasketballMatchTeam
    let awayTeam: BasketballMatchTeam
    let score: BasketballMatchScore
}

nonisolated struct BasketballMatchTeam: Equatable, Identifiable, Sendable {

    var id: String {
        "\(teamID ?? -1)-\(name)"
    }

    let teamID: Int?
    let name: String
    let logoURL: URL?
}

nonisolated struct BasketballMatchPeriodScore: Equatable, Sendable {

    let label: String
    let points: Int?
}

nonisolated struct BasketballMatchTeamScore: Equatable, Sendable {

    let total: Int?
    let periods: [BasketballMatchPeriodScore]
}

nonisolated struct BasketballMatchScore: Equatable, Sendable {

    let home: BasketballMatchTeamScore
    let away: BasketballMatchTeamScore
}

// MARK: - Players

nonisolated struct BasketballMatchTeamPlayers: Equatable, Sendable {

    let team: BasketballMatchTeam
    let players: [BasketballMatchPlayer]
}

nonisolated struct BasketballMatchPlayer: Equatable, Identifiable, Sendable {

    var id: String {
        "\(playerID ?? -1)-\(name)"
    }

    let playerID: Int?
    let name: String
    let photoURL: URL?
    let number: Int?
    let position: String?
    let statistics: [BasketballMatchPlayerStatistics]
}

// MARK: - Player Statistics

nonisolated struct BasketballMatchPlayerStatistics: Equatable, Sendable {

    let points: Double?
    let fieldGoalsMade: Double?
    let fieldGoalsAttempted: Double?
    let threePointsMade: Double?
    let threePointsAttempted: Double?
    let freeThrowsMade: Double?
    let freeThrowsAttempted: Double?
    let rebounds: Double?
    let assists: Double?
    let steals: Double?
    let blocks: Double?
    let turnovers: Double?
}
