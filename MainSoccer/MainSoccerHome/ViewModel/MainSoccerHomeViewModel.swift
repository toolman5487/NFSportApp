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

    // MARK: - Constants

    private enum DisplayLimit {
        static let liveFixtures = 3
        static let todayFixtures = 6
        static let standings = 5
    }

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
                makeTodaySection(from: dashboard.todayFixtures),
                makeTopLeaguesSection(from: dashboard.topLeagues),
                makeStandingsSection(
                    title: dashboard.standingsTitle,
                    standings: dashboard.standings
                )
            ]
        )
    }

    private func makeLiveMatchesSection(from fixtures: [MainSoccerFixture]) -> MainSoccerHomeSection {
        let liveFixtures = fixtures.prefix(DisplayLimit.liveFixtures).map(makeLiveMatchViewData)
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
                badgeText: "\(fixtures.count) Live",
                state: state
            )
        )
    }

    private func makeTodaySection(from fixtures: [MainSoccerFixture]) -> MainSoccerHomeSection {
        let todayFixtures = fixtures.prefix(DisplayLimit.todayFixtures).map(makeFixtureViewData)
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

    private func makeTopLeaguesSection(from leagues: [MainSoccerLeague]) -> MainSoccerHomeSection {
        .topLeagues(
            MainSoccerTopLeaguesViewData(
                title: "Top Leagues",
                leagues: leagues.map(makeTopLeagueViewData)
            )
        )
    }

    private func makeStandingsSection(
        title: String?,
        standings: [MainSoccerStandingRow]
    ) -> MainSoccerHomeSection {
        let rows = standings.prefix(DisplayLimit.standings).map(makeStandingRowViewData)
        let state: MainSoccerStandingsViewData.State

        switch rows.isEmpty {
        case true:
            state = .empty(message: "No standings available")

        case false:
            state = .loaded(Array(rows))
        }

        return .standings(
            MainSoccerStandingsViewData(
                title: title ?? "Standings",
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
            awayTeamName: fixture.awayTeamName,
            scoreText: makeScoreText(from: fixture)
        )
    }

    private func makeFixtureViewData(from fixture: MainSoccerFixture) -> MainSoccerFixtureViewData {
        MainSoccerFixtureViewData(
            timeText: makeFixtureTimeText(from: fixture),
            leagueName: fixture.leagueName,
            homeTeamName: fixture.homeTeamName,
            awayTeamName: fixture.awayTeamName
        )
    }

    private func makeTopLeagueViewData(from league: MainSoccerLeague) -> MainSoccerTopLeagueViewData {
        MainSoccerTopLeagueViewData(
            name: league.name,
            region: league.countryName ?? "International",
            logoURL: league.logoURL,
            systemImageName: "trophy.fill"
        )
    }

    private func makeStandingRowViewData(from standing: MainSoccerStandingRow) -> MainSoccerStandingRowViewData {
        MainSoccerStandingRowViewData(
            rankText: "\(standing.rank)",
            teamName: standing.teamName,
            recordText: makeRecordText(from: standing),
            pointsText: "\(standing.points)"
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

    private func makeRecordText(from standing: MainSoccerStandingRow) -> String {
        let recordText: String

        switch (standing.wins, standing.draws, standing.losses) {
        case (.some(let wins), .some(let draws), .some(let losses)):
            recordText = "\(wins)-\(draws)-\(losses)"

        default:
            recordText = "\(standing.played ?? 0) played"
        }

        guard let goalsDifference = standing.goalsDifference else {
            return recordText
        }

        return "\(recordText) | GD \(goalsDifference)"
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
            return .finished

        default:
            return .neutral
        }
    }
}

// MARK: - Fixture Status Style

private enum MainSoccerFixtureStatusStyle {
    case live
    case upcoming
    case finished
    case neutral
}
