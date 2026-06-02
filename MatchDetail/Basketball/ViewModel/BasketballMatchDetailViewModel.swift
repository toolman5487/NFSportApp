//
//  BasketballMatchDetailViewModel.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/27.
//

import Foundation

// MARK: - State

nonisolated enum BasketballMatchDetailViewState: Equatable, Sendable {

    case idle
    case loading
    case loaded(BasketballMatchDetailPresentation)
    case failed(message: String)
}

// MARK: - BasketballMatchDetailViewModel

@MainActor
final class BasketballMatchDetailViewModel {

    // MARK: - Properties

    private(set) var state: BasketballMatchDetailViewState = .idle {
        didSet {
            onStateChange?(state)
        }
    }

    var onStateChange: ((BasketballMatchDetailViewState) -> Void)?

    var title: String {
        "Match Detail"
    }

    private let gameID: Int
    private let detailService: BasketballMatchDetailServicing
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = .current
        calendar.timeZone = .current
        return calendar
    }()

    // MARK: - Initialization

    init(
        gameID: Int,
        detailService: BasketballMatchDetailServicing
    ) {
        self.gameID = gameID
        self.detailService = detailService
    }

    // MARK: - Actions

    func loadMatchDetail() async {
        state = .loading

        do {
            let detail = try await detailService.fetchMatchDetail(gameID: gameID)
            state = .loaded(makePresentation(from: detail))
        } catch {
            state = .failed(message: error.localizedDescription)
            AppLogger.logUIError(
                error,
                message: "Basketball match detail loading failed",
                metadata: "gameID=\(gameID)"
            )
        }
    }

    // MARK: - Presentation Builders

    private func makePresentation(from detail: BasketballMatchDetail) -> BasketballMatchDetailPresentation {
        let phase = makePhase(from: detail.fixture)
        let displayPolicy = phase.displayPolicy(for: .basketball)

        var sections: [BasketballMatchDetailSectionViewData] = [
            .header(makeHeaderViewData(from: detail.fixture, phase: phase))
        ]

        if displayPolicy.showsStatsSection {
            sections.append(.stats(makeStatsViewData(from: detail, phase: phase)))
        }

        return BasketballMatchDetailPresentation(
            title: detail.fixture.leagueName,
            sections: sections
        )
    }

    private func makePhase(from fixture: BasketballMatchFixtureDetail) -> MatchFixturePhase {
        MatchFixturePhase(
            sport: .basketball,
            snapshot: MatchFixtureStatusSnapshot.make(
                statusShort: fixture.statusShort,
                statusLong: fixture.statusLong
            )
        )
    }

    private func makeHeaderViewData(
        from fixture: BasketballMatchFixtureDetail,
        phase: MatchFixturePhase
    ) -> BasketballMatchDetailHeaderViewData {
        let statusStyle = BasketballMatchDetailHeaderStatusStyle(
            matchNavigationStyle: phase.navigationStatusStyle
        )
        let statusText = phase.statusText(
            fallbackStatusLong: fixture.statusLong,
            fallbackStatusShort: fixture.statusShort
        )
        let showsScore = phase.displayPolicy(for: .basketball).showsHeaderScore

        return BasketballMatchDetailHeaderViewData(
            leagueName: fixture.leagueName,
            leagueLogoURL: fixture.leagueLogoURL,
            statusText: statusText,
            statusStyle: statusStyle,
            navigationBadgeViewData: makeNavigationBadgeViewData(
                text: statusText,
                statusStyle: statusStyle
            ),
            timeText: makeTimeText(
                from: fixture.scheduledStartDate,
                fallback: fixture.scheduledStartText ?? "TBD"
            ),
            homeTeamName: fixture.homeTeam.name,
            homeTeamLogoURL: fixture.homeTeam.logoURL,
            awayTeamName: fixture.awayTeam.name,
            awayTeamLogoURL: fixture.awayTeam.logoURL,
            homeScoreText: showsScore ? formatOptionalCount(fixture.score.home.total) : "-",
            awayScoreText: showsScore ? formatOptionalCount(fixture.score.away.total) : "-",
            venue: makeVenueSection(from: fixture)
        )
    }

    // MARK: - Navigation Badge

    private func makeNavigationBadgeViewData(
        text: String,
        statusStyle: BasketballMatchDetailHeaderStatusStyle
    ) -> MatchDetailNavigationBadgeViewData {
        MatchDetailNavigationBadgeViewData(
            text: text,
            style: makeNavigationStatusStyle(from: statusStyle)
        )
    }

    private func makeNavigationStatusStyle(
        from statusStyle: BasketballMatchDetailHeaderStatusStyle
    ) -> MatchDetailNavigationStatusStyle {
        switch statusStyle {
        case .live:
            return .live
        case .final:
            return .final
        case .upcoming:
            return .upcoming
        case .postponed:
            return .postponed
        case .cancelled:
            return .cancelled
        case .neutral:
            return .neutral
        }
    }

    private func makeVenueSection(from fixture: BasketballMatchFixtureDetail) -> BasketballMatchDetailVenueViewData? {
        guard let venueName = fixture.venueName?.trimmingCharacters(in: .whitespacesAndNewlines),
              !venueName.isEmpty else {
            return nil
        }

        return BasketballMatchDetailVenueViewData(venueText: venueName)
    }

    private func makeTimeText(from date: Date?, fallback: String) -> String {
        guard let date else {
            return fallback
        }

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = .current
        formatter.timeStyle = .short
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    // MARK: - Stats Aggregation

    private func makeStatsViewData(
        from detail: BasketballMatchDetail,
        phase: MatchFixturePhase
    ) -> BasketballMatchDetailStatsViewData {
        let fixture = detail.fixture
        let displayPolicy = phase.displayPolicy(for: .basketball)

        if displayPolicy.showsDetailedStatistics,
           let teamStatisticsStats = makeTeamStatisticsStatsViewData(from: detail, phase: phase) {
            return teamStatisticsStats
        }

        if displayPolicy.showsDetailedStatistics,
           let homePlayers = findTeamPlayers(for: fixture.homeTeam, in: detail.playersByTeam),
           let awayPlayers = findTeamPlayers(for: fixture.awayTeam, in: detail.playersByTeam, excluding: homePlayers),
           !homePlayers.players.isEmpty || !awayPlayers.players.isEmpty {
            let homeTotals = aggregate(players: homePlayers.players)
            let awayTotals = aggregate(players: awayPlayers.players)
            let comparisonRows = makeComparisonRows(home: homeTotals, away: awayTotals)

            if !comparisonRows.isEmpty {
                return finalizeStatsViewData(
                    fixture: fixture,
                    phase: phase,
                    viewData: appendQuarterPeriods(
                        to: BasketballMatchDetailStatsViewData(
                            homeTeamName: fixture.homeTeam.name,
                            homeTeamLogoURL: fixture.homeTeam.logoURL,
                            awayTeamName: fixture.awayTeam.name,
                            awayTeamLogoURL: fixture.awayTeam.logoURL,
                            displayState: .content,
                            showsFilter: true,
                            comparisonRows: comparisonRows,
                            homeRows: makeValueRows(from: homeTotals),
                            awayRows: makeValueRows(from: awayTotals)
                        ),
                        score: fixture.score
                    )
                )
            }
        }

        if let scoreStats = makeGameScoreStatsViewData(from: fixture, phase: phase) {
            return scoreStats
        }

        return makeEmptyStatsViewData(from: fixture, phase: phase)
    }

    private func makeTeamStatisticsStatsViewData(
        from detail: BasketballMatchDetail,
        phase: MatchFixturePhase
    ) -> BasketballMatchDetailStatsViewData? {
        let fixture = detail.fixture
        guard let homeStatistics = findTeamStatistics(
            for: fixture.homeTeam,
            in: detail.teamStatisticsByTeam
        ),
              let awayStatistics = findTeamStatistics(
                for: fixture.awayTeam,
                in: detail.teamStatisticsByTeam,
                excluding: homeStatistics
              ) else {
            return nil
        }

        let homeTotals = makeTotals(from: homeStatistics, score: fixture.score.home)
        let awayTotals = makeTotals(from: awayStatistics, score: fixture.score.away)
        let comparisonRows = makeComparisonRows(home: homeTotals, away: awayTotals)

        guard !comparisonRows.isEmpty else {
            return nil
        }

        return finalizeStatsViewData(
            fixture: fixture,
            phase: phase,
            viewData: appendQuarterPeriods(
                to: BasketballMatchDetailStatsViewData(
                    homeTeamName: fixture.homeTeam.name,
                    homeTeamLogoURL: fixture.homeTeam.logoURL,
                    awayTeamName: fixture.awayTeam.name,
                    awayTeamLogoURL: fixture.awayTeam.logoURL,
                    displayState: .content,
                    showsFilter: true,
                    comparisonRows: comparisonRows,
                    homeRows: makeValueRows(from: homeTotals),
                    awayRows: makeValueRows(from: awayTotals)
                ),
                score: fixture.score
            )
        )
    }

    private func makeGameScoreStatsViewData(
        from fixture: BasketballMatchFixtureDetail,
        phase: MatchFixturePhase
    ) -> BasketballMatchDetailStatsViewData? {
        let homeScore = fixture.score.home
        let awayScore = fixture.score.away
        let homePoints = Double(homeScore.total ?? 0)
        let awayPoints = Double(awayScore.total ?? 0)

        var comparisonRows: [BasketballMatchStatsComparisonRowViewData] = []

        if homePoints > 0 || awayPoints > 0 {
            comparisonRows.append(
                makeRatioComparisonRow(
                    title: "Points",
                    home: homePoints,
                    away: awayPoints
                )
            )
        }

        comparisonRows += makeQuarterComparisonRows(
            homePeriods: homeScore.periods,
            awayPeriods: awayScore.periods
        )

        guard !comparisonRows.isEmpty else {
            return nil
        }

        return finalizeStatsViewData(
            fixture: fixture,
            phase: phase,
            viewData: BasketballMatchDetailStatsViewData(
                homeTeamName: fixture.homeTeam.name,
                homeTeamLogoURL: fixture.homeTeam.logoURL,
                awayTeamName: fixture.awayTeam.name,
                awayTeamLogoURL: fixture.awayTeam.logoURL,
                displayState: .content,
                showsFilter: true,
                comparisonRows: comparisonRows,
                homeRows: makeGameScoreValueRows(from: homeScore),
                awayRows: makeGameScoreValueRows(from: awayScore)
            )
        )
    }

    private func makeGameScoreValueRows(
        from teamScore: BasketballMatchTeamScore
    ) -> [BasketballMatchStatsValueRowViewData] {
        var rows: [BasketballMatchStatsValueRowViewData] = []

        if teamScore.total != nil {
            rows.append(
                BasketballMatchStatsValueRowViewData(
                    title: "Points",
                    value: formatOptionalCount(teamScore.total)
                )
            )
        }

        rows += teamScore.periods.map { period in
            BasketballMatchStatsValueRowViewData(
                title: period.label,
                value: formatOptionalCount(period.points)
            )
        }

        return rows
    }

    private func makeQuarterComparisonRows(
        homePeriods: [BasketballMatchPeriodScore],
        awayPeriods: [BasketballMatchPeriodScore]
    ) -> [BasketballMatchStatsComparisonRowViewData] {
        let awayPointsByLabel = Dictionary(uniqueKeysWithValues: awayPeriods.map { ($0.label, $0.points) })

        return homePeriods.compactMap { homePeriod in
            makePeriodComparisonRow(
                title: homePeriod.label,
                home: homePeriod.points,
                away: awayPointsByLabel[homePeriod.label] ?? nil
            )
        }
    }

    private func makePeriodComparisonRow(
        title: String,
        home: Int?,
        away: Int?
    ) -> BasketballMatchStatsComparisonRowViewData? {
        guard home != nil || away != nil else {
            return nil
        }

        return makeRatioComparisonRow(
            title: title,
            home: Double(home ?? 0),
            away: Double(away ?? 0)
        )
    }

    private func makeRatioComparisonRow(
        title: String,
        home: Double,
        away: Double
    ) -> BasketballMatchStatsComparisonRowViewData {
        let total = home + away
        let homeRatio = total > 0 ? home / total : 0.5
        let awayRatio = total > 0 ? away / total : 0.5

        return BasketballMatchStatsComparisonRowViewData(
            title: title,
            homeValue: Self.formatCount(home),
            awayValue: Self.formatCount(away),
            homeRatio: homeRatio,
            awayRatio: awayRatio
        )
    }

    private func appendQuarterPeriods(
        to viewData: BasketballMatchDetailStatsViewData,
        score: BasketballMatchScore
    ) -> BasketballMatchDetailStatsViewData {
        let quarterComparisonRows = makeQuarterComparisonRows(
            homePeriods: score.home.periods,
            awayPeriods: score.away.periods
        )

        guard !quarterComparisonRows.isEmpty else {
            return viewData
        }

        return BasketballMatchDetailStatsViewData(
            homeTeamName: viewData.homeTeamName,
            homeTeamLogoURL: viewData.homeTeamLogoURL,
            awayTeamName: viewData.awayTeamName,
            awayTeamLogoURL: viewData.awayTeamLogoURL,
            displayState: viewData.displayState,
            showsFilter: viewData.showsFilter,
            comparisonRows: viewData.comparisonRows + quarterComparisonRows,
            homeRows: viewData.homeRows + makeQuarterValueRows(from: score.home.periods),
            awayRows: viewData.awayRows + makeQuarterValueRows(from: score.away.periods)
        )
    }

    private func finalizeStatsViewData(
        fixture: BasketballMatchFixtureDetail,
        phase: MatchFixturePhase,
        viewData: BasketballMatchDetailStatsViewData
    ) -> BasketballMatchDetailStatsViewData {
        let metadata = phase.statsViewMetadata(
            hasRows: !viewData.comparisonRows.isEmpty,
            sport: .basketball
        )

        return BasketballMatchDetailStatsViewData(
            homeTeamName: fixture.homeTeam.name,
            homeTeamLogoURL: fixture.homeTeam.logoURL,
            awayTeamName: fixture.awayTeam.name,
            awayTeamLogoURL: fixture.awayTeam.logoURL,
            displayState: metadata.displayState,
            showsFilter: metadata.showsFilter,
            comparisonRows: viewData.comparisonRows,
            homeRows: viewData.homeRows,
            awayRows: viewData.awayRows
        )
    }

    private func makeQuarterValueRows(
        from periods: [BasketballMatchPeriodScore]
    ) -> [BasketballMatchStatsValueRowViewData] {
        periods.map { period in
            BasketballMatchStatsValueRowViewData(
                title: period.label,
                value: formatOptionalCount(period.points)
            )
        }
    }

    private func formatOptionalCount(_ value: Int?) -> String {
        guard let value else {
            return "-"
        }

        return Self.formatCount(Double(value))
    }

    private func makeEmptyStatsViewData(
        from fixture: BasketballMatchFixtureDetail,
        phase: MatchFixturePhase
    ) -> BasketballMatchDetailStatsViewData {
        finalizeStatsViewData(
            fixture: fixture,
            phase: phase,
            viewData: BasketballMatchDetailStatsViewData(
                homeTeamName: fixture.homeTeam.name,
                homeTeamLogoURL: fixture.homeTeam.logoURL,
                awayTeamName: fixture.awayTeam.name,
                awayTeamLogoURL: fixture.awayTeam.logoURL,
                displayState: .content,
                showsFilter: false,
                comparisonRows: [],
                homeRows: [],
                awayRows: []
            )
        )
    }

    private func findTeamPlayers(
        for team: BasketballMatchTeam,
        in playersByTeam: [BasketballMatchTeamPlayers],
        excluding excluded: BasketballMatchTeamPlayers? = nil
    ) -> BasketballMatchTeamPlayers? {
        let candidates = playersByTeam.filter { $0.team.id != excluded?.team.id }

        if let byID = candidates.first(where: { $0.team.teamID != nil && $0.team.teamID == team.teamID }) {
            return byID
        }

        let normalizedName = team.name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        if let byName = candidates.first(where: {
            $0.team.name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current) == normalizedName
        }) {
            return byName
        }

        return candidates.first
    }

    private func findTeamStatistics(
        for team: BasketballMatchTeam,
        in statisticsByTeam: [BasketballMatchTeamStatistics],
        excluding excluded: BasketballMatchTeamStatistics? = nil
    ) -> BasketballMatchTeamStatistics? {
        let candidates = statisticsByTeam.filter { $0.teamID != excluded?.teamID }

        if let byID = candidates.first(where: { $0.teamID != nil && $0.teamID == team.teamID }) {
            return byID
        }

        return candidates.first
    }

    private func aggregate(players: [BasketballMatchPlayer]) -> BasketballTeamTotals {
        var totals = BasketballTeamTotals()

        for player in players {
            for statistic in player.statistics {
                totals.points += statistic.points ?? 0
                totals.fieldGoalsMade += statistic.fieldGoalsMade ?? 0
                totals.fieldGoalsAttempted += statistic.fieldGoalsAttempted ?? 0
                totals.threePointsMade += statistic.threePointsMade ?? 0
                totals.threePointsAttempted += statistic.threePointsAttempted ?? 0
                totals.freeThrowsMade += statistic.freeThrowsMade ?? 0
                totals.freeThrowsAttempted += statistic.freeThrowsAttempted ?? 0
                totals.rebounds += statistic.rebounds ?? 0
                totals.assists += statistic.assists ?? 0
                totals.steals += statistic.steals ?? 0
                totals.blocks += statistic.blocks ?? 0
                totals.turnovers += statistic.turnovers ?? 0
            }
        }

        return totals
    }

    private func makeTotals(
        from statistics: BasketballMatchTeamStatistics,
        score: BasketballMatchTeamScore
    ) -> BasketballTeamTotals {
        BasketballTeamTotals(
            points: Double(score.total ?? 0),
            fieldGoalsMade: statistics.fieldGoalsMade ?? 0,
            fieldGoalsAttempted: statistics.fieldGoalsAttempted ?? 0,
            fieldGoalPercentageOverride: statistics.fieldGoalPercentage,
            threePointsMade: statistics.threePointsMade ?? 0,
            threePointsAttempted: statistics.threePointsAttempted ?? 0,
            threePointPercentageOverride: statistics.threePointPercentage,
            freeThrowsMade: statistics.freeThrowsMade ?? 0,
            freeThrowsAttempted: statistics.freeThrowsAttempted ?? 0,
            freeThrowPercentageOverride: statistics.freeThrowPercentage,
            rebounds: statistics.rebounds ?? 0,
            offensiveRebounds: statistics.offensiveRebounds ?? 0,
            defensiveRebounds: statistics.defensiveRebounds ?? 0,
            assists: statistics.assists ?? 0,
            steals: statistics.steals ?? 0,
            blocks: statistics.blocks ?? 0,
            turnovers: statistics.turnovers ?? 0,
            personalFouls: statistics.personalFouls ?? 0
        )
    }

    private func makeComparisonRows(
        home: BasketballTeamTotals,
        away: BasketballTeamTotals
    ) -> [BasketballMatchStatsComparisonRowViewData] {
        let definitions: [(title: String, home: Double, away: Double, text: (Double) -> String)] = [
            ("Points", home.points, away.points, Self.formatCount),
            ("FG%", home.fieldGoalPercentage, away.fieldGoalPercentage, Self.formatPercentage),
            ("3PT%", home.threePointPercentage, away.threePointPercentage, Self.formatPercentage),
            ("FT%", home.freeThrowPercentage, away.freeThrowPercentage, Self.formatPercentage),
            ("Rebounds", home.rebounds, away.rebounds, Self.formatCount),
            ("Off Reb", home.offensiveRebounds, away.offensiveRebounds, Self.formatCount),
            ("Def Reb", home.defensiveRebounds, away.defensiveRebounds, Self.formatCount),
            ("Assists", home.assists, away.assists, Self.formatCount),
            ("Steals", home.steals, away.steals, Self.formatCount),
            ("Blocks", home.blocks, away.blocks, Self.formatCount),
            ("Turnovers", home.turnovers, away.turnovers, Self.formatCount),
            ("Fouls", home.personalFouls, away.personalFouls, Self.formatCount)
        ]

        return definitions.compactMap { definition in
            guard definition.home > 0 || definition.away > 0 else {
                return nil
            }

            let total = definition.home + definition.away
            let homeRatio = total > 0 ? definition.home / total : 0.5
            let awayRatio = total > 0 ? definition.away / total : 0.5

            return BasketballMatchStatsComparisonRowViewData(
                title: definition.title,
                homeValue: definition.text(definition.home),
                awayValue: definition.text(definition.away),
                homeRatio: homeRatio,
                awayRatio: awayRatio
            )
        }
    }

    private func makeValueRows(from totals: BasketballTeamTotals) -> [BasketballMatchStatsValueRowViewData] {
        [
            BasketballMatchStatsValueRowViewData(title: "Points", value: Self.formatCount(totals.points)),
            BasketballMatchStatsValueRowViewData(title: "FG%", value: Self.formatPercentage(totals.fieldGoalPercentage)),
            BasketballMatchStatsValueRowViewData(title: "3PT%", value: Self.formatPercentage(totals.threePointPercentage)),
            BasketballMatchStatsValueRowViewData(title: "FT%", value: Self.formatPercentage(totals.freeThrowPercentage)),
            BasketballMatchStatsValueRowViewData(title: "Rebounds", value: Self.formatCount(totals.rebounds)),
            BasketballMatchStatsValueRowViewData(title: "Off Reb", value: Self.formatCount(totals.offensiveRebounds)),
            BasketballMatchStatsValueRowViewData(title: "Def Reb", value: Self.formatCount(totals.defensiveRebounds)),
            BasketballMatchStatsValueRowViewData(title: "Assists", value: Self.formatCount(totals.assists)),
            BasketballMatchStatsValueRowViewData(title: "Steals", value: Self.formatCount(totals.steals)),
            BasketballMatchStatsValueRowViewData(title: "Blocks", value: Self.formatCount(totals.blocks)),
            BasketballMatchStatsValueRowViewData(title: "Turnovers", value: Self.formatCount(totals.turnovers)),
            BasketballMatchStatsValueRowViewData(title: "Fouls", value: Self.formatCount(totals.personalFouls))
        ]
    }

    private static func formatCount(_ value: Double) -> String {
        String(Int(value.rounded()))
    }

    private static func formatPercentage(_ value: Double) -> String {
        String(format: "%.1f%%", value * 100)
    }
}

