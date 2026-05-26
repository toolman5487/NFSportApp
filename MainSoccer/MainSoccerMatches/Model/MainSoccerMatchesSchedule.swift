//
//  MainSoccerMatchesSchedule.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/26.
//

import Foundation

// MARK: - Schedule

nonisolated struct MainSoccerMatchesSchedule: Equatable, Sendable {

    let sport: SportType
    let date: Date
    let games: [MainSoccerMatchesGame]
}

// MARK: - Game

nonisolated struct MainSoccerMatchesGame: Equatable, Identifiable, Sendable {

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
