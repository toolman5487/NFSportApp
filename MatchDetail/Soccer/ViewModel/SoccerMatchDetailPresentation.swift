//
//  SoccerMatchDetailPresentation.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/26.
//

import Foundation

// MARK: - Presentation

nonisolated struct SoccerMatchDetailPresentation: Equatable, Sendable {

    let title: String
    let sections: [SoccerMatchDetailSectionViewData]
}

// MARK: - Sections

nonisolated enum SoccerMatchDetailSectionViewData: Equatable, Sendable {

    case header(SoccerMatchDetailHeaderViewData)
    case statistics(SoccerMatchDetailStatisticsSectionViewData)
    case events(SoccerMatchDetailEventsSectionViewData)
    case lineups(SoccerMatchDetailLineupsSectionViewData)
}

// MARK: - Header

nonisolated struct SoccerMatchDetailHeaderViewData: Equatable, Sendable {

    let leagueName: String
    let leagueLogoURL: URL?
    let statusText: String
    let statusStyle: SoccerMatchDetailHeaderStatusStyle
    let navigationBadgeViewData: MatchDetailNavigationBadgeViewData
    let timeText: String
    let homeTeamName: String
    let homeTeamLogoURL: URL?
    let awayTeamName: String
    let awayTeamLogoURL: URL?
    let homeScoreText: String
    let awayScoreText: String
    let venue: SoccerMatchDetailVenueViewData?
}

nonisolated enum SoccerMatchDetailHeaderStatusStyle: Equatable, Sendable {

    case live
    case final
    case upcoming
    case postponed
    case cancelled
    case neutral
}

// MARK: - Statistics

nonisolated struct SoccerMatchDetailStatisticsSectionViewData: Equatable, Sendable {

    let title: String
    let rows: [SoccerMatchDetailStatisticRowViewData]
}

nonisolated struct SoccerMatchDetailStatisticRowViewData: Equatable, Identifiable, Sendable {

    var id: String {
        title
    }

    let title: String
    let homeValueText: String
    let awayValueText: String
}

// MARK: - Events

nonisolated struct SoccerMatchDetailEventsSectionViewData: Equatable, Sendable {

    let title: String
    let items: [SoccerMatchDetailEventViewData]
}

nonisolated struct SoccerMatchDetailEventViewData: Equatable, Identifiable, Sendable {

    let id: String
    let timeText: String
    let teamName: String?
    let title: String
    let subtitle: String?
}

// MARK: - Lineups

nonisolated struct SoccerMatchDetailLineupsSectionViewData: Equatable, Sendable {

    let title: String
    let home: SoccerMatchDetailLineupViewData?
    let away: SoccerMatchDetailLineupViewData?
}

nonisolated struct SoccerMatchDetailLineupViewData: Equatable, Sendable {

    let teamName: String
    let formationText: String?
    let coachName: String?
    let starters: [String]
    let substitutes: [String]
}

// MARK: - Venue

nonisolated struct SoccerMatchDetailVenueViewData: Equatable, Sendable {

    let venueText: String
}
