//
//  MainSoccerMatchesViewModel.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/26.
//

import Foundation

// MARK: - State

nonisolated enum MainSoccerMatchesViewState: Equatable, Sendable {

    case idle
    case loading
    case loaded(MainSoccerMatchesPresentation)
    case empty(presentation: MainSoccerMatchesPresentation, message: String)
    case failed(message: String)
}

// MARK: - MainSoccerMatchesViewModel

@MainActor
final class MainSoccerMatchesViewModel {

    // MARK: - Properties

    private(set) var state: MainSoccerMatchesViewState = .idle {
        didSet {
            onStateChange?(state)
        }
    }

    var onStateChange: ((MainSoccerMatchesViewState) -> Void)?

    var title: String {
        "Matches"
    }

    private let selectedSport: SportType
    private let scheduleService: MainSoccerMatchesServicing
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = .current
        calendar.timeZone = .current
        return calendar
    }()
    private var schedule: MainSoccerMatchesSchedule?
    private var selectedDate: Date
    private var selectedFilterOption: MainSoccerMatchesFilterOption = .allLeagues

    // MARK: - Initialization

    init(
        selectedSport: SportType,
        scheduleService: MainSoccerMatchesServicing,
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
                message: "Main soccer matches loading failed",
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

    func selectFilterOption(_ option: MainSoccerMatchesFilterOption) {
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

    private func renderSchedule(_ schedule: MainSoccerMatchesSchedule) {
        normalizeSelectedFilterOption(for: schedule.games)
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

    private func makePresentation(from schedule: MainSoccerMatchesSchedule) -> MainSoccerMatchesPresentation {
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

        var sections: [MainSoccerMatchesContentSectionViewData] = [
            .datePicker(makeDatePickerViewData())
        ]

        if !schedule.games.isEmpty {
            sections.append(.filter(makeFilterViewData(from: schedule.games)))
        }

        sections += makeScheduleGroups(from: sortedGames).map { group in
            .scheduleGroup(group)
        }

        return MainSoccerMatchesPresentation(
            title: title,
            sections: sections
        )
    }

    private func makeDatePickerViewData() -> MainSoccerMatchesDatePickerViewData {
        let weekStartDate = makeWeekStartDate(for: selectedDate)
        let dates = (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: weekStartDate)
        }

        return MainSoccerMatchesDatePickerViewData(
            title: makeDatePageTitle(from: dates),
            dates: dates.map { date in
                MainSoccerMatchesDateItemViewData(
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

    private func makeFilterViewData(from games: [MainSoccerMatchesGame]) -> MainSoccerMatchesFilterViewData {
        let leagueOptions = makeLeagueFilterOptions(from: games)

        return MainSoccerMatchesFilterViewData(
            options: leagueOptions.map { option in
                MainSoccerMatchesFilterOptionViewData(
                    option: option,
                    title: option.title,
                    systemImageName: option.systemImageName,
                    logoURL: option.logoURL,
                    isSelected: option == selectedFilterOption
                )
            }
        )
    }

    private func makeScheduleGroups(
        from games: [MainSoccerMatchesGame]
    ) -> [MainSoccerMatchesScheduleGroupViewData] {
        guard !games.isEmpty else {
            return []
        }

        return [
            MainSoccerMatchesScheduleGroupViewData(
                items: games.map(makeGameViewData)
            )
        ]
    }

    private func makeGameViewData(from game: MainSoccerMatchesGame) -> MainSoccerMatchesGameViewData {
        MainSoccerMatchesGameViewData(
            id: game.id,
            leagueName: game.leagueName,
            timeText: makeTimeText(from: game.scheduledStartDate, fallback: game.scheduledStartText),
            statusText: game.statusDescription ?? "Scheduled",
            statusStyle: makeStatusStyle(from: game.statusDescription),
            awayTeamName: game.awayTeamName,
            awayTeamLogoURL: game.awayTeamLogoURL,
            homeTeamName: game.homeTeamName,
            homeTeamLogoURL: game.homeTeamLogoURL,
            awayScoreText: game.awayScore ?? "-",
            homeScoreText: game.homeScore ?? "-"
        )
    }

    // MARK: - Filtering

    private func filterGames(_ games: [MainSoccerMatchesGame]) -> [MainSoccerMatchesGame] {
        games.filter { game in
            matchesSelectedFilterOption(game)
        }
    }

    private func matchesSelectedFilterOption(_ game: MainSoccerMatchesGame) -> Bool {
        switch selectedFilterOption {
        case .allLeagues:
            return true

        case .league(let name, _):
            return game.leagueName == name
        }
    }

    private func makeLeagueFilterOptions(
        from games: [MainSoccerMatchesGame]
    ) -> [MainSoccerMatchesFilterOption] {
        let leagueLogoURLsByName = Dictionary(
            grouping: games,
            by: \.leagueName
        ).mapValues { games in
            games.compactMap(\.leagueLogoURL).first
        }
        let leagueNames = leagueLogoURLsByName.keys.sorted { lhs, rhs in
            lhs.localizedStandardCompare(rhs) == .orderedAscending
        }

        return [.allLeagues] + leagueNames.map { name in
            .league(name: name, logoURL: leagueLogoURLsByName[name] ?? nil)
        }
    }

    private func normalizeSelectedFilterOption(for games: [MainSoccerMatchesGame]) {
        let options = makeLeagueFilterOptions(from: games)

        guard options.contains(selectedFilterOption) else {
            selectedFilterOption = .allLeagues
            return
        }
    }

    private func makeStatusStyle(from statusDescription: String?) -> MainSoccerMatchesGameStatusStyle {
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
        case .allLeagues:
            return "No matches on this date."

        case .league(let name, _):
            return "No matches for \(name) on this date."
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
