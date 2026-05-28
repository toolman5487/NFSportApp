//
//  HockeyMatchDetailPresentation.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/28.
//

import Foundation

// MARK: - Presentation

nonisolated struct HockeyMatchDetailPresentation: Equatable, Sendable {

    let title: String
    let sections: [HockeyMatchDetailSectionViewData]
}

// MARK: - Sections

nonisolated enum HockeyMatchDetailSectionViewData: Equatable, Sendable {

    case header(HockeyMatchDetailHeaderViewData)
}

// MARK: - Header

nonisolated struct HockeyMatchDetailHeaderViewData: Equatable, Sendable {

    let leagueName: String
    let leagueLogoURL: URL?
    let statusText: String
    let statusStyle: HockeyMatchDetailHeaderStatusStyle
    let navigationBadgeViewData: MatchDetailNavigationBadgeViewData
    let timeText: String
    let homeTeamName: String
    let homeTeamLogoURL: URL?
    let awayTeamName: String
    let awayTeamLogoURL: URL?
    let homeScoreText: String
    let awayScoreText: String
    let venue: HockeyMatchDetailVenueViewData?
}

nonisolated enum HockeyMatchDetailHeaderStatusStyle: Equatable, Sendable {

    case live
    case final
    case upcoming
    case postponed
    case cancelled
    case neutral
}

// MARK: - Venue

nonisolated struct HockeyMatchDetailVenueViewData: Equatable, Sendable {

    let venueText: String
}

