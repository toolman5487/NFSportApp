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
    let scheduledStartDate: Date?
    let scheduledStartText: String
    let statusDescription: String?
    let homeTeamName: String
    let awayTeamName: String
    let homeScore: String?
    let awayScore: String?
}
