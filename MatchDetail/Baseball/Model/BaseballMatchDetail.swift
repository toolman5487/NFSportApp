//
//  BaseballMatchDetail.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/28.
//

import Foundation

// MARK: - Match Detail

nonisolated struct BaseballMatchDetail: Equatable, Sendable {

    let fixture: BaseballMatchFixtureDetail
    let playersByTeam: [BaseballMatchTeamPlayers]
}

// MARK: - Fixture

nonisolated struct BaseballMatchFixtureDetail: Equatable, Sendable {

    let id: Int
    let leagueName: String
    let leagueLogoURL: URL?
    let venueName: String?
    let scheduledStartDate: Date?
    let scheduledStartText: String?
    let statusLong: String?
    let statusShort: String?
    let elapsedMinute: Int?
    let homeTeam: BaseballMatchTeam
    let awayTeam: BaseballMatchTeam
    let score: BaseballMatchScore
}

nonisolated struct BaseballMatchTeam: Equatable, Identifiable, Sendable {

    var id: String {
        "\(teamID ?? -1)-\(name)"
    }

    let teamID: Int?
    let name: String
    let logoURL: URL?
}

nonisolated struct BaseballMatchPeriodScore: Equatable, Sendable {

    let label: String
    let runs: Int?
}

nonisolated struct BaseballMatchTeamLineScore: Equatable, Sendable {

    let runs: Int?
    let hits: Int?
    let errors: Int?
    let innings: [BaseballMatchPeriodScore]
}

nonisolated struct BaseballMatchScore: Equatable, Sendable {

    let home: BaseballMatchTeamLineScore
    let away: BaseballMatchTeamLineScore
}

// MARK: - Players

nonisolated struct BaseballMatchTeamPlayers: Equatable, Sendable {

    let team: BaseballMatchTeam
    let players: [BaseballMatchPlayer]
}

nonisolated struct BaseballMatchPlayer: Equatable, Identifiable, Sendable {

    var id: String {
        "\(playerID ?? -1)-\(name)"
    }

    let playerID: Int?
    let name: String
    let photoURL: URL?
    let number: Int?
    let position: String?
    let statistics: [BaseballMatchPlayerStatistics]
}

// MARK: - Player Statistics

nonisolated struct BaseballMatchPlayerStatistics: Equatable, Sendable {

    let batting: BaseballMatchBattingStats
    let pitching: BaseballMatchPitchingStats
    let fielding: BaseballMatchFieldingStats
}

nonisolated struct BaseballMatchBattingStats: Equatable, Sendable {

    let atBats: Double?
    let hits: Double?
    let runs: Double?
    let homeRuns: Double?
    let runsBattedIn: Double?
    let walks: Double?
    let strikeouts: Double?
    let stolenBases: Double?
}

nonisolated struct BaseballMatchPitchingStats: Equatable, Sendable {

    let inningsPitched: Double?
    let hits: Double?
    let earnedRuns: Double?
    let walks: Double?
    let strikeouts: Double?
}

nonisolated struct BaseballMatchFieldingStats: Equatable, Sendable {

    let putouts: Double?
    let assists: Double?
    let errors: Double?
}

