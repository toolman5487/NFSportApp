//
//  BaseballMatchDetailViewModel.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/28.
//

import Foundation

// MARK: - State

nonisolated enum BaseballMatchDetailViewState: Equatable, Sendable {

    case idle
    case loading
    case loaded(BaseballMatchDetailPresentation)
    case failed(message: String)
}

// MARK: - BaseballMatchDetailViewModel

@MainActor
final class BaseballMatchDetailViewModel {

    private(set) var state: BaseballMatchDetailViewState = .idle {
        didSet {
            onStateChange?(state)
        }
    }

    var onStateChange: ((BaseballMatchDetailViewState) -> Void)?

    var title: String {
        "Match Detail"
    }

    private let gameID: Int
    private let detailService: BaseballMatchDetailServicing
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = .current
        calendar.timeZone = .current
        return calendar
    }()

    init(
        gameID: Int,
        detailService: BaseballMatchDetailServicing
    ) {
        self.gameID = gameID
        self.detailService = detailService
    }

    func loadMatchDetail() async {
        state = .loading

        do {
            let detail = try await detailService.fetchMatchDetail(gameID: gameID)
            state = .loaded(makePresentation(from: detail))
        } catch {
            state = .failed(message: error.localizedDescription)
            AppLogger.logUIError(
                error,
                message: "Baseball match detail loading failed",
                metadata: "gameID=\(gameID)"
            )
        }
    }

    private func makePresentation(from detail: BaseballMatchDetail) -> BaseballMatchDetailPresentation {
        let sections: [BaseballMatchDetailSectionViewData] = [
            .header(makeHeaderViewData(from: detail.fixture))
        ]

        return BaseballMatchDetailPresentation(
            title: detail.fixture.leagueName,
            sections: sections
        )
    }

    private func makeHeaderViewData(from fixture: BaseballMatchFixtureDetail) -> BaseballMatchDetailHeaderViewData {
        BaseballMatchDetailHeaderViewData(
            leagueName: fixture.leagueName,
            leagueLogoURL: fixture.leagueLogoURL,
            statusText: makeStatusText(from: fixture),
            statusStyle: makeStatusStyle(from: fixture),
            timeText: makeTimeText(
                from: fixture.scheduledStartDate,
                fallback: fixture.scheduledStartText ?? "TBD"
            ),
            homeTeamName: fixture.homeTeam.name,
            homeTeamLogoURL: fixture.homeTeam.logoURL,
            awayTeamName: fixture.awayTeam.name,
            awayTeamLogoURL: fixture.awayTeam.logoURL,
            homeScoreText: fixture.score.home.map(String.init) ?? "-",
            awayScoreText: fixture.score.away.map(String.init) ?? "-",
            venue: makeVenueSection(from: fixture)
        )
    }

    private func makeStatusText(from fixture: BaseballMatchFixtureDetail) -> String {
        if let statusShort = fixture.statusShort,
           isLiveStatus(statusShort.lowercased()) {
            return statusShort
        }

        return fixture.statusShort ?? fixture.statusLong ?? "Scheduled"
    }

    private func makeStatusStyle(from fixture: BaseballMatchFixtureDetail) -> BaseballMatchDetailHeaderStatusStyle {
        let normalizedStatus = fixture.statusShort?.lowercased() ?? fixture.statusLong?.lowercased()

        guard let normalizedStatus else {
            return .neutral
        }

        if isLiveStatus(normalizedStatus) {
            return .live
        }

        switch normalizedStatus {
        case let status where status.contains("ft")
            || status.contains("finish")
            || status.contains("final")
            || status.contains("ended")
            || status.contains("after"):
            return .final

        case let status where status.contains("ns")
            || status.contains("scheduled")
            || status.contains("not started")
            || status.contains("tbd"):
            return .upcoming

        default:
            return .neutral
        }
    }

    private func isLiveStatus(_ status: String) -> Bool {
        status.contains("live")
            || status.contains("in progress")
            || status.contains("inning")
            || status.contains("top")
            || status.contains("bottom")
            || status.contains("half")
    }

    private func makeVenueSection(from fixture: BaseballMatchFixtureDetail) -> BaseballMatchDetailVenueViewData? {
        guard let venueName = fixture.venueName?.trimmingCharacters(in: .whitespacesAndNewlines),
              !venueName.isEmpty else {
            return nil
        }

        return BaseballMatchDetailVenueViewData(venueText: venueName)
    }

    private func makeTimeText(from date: Date?, fallback: String) -> String {
        guard let date else {
            return fallback
        }

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = .current
        formatter.timeStyle = .short
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

