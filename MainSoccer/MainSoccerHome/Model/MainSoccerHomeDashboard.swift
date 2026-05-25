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
