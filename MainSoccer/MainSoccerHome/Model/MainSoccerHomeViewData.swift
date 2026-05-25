//
//  MainSoccerHomeViewData.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/25.
//

import Foundation

// MARK: - Live Matches

nonisolated struct MainSoccerLiveMatchesViewData: Equatable, Sendable {

    nonisolated enum State: Equatable, Sendable {
        case empty(message: String)
        case loaded([MainSoccerLiveMatchViewData])
    }

    let title: String
    let state: State
}

nonisolated struct MainSoccerLiveMatchViewData: Equatable, Sendable {
    let minuteText: String
    let leagueName: String
    let homeTeamName: String
    let awayTeamName: String
    let scoreText: String
}

// MARK: - Today Fixtures

nonisolated struct MainSoccerTodayFixturesViewData: Equatable, Sendable {

    nonisolated enum State: Equatable, Sendable {
        case empty(message: String)
        case loaded([MainSoccerFixtureViewData])
    }

    let title: String
    let state: State
}

nonisolated struct MainSoccerFixtureViewData: Equatable, Sendable {
    let timeText: String
    let leagueName: String
    let homeTeamName: String
    let awayTeamName: String
}

// MARK: - Top Leagues

nonisolated struct MainSoccerTopLeaguesViewData: Equatable, Sendable {
    let title: String
    let leagues: [MainSoccerTopLeagueViewData]
}

nonisolated struct MainSoccerTopLeagueViewData: Equatable, Sendable {
    let name: String
    let region: String
    let logoURL: URL?
    let systemImageName: String
}

// MARK: - Standings

nonisolated struct MainSoccerStandingsViewData: Equatable, Sendable {

    nonisolated enum State: Equatable, Sendable {
        case empty(message: String)
        case loaded([MainSoccerStandingRowViewData])
    }

    let title: String
    let state: State
}

nonisolated struct MainSoccerStandingRowViewData: Equatable, Sendable {
    let rankText: String
    let teamName: String
    let recordText: String
    let pointsText: String
}

// MARK: - Empty State

nonisolated struct MainSoccerEmptyStateViewData: Equatable, Sendable {
    let message: String
}
