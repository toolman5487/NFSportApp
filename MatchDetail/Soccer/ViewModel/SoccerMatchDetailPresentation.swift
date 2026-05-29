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
    case stats(SoccerMatchDetailStatsViewData)
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

// MARK: - Venue

nonisolated struct SoccerMatchDetailVenueViewData: Equatable, Sendable {

    let venueText: String
}

// MARK: - Stats

nonisolated struct SoccerMatchDetailStatsViewData: Equatable, Sendable {

    let homeTeamName: String
    let awayTeamName: String
    let comparisonRows: [SoccerMatchStatsComparisonRowViewData]
    let homeRows: [SoccerMatchStatsValueRowViewData]
    let awayRows: [SoccerMatchStatsValueRowViewData]
}

nonisolated struct SoccerMatchStatsComparisonRowViewData: Equatable, Identifiable, Sendable {

    var id: String { title }

    let title: String
    let homeValue: String
    let awayValue: String
    let homeRatio: Double
    let awayRatio: Double
}

nonisolated struct SoccerMatchStatsValueRowViewData: Equatable, Identifiable, Sendable {

    var id: String { title }

    let title: String
    let value: String
}

// MARK: - Events

nonisolated struct SoccerMatchDetailEventsSectionViewData: Equatable, Sendable {

    let title: String
    let items: [SoccerMatchDetailEventViewData]
}

nonisolated struct SoccerMatchDetailEventViewData: Equatable, Identifiable, Sendable {

    let id: String
    let timeText: String
    let title: String
    let subtitle: String?
}

// MARK: - Lineups

nonisolated struct SoccerMatchDetailLineupsSectionViewData: Equatable, Sendable {

    let title: String
    let teams: [SoccerMatchDetailLineupViewData]
}

nonisolated struct SoccerMatchDetailLineupViewData: Equatable, Identifiable, Sendable {

    var id: String { teamName }

    let teamName: String
    let formationText: String?
    let coachName: String?
    let starters: [String]
    let substitutes: [String]
}
