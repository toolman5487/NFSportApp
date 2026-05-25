//
//  MainSoccerHomeSection.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/25.
//

import Foundation

// MARK: - MainSoccerHomeSection

nonisolated enum MainSoccerHomeSection: Equatable, Sendable {
    case liveMatches(MainSoccerLiveMatchesViewData)
    case today(MainSoccerTodayFixturesViewData)
    case topLeagues(MainSoccerTopLeaguesViewData)
    case standings(MainSoccerStandingsViewData)
}

// MARK: - Content

extension MainSoccerHomeSection {

    var title: String? {
        switch self {
        case .liveMatches:
            return nil

        case .today(let viewData):
            return viewData.title

        case .topLeagues(let viewData):
            return viewData.title

        case .standings(let viewData):
            return viewData.title
        }
    }

    var items: [MainSoccerHomeItem] {
        switch self {
        case .liveMatches(let viewData):
            return liveMatchItems(from: viewData)

        case .today(let viewData):
            return fixtureItems(from: viewData)

        case .topLeagues(let viewData):
            return leagueItems(from: viewData)

        case .standings(let viewData):
            return standingItems(from: viewData)
        }
    }

    private func liveMatchItems(from viewData: MainSoccerLiveMatchesViewData) -> [MainSoccerHomeItem] {
        switch viewData.state {
        case .empty:
            return [.liveHero(viewData)]

        case .loaded(let matches):
            return [.liveHero(viewData)] + matches.map(MainSoccerHomeItem.liveMatch)
        }
    }

    private func fixtureItems(from viewData: MainSoccerTodayFixturesViewData) -> [MainSoccerHomeItem] {
        switch viewData.state {
        case .empty(let message):
            return [.empty(MainSoccerEmptyStateViewData(message: message))]

        case .loaded(let fixtures):
            return fixtures.map(MainSoccerHomeItem.fixture)
        }
    }

    private func leagueItems(from viewData: MainSoccerTopLeaguesViewData) -> [MainSoccerHomeItem] {
        guard !viewData.leagues.isEmpty else {
            return [.empty(MainSoccerEmptyStateViewData(message: "No top leagues"))]
        }

        return viewData.leagues.map(MainSoccerHomeItem.league)
    }

    private func standingItems(from viewData: MainSoccerStandingsViewData) -> [MainSoccerHomeItem] {
        switch viewData.state {
        case .empty(let message):
            return [.empty(MainSoccerEmptyStateViewData(message: message))]

        case .loaded(let standings):
            return standings.map(MainSoccerHomeItem.standing)
        }
    }
}

// MARK: - Item

nonisolated enum MainSoccerHomeItem: Equatable, Sendable {
    case liveHero(MainSoccerLiveMatchesViewData)
    case liveMatch(MainSoccerLiveMatchViewData)
    case empty(MainSoccerEmptyStateViewData)
    case fixture(MainSoccerFixtureViewData)
    case league(MainSoccerTopLeagueViewData)
    case standing(MainSoccerStandingRowViewData)
}

// MARK: - Default Sections

extension MainSoccerHomeSection {

    static let defaultSections: [MainSoccerHomeSection] = [
        .liveMatches(
            MainSoccerLiveMatchesViewData(
                title: "Live Matches",
                badgeText: "0 Live",
                state: .empty(message: "No live matches")
            )
        ),
        .today(
            MainSoccerTodayFixturesViewData(
                title: "Today",
                state: .empty(message: "No fixtures today")
            )
        ),
        .topLeagues(
            MainSoccerTopLeaguesViewData(
                title: "Top Leagues",
                leagues: [
                    MainSoccerTopLeagueViewData(
                        name: "Premier League",
                        region: "England",
                        logoURL: nil,
                        systemImageName: "trophy.fill"
                    ),
                    MainSoccerTopLeagueViewData(
                        name: "La Liga",
                        region: "Spain",
                        logoURL: nil,
                        systemImageName: "star.circle.fill"
                    ),
                    MainSoccerTopLeagueViewData(
                        name: "Champions League",
                        region: "Europe",
                        logoURL: nil,
                        systemImageName: "sparkles"
                    ),
                    MainSoccerTopLeagueViewData(
                        name: "Serie A",
                        region: "Italy",
                        logoURL: nil,
                        systemImageName: "shield.fill"
                    )
                ]
            )
        ),
        .standings(
            MainSoccerStandingsViewData(
                title: "Standings",
                state: .empty(message: "No standings selected")
            )
        )
    ]
}
