//
//  MainHomePresentation.swift
//  NFSportApp
//
//  Created by Willy Hsu 2026/5/23.
//

import Foundation

// MARK: - MainHomePresentation

nonisolated struct MainHomePresentation: Equatable, Sendable {

    let title: String
    let sections: [MainHomeContentSectionViewData]

    var hasLeagueSections: Bool {
        sections.contains { section in
            switch section {
            case .filter:
                return false

            case .league:
                return true
            }
        }
    }
}

// MARK: - Content Section

nonisolated enum MainHomeContentSectionViewData: Equatable, Sendable {

    case filter(MainHomeFilterViewData)
    case league(MainHomeSectionViewData)
}

// MARK: - Filter

nonisolated struct MainHomeFilterViewData: Equatable, Sendable {

    let options: [MainHomeFilterOptionViewData]
}

nonisolated struct MainHomeFilterOptionViewData: Equatable, Identifiable, Sendable {

    var id: MainHomeFilterOption {
        option
    }

    let option: MainHomeFilterOption
    let title: String
    let systemImageName: String?
    let isSelected: Bool
}

// MARK: - League Section

nonisolated struct MainHomeSectionViewData: Equatable, Sendable {

    let title: String
    let logoURL: URL?
    let fallbackSystemImageName: String
    let items: [MainHomeGameViewData]
}

// MARK: - Game

nonisolated struct MainHomeGameViewData: Equatable, Identifiable, Sendable {

    let id: Int
    let awayTeamName: String
    let homeTeamName: String
    let awayScoreText: String
    let homeScoreText: String
    let scheduledStartText: String
    let statusText: String
    let statusStyle: MainHomeGameStatusStyle
}

// MARK: - Game Status Style

nonisolated enum MainHomeGameStatusStyle: Equatable, Sendable {

    case live
    case final
    case upcoming
    case neutral
}

// MARK: - Filter Option

nonisolated enum MainHomeFilterOption: CaseIterable, Equatable, Hashable, Sendable {

    case all
    case live
    case upcoming
    case finished
    case ascending
    case descending

    var title: String {
        switch self {
        case .all:
            return "All"

        case .live:
            return "Live"

        case .upcoming:
            return "Upcoming"

        case .finished:
            return "Finished"

        case .ascending:
            return "A to Z"

        case .descending:
            return "Z to A"
        }
    }

    var systemImageName: String? {
        switch self {
        case .all:
            return "circle.grid.2x2"

        case .live:
            return "play.circle"

        case .upcoming:
            return "calendar"

        case .finished:
            return "checkmark.circle"

        case .ascending:
            return "arrow.up"

        case .descending:
            return "arrow.down"
        }
    }
}
