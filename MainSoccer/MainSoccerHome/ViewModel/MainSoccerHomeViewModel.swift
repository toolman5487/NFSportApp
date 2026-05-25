//
//  MainSoccerHomeViewModel.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/25.
//

import Foundation

// MARK: - State

nonisolated enum MainSoccerHomeViewState: Equatable, Sendable {

    case idle
    case loading(MainSoccerHomePresentation)
    case loaded(MainSoccerHomePresentation)
    case empty(presentation: MainSoccerHomePresentation, message: String)
    case failed(message: String)
}

// MARK: - MainSoccerHomeViewModel

@MainActor
final class MainSoccerHomeViewModel {

    // MARK: - Properties

    private(set) var state: MainSoccerHomeViewState = .idle {
        didSet {
            onStateChange?(state)
        }
    }

    var onStateChange: ((MainSoccerHomeViewState) -> Void)?

    var title: String {
        selectedSport.title
    }

    private let selectedSport: SportType
    private let homeService: MainSoccerHomeServicing
    private var dashboard: MainSoccerHomeDashboard?
    private var selectedFilterOption: MainHomeFilterOption = .all

    // MARK: - Initialization

    init(
        selectedSport: SportType,
        homeService: MainSoccerHomeServicing
    ) {
        self.selectedSport = selectedSport
        self.homeService = homeService
    }

    // MARK: - Public Methods

    func loadDashboard() async {
        state = .loading(.loading(title: selectedSport.title))

        do {
            let dashboard = try await homeService.fetchDashboard(
                for: selectedSport,
                date: Date()
            )
            self.dashboard = dashboard
            renderDashboard(dashboard)
        } catch {
            state = .failed(message: error.localizedDescription)
            AppLogger.logUIError(
                error,
                message: "Main soccer home loading failed",
                metadata: "sport=\(selectedSport.id)"
            )
        }
    }

    func selectFilterOption(_ option: MainHomeFilterOption) {
        guard selectedFilterOption != option else {
            return
        }

        selectedFilterOption = option
        guard let dashboard else {
            return
        }

        renderDashboard(dashboard)
    }

    // MARK: - Rendering

    private func renderDashboard(_ dashboard: MainSoccerHomeDashboard) {
        let presentation = makePresentation(from: dashboard)

        switch presentation.hasLeagueSections {
        case true:
            state = .loaded(presentation)

        case false:
            state = .empty(presentation: presentation, message: makeEmptyMessage())
        }
    }

    // MARK: - Presentation Mapping

    private func makePresentation(from dashboard: MainSoccerHomeDashboard) -> MainSoccerHomePresentation {
        let mergedFixtures = mergeFixtures(
            liveFixtures: dashboard.liveFixtures,
            todayFixtures: dashboard.todayFixtures
        )
        let fixtures = filterFixtures(mergedFixtures)
        let leagueSections = makeLeagueSections(
            from: fixtures,
            fallbackSystemImageName: dashboard.sport.systemImageName
        )
        let sections: [MainSoccerHomeContentSectionViewData] = [
            .filter(makeFilterViewData())
        ] + leagueSections.map { section in
            .league(section)
        }

        return MainSoccerHomePresentation(
            title: dashboard.sport.title,
            sections: sections
        )
    }

    // MARK: - Filter Mapping

    private func makeFilterViewData() -> MainHomeFilterViewData {
        MainHomeFilterViewData(
            options: MainHomeFilterOption.allCases.map { option in
                MainHomeFilterOptionViewData(
                    option: option,
                    title: option.title,
                    systemImageName: option.systemImageName,
                    isSelected: option == selectedFilterOption
                )
            }
        )
    }

    // MARK: - Fixture Mapping

    private func makeGameViewData(from fixture: MainSoccerFixture) -> MainHomeGameViewData {
        MainHomeGameViewData(
            id: fixture.id,
            awayTeamName: fixture.awayTeamName,
            awayTeamLogoURL: fixture.awayTeamLogoURL,
            homeTeamName: fixture.homeTeamName,
            homeTeamLogoURL: fixture.homeTeamLogoURL,
            awayScoreText: fixture.awayScore?.description ?? "-",
            homeScoreText: fixture.homeScore?.description ?? "-",
            scheduledStartText: makeFixtureTimeText(from: fixture),
            statusText: makeFixtureStatusText(from: fixture),
            statusStyle: makeStatusStyle(from: fixture)
        )
    }

