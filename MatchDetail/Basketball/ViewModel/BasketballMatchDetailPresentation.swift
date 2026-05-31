//
//  BasketballMatchDetailPresentation.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/27.
//

import Foundation

// MARK: - Presentation

nonisolated struct BasketballMatchDetailPresentation: Equatable, Sendable {

    let title: String
    let sections: [BasketballMatchDetailSectionViewData]

    var headerViewData: BasketballMatchDetailHeaderViewData? {
        sections.compactMap(\.headerViewData).first
    }
}

// MARK: - Sections

nonisolated enum BasketballMatchDetailSectionViewData: Equatable, Sendable {

    case header(BasketballMatchDetailHeaderViewData)
    case stats(BasketballMatchDetailStatsViewData)

    var headerViewData: BasketballMatchDetailHeaderViewData? {
        guard case .header(let viewData) = self else {
            return nil
        }

        return viewData
    }
}

// MARK: - Header

nonisolated struct BasketballMatchDetailHeaderViewData: Equatable, Sendable {

    let leagueName: String
    let leagueLogoURL: URL?
    let statusText: String
    let statusStyle: BasketballMatchDetailHeaderStatusStyle
    let navigationBadgeViewData: MatchDetailNavigationBadgeViewData
    let timeText: String
    let homeTeamName: String
    let homeTeamLogoURL: URL?
    let awayTeamName: String
    let awayTeamLogoURL: URL?
    let homeScoreText: String
    let awayScoreText: String
    let venue: BasketballMatchDetailVenueViewData?
}

nonisolated enum BasketballMatchDetailHeaderStatusStyle: Equatable, Sendable {

    case live
    case final
    case upcoming
    case postponed
    case cancelled
    case neutral
}

// MARK: - Venue

nonisolated struct BasketballMatchDetailVenueViewData: Equatable, Sendable {

    let venueText: String
}

// MARK: - Stats

nonisolated enum BasketballMatchFilterOption: Int, CaseIterable, Equatable, Sendable {

    case total
    case home
    case away

    var title: String {
        switch self {
        case .total:
            return "Game Total"
        case .home:
            return "Home"
        case .away:
            return "Away"
        }
    }
}

nonisolated struct BasketballMatchDetailStatsViewData: Equatable, Sendable {

    let homeTeamName: String
    let awayTeamName: String
    let displayState: MatchDetailStatsDisplayState
    let showsFilter: Bool
    let comparisonRows: [BasketballMatchStatsComparisonRowViewData]
    let homeRows: [BasketballMatchStatsValueRowViewData]
    let awayRows: [BasketballMatchStatsValueRowViewData]

    func itemCount(for filter: BasketballMatchFilterOption) -> Int {
        switch displayState {
        case .empty:
            return 1

        case .content:
            let rowCount = rowCount(for: filter)
            return rowCount > 0 ? rowCount : 1
        }
    }

    func hasContent(for filter: BasketballMatchFilterOption) -> Bool {
        switch displayState {
        case .empty:
            return false

        case .content:
            return rowCount(for: filter) > 0
        }
    }

    func rowContent(
        at index: Int,
        filter: BasketballMatchFilterOption
    ) -> BasketballMatchStatsRowContent? {
        switch filter {
        case .total:
            guard comparisonRows.indices.contains(index) else {
                return nil
            }

            return .comparison(comparisonRows[index])

        case .home:
            guard homeRows.indices.contains(index) else {
                return nil
            }

            return .value(homeRows[index])

        case .away:
            guard awayRows.indices.contains(index) else {
                return nil
            }

            return .value(awayRows[index])
        }
    }

    var emptyCellText: (title: String, subtitle: String?) {
        switch displayState {
        case .empty(let title, let subtitle):
            return (title, subtitle)

        case .content:
            return (
                "No Stats Available",
                "Team statistics are not available for this game."
            )
        }
    }

    private func rowCount(for filter: BasketballMatchFilterOption) -> Int {
        switch filter {
        case .total:
            return comparisonRows.count
        case .home:
            return homeRows.count
        case .away:
            return awayRows.count
        }
    }
}

nonisolated enum BasketballMatchStatsRowContent: Equatable, Sendable {

    case comparison(BasketballMatchStatsComparisonRowViewData)
    case value(BasketballMatchStatsValueRowViewData)
}

nonisolated struct BasketballMatchStatsComparisonRowViewData: Equatable, Identifiable, Sendable {

    var id: String { title }

    let title: String
    let homeValue: String
    let awayValue: String
    let homeRatio: Double
    let awayRatio: Double
}

nonisolated struct BasketballMatchStatsValueRowViewData: Equatable, Identifiable, Sendable {

    var id: String { title }

    let title: String
    let value: String
}
