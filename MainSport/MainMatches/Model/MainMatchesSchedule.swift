//
//  MainMatchesSchedule.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/25.
//

import Foundation

// MARK: - Schedule

nonisolated struct MainMatchesSchedule: Equatable, Sendable {

    let sport: SportType
    let date: Date
    let games: [MainMatchesGame]
}

// MARK: - Game

nonisolated struct MainMatchesGame: Equatable, Identifiable, Sendable {

    let id: Int
    let leagueName: String
    let leagueLogoURL: URL?
    let scheduledStartDate: Date?
    let scheduledStartText: String
    let statusDescription: String?
    let homeTeamName: String
    let homeTeamLogoURL: URL?
    let awayTeamName: String
    let awayTeamLogoURL: URL?
    let homeScore: String?
    let awayScore: String?
}
