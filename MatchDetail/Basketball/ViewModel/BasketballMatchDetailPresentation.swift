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
}

// MARK: - Header

nonisolated struct BasketballMatchDetailHeaderViewData: Equatable, Sendable {

    let leagueName: String
    let leagueLogoURL: URL?
    let statusText: String
    let statusStyle: BasketballMatchDetailHeaderStatusStyle
    let timeText: String
    let homeTeamName: String
    let homeTeamLogoURL: URL?
    let awayTeamName: String
    let awayTeamLogoURL: URL?
    let homeScoreText: String
    let awayScoreText: String
    let venue: BasketballMatchDetailVenueViewData
}

nonisolated enum BasketballMatchDetailHeaderStatusStyle: Equatable, Sendable {

    case live
    case final
    case upcoming
    case neutral
}

// MARK: - Venue

nonisolated struct BasketballMatchDetailVenueViewData: Equatable, Sendable {

    let title: String
    let venueText: String
}
