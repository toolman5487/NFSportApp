//
//  HockeyMatchDetailViewModel.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/28.
//

import Foundation

// MARK: - State

nonisolated enum HockeyMatchDetailViewState: Equatable, Sendable {

    case idle
    case loading
    case loaded(HockeyMatchDetailPresentation)
    case failed(message: String)
}

// MARK: - HockeyMatchDetailViewModel

@MainActor
final class HockeyMatchDetailViewModel {

    // MARK: - Types

    private enum MatchStatus: Equatable {
        case live(periodText: String?)
        case scheduled
        case tbd
        case intermission
        case overtime
        case final
        case postponed
        case cancelled
        case unknown

        var displayText: String {
            switch self {
            case .live(let periodText):
                return periodText ?? "Live"
            case .scheduled:
                return "Scheduled"
            case .tbd:
                return "TBD"
            case .intermission:
                return "Intermission"
            case .overtime:
                return "Overtime"
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

        var style: HockeyMatchDetailHeaderStatusStyle {
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
            case .intermission, .overtime, .unknown:
                return .neutral
            }
        }
    }

    // MARK: - Properties

    private(set) var state: HockeyMatchDetailViewState = .idle {
        didSet {
            onStateChange?(state)
        }
    }

    var onStateChange: ((HockeyMatchDetailViewState) -> Void)?

    var title: String {
        "Match Detail"
    }

    private let gameID: Int
    private let detailService: HockeyMatchDetailServicing
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = .current
        calendar.timeZone = .current
        return calendar
    }()

    // MARK: - Initialization

    init(
        gameID: Int,
        detailService: HockeyMatchDetailServicing
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
                message: "Hockey match detail loading failed",
                metadata: "gameID=\(gameID)"
            )
        }
    }

    // MARK: - Presentation Builders

    private func makePresentation(from detail: HockeyMatchDetail) -> HockeyMatchDetailPresentation {
        let sections: [HockeyMatchDetailSectionViewData] = [
            .header(makeHeaderViewData(from: detail.fixture))
        ]

        return HockeyMatchDetailPresentation(
            title: detail.fixture.leagueName,
            sections: sections
        )
    }

    private func makeHeaderViewData(from fixture: HockeyMatchFixtureDetail) -> HockeyMatchDetailHeaderViewData {
        let statusStyle = makeStatusStyle(from: fixture)
        let statusText = makeStatusText(from: fixture)

        return HockeyMatchDetailHeaderViewData(
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

    private func makeStatusText(from fixture: HockeyMatchFixtureDetail) -> String {
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

    private func makeStatusStyle(from fixture: HockeyMatchFixtureDetail) -> HockeyMatchDetailHeaderStatusStyle {
        makeMatchStatus(from: fixture).style
    }

    // MARK: - Navigation Badge

    private func makeNavigationBadgeViewData(
        text: String,
        statusStyle: HockeyMatchDetailHeaderStatusStyle
    ) -> MatchDetailNavigationBadgeViewData {
        MatchDetailNavigationBadgeViewData(
            text: text,
            style: makeNavigationStatusStyle(from: statusStyle)
        )
    }

    private func makeNavigationStatusStyle(
        from statusStyle: HockeyMatchDetailHeaderStatusStyle
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

    private func makeMatchStatus(from fixture: HockeyMatchFixtureDetail) -> MatchStatus {
        guard let normalizedStatus = fixture.statusShort?.lowercased() ?? fixture.statusLong?.lowercased() else {
            return .unknown
        }

        if isLiveStatus(normalizedStatus) {
            return .live(periodText: makePeriodText(from: normalizedStatus))
        }

        switch normalizedStatus {
        case "ns", "not started":
            return .scheduled
        case "tbd":
            return .tbd
        case "int", "intermission":
            return .intermission
        case "ot", "overtime":
            return .overtime
        case "ft", "final":
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
        status.contains("p1")
            || status.contains("p2")
            || status.contains("p3")
            || status.contains("ot")
            || status.contains("live")
            || status.contains("in progress")
    }

    private func makePeriodText(from status: String) -> String? {
        switch status {
        case let value where value.contains("p1"):
            return "P1"
        case let value where value.contains("p2"):
            return "P2"
        case let value where value.contains("p3"):
            return "P3"
        case let value where value.contains("ot"):
            return "OT"
        default:
            return nil
        }
    }

    private func makeVenueSection(from fixture: HockeyMatchFixtureDetail) -> HockeyMatchDetailVenueViewData? {
        guard let venueName = fixture.venueName?.trimmingCharacters(in: .whitespacesAndNewlines),
              !venueName.isEmpty else {
            return nil
        }

        return HockeyMatchDetailVenueViewData(venueText: venueName)
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

