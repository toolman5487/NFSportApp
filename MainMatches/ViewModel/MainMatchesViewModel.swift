//
//  MainMatchesViewModel.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/25.
//

import Foundation

// MARK: - State

nonisolated enum MainMatchesViewState: Equatable, Sendable {

    case idle
    case loading
    case loaded(MainMatchesPresentation)
    case empty(presentation: MainMatchesPresentation, message: String)
    case failed(message: String)
}

// MARK: - MainMatchesViewModel

@MainActor
final class MainMatchesViewModel {

    // MARK: - Properties

    private(set) var state: MainMatchesViewState = .idle {
        didSet {
            onStateChange?(state)
        }
    }

    var onStateChange: ((MainMatchesViewState) -> Void)?

    var title: String {
        "Matches"
    }

    private let selectedSport: SportType
    private let scheduleService: MainMatchesServicing
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = .current
        calendar.timeZone = .current
        return calendar
    }()
    private var schedule: MainMatchesSchedule?
    private var selectedDate: Date
    private var selectedFilterOption: MainMatchesFilterOption = .all

    // MARK: - Initialization

    init(
        selectedSport: SportType,
        scheduleService: MainMatchesServicing,
        selectedDate: Date = Date()
    ) {
        self.selectedSport = selectedSport
        self.scheduleService = scheduleService
        self.selectedDate = selectedDate
    }

    // MARK: - Public Methods

    func loadSchedule() async {
        state = .loading

        do {
            let schedule = try await scheduleService.fetchSchedule(
                for: selectedSport,
                date: selectedDate
            )
            self.schedule = schedule
            renderSchedule(schedule)
        } catch {
            state = .failed(message: error.localizedDescription)
            AppLogger.logUIError(
                error,
                message: "Main matches loading failed",
                metadata: "sport=\(selectedSport.id)"
            )
        }
    }

    func selectDate(_ date: Date) async {
        guard !calendar.isDate(date, inSameDayAs: selectedDate) else {
            return
        }

        selectedDate = date
        await loadSchedule()
    }

    func selectPreviousDatePage() async {
        await selectDatePage(dayOffset: -7)
    }

    func selectNextDatePage() async {
        await selectDatePage(dayOffset: 7)
    }

    func selectFilterOption(_ option: MainMatchesFilterOption) {
        guard selectedFilterOption != option else {
            return
        }

        selectedFilterOption = option
        guard let schedule else {
            return
        }

        renderSchedule(schedule)
    }

    // MARK: - Rendering

    private func renderSchedule(_ schedule: MainMatchesSchedule) {
        let presentation = makePresentation(from: schedule)

        switch presentation.hasScheduleGroups {
        case true:
            state = .loaded(presentation)

        case false:
            state = .empty(
                presentation: presentation,
                message: makeEmptyMessage()
            )
        }
    }

    // MARK: - Presentation Mapping

    private func makePresentation(from schedule: MainMatchesSchedule) -> MainMatchesPresentation {
        let filteredGames = filterGames(schedule.games)
        let sortedGames = filteredGames.sorted { lhs, rhs in
            switch (lhs.scheduledStartDate, rhs.scheduledStartDate) {
            case (.some(let lhsDate), .some(let rhsDate)):
                return lhsDate < rhsDate

            case (.some, .none):
                return true

            case (.none, .some):
                return false

            case (.none, .none):
                return lhs.id < rhs.id
            }
        }

        let sections: [MainMatchesContentSectionViewData] = [
            .datePicker(makeDatePickerViewData()),
            .filter(makeFilterViewData())
        ] + makeScheduleGroups(from: sortedGames).map { group in
            .scheduleGroup(group)
        }

        return MainMatchesPresentation(
            title: title,
            sections: sections
        )
    }

    private func makeDatePickerViewData() -> MainMatchesDatePickerViewData {
        let weekStartDate = makeWeekStartDate(for: selectedDate)
        let dates = (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: weekStartDate)
        }

        return MainMatchesDatePickerViewData(
            title: makeDatePageTitle(from: dates),
            dates: dates.map { date in
                MainMatchesDateItemViewData(
                    date: date,
                    weekdayText: makeWeekdayText(from: date),
                    dayText: makeDayText(from: date),
                    monthText: makeMonthText(from: date),
                    isToday: calendar.isDateInToday(date),
                    isSelected: calendar.isDate(date, inSameDayAs: selectedDate)
                )
            }
        )
    }

    private func selectDatePage(dayOffset: Int) async {
        guard let date = calendar.date(byAdding: .day, value: dayOffset, to: selectedDate) else {
            return
        }

        selectedDate = date
        await loadSchedule()
    }

    private func makeFilterViewData() -> MainMatchesFilterViewData {
        MainMatchesFilterViewData(
            options: MainMatchesFilterOption.allCases.map { option in
                MainMatchesFilterOptionViewData(
                    option: option,
                    title: option.title,
                    systemImageName: option.systemImageName,
                    isSelected: option == selectedFilterOption
                )
            }
        )
    }

    private func makeScheduleGroups(
        from games: [MainMatchesGame]
    ) -> [MainMatchesScheduleGroupViewData] {
        let groupedGames = Dictionary(grouping: games) { game in
            makeGroupTitle(from: game.scheduledStartDate, fallback: game.scheduledStartText)
        }
        let orderedTitles = groupedGames.keys.sorted { lhs, rhs in
            let lhsDate = groupedGames[lhs]?.first?.scheduledStartDate
            let rhsDate = groupedGames[rhs]?.first?.scheduledStartDate

            switch (lhsDate, rhsDate) {
            case (.some(let lhsDate), .some(let rhsDate)):
                return lhsDate < rhsDate

            case (.some, .none):
                return true

            case (.none, .some):
                return false

            case (.none, .none):
                return lhs < rhs
            }
        }

        return orderedTitles.compactMap { title in
            guard let games = groupedGames[title] else {
                return nil
            }

            let items = games.map(makeGameViewData)
            return MainMatchesScheduleGroupViewData(
                title: title,
                subtitle: "\(items.count) matches",
                items: items
            )
        }
    }

    private func makeGameViewData(from game: MainMatchesGame) -> MainMatchesGameViewData {
        MainMatchesGameViewData(
            id: game.id,
            leagueName: game.leagueName,
            timeText: makeTimeText(from: game.scheduledStartDate, fallback: game.scheduledStartText),
            statusText: game.statusDescription ?? "Scheduled",
            statusStyle: makeStatusStyle(from: game.statusDescription),
            awayTeamName: game.awayTeamName,
            homeTeamName: game.homeTeamName,
            awayScoreText: game.awayScore ?? "-",
            homeScoreText: game.homeScore ?? "-"
        )
    }

    // MARK: - Filtering

    private func filterGames(_ games: [MainMatchesGame]) -> [MainMatchesGame] {
        games.filter { game in
            matchesSelectedFilterOption(makeStatusStyle(from: game.statusDescription))
        }
    }

    private func matchesSelectedFilterOption(_ statusStyle: MainMatchesGameStatusStyle) -> Bool {
        switch selectedFilterOption {
        case .all:
            return true

        case .live:
            return statusStyle == .live

        case .upcoming:
            return statusStyle == .upcoming

        case .finished:
            return statusStyle == .final
        }
    }

    private func makeStatusStyle(from statusDescription: String?) -> MainMatchesGameStatusStyle {
        guard let normalizedStatus = statusDescription?.lowercased() else {
            return .neutral
        }

        switch normalizedStatus {
        case let status where status.contains("live")
            || status.contains("progress")
            || status.contains("quarter")
            || status.contains("half"):
            return .live

        case let status where status.contains("finish")
            || status.contains("final")
            || status.contains("ended"):
            return .final

        case let status where status.contains("scheduled")
            || status.contains("not started"):
            return .upcoming

        default:
            return .neutral
        }
    }

    private func makeEmptyMessage() -> String {
        switch selectedFilterOption {
        case .all:
            return "No matches on this date."

        case .live, .upcoming, .finished:
            return "No \(selectedFilterOption.title.lowercased()) matches on this date."
        }
    }

    // MARK: - Date Formatting

    private func makeWeekdayText(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = .current
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private func makeDayText(from date: Date) -> String {
        let day = calendar.component(.day, from: date)
        return "\(day)"
    }

    private func makeMonthText(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = .current
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }

    private func makeWeekStartDate(for date: Date) -> Date {
        let startOfDay = calendar.startOfDay(for: date)
        return calendar.dateInterval(of: .weekOfYear, for: startOfDay)?.start ?? startOfDay
    }

    private func makeDatePageTitle(from dates: [Date]) -> String {
        guard let firstDate = dates.first,
              let lastDate = dates.last else {
            return ""
        }

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = .current
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: firstDate)) - \(formatter.string(from: lastDate))"
    }

    private func makeGroupTitle(from date: Date?, fallback: String) -> String {
        guard let date else {
            return fallback
        }

        return makeTimeText(from: date, fallback: fallback)
    }

    private func makeTimeText(from date: Date?, fallback: String) -> String {
        guard let date else {
            return fallback
        }

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = .current
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}
