//
//  MainSoccerHomeDashboard.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/25.
//

import Foundation

// MARK: - Dashboard

nonisolated struct MainSoccerHomeDashboard: Equatable, Sendable {

    let sport: SportType
    let date: Date
    let liveFixtures: [MainSoccerFixture]
    let todayFixtures: [MainSoccerFixture]
    let topLeagues: [MainSoccerLeague]
    let standingsTitle: String?
    let standings: [MainSoccerStandingRow]
}

// MARK: - Fixture

nonisolated struct MainSoccerFixture: Equatable, Identifiable, Sendable {

    let id: Int
    let leagueName: String
    let leagueLogoURL: URL?
    let scheduledStartDate: Date?
    let scheduledStartText: String?
    let statusLong: String?
    let statusShort: String?
    let elapsedMinute: Int?
    let homeTeamName: String
    let homeTeamLogoURL: URL?
    let awayTeamName: String
    let awayTeamLogoURL: URL?
    let homeScore: Int?
    let awayScore: Int?
}

// MARK: - League

nonisolated struct MainSoccerLeague: Equatable, Identifiable, Sendable {

    let id: Int
    let name: String
    let countryName: String?
    let logoURL: URL?
    let currentSeason: Int?
    let supportsStandings: Bool
}

// MARK: - Standing

nonisolated struct MainSoccerStandingRow: Equatable, Identifiable, Sendable {

    var id: String {
        "\(rank)-\(teamName)"
    }

    let rank: Int
    let teamName: String
    let teamLogoURL: URL?
    let points: Int
    let played: Int?
    let wins: Int?
    let draws: Int?
    let losses: Int?
    let goalsDifference: Int?
}