    private func makeFixtureTimeText(from fixture: MainSoccerFixture) -> String {
        guard let scheduledStartDate = fixture.scheduledStartDate else {
            return fixture.scheduledStartText ?? "TBD"
        }

        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.timeZone = .current
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: scheduledStartDate)
    }

    private func makeFixtureStatusText(from fixture: MainSoccerFixture) -> String {
        switch makeStatusStyle(from: fixture) {
        case .live:
            return makeMinuteText(from: fixture)

        case .upcoming:
            return "Upcoming"

        case .final:
            return "Final"

        case .neutral:
            return fixture.statusShort ?? fixture.statusLong ?? "Info"
        }
    }

    private func makeMinuteText(from fixture: MainSoccerFixture) -> String {
        if let elapsedMinute = fixture.elapsedMinute {
            return "\(elapsedMinute)'"
        }

        return fixture.statusShort ?? fixture.statusLong ?? "Live"
    }

    private func makeStatusStyle(from fixture: MainSoccerFixture) -> MainHomeGameStatusStyle {
        guard let statusShort = fixture.statusShort else {
            return .neutral
        }

        switch statusShort {
        case "1H", "HT", "2H", "ET", "BT", "P", "SUSP", "INT", "LIVE":
            return .live

        case "NS", "TBD":
            return .upcoming

        case "FT", "AET", "PEN", "PST", "CANC", "ABD", "AWD", "WO":
            return .final

        default:
            return .neutral
        }
    }

    // MARK: - Filtering

    private func filterFixtures(_ fixtures: [MainSoccerFixture]) -> [MainSoccerFixture] {
        fixtures.filter { fixture in
            matchesSelectedFilterOption(makeStatusStyle(from: fixture))
        }
    }

    private func matchesSelectedFilterOption(_ statusStyle: MainHomeGameStatusStyle) -> Bool {
        switch selectedFilterOption {
        case .all, .ascending, .descending:
            return true

        case .live:
            return statusStyle == .live

        case .upcoming:
            return statusStyle == .upcoming

        case .finished:
            return statusStyle == .final
        }
    }

    private func makeEmptyMessage() -> String {
        switch selectedFilterOption {
        case .all, .ascending, .descending:
            return "No matches available."

        case .live, .upcoming, .finished:
            return "No \(selectedFilterOption.title.lowercased()) matches available."
        }
    }

    // MARK: - Merging

    private func mergeFixtures(
        liveFixtures: [MainSoccerFixture],
        todayFixtures: [MainSoccerFixture]
    ) -> [MainSoccerFixture] {
        var seenFixtureIDs = Set<Int>()
        var mergedFixtures: [MainSoccerFixture] = []

        for fixture in liveFixtures + todayFixtures where seenFixtureIDs.insert(fixture.id).inserted {
            mergedFixtures.append(fixture)
        }

        return mergedFixtures
    }

    // MARK: - League Grouping

    private func makeLeagueSections(
        from fixtures: [MainSoccerFixture],
        fallbackSystemImageName: String
    ) -> [MainHomeSectionViewData] {
        var orderedLeagueNames: [String] = []
        var fixturesByLeagueName: [String: [MainSoccerFixture]] = [:]
        var leagueLogoURLsByName: [String: URL] = [:]

        for fixture in fixtures {
            let leagueName = fixture.leagueName

            if fixturesByLeagueName[leagueName] == nil {
                orderedLeagueNames.append(leagueName)
            }

            if leagueLogoURLsByName[leagueName] == nil,
               let leagueLogoURL = fixture.leagueLogoURL {
                leagueLogoURLsByName[leagueName] = leagueLogoURL
            }

            fixturesByLeagueName[leagueName, default: []].append(fixture)
        }

        let leagueSections: [MainHomeSectionViewData] = orderedLeagueNames.compactMap { leagueName in
            guard let leagueFixtures = fixturesByLeagueName[leagueName],
                  !leagueFixtures.isEmpty else {
                return nil as MainHomeSectionViewData?
            }

            return MainHomeSectionViewData(
                title: leagueName,
                logoURL: leagueLogoURLsByName[leagueName],
                fallbackSystemImageName: fallbackSystemImageName,
                items: leagueFixtures.map(makeGameViewData)
            )
        }

        return sortLeagueSections(leagueSections)
    }

    // MARK: - Sorting

    private func sortLeagueSections(
        _ sections: [MainHomeSectionViewData]
    ) -> [MainHomeSectionViewData] {
        switch selectedFilterOption {
        case .ascending:
            return sections.sorted { lhs, rhs in
                lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }

        case .descending:
            return sections.sorted { lhs, rhs in
                lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedDescending
            }

        case .all, .live, .upcoming, .finished:
            return sections
        }
    }
}
