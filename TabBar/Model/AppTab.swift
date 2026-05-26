//
//  AppTab.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/22.
//

import Foundation

enum AppTab: Hashable, Sendable {
    case mainSport(MainSportTab)
    case mainSoccer(MainSoccerTab)
}

enum MainSportTab: Int, CaseIterable, Sendable {

    case home
    case matches
    case search
}

extension MainSportTab {

    var title: String {
        switch self {
        case .home:
            return "Home"
        case .matches:
            return "Matches"
        case .search:
            return "Search"
        }
    }

    var systemImageName: String {
        switch self {
        case .home:
            return "house"
        case .matches:
            return "calendar"
        case .search:
            return "magnifyingglass"
        }
    }
}

enum MainSoccerTab: Int, CaseIterable, Sendable {

    case home
    case matches
    case favorites
}

extension MainSoccerTab {

    var title: String {
        switch self {
        case .home:
            return "Home"
        case .matches:
            return "Matches"
        case .favorites:
            return "Favorites"
        }
    }

    var systemImageName: String {
        switch self {
        case .home:
            return "house"
        case .matches:
            return "calendar"
        case .favorites:
            return "star"
        }
    }
}

// MARK: - Display

extension AppTab {

    var title: String {
        switch self {
        case .mainSport(let tab):
            return tab.title
        case .mainSoccer(let tab):
            return tab.title
        }
    }

    var systemImageName: String {
        switch self {
        case .mainSport(let tab):
            return tab.systemImageName
        case .mainSoccer(let tab):
            return tab.systemImageName
        }
    }
}
