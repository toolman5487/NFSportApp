//
//  BasketballMatchDetailViewModel.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/27.
//

import Foundation

// MARK: - State

nonisolated enum BasketballMatchDetailViewState: Equatable, Sendable {

    case idle
    case loading
    case loaded(BasketballMatchDetailPresentation)
    case failed(message: String)
}

// MARK: - BasketballMatchDetailViewModel

@MainActor
final class BasketballMatchDetailViewModel {

    private(set) var state: BasketballMatchDetailViewState = .idle {
        didSet {
            onStateChange?(state)
        }
    }

    var onStateChange: ((BasketballMatchDetailViewState) -> Void)?

    var title: String {
        "Match Detail"
    }

    private let gameID: Int
    private let detailService: BasketballMatchDetailServicing
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = .current
        calendar.timeZone = .current
        return calendar
    }()

    init(
        gameID: Int,
        detailService: BasketballMatchDetailServicing
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
                message: "Basketball match detail loading failed",
                metadata: "gameID=\(gameID)"
            )
        }
    }

    private func makePresentation(from detail: BasketballMatchDetail) -> BasketballMatchDetailPresentation {
        let sections: [BasketballMatchDetailSectionViewData] = [
            .header(makeHeaderViewData(from: detail.fixture))
        ]

        return BasketballMatchDetailPresentation(
            title: detail.fixture.leagueName,
            sections: sections
        )
    }

    private func makeHeaderViewData(from fixture: BasketballMatchFixtureDetail) -> BasketballMatchDetailHeaderViewData {
        BasketballMatchDetailHeaderViewData(
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

    private func makeStatusText(from fixture: BasketballMatchFixtureDetail) -> String {
        if let statusShort = fixture.statusShort,
           isLiveStatus(statusShort.lowercased()) {
            return statusShort
        }

        return fixture.statusShort ?? fixture.statusLong ?? "Scheduled"
    }

    private func makeStatusStyle(from fixture: BasketballMatchFixtureDetail) -> BasketballMatchDetailHeaderStatusStyle {
        let normalizedStatus = fixture.statusShort?.lowercased() ?? fixture.statusLong?.lowercased()

        guard let normalizedStatus else {
            return .neutral
        }

        if isLiveStatus(normalizedStatus) {
            return .live
        }

        switch normalizedStatus {
        case let status where status.contains("ft")
            || status.contains("aot")
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
        status.contains("q1")
            || status.contains("q2")
            || status.contains("q3")
            || status.contains("q4")
            || status.contains("ot")
            || status.contains("bt")
            || status.contains("ht")
            || status.contains("live")
            || status.contains("half")
    }

    private func makeVenueSection(from fixture: BasketballMatchFixtureDetail) -> BasketballMatchDetailVenueViewData {
        let venueName = fixture.venueName?.trimmingCharacters(in: .whitespacesAndNewlines)
        return BasketballMatchDetailVenueViewData(
            title: "Venue",
            venueText: venueName?.isEmpty == false ? venueName ?? "TBD" : "TBD"
        )
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
