//
//  MainHomeViewModel.swift
//  NFSportApp
//
//  Created by Willy Hsu 2026/5/23.
//

import Foundation

// MARK: - State

nonisolated enum MainHomeViewState: Equatable, Sendable {

    case idle
    case loading
    case loaded(MainHomePresentation)
    case empty(presentation: MainHomePresentation, message: String)
    case failed(message: String)
}

// MARK: - MainHomeViewModel

@MainActor
final class MainHomeViewModel {

    // MARK: - Properties

    private(set) var state: MainHomeViewState = .idle {
        didSet {
            onStateChange?(state)
        }
    }

    var onStateChange: ((MainHomeViewState) -> Void)?

    var title: String {
        selectedSport.title
    }

    private let homeService: MainHomeServicing
    private let selectedSport: SportType
    private var dashboard: MainHomeDashboard?
    private var selectedFilterOption: MainHomeFilterOption = .all

    // MARK: - Initialization

    init(
        selectedSport: SportType,
        homeService: MainHomeServicing
    ) {
        self.selectedSport = selectedSport
        self.homeService = homeService
    }

    // MARK: - Public Methods

    func loadDashboard() async {
        state = .loading

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
                message: "Main home loading failed",
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

    private func renderDashboard(_ dashboard: MainHomeDashboard) {
        let presentation = makePresentation(from: dashboard)

        switch presentation.hasLeagueSections {
        case true:
            state = .loaded(presentation)

        case false:
            state = .empty(presentation: presentation, message: makeEmptyMessage())
        }
    }

    // MARK: - Presentation Mapping

    private func makePresentation(from dashboard: MainHomeDashboard) -> MainHomePresentation {
        let mergedGames = mergeGames(
            liveGames: dashboard.liveGames,
            todayGames: dashboard.todayGames
        )
        let games = filterGames(mergedGames)
        let leagueSections = makeLeagueSections(
            from: games,
            fallbackSystemImageName: dashboard.sport.systemImageName
        )
        let contentSections: [MainHomeContentSectionViewData] = [
            .filter(makeFilterViewData())
        ] + leagueSections.map { section in
            .league(section)
        }

        return MainHomePresentation(
            title: dashboard.sport.title,
            sections: contentSections
        )
    }

    // MARK: - Filter Mapping

    private func makeFilterViewData() -> MainHomeFilterViewData {
        return MainHomeFilterViewData(
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

    // MARK: - Game Mapping

    private func makeGameViewData(from game: MainHomeGame) -> MainHomeGameViewData {
        MainHomeGameViewData(
            id: game.id,
            awayTeamName: game.awayTeamName,
            awayTeamLogoURL: game.awayTeamLogoURL,
            homeTeamName: game.homeTeamName,
            homeTeamLogoURL: game.homeTeamLogoURL,
            awayScoreText: game.awayScore ?? "-",
            homeScoreText: game.homeScore ?? "-",
            scheduledStartText: game.scheduledStartText ?? "TBD",
            statusText: game.statusDescription ?? "Unknown",
            statusStyle: makeStatusStyle(from: game.statusDescription)
        )
    }

    private func makeStatusStyle(from statusDescription: String?) -> MainHomeGameStatusStyle {
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

    // MARK: - Filtering

    private func filterGames(_ games: [MainHomeGame]) -> [MainHomeGame] {
        games.filter { game in
            matchesSelectedFilterOption(makeStatusStyle(from: game.statusDescription))
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
            return "No games available."

        case .live, .upcoming, .finished:
            return "No \(selectedFilterOption.title.lowercased()) games available."
        }
    }

    // MARK: - Merging

    private func mergeGames(
        liveGames: [MainHomeGame],
        todayGames: [MainHomeGame]
    ) -> [MainHomeGame] {
        var seenGameIDs = Set<Int>()
        var mergedGames: [MainHomeGame] = []

        for game in liveGames + todayGames where seenGameIDs.insert(game.id).inserted {
            mergedGames.append(game)
        }

        return mergedGames
    }

    // MARK: - League Grouping

    private func makeLeagueSections(
        from games: [MainHomeGame],
        fallbackSystemImageName: String
    ) -> [MainHomeSectionViewData] {
        var orderedLeagueNames: [String] = []
        var gamesByLeagueName: [String: [MainHomeGame]] = [:]
        var leagueLogoURLsByName: [String: URL] = [:]

        for game in games {
            let leagueName = game.leagueName

            if gamesByLeagueName[leagueName] == nil {
                orderedLeagueNames.append(leagueName)
                if let leagueLogoURL = game.leagueLogoURL {
                    leagueLogoURLsByName[leagueName] = leagueLogoURL
                }
            }

            gamesByLeagueName[leagueName, default: []].append(game)
        }

        let leagueSections: [MainHomeSectionViewData] = orderedLeagueNames.compactMap { leagueName in
            guard let leagueGames = gamesByLeagueName[leagueName],
                  !leagueGames.isEmpty else {
                return nil as MainHomeSectionViewData?
            }

            return MainHomeSectionViewData(
                title: leagueName,
                logoURL: leagueLogoURLsByName[leagueName],
                fallbackSystemImageName: fallbackSystemImageName,
                items: leagueGames.map(makeGameViewData)
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
