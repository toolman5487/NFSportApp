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
        let statusShort = fixture.statusShort?.lowercased()
        let statusLong = fixture.statusLong?.lowercased()
        let normalizedStatus = statusShort ?? statusLong

        if let normalizedStatus,
           isLiveStatus(normalizedStatus) {
            if let quarterText = makeQuarterText(from: normalizedStatus) {
                return quarterText
            }

            return "Live"
        }

        guard let normalizedStatus else {
            return "Scheduled"
        }

        switch normalizedStatus {
        case "ns", "not started":
            return "Scheduled"
        case "tbd":
            return "TBD"
        case "ht", "half time":
            return "Half Time"
        case "ot", "overtime":
            return "Overtime"
        case "bt", "break time":
            return "Break"
        case "ft", "aot", "after overtime", "final":
            return "Final"
        case "pst", "postponed":
            return "Postponed"
        case "canc", "cancelled", "abd", "abandoned", "susp", "suspended":
            return "Cancelled"
        default:
            if let statusLong,
               !statusLong.isEmpty {
                return fixture.statusLong ?? "Scheduled"
            }

            return fixture.statusShort ?? "Scheduled"
        }
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

        case let status where status.contains("postponed")
            || status == "pst":
            return .postponed

        case let status where status.contains("cancel")
            || status.contains("abandoned")
            || status.contains("suspended")
            || status == "abd"
            || status == "canc"
            || status == "susp":
            return .cancelled

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

    private func makeQuarterText(from status: String) -> String? {
        switch status {
        case let value where value.contains("q1"):
            return "Q1"
        case let value where value.contains("q2"):
            return "Q2"
        case let value where value.contains("q3"):
            return "Q3"
        case let value where value.contains("q4"):
            return "Q4"
        case let value where value.contains("ot"):
            return "OT"
        default:
            return nil
        }
    }

    private func makeVenueSection(from fixture: BasketballMatchFixtureDetail) -> BasketballMatchDetailVenueViewData? {
        guard let venueName = fixture.venueName?.trimmingCharacters(in: .whitespacesAndNewlines),
              !venueName.isEmpty else {
            return nil
        }

        return BasketballMatchDetailVenueViewData(venueText: venueName)
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
