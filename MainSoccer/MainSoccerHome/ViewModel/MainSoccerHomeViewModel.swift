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
    case loading
    case loaded(MainSoccerHomePresentation)
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
        state = .loading

        do {
            let dashboard = try await homeService.fetchDashboard(
                for: selectedSport,
                date: Date()
            )
            state = .loaded(makePresentation(from: dashboard))
        } catch {
            state = .failed(message: error.localizedDescription)
            AppLogger.logUIError(
                error,
                message: "Main soccer home loading failed",
                metadata: "sport=\(selectedSport.id)"
            )
        }
    }

    // MARK: - Presentation Mapping

    private func makePresentation(from dashboard: MainSoccerHomeDashboard) -> MainSoccerHomePresentation {
        MainSoccerHomePresentation(
            title: dashboard.sport.title,
            sections: [
                makeLiveMatchesSection(from: dashboard.liveFixtures),
                makeTodaySection(from: dashboard.todayFixtures)
            ]
        )
    }

    private func makeLiveMatchesSection(from fixtures: [MainSoccerFixture]) -> MainSoccerHomeSection {
        let liveFixtures = fixtures.map(makeLiveMatchViewData)
        let state: MainSoccerLiveMatchesViewData.State

        switch liveFixtures.isEmpty {
        case true:
            state = .empty(message: "No live matches")

        case false:
            state = .loaded(Array(liveFixtures))
        }

        return .liveMatches(
            MainSoccerLiveMatchesViewData(
                title: "Live Matches",
                state: state
            )
        )
    }

    private func makeTodaySection(from fixtures: [MainSoccerFixture]) -> MainSoccerHomeSection {
        let todayFixtures = fixtures.map(makeFixtureViewData)
        let state: MainSoccerTodayFixturesViewData.State

        switch todayFixtures.isEmpty {
        case true:
            state = .empty(message: "No fixtures today")

        case false:
            state = .loaded(Array(todayFixtures))
        }

        return .today(
            MainSoccerTodayFixturesViewData(
                title: "Today",
                state: state
            )
        )
    }

    // MARK: - Item Mapping

    private func makeLiveMatchViewData(from fixture: MainSoccerFixture) -> MainSoccerLiveMatchViewData {
        MainSoccerLiveMatchViewData(
            minuteText: makeMinuteText(from: fixture),
            leagueName: fixture.leagueName,
            homeTeamName: fixture.homeTeamName,
            homeTeamLogoURL: fixture.homeTeamLogoURL,
            awayTeamName: fixture.awayTeamName,
            awayTeamLogoURL: fixture.awayTeamLogoURL,
            scoreText: makeScoreText(from: fixture)
        )
    }

    private func makeFixtureViewData(from fixture: MainSoccerFixture) -> MainSoccerFixtureViewData {
        MainSoccerFixtureViewData(
            timeText: makeFixtureTimeText(from: fixture),
            leagueName: fixture.leagueName,
            homeTeamName: fixture.homeTeamName,
            homeTeamLogoURL: fixture.homeTeamLogoURL,
            awayTeamName: fixture.awayTeamName,
            awayTeamLogoURL: fixture.awayTeamLogoURL,
            homeScoreText: fixture.homeScore?.description ?? "-",
            awayScoreText: fixture.awayScore?.description ?? "-",
            statusText: makeFixtureStatusText(from: fixture),
            statusStyle: makeStatusStyle(from: fixture)
        )
    }

    // MARK: - Text Formatting

    private func makeMinuteText(from fixture: MainSoccerFixture) -> String {
        if let elapsedMinute = fixture.elapsedMinute {
            return "\(elapsedMinute)'"
        }

        return fixture.statusShort ?? fixture.statusLong ?? "Live"
    }

    private func makeScoreText(from fixture: MainSoccerFixture) -> String {
        "\(fixture.homeScore?.description ?? "-") - \(fixture.awayScore?.description ?? "-")"
    }

    private func makeFixtureTimeText(from fixture: MainSoccerFixture) -> String {
        guard makeStatusStyle(from: fixture) == .upcoming else {
            return fixture.statusShort ?? fixture.statusLong ?? "Live"
        }

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

    private func makeStatusStyle(from fixture: MainSoccerFixture) -> MainSoccerFixtureStatusStyle {
        guard let statusShort = fixture.statusShort else {
            return .neutral
        }

        switch statusShort {
        case "1H", "HT", "2H", "ET", "BT", "P", "SUSP", "INT":
            return .live

        case "NS", "TBD":
            return .upcoming

        case "FT", "AET", "PEN", "PST", "CANC", "ABD", "AWD", "WO":
            return .final

        default:
            return .neutral
        }
    }
}
