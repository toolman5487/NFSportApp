//
//  AppTab.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/22.
//

import Foundation

enum AppTab: Int, CaseIterable, Sendable {

    case home
    case schedule
    case news
    case profile
}

// MARK: - Display

extension AppTab {

    var title: String {
        switch self {
        case .home:
            return "Home"
        case .schedule:
            return "Schedule"
        case .news:
            return "News"
        case .profile:
            return "Profile"
        }
    }

    var systemImageName: String {
        switch self {
        case .home:
            return "house"
        case .schedule:
            return "sportscourt"
        case .news:
            return "newspaper"
        case .profile:
            return "person"
        }
    }
}
