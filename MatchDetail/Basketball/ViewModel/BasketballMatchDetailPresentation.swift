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
}

// MARK: - Sections

nonisolated enum BasketballMatchDetailSectionViewData: Equatable, Sendable {

    case header(BasketballMatchDetailHeaderViewData)
    case stats(BasketballMatchDetailStatsViewData)
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

nonisolated struct BasketballMatchDetailStatsViewData: Equatable, Sendable {

    let homeTeamName: String
    let awayTeamName: String
    let displayState: MatchDetailStatsDisplayState
    let showsFilter: Bool
    let comparisonRows: [BasketballMatchStatsComparisonRowViewData]
    let homeRows: [BasketballMatchStatsValueRowViewData]
    let awayRows: [BasketballMatchStatsValueRowViewData]
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
