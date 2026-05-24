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
    case empty(message: String)
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

    let selectedSport: SportType

    private let homeService: MainHomeServicing

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
            let presentation = makePresentation(from: dashboard)

            state = presentation.sections.isEmpty
                ? .empty(message: "No games available.")
                : .loaded(presentation)
        } catch {
            state = .failed(message: error.localizedDescription)
            AppLogger.logUIError(
                error,
                message: "Main home loading failed",
                metadata: "sport=\(selectedSport.id)"
            )
        }
    }

    // MARK: - Private Methods

    private func makePresentation(from dashboard: MainHomeDashboard) -> MainHomePresentation {
        let games = mergeGames(
            liveGames: dashboard.liveGames,
            todayGames: dashboard.todayGames
        )
        let sections = makeLeagueSections(from: games)

        return MainHomePresentation(
            title: dashboard.sport.title,
            sections: sections
        )
    }

    private func makeGameViewData(from game: MainHomeGame) -> MainHomeGameViewData {
        MainHomeGameViewData(
            id: game.id,
            awayTeamName: game.awayTeamName,
            homeTeamName: game.homeTeamName,
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

    private func makeLeagueSections(from games: [MainHomeGame]) -> [MainHomeSectionViewData] {
        var orderedLeagueNames: [String] = []
        var gamesByLeagueName: [String: [MainHomeGame]] = [:]

        for game in games {
            let leagueName = game.leagueName

            if gamesByLeagueName[leagueName] == nil {
                orderedLeagueNames.append(leagueName)
            }

            gamesByLeagueName[leagueName, default: []].append(game)
        }

        return orderedLeagueNames.compactMap { leagueName in
            guard let leagueGames = gamesByLeagueName[leagueName],
                  !leagueGames.isEmpty else {
                return nil
            }

            return MainHomeSectionViewData(
                title: leagueName,
                items: leagueGames.map(makeGameViewData)
            )
        }
    }
}
