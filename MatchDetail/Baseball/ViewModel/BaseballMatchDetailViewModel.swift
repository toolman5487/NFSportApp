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

    // MARK: - Properties

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

    // MARK: - Initialization

    init(
        gameID: Int,
        detailService: BaseballMatchDetailServicing
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
                message: "Baseball match detail loading failed",
                metadata: "gameID=\(gameID)"
            )
        }
    }

    // MARK: - Presentation Builders

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
        let statusStyle = makeStatusStyle(from: fixture)
        let statusText = makeStatusText(from: fixture)

        return BaseballMatchDetailHeaderViewData(
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

    // MARK: - Navigation Badge

    private func makeNavigationStatusStyle(
        from statusStyle: BaseballMatchDetailHeaderStatusStyle
    ) -> MatchDetailNavigationStatusStyle {
        switch statusStyle {
        case .live:
            return .live
        case .final:
            return .final
        case .upcoming:
            return .upcoming
        case .neutral:
            return .neutral
        }
    }

    private func makeNavigationBadgeViewData(
        text: String,
        statusStyle: BaseballMatchDetailHeaderStatusStyle
    ) -> MatchDetailNavigationBadgeViewData {
        MatchDetailNavigationBadgeViewData(
            text: text,
            style: makeNavigationStatusStyle(from: statusStyle)
        )
    }

    // MARK: - Status Mapping

    private func makeStatusText(from fixture: BaseballMatchFixtureDetail) -> String {
        let statusShort = fixture.statusShort?.lowercased()
        let statusLong = fixture.statusLong?.lowercased()
        let normalizedStatus = statusShort ?? statusLong

        if let normalizedStatus,
           isLiveStatus(normalizedStatus) {
            return "Live"
        }

        guard let normalizedStatus else {
            return "Scheduled"
        }

        switch normalizedStatus {
        case "ns", "not started":
            return "Scheduled"
        case "tbd", "time to be defined":
            return "TBD"
        case "ht", "half time":
            return "Half Time"
        case "et", "extra time":
            return "Extra Time"
        case "bt", "break time":
            return "Break"
        case "p", "pen", "penalty in progress":
            return "Penalties"
        case "ft", "aet", "aft", "aot", "after overtime", "final", "match finished":
            return "Final"
        case "pst", "postponed":
            return "Postponed"
        case "canc", "cancelled", "abandoned", "abd":
            return "Cancelled"
        case "int", "interrupted", "susp", "suspended":
            return "Suspended"
        default:
            if let statusLong,
               !statusLong.isEmpty {
                return fixture.statusLong ?? "Scheduled"
            }

            return fixture.statusShort ?? "Scheduled"
        }
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

    // MARK: - Helpers

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

