//
//  BaseballMatchDetailViewModel.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/28.
//

import Foundation

// MARK: - State

nonisolated enum BaseballMatchDetailViewState: Equatable, Sendable {

    case idle
    case loading
    case loaded(BaseballMatchDetailPresentation)
    case failed(message: String)
}

// MARK: - BaseballMatchDetailViewModel

@MainActor
final class BaseballMatchDetailViewModel {

    // MARK: - Properties

    private(set) var state: BaseballMatchDetailViewState = .idle {
        didSet {
            onStateChange?(state)
        }
    }

    var onStateChange: ((BaseballMatchDetailViewState) -> Void)?

    var title: String {
        "Match Detail"
    }

    private let gameID: Int
    private let detailService: BaseballMatchDetailServicing
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = .current
        calendar.timeZone = .current
        return calendar
    }()

    // MARK: - Initialization

    init(
        gameID: Int,
        detailService: BaseballMatchDetailServicing
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
                message: "Baseball match detail loading failed",
                metadata: "gameID=\(gameID)"
            )
        }
    }

    // MARK: - Presentation Builders

    private func makePresentation(from detail: BaseballMatchDetail) -> BaseballMatchDetailPresentation {
        var sections: [BaseballMatchDetailSectionViewData] = [
            .header(makeHeaderViewData(from: detail.fixture))
        ]

        sections.append(.stats(makeStatsViewData(from: detail)))

        return BaseballMatchDetailPresentation(
            title: detail.fixture.leagueName,
            sections: sections
        )
    }

    private func makeHeaderViewData(from fixture: BaseballMatchFixtureDetail) -> BaseballMatchDetailHeaderViewData {
        let statusStyle = makeStatusStyle(from: fixture)
        let statusText = makeStatusText(from: fixture)

        return BaseballMatchDetailHeaderViewData(
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
            homeScoreText: fixture.score.home.runs.map(String.init) ?? "-",
            awayScoreText: fixture.score.away.runs.map(String.init) ?? "-",
            venue: makeVenueSection(from: fixture)
        )
    }

    // MARK: - Navigation Badge

    private func makeNavigationStatusStyle(
        from statusStyle: BaseballMatchDetailHeaderStatusStyle
    ) -> MatchDetailNavigationStatusStyle {
        switch statusStyle {
        case .live:
            return .live
        case .final:
            return .final
        case .upcoming:
            return .upcoming
        case .neutral:
            return .neutral
        }
    }

    private func makeNavigationBadgeViewData(
        text: String,
        statusStyle: BaseballMatchDetailHeaderStatusStyle
    ) -> MatchDetailNavigationBadgeViewData {
        MatchDetailNavigationBadgeViewData(
            text: text,
            style: makeNavigationStatusStyle(from: statusStyle)
        )
    }

    // MARK: - Status Mapping

    private func makeStatusText(from fixture: BaseballMatchFixtureDetail) -> String {
        let statusShort = fixture.statusShort?.lowercased()
        let statusLong = fixture.statusLong?.lowercased()
        let normalizedStatus = statusShort ?? statusLong

        if let normalizedStatus,
           isLiveStatus(normalizedStatus) {
            return "Live"
        }

        guard let normalizedStatus else {
            return "Scheduled"
        }

        switch normalizedStatus {
        case "ns", "not started":
            return "Scheduled"
        case "tbd", "time to be defined":
            return "TBD"
        case "ht", "half time":
            return "Half Time"
        case "et", "extra time":
            return "Extra Time"
        case "bt", "break time":
            return "Break"
        case "p", "pen", "penalty in progress":
            return "Penalties"
        case "ft", "aet", "aft", "aot", "after overtime", "final", "match finished":
            return "Final"
        case "pst", "postponed":
            return "Postponed"
        case "canc", "cancelled", "abandoned", "abd":
            return "Cancelled"
        case "int", "interrupted", "susp", "suspended":
            return "Suspended"
        default:
            if let statusLong,
               !statusLong.isEmpty {
                return fixture.statusLong ?? "Scheduled"
            }

            return fixture.statusShort ?? "Scheduled"
        }
    }

    private func makeStatusStyle(from fixture: BaseballMatchFixtureDetail) -> BaseballMatchDetailHeaderStatusStyle {
        let normalizedStatus = fixture.statusShort?.lowercased() ?? fixture.statusLong?.lowercased()

        guard let normalizedStatus else {
            return .neutral
        }

        if isLiveStatus(normalizedStatus) {
            return .live
        }

        switch normalizedStatus {
        case let status where status.contains("ft")
            || status.contains("finish")
            || status.contains("final")
            || status.contains("ended")
            || status.contains("after"):
            return .final

        case let status where status.contains("ns")
            || status.contains("scheduled")
            || status.contains("not started")
            || status.contains("tbd"):
            return .upcoming

        default:
            return .neutral
        }
    }

    // MARK: - Helpers

    private func isLiveStatus(_ status: String) -> Bool {
        status.contains("live")
            || status.contains("in progress")
            || status.contains("inning")
            || status.contains("top")
            || status.contains("bottom")
            || status.contains("half")
    }

    private func makeVenueSection(from fixture: BaseballMatchFixtureDetail) -> BaseballMatchDetailVenueViewData? {
        guard let venueName = fixture.venueName?.trimmingCharacters(in: .whitespacesAndNewlines),
              !venueName.isEmpty else {
            return nil
        }

        return BaseballMatchDetailVenueViewData(venueText: venueName)
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

    private func makeStatsViewData(from detail: BaseballMatchDetail) -> BaseballMatchDetailStatsViewData {
        let fixture = detail.fixture

        if let homePlayers = findTeamPlayers(for: fixture.homeTeam, in: detail.playersByTeam),
           let awayPlayers = findTeamPlayers(for: fixture.awayTeam, in: detail.playersByTeam, excluding: homePlayers),
           !homePlayers.players.isEmpty || !awayPlayers.players.isEmpty {
            let homeTotals = aggregate(players: homePlayers.players)
            let awayTotals = aggregate(players: awayPlayers.players)
            let comparisonRows = makeComparisonRows(home: homeTotals, away: awayTotals)

            if !comparisonRows.isEmpty {
                return appendInningPeriods(
                    to: BaseballMatchDetailStatsViewData(
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

        if let lineScoreStats = makeLineScoreStatsViewData(from: fixture) {
            return lineScoreStats
        }

        return makeEmptyStatsViewData(from: fixture)
    }

    private func makeLineScoreStatsViewData(
        from fixture: BaseballMatchFixtureDetail
    ) -> BaseballMatchDetailStatsViewData? {
        let comparisonRows = makeLineScoreComparisonRows(from: fixture.score)
        guard !comparisonRows.isEmpty else {
            return nil
        }

        return BaseballMatchDetailStatsViewData(
            homeTeamName: fixture.homeTeam.name,
            awayTeamName: fixture.awayTeam.name,
            comparisonRows: comparisonRows,
            homeRows: makeLineScoreValueRows(from: fixture.score.home),
            awayRows: makeLineScoreValueRows(from: fixture.score.away)
        )
    }

    private func makeLineScoreComparisonRows(
        from score: BaseballMatchScore
    ) -> [BaseballMatchStatsComparisonRowViewData] {
        let summaryDefinitions: [(title: String, home: Double, away: Double)] = [
            ("Runs", lineScoreValue(score.home.runs), lineScoreValue(score.away.runs)),
            ("Hits", lineScoreValue(score.home.hits), lineScoreValue(score.away.hits)),
            ("Errors", lineScoreValue(score.home.errors), lineScoreValue(score.away.errors))
        ]

        let summaryRows = summaryDefinitions.compactMap { definition in
            makePositiveComparisonRow(
                title: definition.title,
                home: definition.home,
                away: definition.away
            )
        }

        return summaryRows + makeInningComparisonRows(
            homeInnings: score.home.innings,
            awayInnings: score.away.innings
        )
    }

    private func makeInningComparisonRows(
        homeInnings: [BaseballMatchPeriodScore],
        awayInnings: [BaseballMatchPeriodScore]
    ) -> [BaseballMatchStatsComparisonRowViewData] {
        let awayRunsByLabel = Dictionary(uniqueKeysWithValues: awayInnings.map { ($0.label, $0.runs) })

        return homeInnings.compactMap { homeInning in
            makePeriodComparisonRow(
                title: homeInning.label,
                home: homeInning.runs,
                away: awayRunsByLabel[homeInning.label] ?? nil
            )
        }
    }

    private func makeLineScoreValueRows(
        from lineScore: BaseballMatchTeamLineScore
    ) -> [BaseballMatchStatsValueRowViewData] {
        var rows = [
            BaseballMatchStatsValueRowViewData(title: "Runs", value: formatOptionalCount(lineScore.runs)),
            BaseballMatchStatsValueRowViewData(title: "Hits", value: formatOptionalCount(lineScore.hits)),
            BaseballMatchStatsValueRowViewData(title: "Errors", value: formatOptionalCount(lineScore.errors))
        ]

        rows += lineScore.innings.compactMap { inning in
            guard inning.runs != nil else {
                return nil
            }

            return BaseballMatchStatsValueRowViewData(
                title: inning.label,
                value: formatOptionalCount(inning.runs)
            )
        }

        return rows
    }

    private func appendInningPeriods(
        to viewData: BaseballMatchDetailStatsViewData,
        score: BaseballMatchScore
    ) -> BaseballMatchDetailStatsViewData {
        let inningComparisonRows = makeInningComparisonRows(
            homeInnings: score.home.innings,
            awayInnings: score.away.innings
        )

        guard !inningComparisonRows.isEmpty else {
            return viewData
        }

        return BaseballMatchDetailStatsViewData(
            homeTeamName: viewData.homeTeamName,
            awayTeamName: viewData.awayTeamName,
            comparisonRows: viewData.comparisonRows + inningComparisonRows,
            homeRows: viewData.homeRows + makeInningValueRows(from: score.home.innings),
            awayRows: viewData.awayRows + makeInningValueRows(from: score.away.innings)
        )
    }

    private func makeInningValueRows(
        from innings: [BaseballMatchPeriodScore]
    ) -> [BaseballMatchStatsValueRowViewData] {
        innings.compactMap { inning in
            guard inning.runs != nil else {
                return nil
            }

            return BaseballMatchStatsValueRowViewData(
                title: inning.label,
                value: formatOptionalCount(inning.runs)
            )
        }
    }

    private func makePositiveComparisonRow(
        title: String,
        home: Double,
        away: Double
    ) -> BaseballMatchStatsComparisonRowViewData? {
        guard home > 0 || away > 0 else {
            return nil
        }

        return makeRatioComparisonRow(title: title, home: home, away: away)
    }

    private func makePeriodComparisonRow(
        title: String,
        home: Int?,
        away: Int?
    ) -> BaseballMatchStatsComparisonRowViewData? {
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
    ) -> BaseballMatchStatsComparisonRowViewData {
        let total = home + away
        let homeRatio = total > 0 ? home / total : 0.5
        let awayRatio = total > 0 ? away / total : 0.5

        return BaseballMatchStatsComparisonRowViewData(
            title: title,
            homeValue: Self.formatCount(home),
            awayValue: Self.formatCount(away),
            homeRatio: homeRatio,
            awayRatio: awayRatio
        )
    }

    private func lineScoreValue(_ value: Int?) -> Double {
        Double(value ?? 0)
    }

    private func formatOptionalCount(_ value: Int?) -> String {
        guard let value else {
            return "-"
        }

        return Self.formatCount(Double(value))
    }

    private func makeEmptyStatsViewData(from fixture: BaseballMatchFixtureDetail) -> BaseballMatchDetailStatsViewData {
        BaseballMatchDetailStatsViewData(
            homeTeamName: fixture.homeTeam.name,
            awayTeamName: fixture.awayTeam.name,
            comparisonRows: [],
            homeRows: [],
            awayRows: []
        )
    }

    private func findTeamPlayers(
        for team: BaseballMatchTeam,
        in playersByTeam: [BaseballMatchTeamPlayers],
        excluding excluded: BaseballMatchTeamPlayers? = nil
    ) -> BaseballMatchTeamPlayers? {
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

    private func aggregate(players: [BaseballMatchPlayer]) -> BaseballTeamTotals {
        var totals = BaseballTeamTotals()

        for player in players {
            for statistic in player.statistics {
                totals.atBats += statistic.batting.atBats ?? 0
                totals.hits += statistic.batting.hits ?? 0
                totals.runs += statistic.batting.runs ?? 0
                totals.homeRuns += statistic.batting.homeRuns ?? 0
                totals.runsBattedIn += statistic.batting.runsBattedIn ?? 0
                totals.walks += statistic.batting.walks ?? 0
                totals.strikeouts += statistic.batting.strikeouts ?? 0
                totals.stolenBases += statistic.batting.stolenBases ?? 0
                totals.inningsPitched += statistic.pitching.inningsPitched ?? 0
                totals.earnedRuns += statistic.pitching.earnedRuns ?? 0
                totals.errors += statistic.fielding.errors ?? 0
            }
        }

        return totals
    }

    private func makeComparisonRows(
        home: BaseballTeamTotals,
        away: BaseballTeamTotals
    ) -> [BaseballMatchStatsComparisonRowViewData] {
        let definitions: [(title: String, home: Double, away: Double, text: (Double) -> String)] = [
            ("Batting Avg", home.battingAverage, away.battingAverage, Self.formatRate),
            ("Hits", home.hits, away.hits, Self.formatCount),
            ("Home Runs", home.homeRuns, away.homeRuns, Self.formatCount),
            ("RBI", home.runsBattedIn, away.runsBattedIn, Self.formatCount),
            ("Runs", home.runs, away.runs, Self.formatCount),
            ("Stolen Bases", home.stolenBases, away.stolenBases, Self.formatCount),
            ("Walks", home.walks, away.walks, Self.formatCount),
            ("Strikeouts", home.strikeouts, away.strikeouts, Self.formatCount),
            ("Errors", home.errors, away.errors, Self.formatCount),
            ("ERA", home.earnedRunAverage, away.earnedRunAverage, Self.formatEra)
        ]

        return definitions.compactMap { definition in
            guard definition.home > 0 || definition.away > 0 else {
                return nil
            }

            let total = definition.home + definition.away
            let homeRatio = total > 0 ? definition.home / total : 0.5
            let awayRatio = total > 0 ? definition.away / total : 0.5

            return BaseballMatchStatsComparisonRowViewData(
                title: definition.title,
                homeValue: definition.text(definition.home),
                awayValue: definition.text(definition.away),
                homeRatio: homeRatio,
                awayRatio: awayRatio
            )
        }
    }

    private func makeValueRows(from totals: BaseballTeamTotals) -> [BaseballMatchStatsValueRowViewData] {
        [
            BaseballMatchStatsValueRowViewData(title: "Batting Avg", value: Self.formatRate(totals.battingAverage)),
            BaseballMatchStatsValueRowViewData(title: "Hits", value: Self.formatCount(totals.hits)),
            BaseballMatchStatsValueRowViewData(title: "Home Runs", value: Self.formatCount(totals.homeRuns)),
            BaseballMatchStatsValueRowViewData(title: "RBI", value: Self.formatCount(totals.runsBattedIn)),
            BaseballMatchStatsValueRowViewData(title: "Runs", value: Self.formatCount(totals.runs)),
            BaseballMatchStatsValueRowViewData(title: "Stolen Bases", value: Self.formatCount(totals.stolenBases)),
            BaseballMatchStatsValueRowViewData(title: "Walks", value: Self.formatCount(totals.walks)),
            BaseballMatchStatsValueRowViewData(title: "Strikeouts", value: Self.formatCount(totals.strikeouts)),
            BaseballMatchStatsValueRowViewData(title: "Errors", value: Self.formatCount(totals.errors)),
            BaseballMatchStatsValueRowViewData(title: "ERA", value: Self.formatEra(totals.earnedRunAverage))
        ]
    }

    private static func formatCount(_ value: Double) -> String {
        String(Int(value.rounded()))
    }

    private static func formatRate(_ value: Double) -> String {
        let text = String(format: "%.3f", value)
        return text.hasPrefix("0") ? String(text.dropFirst()) : text
    }

    private static func formatEra(_ value: Double) -> String {
        String(format: "%.2f", value)
    }
}

// MARK: - Team Totals

private struct BaseballTeamTotals {

    var atBats: Double = 0
    var hits: Double = 0
    var runs: Double = 0
    var homeRuns: Double = 0
    var runsBattedIn: Double = 0
    var walks: Double = 0
    var strikeouts: Double = 0
    var stolenBases: Double = 0
    var inningsPitched: Double = 0
    var earnedRuns: Double = 0
    var errors: Double = 0

    var battingAverage: Double {
        atBats > 0 ? hits / atBats : 0
    }

    var earnedRunAverage: Double {
        inningsPitched > 0 ? (earnedRuns * 9) / inningsPitched : 0
    }
}

