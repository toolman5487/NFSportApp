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
}

// MARK: - Sections

nonisolated enum BaseballMatchDetailSectionViewData: Equatable, Sendable {

    case header(BaseballMatchDetailHeaderViewData)
    case stats(BaseballMatchDetailStatsViewData)
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

nonisolated struct BaseballMatchDetailStatsViewData: Equatable, Sendable {

    let homeTeamName: String
    let awayTeamName: String
    let displayState: MatchDetailStatsDisplayState
    let showsFilter: Bool
    let comparisonRows: [BaseballMatchStatsComparisonRowViewData]
    let homeRows: [BaseballMatchStatsValueRowViewData]
    let awayRows: [BaseballMatchStatsValueRowViewData]
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

