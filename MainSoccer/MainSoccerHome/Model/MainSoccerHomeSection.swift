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
}

// MARK: - Content

extension MainSoccerHomeSection {

    var title: String? {
        switch self {
        case .liveMatches(let viewData):
            return viewData.title

        case .today(let viewData):
            return viewData.title
        }
    }

    var items: [MainSoccerHomeItem] {
        switch self {
        case .liveMatches(let viewData):
            return liveMatchItems(from: viewData)

        case .today(let viewData):
            return fixtureItems(from: viewData)
        }
    }

    private func liveMatchItems(from viewData: MainSoccerLiveMatchesViewData) -> [MainSoccerHomeItem] {
        switch viewData.state {
        case .empty(let message):
            return [.empty(MainSoccerEmptyStateViewData(message: message))]

        case .loaded(let matches):
            return matches.map(MainSoccerHomeItem.liveHero)
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
}

// MARK: - Item

nonisolated enum MainSoccerHomeItem: Equatable, Sendable {
    case liveHero(MainSoccerLiveMatchViewData)
    case empty(MainSoccerEmptyStateViewData)
    case fixture(MainSoccerFixtureViewData)
}
