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

    var headerViewData: SoccerMatchDetailHeaderViewData? {
        sections.compactMap(\.headerViewData).first
    }
}

// MARK: - Sections

nonisolated enum SoccerMatchDetailSectionViewData: Equatable, Sendable {

    case header(SoccerMatchDetailHeaderViewData)
    case stats(SoccerMatchDetailStatsViewData)
    case events(SoccerMatchDetailEventsSectionViewData)
    case lineups(SoccerMatchDetailLineupsSectionViewData)

    var headerViewData: SoccerMatchDetailHeaderViewData? {
        guard case .header(let viewData) = self else {
            return nil
        }

        return viewData
    }
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

nonisolated enum SoccerMatchFilterOption: Int, CaseIterable, Equatable, Sendable {

    case home
    case total
    case away

    var title: String {
        switch self {
        case .home:
            return "Home"
        case .total:
            return "Total Game"
        case .away:
            return "Away"
        }
    }
}

nonisolated struct SoccerMatchDetailStatsViewData: Equatable, Sendable {

    let homeTeamName: String
    let homeTeamLogoURL: URL?
    let awayTeamName: String
    let awayTeamLogoURL: URL?
    let displayState: MatchDetailStatsDisplayState
    let showsFilter: Bool
    let comparisonRows: [SoccerMatchStatsComparisonRowViewData]
    let homeRows: [SoccerMatchStatsValueRowViewData]
    let awayRows: [SoccerMatchStatsValueRowViewData]

    func itemCount(for filter: SoccerMatchFilterOption) -> Int {
        switch displayState {
        case .empty:
            return 1

        case .content:
            let rowCount = rowCount(for: filter)
            return rowCount > 0 ? rowCount : 1
        }
    }

    func hasContent(for filter: SoccerMatchFilterOption) -> Bool {
        switch displayState {
        case .empty:
            return false

        case .content:
            return rowCount(for: filter) > 0
        }
    }

    func resultContent(
        at index: Int,
        filter: SoccerMatchFilterOption
    ) -> SoccerMatchStatsResultContent? {
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

    func resultContents(for filter: SoccerMatchFilterOption) -> [SoccerMatchStatsResultContent] {
        switch filter {
        case .total:
            return comparisonRows.map(SoccerMatchStatsResultContent.comparison)

        case .home:
            return homeRows.map(SoccerMatchStatsResultContent.value)

        case .away:
            return awayRows.map(SoccerMatchStatsResultContent.value)
        }
    }

    var emptyCellText: (title: String, subtitle: String?) {
        switch displayState {
        case .empty(let title, let subtitle):
            return (title, subtitle)

        case .content:
            return (
                "No Stats Available",
                "Match statistics are not available for this game."
            )
        }
    }

    private func rowCount(for filter: SoccerMatchFilterOption) -> Int {
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

nonisolated enum SoccerMatchStatsResultContent: Equatable, Sendable {

    case comparison(SoccerMatchStatsComparisonRowViewData)
    case value(SoccerMatchStatsValueRowViewData)
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
    let side: SoccerMatchDetailEventSide
    let iconSystemName: String
    let timeText: String
    let title: String
    let subtitle: String?
}

nonisolated enum SoccerMatchDetailEventSide: Equatable, Sendable {

    case home
    case away
    case neutral
}

// MARK: - Lineups

nonisolated struct SoccerMatchDetailLineupsSectionViewData: Equatable, Sendable {

    let title: String
    let homeTeam: SoccerMatchLineupTeamViewData
    let awayTeam: SoccerMatchLineupTeamViewData

    var hasSubstitutes: Bool {
        !homeTeam.substitutes.isEmpty || !awayTeam.substitutes.isEmpty
    }
}

nonisolated struct SoccerMatchLineupTeamViewData: Equatable, Sendable {

    let name: String
    let formationText: String?
    let coachText: String?
    let formationRows: [SoccerMatchLineupFormationRowViewData]
    let substitutes: [SoccerMatchLineupPlayerViewData]
}

nonisolated struct SoccerMatchLineupFormationRowViewData: Equatable, Identifiable, Sendable {

    var id: String {
        [
            title,
            players.map(\.id).joined(separator: "-")
        ].joined(separator: "|")
    }

    let title: String
    let players: [SoccerMatchLineupPlayerViewData]
}

nonisolated struct SoccerMatchLineupPlayerViewData: Equatable, Identifiable, Sendable {

    let id: String
    let displayName: String
    let shortDisplayName: String
    let numberText: String?
    let positionText: String?
}

nonisolated enum SoccerMatchLineupPositionGroup: String, CaseIterable, Sendable {

    case goalkeeper = "Goalkeeper"
    case defender = "Defenders"
    case midfielder = "Midfielders"
    case forward = "Forwards"
    case other = "Other"
}
