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
    let homeTeamLogoURL: URL?
    let awayTeamName: String
    let awayTeamLogoURL: URL?
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
    let homeTeamLogoURL: URL?
    let awayTeamName: String
    let awayTeamLogoURL: URL?
    let homeScoreText: String
    let awayScoreText: String
    let statusText: String
    let statusStyle: MainSoccerFixtureStatusStyle
}

nonisolated enum MainSoccerFixtureStatusStyle: Equatable, Sendable {
    case live
    case final
    case upcoming
    case neutral
}

// MARK: - Empty State

nonisolated struct MainSoccerEmptyStateViewData: Equatable, Sendable {
    let message: String
}
