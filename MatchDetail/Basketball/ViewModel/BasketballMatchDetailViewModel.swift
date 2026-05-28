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

    // MARK: - Types

    private enum MatchStatus: Equatable {
        case live(quarterText: String?)
        case scheduled
        case tbd
        case halfTime
        case overtime
        case breakTime
        case final
        case postponed
        case cancelled
        case unknown

        var displayText: String {
            switch self {
            case .live(let quarterText):
                return quarterText ?? "Live"
            case .scheduled:
                return "Scheduled"
            case .tbd:
                return "TBD"
            case .halfTime:
                return "Half Time"
            case .overtime:
                return "Overtime"
            case .breakTime:
                return "Break"
            case .final:
                return "Final"
            case .postponed:
                return "Postponed"
            case .cancelled:
                return "Cancelled"
            case .unknown:
                return "Scheduled"
            }
        }

        var style: BasketballMatchDetailHeaderStatusStyle {
            switch self {
            case .live:
                return .live
            case .final:
                return .final
            case .scheduled, .tbd:
                return .upcoming
            case .postponed:
                return .postponed
            case .cancelled:
                return .cancelled
            case .halfTime, .overtime, .breakTime, .unknown:
                return .neutral
            }
        }
    }

    // MARK: - Properties

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

    // MARK: - Initialization

    init(
        gameID: Int,
        detailService: BasketballMatchDetailServicing
    ) {
        self.gameID = gameID
        self.detailService = detailService
    }

    // MARK: - Actions

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

    // MARK: - Presentation Builders

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
        let statusStyle = makeStatusStyle(from: fixture)
        let statusText = makeStatusText(from: fixture)

        return BasketballMatchDetailHeaderViewData(
            leagueName: fixture.leagueName,
            leagueLogoURL: fixture.leagueLogoURL,
            statusText: statusText,
            statusStyle: statusStyle,
            navigationBadgeViewData: makeNavigationBadgeViewData(
                text: statusText,
                statusStyle: statusStyle
            ),
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

    // MARK: - Status Mapping

    private func makeStatusText(from fixture: BasketballMatchFixtureDetail) -> String {
        let matchStatus = makeMatchStatus(from: fixture)
        if case .unknown = matchStatus {
            if let statusLong = fixture.statusLong,
               !statusLong.isEmpty {
                return statusLong
            }

            return fixture.statusShort ?? "Scheduled"
        }

        return matchStatus.displayText
    }

    private func makeStatusStyle(from fixture: BasketballMatchFixtureDetail) -> BasketballMatchDetailHeaderStatusStyle {
        makeMatchStatus(from: fixture).style
    }

    // MARK: - Navigation Badge

    private func makeNavigationBadgeViewData(
        text: String,
        statusStyle: BasketballMatchDetailHeaderStatusStyle
    ) -> MatchDetailNavigationBadgeViewData {
        MatchDetailNavigationBadgeViewData(
            text: text,
            style: makeNavigationStatusStyle(from: statusStyle)
        )
    }

    private func makeNavigationStatusStyle(
        from statusStyle: BasketballMatchDetailHeaderStatusStyle
    ) -> MatchDetailNavigationStatusStyle {
        switch statusStyle {
        case .live:
            return .live
        case .final:
            return .final
        case .upcoming:
            return .upcoming
        case .postponed:
            return .postponed
        case .cancelled:
            return .cancelled
        case .neutral:
            return .neutral
        }
    }

    // MARK: - Match Status Parsing

    private func makeMatchStatus(from fixture: BasketballMatchFixtureDetail) -> MatchStatus {
        guard let normalizedStatus = fixture.statusShort?.lowercased() ?? fixture.statusLong?.lowercased() else {
            return .unknown
        }

        if isLiveStatus(normalizedStatus) {
            return .live(quarterText: makeQuarterText(from: normalizedStatus))
        }

        switch normalizedStatus {
        case "ns", "not started":
            return .scheduled
        case "tbd":
            return .tbd
        case "ht", "half time":
            return .halfTime
        case "ot", "overtime":
            return .overtime
        case "bt", "break time":
            return .breakTime
        case "ft", "aot", "after overtime", "final":
            return .final
        case "pst", "postponed":
            return .postponed
        case "canc", "cancelled", "abd", "abandoned", "susp", "suspended":
            return .cancelled
        default:
            return .unknown
        }
    }

    // MARK: - Helpers

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
