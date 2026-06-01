//
//  BaseballMatchDetailPresentation.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/28.
//

import Foundation

// MARK: - Presentation

nonisolated struct BaseballMatchDetailPresentation: Equatable, Sendable {

    let title: String
    let sections: [BaseballMatchDetailSectionViewData]

    var headerViewData: BaseballMatchDetailHeaderViewData? {
        sections.compactMap(\.headerViewData).first
    }
}

// MARK: - Sections

nonisolated enum BaseballMatchDetailSectionViewData: Equatable, Sendable {

    case header(BaseballMatchDetailHeaderViewData)
    case stats(BaseballMatchDetailStatsViewData)

    var headerViewData: BaseballMatchDetailHeaderViewData? {
        guard case .header(let viewData) = self else {
            return nil
        }

        return viewData
    }
}

// MARK: - Header

nonisolated struct BaseballMatchDetailHeaderViewData: Equatable, Sendable {

    let leagueName: String
    let leagueLogoURL: URL?
    let statusText: String
    let statusStyle: BaseballMatchDetailHeaderStatusStyle
    let navigationBadgeViewData: MatchDetailNavigationBadgeViewData
    let timeText: String
    let homeTeamName: String
    let homeTeamLogoURL: URL?
    let awayTeamName: String
    let awayTeamLogoURL: URL?
    let homeScoreText: String
    let awayScoreText: String
    let venue: BaseballMatchDetailVenueViewData?
}

nonisolated enum BaseballMatchDetailHeaderStatusStyle: Equatable, Sendable {

    case live
    case final
    case upcoming
    case neutral
}

// MARK: - Venue

nonisolated struct BaseballMatchDetailVenueViewData: Equatable, Sendable {

    let venueText: String
}

// MARK: - Stats

nonisolated enum BaseballMatchFilterOption: Int, CaseIterable, Equatable, Sendable {

    case total
    case home
    case away

    func title(homeTeamName: String?, awayTeamName: String?) -> String {
        switch self {
        case .total:
            return "Game Total"
        case .home:
            return homeTeamName ?? "Home"
        case .away:
            return awayTeamName ?? "Away"
        }
    }
}

nonisolated struct BaseballMatchDetailStatsViewData: Equatable, Sendable {

    let homeTeamName: String
    let awayTeamName: String
    let displayState: MatchDetailStatsDisplayState
    let showsFilter: Bool
    let comparisonRows: [BaseballMatchStatsComparisonRowViewData]
    let homeRows: [BaseballMatchStatsValueRowViewData]
    let awayRows: [BaseballMatchStatsValueRowViewData]

    func hasContent(for filter: BaseballMatchFilterOption) -> Bool {
        switch displayState {
        case .empty:
            return false

        case .content:
            return rowCount(for: filter) > 0
        }
    }

    func resultContents(for filter: BaseballMatchFilterOption) -> [BaseballMatchStatsResultContent] {
        switch filter {
        case .total:
            return comparisonRows.map(BaseballMatchStatsResultContent.comparison)

        case .home:
            return homeRows.map(BaseballMatchStatsResultContent.value)

        case .away:
            return awayRows.map(BaseballMatchStatsResultContent.value)
        }
    }

    var emptyCellText: (title: String, subtitle: String?) {
        switch displayState {
        case .empty(let title, let subtitle):
            return (title, subtitle)

        case .content:
            return (
                "No Stats Available",
                "Player statistics are not available for this game."
            )
        }
    }

    private func rowCount(for filter: BaseballMatchFilterOption) -> Int {
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

nonisolated enum BaseballMatchStatsResultContent: Equatable, Sendable {

    case comparison(BaseballMatchStatsComparisonRowViewData)
    case value(BaseballMatchStatsValueRowViewData)
}

nonisolated struct BaseballMatchStatsComparisonRowViewData: Equatable, Identifiable, Sendable {

    var id: String { title }

    let title: String
    let homeValue: String
    let awayValue: String
    let homeRatio: Double
    let awayRatio: Double
}

nonisolated struct BaseballMatchStatsValueRowViewData: Equatable, Identifiable, Sendable {

    var id: String { title }

    let title: String
    let value: String
}