// MARK: - Team Totals

private struct BasketballTeamTotals {

    var points: Double = 0
    var fieldGoalsMade: Double = 0
    var fieldGoalsAttempted: Double = 0
    var fieldGoalPercentageOverride: Double?
    var threePointsMade: Double = 0
    var threePointsAttempted: Double = 0
    var threePointPercentageOverride: Double?
    var freeThrowsMade: Double = 0
    var freeThrowsAttempted: Double = 0
    var freeThrowPercentageOverride: Double?
    var rebounds: Double = 0
    var offensiveRebounds: Double = 0
    var defensiveRebounds: Double = 0
    var assists: Double = 0
    var steals: Double = 0
    var blocks: Double = 0
    var turnovers: Double = 0
    var personalFouls: Double = 0

    var fieldGoalPercentage: Double {
        fieldGoalPercentageOverride ?? (fieldGoalsAttempted > 0 ? fieldGoalsMade / fieldGoalsAttempted : 0)
    }

    var threePointPercentage: Double {
        threePointPercentageOverride ?? (threePointsAttempted > 0 ? threePointsMade / threePointsAttempted : 0)
    }

    var freeThrowPercentage: Double {
        freeThrowPercentageOverride ?? (freeThrowsAttempted > 0 ? freeThrowsMade / freeThrowsAttempted : 0)
    }
}
