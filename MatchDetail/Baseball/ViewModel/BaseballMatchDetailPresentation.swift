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
}

// MARK: - Header

nonisolated struct BaseballMatchDetailHeaderViewData: Equatable, Sendable {

    let leagueName: String
    let leagueLogoURL: URL?
    let statusText: String
    let statusStyle: BaseballMatchDetailHeaderStatusStyle
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

