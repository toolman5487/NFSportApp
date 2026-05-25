//
//  MainMatchesPresentation.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/25.
//

import Foundation

// MARK: - MainMatchesPresentation

nonisolated struct MainMatchesPresentation: Equatable, Sendable {

    let title: String
    let sections: [MainMatchesContentSectionViewData]

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

nonisolated enum MainMatchesContentSectionViewData: Equatable, Sendable {

    case datePicker(MainMatchesDatePickerViewData)
    case filter(MainMatchesFilterViewData)
    case scheduleGroup(MainMatchesScheduleGroupViewData)
}

// MARK: - Date Picker

nonisolated struct MainMatchesDatePickerViewData: Equatable, Sendable {

    let title: String
    let dates: [MainMatchesDateItemViewData]
}

nonisolated struct MainMatchesDateItemViewData: Equatable, Identifiable, Sendable {

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

nonisolated struct MainMatchesFilterViewData: Equatable, Sendable {

    let options: [MainMatchesFilterOptionViewData]
}

nonisolated struct MainMatchesFilterOptionViewData: Equatable, Identifiable, Sendable {

    var id: MainMatchesFilterOption {
        option
    }

    let option: MainMatchesFilterOption
    let title: String
    let systemImageName: String?
    let isSelected: Bool
}

// MARK: - Schedule Group

nonisolated struct MainMatchesScheduleGroupViewData: Equatable, Sendable {

    let title: String
    let subtitle: String
    let items: [MainMatchesGameViewData]
}

// MARK: - Game

nonisolated struct MainMatchesGameViewData: Equatable, Identifiable, Sendable {

    let id: Int
    let leagueName: String
    let timeText: String
    let statusText: String
    let statusStyle: MainMatchesGameStatusStyle
    let awayTeamName: String
    let homeTeamName: String
    let awayScoreText: String
    let homeScoreText: String
}

// MARK: - Status

nonisolated enum MainMatchesGameStatusStyle: Equatable, Sendable {

    case live
    case final
    case upcoming
    case neutral
}

// MARK: - Filter Option

nonisolated enum MainMatchesFilterOption: CaseIterable, Equatable, Hashable, Sendable {

    case all
    case live
    case upcoming
    case finished

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
        }
    }

    var systemImageName: String? {
        switch self {
        case .all:
            return "calendar"

        case .live:
            return "play.circle"

        case .upcoming:
            return "clock"

        case .finished:
            return "checkmark.circle"
        }
    }
}
