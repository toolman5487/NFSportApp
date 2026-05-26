//
//  MainSoccerMatchesPresentation.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/26.
//

import Foundation

// MARK: - MainSoccerMatchesPresentation

nonisolated struct MainSoccerMatchesPresentation: Equatable, Sendable {

    let title: String
    let sections: [MainSoccerMatchesContentSectionViewData]

    var hasScheduleGroups: Bool {
        sections.contains { section in
            switch section {
            case .datePicker, .filter:
                return false

            case .scheduleGroup:
                return true
            }
        }
    }
}

// MARK: - Content Section

nonisolated enum MainSoccerMatchesContentSectionViewData: Equatable, Sendable {

    case datePicker(MainSoccerMatchesDatePickerViewData)
    case filter(MainSoccerMatchesFilterViewData)
    case scheduleGroup(MainSoccerMatchesScheduleGroupViewData)
}

// MARK: - Date Picker

nonisolated struct MainSoccerMatchesDatePickerViewData: Equatable, Sendable {

    let title: String
    let dates: [MainSoccerMatchesDateItemViewData]
}

nonisolated struct MainSoccerMatchesDateItemViewData: Equatable, Identifiable, Sendable {

    var id: Date {
        date
    }

    let date: Date
    let weekdayText: String
    let dayText: String
    let monthText: String
    let isToday: Bool
    let isSelected: Bool
}

// MARK: - Filter

nonisolated struct MainSoccerMatchesFilterViewData: Equatable, Sendable {

    let options: [MainSoccerMatchesFilterOptionViewData]
}

nonisolated struct MainSoccerMatchesFilterOptionViewData: Equatable, Identifiable, Sendable {

    var id: MainSoccerMatchesFilterOption {
        option
    }

    let option: MainSoccerMatchesFilterOption
    let title: String
    let systemImageName: String?
    let logoURL: URL?
    let isSelected: Bool
}

// MARK: - Schedule Group

nonisolated struct MainSoccerMatchesScheduleGroupViewData: Equatable, Sendable {

    let items: [MainSoccerMatchesGameViewData]
}

// MARK: - Game

nonisolated struct MainSoccerMatchesGameViewData: Equatable, Identifiable, Sendable {

    let id: Int
    let leagueName: String
    let timeText: String
    let statusText: String
    let statusStyle: MainSoccerMatchesGameStatusStyle
    let awayTeamName: String
    let awayTeamLogoURL: URL?
    let homeTeamName: String
    let homeTeamLogoURL: URL?
    let awayScoreText: String
    let homeScoreText: String
}

// MARK: - Status

nonisolated enum MainSoccerMatchesGameStatusStyle: Equatable, Sendable {

    case live
    case final
    case upcoming
    case neutral
}

// MARK: - Filter Option

nonisolated enum MainSoccerMatchesFilterOption: CaseIterable, Equatable, Hashable, Sendable {

    case allLeagues
    case league(name: String, logoURL: URL?)

    var title: String {
        switch self {
        case .allLeagues:
            return "All"

        case .league(let name, _):
            return name
        }
    }

    var systemImageName: String? {
        switch self {
        case .allLeagues:
            return "list.bullet"

        case .league(_, let logoURL):
            return logoURL == nil ? "trophy" : nil
        }
    }

    var logoURL: URL? {
        switch self {
        case .allLeagues:
            return nil

        case .league(_, let logoURL):
            return logoURL
        }
    }

    static var allCases: [MainSoccerMatchesFilterOption] {
        [.allLeagues]
    }
}
