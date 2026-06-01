//
//  MatchDetailHeaderStatusStyle+MatchFixturePhase.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/29.
//

import Foundation

// MARK: - Soccer

extension SoccerMatchDetailHeaderStatusStyle {

    nonisolated init(matchNavigationStyle: MatchDetailNavigationStatusStyle) {
        switch matchNavigationStyle {
        case .live:
            self = .live

        case .final:
            self = .final

        case .upcoming:
            self = .upcoming

        case .postponed:
            self = .postponed

        case .cancelled:
            self = .cancelled

        case .neutral:
            self = .neutral
        }
    }
}

// MARK: - Basketball

extension BasketballMatchDetailHeaderStatusStyle {

    nonisolated init(matchNavigationStyle: MatchDetailNavigationStatusStyle) {
        switch matchNavigationStyle {
        case .live:
            self = .live

        case .final:
            self = .final

        case .upcoming:
            self = .upcoming

        case .postponed:
            self = .postponed

        case .cancelled:
            self = .cancelled

        case .neutral:
            self = .neutral
        }
    }
}

// MARK: - Baseball

extension BaseballMatchDetailHeaderStatusStyle {

    nonisolated init(matchNavigationStyle: MatchDetailNavigationStatusStyle) {
        switch matchNavigationStyle {
        case .live:
            self = .live

        case .final:
            self = .final

        case .upcoming:
            self = .upcoming

        case .postponed, .cancelled, .neutral:
            self = .neutral
        }
    }
}
