//
//  AppTab.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/22.
//

import Foundation

enum AppTab: Int, CaseIterable, Sendable {

    case home
    case matches
    case favorites
}

// MARK: - Display

extension AppTab {

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
