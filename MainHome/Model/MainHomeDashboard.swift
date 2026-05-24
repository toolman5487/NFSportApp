//
//  MainHomeDashboard.swift
//  NFSportApp
//
//  Created by Willy Hsu 2026/5/23.
//

import Foundation

// MARK: - Dashboard

nonisolated struct MainHomeDashboard: Equatable, Sendable {

    let sport: SportType
    let liveGames: [MainHomeGame]
    let todayGames: [MainHomeGame]
}

// MARK: - Game

nonisolated struct MainHomeGame: Equatable, Identifiable, Sendable {

    let id: Int
    let leagueName: String
    let leagueLogoURL: URL?
    let homeTeamName: String
    let awayTeamName: String
    let scheduledStartText: String?
    let statusDescription: String?
    let homeScore: String?
    let awayScore: String?
}
