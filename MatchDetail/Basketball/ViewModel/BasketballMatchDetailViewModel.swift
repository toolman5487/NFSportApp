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

    // MARK: - Types

    private enum MatchStatus: Equatable {
        case live(quarterText: String?)
        case scheduled
        case tbd
        case halfTime
        case overtime
        case breakTime
        case final
        case postponed
        case cancelled
        case unknown

        var displayText: String {
            switch self {
            case .live(let quarterText):
                return quarterText ?? "Live"
            case .scheduled:
                return "Scheduled"
            case .tbd:
                return "TBD"
            case .halfTime:
                return "Half Time"
            case .overtime:
                return "Overtime"
            case .breakTime:
                return "Break"
            case .final:
                return "Final"
            case .postponed:
                return "Postponed"
            case .cancelled:
                return "Cancelled"
            case .unknown:
                return "Scheduled"
            }
        }

        var style: BasketballMatchDetailHeaderStatusStyle {
            switch self {
            case .live:
                return .live
            case .final:
                return .final
            case .scheduled, .tbd:
                return .upcoming
            case .postponed:
                return .postponed
            case .cancelled:
                return .cancelled
            case .halfTime, .overtime, .breakTime, .unknown:
                return .neutral
            }
        }
    }

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
        let sections: [BasketballMatchDetailSectionViewData] = [
            .header(makeHeaderViewData(from: detail.fixture)),
            .stats(makeStatsViewData(from: detail))
        ]

        return BasketballMatchDetailPresentation(
            title: detail.fixture.leagueName,
            sections: sections
        )
    }

    private func makeHeaderViewData(from fixture: BasketballMatchFixtureDetail) -> BasketballMatchDetailHeaderViewData {
        let statusStyle = makeStatusStyle(from: fixture)
        let statusText = makeStatusText(from: fixture)

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
            homeScoreText: fixture.score.home.total.map(String.init) ?? "-",
            awayScoreText: fixture.score.away.total.map(String.init) ?? "-",
            venue: makeVenueSection(from: fixture)
        )
    }

    // MARK: - Status Mapping

    private func makeStatusText(from fixture: BasketballMatchFixtureDetail) -> String {
        let matchStatus = makeMatchStatus(from: fixture)
        if case .unknown = matchStatus {
            if let statusLong = fixture.statusLong,
               !statusLong.isEmpty {
                return statusLong
            }

            return fixture.statusShort ?? "Scheduled"
        }

        return matchStatus.displayText
    }

    private func makeStatusStyle(from fixture: BasketballMatchFixtureDetail) -> BasketballMatchDetailHeaderStatusStyle {
        makeMatchStatus(from: fixture).style
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

    // MARK: - Match Status Parsing

    private func makeMatchStatus(from fixture: BasketballMatchFixtureDetail) -> MatchStatus {
        guard let normalizedStatus = fixture.statusShort?.lowercased() ?? fixture.statusLong?.lowercased() else {
            return .unknown
        }

        if isLiveStatus(normalizedStatus) {
            return .live(quarterText: makeQuarterText(from: normalizedStatus))
        }

        switch normalizedStatus {
        case "ns", "not started":
            return .scheduled
        case "tbd":
            return .tbd
        case "ht", "half time":
            return .halfTime
        case "ot", "overtime":
            return .overtime
        case "bt", "break time":
            return .breakTime
        case "ft", "aot", "after overtime", "final":
            return .final
        case "pst", "postponed":
            return .postponed
        case "canc", "cancelled", "abd", "abandoned", "susp", "suspended":
            return .cancelled
        default:
            return .unknown
        }
    }

    // MARK: - Helpers

    private func isLiveStatus(_ status: String) -> Bool {
        status.contains("q1")
            || status.contains("q2")
            || status.contains("q3")
            || status.contains("q4")
            || status.contains("ot")
            || status.contains("bt")
            || status.contains("ht")
            || status.contains("live")
            || status.contains("half")
    }

    private func makeQuarterText(from status: String) -> String? {
        switch status {
        case let value where value.contains("q1"):
            return "Q1"
        case let value where value.contains("q2"):
            return "Q2"
        case let value where value.contains("q3"):
            return "Q3"
        case let value where value.contains("q4"):
            return "Q4"
        case let value where value.contains("ot"):
            return "OT"
        default:
            return nil
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

    private func makeStatsViewData(from detail: BasketballMatchDetail) -> BasketballMatchDetailStatsViewData {
        let fixture = detail.fixture

        if let homePlayers = findTeamPlayers(for: fixture.homeTeam, in: detail.playersByTeam),
           let awayPlayers = findTeamPlayers(for: fixture.awayTeam, in: detail.playersByTeam, excluding: homePlayers),
           !homePlayers.players.isEmpty || !awayPlayers.players.isEmpty {
            let homeTotals = aggregate(players: homePlayers.players)
            let awayTotals = aggregate(players: awayPlayers.players)
            let comparisonRows = makeComparisonRows(home: homeTotals, away: awayTotals)

            if !comparisonRows.isEmpty {
                return appendQuarterPeriods(
                    to: BasketballMatchDetailStatsViewData(
                        homeTeamName: fixture.homeTeam.name,
                        awayTeamName: fixture.awayTeam.name,
                        comparisonRows: comparisonRows,
                        homeRows: makeValueRows(from: homeTotals),
                        awayRows: makeValueRows(from: awayTotals)
                    ),
                    score: fixture.score
                )
            }
        }

        if let scoreStats = makeGameScoreStatsViewData(from: fixture) {
            return scoreStats
        }

        return makeEmptyStatsViewData(from: fixture)
    }

    private func makeGameScoreStatsViewData(
        from fixture: BasketballMatchFixtureDetail
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

        return BasketballMatchDetailStatsViewData(
            homeTeamName: fixture.homeTeam.name,
            awayTeamName: fixture.awayTeam.name,
            comparisonRows: comparisonRows,
            homeRows: makeGameScoreValueRows(from: homeScore),
            awayRows: makeGameScoreValueRows(from: awayScore)
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
            awayTeamName: viewData.awayTeamName,
            comparisonRows: viewData.comparisonRows + quarterComparisonRows,
            homeRows: viewData.homeRows + makeQuarterValueRows(from: score.home.periods),
            awayRows: viewData.awayRows + makeQuarterValueRows(from: score.away.periods)
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

    private func makeEmptyStatsViewData(from fixture: BasketballMatchFixtureDetail) -> BasketballMatchDetailStatsViewData {
        BasketballMatchDetailStatsViewData(
            homeTeamName: fixture.homeTeam.name,
            awayTeamName: fixture.awayTeam.name,
            comparisonRows: [],
            homeRows: [],
            awayRows: []
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

    private func makeComparisonRows(
        home: BasketballTeamTotals,
        away: BasketballTeamTotals
    ) -> [BasketballMatchStatsComparisonRowViewData] {
        let definitions: [(title: String, home: Double, away: Double, text: (Double) -> String)] = [
            ("Points", home.points, away.points, Self.formatCount),
            ("FG%", home.fieldGoalPercentage, away.fieldGoalPercentage, Self.formatPercentage),
            ("3PT%", home.threePointPercentage, away.threePointPercentage, Self.formatPercentage),
            ("Rebounds", home.rebounds, away.rebounds, Self.formatCount),
            ("Assists", home.assists, away.assists, Self.formatCount),
            ("Steals", home.steals, away.steals, Self.formatCount),
            ("Blocks", home.blocks, away.blocks, Self.formatCount),
            ("Turnovers", home.turnovers, away.turnovers, Self.formatCount)
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
            BasketballMatchStatsValueRowViewData(title: "Rebounds", value: Self.formatCount(totals.rebounds)),
            BasketballMatchStatsValueRowViewData(title: "Assists", value: Self.formatCount(totals.assists)),
            BasketballMatchStatsValueRowViewData(title: "Steals", value: Self.formatCount(totals.steals)),
            BasketballMatchStatsValueRowViewData(title: "Blocks", value: Self.formatCount(totals.blocks)),
            BasketballMatchStatsValueRowViewData(title: "Turnovers", value: Self.formatCount(totals.turnovers))
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
    var threePointsMade: Double = 0
    var threePointsAttempted: Double = 0
    var freeThrowsMade: Double = 0
    var freeThrowsAttempted: Double = 0
    var rebounds: Double = 0
    var assists: Double = 0
    var steals: Double = 0
    var blocks: Double = 0
    var turnovers: Double = 0

    var fieldGoalPercentage: Double {
        fieldGoalsAttempted > 0 ? fieldGoalsMade / fieldGoalsAttempted : 0
    }

    var threePointPercentage: Double {
        threePointsAttempted > 0 ? threePointsMade / threePointsAttempted : 0
    }

    var freeThrowPercentage: Double {
        freeThrowsAttempted > 0 ? freeThrowsMade / freeThrowsAttempted : 0
    }
}
