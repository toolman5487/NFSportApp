//
//  SoccerMatchDetailViewModel.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/26.
//

import Foundation

// MARK: - State

nonisolated enum SoccerMatchDetailViewState: Equatable, Sendable {

    case idle
    case loading
    case loaded(SoccerMatchDetailPresentation)
    case failed(message: String)
}

// MARK: - SoccerMatchDetailViewModel

@MainActor
final class SoccerMatchDetailViewModel {

    // MARK: - Constants

    private enum Constant {
        static let preferredStatisticOrder: [String] = [
            "Ball Possession",
            "Shots on Goal",
            "Shots off Goal",
            "Total Shots",
            "Blocked Shots",
            "Shots insidebox",
            "Shots outsidebox",
            "Corner Kicks",
            "Offsides",
            "Fouls",
            "Yellow Cards",
            "Red Cards",
            "Goalkeeper Saves",
            "Total passes",
            "Passes accurate",
            "Passes %"
        ]
    }

    // MARK: - Properties

    private(set) var state: SoccerMatchDetailViewState = .idle {
        didSet {
            onStateChange?(state)
        }
    }

    var onStateChange: ((SoccerMatchDetailViewState) -> Void)?

    var title: String {
        "Match Detail"
    }

    private let fixtureID: Int
    private let detailService: SoccerMatchDetailServicing
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = .current
        calendar.timeZone = .current
        return calendar
    }()

    // MARK: - Initialization

    init(
        fixtureID: Int,
        detailService: SoccerMatchDetailServicing
    ) {
        self.fixtureID = fixtureID
        self.detailService = detailService
    }

    // MARK: - Actions

    func loadMatchDetail() async {
        state = .loading

        do {
            let detail = try await detailService.fetchMatchDetail(fixtureID: fixtureID)
            state = .loaded(makePresentation(from: detail))
        } catch {
            state = .failed(message: error.localizedDescription)
            AppLogger.logUIError(
                error,
                message: "Soccer match detail loading failed",
                metadata: "fixtureID=\(fixtureID)"
            )
        }
    }

    // MARK: - Presentation Builders

    private func makePresentation(from detail: SoccerMatchDetail) -> SoccerMatchDetailPresentation {
        let phase = makePhase(from: detail.fixture)
        let displayPolicy = phase.displayPolicy(for: .soccer)

        var sections: [SoccerMatchDetailSectionViewData] = [
            .header(makeHeaderViewData(from: detail.fixture, phase: phase))
        ]

        if displayPolicy.showsStatsSection {
            sections.append(.stats(makeStatsViewData(from: detail, phase: phase)))
        }

        if displayPolicy.showsEventsSection,
           let eventsSection = makeEventsSection(from: detail.events, fixture: detail.fixture) {
            sections.append(.events(eventsSection))
        }

        if displayPolicy.showsLineupsSection,
           let lineupsSection = makeLineupsSection(from: detail) {
            sections.append(.lineups(lineupsSection))
        }

        return SoccerMatchDetailPresentation(
            title: detail.fixture.leagueName,
            sections: sections
        )
    }

    private func makePhase(from fixture: SoccerMatchFixtureDetail) -> MatchFixturePhase {
        MatchFixturePhase(
            sport: .soccer,
            snapshot: MatchFixtureStatusSnapshot.make(
                statusShort: fixture.statusShort,
                statusLong: fixture.statusLong,
                elapsedMinute: fixture.elapsedMinute
            )
        )
    }

    private func makeHeaderViewData(
        from fixture: SoccerMatchFixtureDetail,
        phase: MatchFixturePhase
    ) -> SoccerMatchDetailHeaderViewData {
        let statusStyle = SoccerMatchDetailHeaderStatusStyle(
            matchNavigationStyle: phase.navigationStatusStyle
        )
        let statusText = phase.statusText(
            fallbackStatusLong: fixture.statusLong,
            fallbackStatusShort: fixture.statusShort
        )
        let showsScore = phase.displayPolicy(for: .soccer).showsHeaderScore

        return SoccerMatchDetailHeaderViewData(
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
            homeScoreText: showsScore ? formatOptionalCount(fixture.score.home) : "-",
            awayScoreText: showsScore ? formatOptionalCount(fixture.score.away) : "-",
            venue: makeVenueSection(from: fixture)
        )
    }

    // MARK: - Navigation Badge

    private func makeNavigationStatusStyle(
        from statusStyle: SoccerMatchDetailHeaderStatusStyle
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

    private func makeNavigationBadgeViewData(
        text: String,
        statusStyle: SoccerMatchDetailHeaderStatusStyle
    ) -> MatchDetailNavigationBadgeViewData {
        MatchDetailNavigationBadgeViewData(
            text: text,
            style: makeNavigationStatusStyle(from: statusStyle)
        )
    }

    // MARK: - Events & Lineups

    private func makeEventsSection(
        from events: [SoccerMatchEvent],
        fixture: SoccerMatchFixtureDetail
    ) -> SoccerMatchDetailEventsSectionViewData? {
        guard !events.isEmpty else {
            return nil
        }

        return SoccerMatchDetailEventsSectionViewData(
            title: "Events",
            items: events.map { event in
                SoccerMatchDetailEventViewData(
                    id: event.id,
                    side: makeEventSide(from: event, fixture: fixture),
                    iconSystemName: makeEventIconSystemName(from: event),
                    timeText: makeEventTimeText(from: event),
                    title: makeEventTitle(from: event),
                    subtitle: makeEventSubtitle(from: event)
                )
            }
        )
    }

    private func makeEventSide(
        from event: SoccerMatchEvent,
        fixture: SoccerMatchFixtureDetail
    ) -> SoccerMatchDetailEventSide {
        guard let eventTeam = event.team else {
            return .neutral
        }

        if matchesTeam(eventTeam, fixture.homeTeam) {
            return .home
        }

        if matchesTeam(eventTeam, fixture.awayTeam) {
            return .away
        }

        return .neutral
    }

    private func makeEventIconSystemName(from event: SoccerMatchEvent) -> String {
        let type = event.type.lowercased()
        let detail = event.detail?.lowercased() ?? ""

        if type.contains("goal") || detail.contains("goal") || detail.contains("penalty") {
            return "soccerball"
        }

        if type.contains("card") || detail.contains("card") {
            return detail.contains("red") ? "rectangle.fill" : "rectangle"
        }

        if type.contains("subst") || detail.contains("subst") {
            return "arrow.left.arrow.right"
        }

        if type.contains("var") || detail.contains("var") {
            return "video"
        }

        return "circle.fill"
    }

    private func makeEventTitle(from event: SoccerMatchEvent) -> String {
        let detail = event.detail?.trimmingCharacters(in: .whitespacesAndNewlines)
        let type = event.type.trimmingCharacters(in: .whitespacesAndNewlines)

        if let detail, !detail.isEmpty {
            return detail
        }

        return type.isEmpty ? "Event" : type
    }

    private func makeEventTimeText(from event: SoccerMatchEvent) -> String {
        switch (event.elapsedMinute, event.extraMinute) {
        case (.some(let elapsed), .some(let extra)):
            return "\(elapsed)+\(extra)'"

        case (.some(let elapsed), .none):
            return "\(elapsed)'"

        case (.none, _):
            return event.type
        }
    }

    private func makeEventSubtitle(from event: SoccerMatchEvent) -> String? {
        var parts: [String] = []

        if let teamName = event.team?.name.trimmingCharacters(in: .whitespacesAndNewlines),
           !teamName.isEmpty {
            parts.append(teamName)
        }

        let playerName = event.playerName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let assistName = event.assistName?.trimmingCharacters(in: .whitespacesAndNewlines)

        switch (playerName?.isEmpty == false ? playerName : nil, assistName?.isEmpty == false ? assistName : nil) {
        case (.some(let player), .some(let assist)):
            parts.append("\(player) · Assist: \(assist)")

        case (.some(let player), .none):
            parts.append(player)

        case (.none, .some(let assist)):
            parts.append("Assist: \(assist)")

        case (.none, .none):
            break
        }

        if let comments = event.comments?.trimmingCharacters(in: .whitespacesAndNewlines),
           !comments.isEmpty {
            parts.append(comments)
        }

        guard !parts.isEmpty else {
            return nil
        }

        return parts.joined(separator: "\n")
    }

    private func makeLineupsSection(from detail: SoccerMatchDetail) -> SoccerMatchDetailLineupsSectionViewData? {
        let homeLineup = detail.lineups.first { matchesTeam($0.team, detail.fixture.homeTeam) }
        let awayLineup = detail.lineups.first { matchesTeam($0.team, detail.fixture.awayTeam) }

        let rows = makeLineupComparisonRows(
            homePlayers: homeLineup?.startXI ?? [],
            awayPlayers: awayLineup?.startXI ?? []
        )

        guard !rows.isEmpty else {
            return nil
        }

        return SoccerMatchDetailLineupsSectionViewData(
            title: "Lineups",
            homeTeamName: detail.fixture.homeTeam.name,
            awayTeamName: detail.fixture.awayTeam.name,
            homeMetaText: makeLineupMetaText(from: homeLineup),
            awayMetaText: makeLineupMetaText(from: awayLineup),
            rows: rows
        )
    }

    private func makeLineupMetaText(from lineup: SoccerMatchLineup?) -> String? {
        guard let lineup else {
            return nil
        }

        var parts: [String] = []
        if let formation = lineup.formation?.trimmingCharacters(in: .whitespacesAndNewlines),
           !formation.isEmpty {
            parts.append(formation)
        }
        if let coachName = lineup.coachName?.trimmingCharacters(in: .whitespacesAndNewlines),
           !coachName.isEmpty {
            parts.append("Coach: \(coachName)")
        }

        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private func makeLineupComparisonRows(
        homePlayers: [SoccerMatchLineupPlayer],
        awayPlayers: [SoccerMatchLineupPlayer]
    ) -> [SoccerMatchLineupComparisonRowViewData] {
        SoccerMatchLineupPositionGroup.allCases.flatMap { group in
            let homeGroupPlayers = sortedLineupPlayers(
                homePlayers.filter { makePositionGroup(from: $0) == group }
            )
            let awayGroupPlayers = sortedLineupPlayers(
                awayPlayers.filter { makePositionGroup(from: $0) == group }
            )
            let rowCount = max(homeGroupPlayers.count, awayGroupPlayers.count)

            return (0..<rowCount).map { index in
                SoccerMatchLineupComparisonRowViewData(
                    positionTitle: index == 0 ? group.rawValue : nil,
                    homePlayer: homeGroupPlayers.indices.contains(index)
                        ? makeLineupPlayerViewData(from: homeGroupPlayers[index])
                        : nil,
                    awayPlayer: awayGroupPlayers.indices.contains(index)
                        ? makeLineupPlayerViewData(from: awayGroupPlayers[index])
                        : nil
                )
            }
        }
    }

    private func makeLineupPlayerViewData(from player: SoccerMatchLineupPlayer) -> SoccerMatchLineupPlayerViewData {
        SoccerMatchLineupPlayerViewData(
            id: player.id,
            displayName: player.name,
            numberText: player.number.map { "#\($0)" },
            photoURL: player.photoURL
        )
    }

    private func makePositionGroup(from player: SoccerMatchLineupPlayer) -> SoccerMatchLineupPositionGroup {
        switch player.position?.uppercased() {
        case .some("G"):
            return .goalkeeper
        case .some("D"):
            return .defender
        case .some("M"):
            return .midfielder
        case .some("F"):
            return .forward
        default:
            return .other
        }
    }

    private func sortedLineupPlayers(_ players: [SoccerMatchLineupPlayer]) -> [SoccerMatchLineupPlayer] {
        players.sorted { lhs, rhs in
            switch (lineupGridOrder(lhs.grid), lineupGridOrder(rhs.grid)) {
            case (.some(let lhsOrder), .some(let rhsOrder)):
                return lhsOrder < rhsOrder
            case (.some, .none):
                return true
            case (.none, .some):
                return false
            case (.none, .none):
                return (lhs.number ?? Int.max) < (rhs.number ?? Int.max)
            }
        }
    }

    private func lineupGridOrder(_ grid: String?) -> Int? {
        guard let grid else {
            return nil
        }

        let parts = grid.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else {
            return nil
        }

        return parts[0] * 100 + parts[1]
    }

    // MARK: - Stats Aggregation

    private func makeStatsViewData(
        from detail: SoccerMatchDetail,
        phase: MatchFixturePhase
    ) -> SoccerMatchDetailStatsViewData {
        let fixture = detail.fixture
        let displayPolicy = phase.displayPolicy(for: .soccer)

        var comparisonRows: [SoccerMatchStatsComparisonRowViewData] = []
        var homeRows: [SoccerMatchStatsValueRowViewData] = []
        var awayRows: [SoccerMatchStatsValueRowViewData] = []

        if displayPolicy.showsScoreBreakdownInStats {
            appendScoreRows(
                from: fixture.score,
                style: phase.scoreBreakdownStyle,
                comparisonRows: &comparisonRows,
                homeRows: &homeRows,
                awayRows: &awayRows
            )
        }

        if displayPolicy.showsDetailedStatistics,
           let (homeStatistics, awayStatistics) = resolveTeamStatistics(
               from: detail.statistics,
               fixture: fixture
           ) {
            let homeValuesByType = Dictionary(uniqueKeysWithValues: homeStatistics.statistics.map { ($0.type, $0.value) })
            let awayValuesByType = Dictionary(uniqueKeysWithValues: awayStatistics.statistics.map { ($0.type, $0.value) })
            let allTypes = Array(Set(homeValuesByType.keys).union(awayValuesByType.keys))
            let orderedTypes = allTypes.sorted(by: compareStatisticType)

            for type in orderedTypes {
                let homeValue = homeValuesByType[type] ?? nil
                let awayValue = awayValuesByType[type] ?? nil

                guard homeValue != nil || awayValue != nil else {
                    continue
                }

                comparisonRows.append(
                    makeStatisticComparisonRow(
                        title: type,
                        homeValue: homeValue,
                        awayValue: awayValue
                    )
                )

                homeRows.append(
                    SoccerMatchStatsValueRowViewData(
                        title: type,
                        value: homeValue ?? "-"
                    )
                )
                awayRows.append(
                    SoccerMatchStatsValueRowViewData(
                        title: type,
                        value: awayValue ?? "-"
                    )
                )
            }
        }

        return finalizeStatsViewData(
            fixture: fixture,
            phase: phase,
            comparisonRows: comparisonRows,
            homeRows: homeRows,
            awayRows: awayRows
        )
    }

    private func finalizeStatsViewData(
        fixture: SoccerMatchFixtureDetail,
        phase: MatchFixturePhase,
        comparisonRows: [SoccerMatchStatsComparisonRowViewData],
        homeRows: [SoccerMatchStatsValueRowViewData],
        awayRows: [SoccerMatchStatsValueRowViewData]
    ) -> SoccerMatchDetailStatsViewData {
        let metadata = phase.statsViewMetadata(
            hasRows: !comparisonRows.isEmpty,
            sport: .soccer
        )

        return SoccerMatchDetailStatsViewData(
            homeTeamName: fixture.homeTeam.name,
            awayTeamName: fixture.awayTeam.name,
            displayState: metadata.displayState,
            showsFilter: metadata.showsFilter,
            comparisonRows: comparisonRows,
            homeRows: homeRows,
            awayRows: awayRows
        )
    }

    private func appendScoreRows(
        from score: SoccerMatchScore,
        style: MatchFixturePhase.ScoreBreakdownStyle,
        comparisonRows: inout [SoccerMatchStatsComparisonRowViewData],
        homeRows: inout [SoccerMatchStatsValueRowViewData],
        awayRows: inout [SoccerMatchStatsValueRowViewData]
    ) {
        switch style {
        case .none:
            return

        case .live:
            if let halftime = score.halftime, halftime.hasValue {
                appendScoreLineRow(
                    title: "Half-time",
                    line: halftime,
                    comparisonRows: &comparisonRows,
                    homeRows: &homeRows,
                    awayRows: &awayRows
                )
            }

            let liveScoreLine = SoccerMatchScoreLine(home: score.home, away: score.away)
            if liveScoreLine.hasValue {
                appendScoreLineRow(
                    title: "Score",
                    line: liveScoreLine,
                    comparisonRows: &comparisonRows,
                    homeRows: &homeRows,
                    awayRows: &awayRows
                )
            }

        case .finished:
            if let halftime = score.halftime, halftime.hasValue {
                appendScoreLineRow(
                    title: "Half-time",
                    line: halftime,
                    comparisonRows: &comparisonRows,
                    homeRows: &homeRows,
                    awayRows: &awayRows
                )
            }

            let fulltimeLine = score.fulltime ?? SoccerMatchScoreLine(home: score.home, away: score.away)
            if fulltimeLine.hasValue {
                appendScoreLineRow(
                    title: "Full-time",
                    line: fulltimeLine,
                    comparisonRows: &comparisonRows,
                    homeRows: &homeRows,
                    awayRows: &awayRows
                )
            }

            if let extratime = score.extratime, extratime.hasValue {
                appendScoreLineRow(
                    title: "Extra Time",
                    line: extratime,
                    comparisonRows: &comparisonRows,
                    homeRows: &homeRows,
                    awayRows: &awayRows
                )
            }

            if let penalty = score.penalty, penalty.hasValue {
                appendScoreLineRow(
                    title: "Penalties",
                    line: penalty,
                    comparisonRows: &comparisonRows,
                    homeRows: &homeRows,
                    awayRows: &awayRows
                )
            }
        }
    }

    private func appendScoreLineRow(
        title: String,
        line: SoccerMatchScoreLine,
        comparisonRows: inout [SoccerMatchStatsComparisonRowViewData],
        homeRows: inout [SoccerMatchStatsValueRowViewData],
        awayRows: inout [SoccerMatchStatsValueRowViewData]
    ) {
        let homeValue = Double(line.home ?? 0)
        let awayValue = Double(line.away ?? 0)

        comparisonRows.append(
            makeRatioComparisonRow(
                title: title,
                home: homeValue,
                away: awayValue,
                homeDisplay: formatOptionalCount(line.home),
                awayDisplay: formatOptionalCount(line.away)
            )
        )
        homeRows.append(
            SoccerMatchStatsValueRowViewData(
                title: title,
                value: formatOptionalCount(line.home)
            )
        )
        awayRows.append(
            SoccerMatchStatsValueRowViewData(
                title: title,
                value: formatOptionalCount(line.away)
            )
        )
    }

    private func resolveTeamStatistics(
        from statistics: [SoccerMatchTeamStatistics],
        fixture: SoccerMatchFixtureDetail
    ) -> (home: SoccerMatchTeamStatistics, away: SoccerMatchTeamStatistics)? {
        guard !statistics.isEmpty else {
            return nil
        }

        if let homeStatistics = statistics.first(where: { matchesTeam($0.team, fixture.homeTeam) }),
           let awayStatistics = statistics.first(where: { matchesTeam($0.team, fixture.awayTeam) }),
           !homeStatistics.statistics.isEmpty || !awayStatistics.statistics.isEmpty {
            return (homeStatistics, awayStatistics)
        }

        guard statistics.count == 2 else {
            return nil
        }

        let first = statistics[0]
        let second = statistics[1]
        guard !first.statistics.isEmpty || !second.statistics.isEmpty else {
            return nil
        }

        if matchesTeam(first.team, fixture.homeTeam) {
            return (first, second)
        }

        if matchesTeam(first.team, fixture.awayTeam) {
            return (second, first)
        }

        return (first, second)
    }

    private func makeStatisticComparisonRow(
        title: String,
        homeValue: String?,
        awayValue: String?
    ) -> SoccerMatchStatsComparisonRowViewData {
        let homeNumeric = parseStatNumber(homeValue)
        let awayNumeric = parseStatNumber(awayValue)
        let home = homeNumeric ?? 0
        let away = awayNumeric ?? 0

        return makeRatioComparisonRow(
            title: title,
            home: home,
            away: away,
            homeDisplay: homeValue ?? "-",
            awayDisplay: awayValue ?? "-"
        )
    }

    private func makeRatioComparisonRow(
        title: String,
        home: Double,
        away: Double,
        homeDisplay: String? = nil,
        awayDisplay: String? = nil
    ) -> SoccerMatchStatsComparisonRowViewData {
        let total = home + away
        let homeRatio = total > 0 ? home / total : 0.5
        let awayRatio = total > 0 ? away / total : 0.5

        return SoccerMatchStatsComparisonRowViewData(
            title: title,
            homeValue: homeDisplay ?? formatCount(home),
            awayValue: awayDisplay ?? formatCount(away),
            homeRatio: homeRatio,
            awayRatio: awayRatio
        )
    }

    private func parseStatNumber(_ value: String?) -> Double? {
        guard let value else {
            return nil
        }

        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else {
            return nil
        }

        let normalizedValue = trimmedValue
            .replacingOccurrences(of: "%", with: "")
            .replacingOccurrences(of: ",", with: "")

        return Double(normalizedValue)
    }

    private func formatCount(_ value: Double) -> String {
        if value.rounded() == value {
            return String(Int(value.rounded()))
        }

        return String(format: "%.1f", value)
    }

    private func formatOptionalCount(_ value: Int?) -> String {
        guard let value else {
            return "-"
        }

        return String(value)
    }

    private func compareStatisticType(lhs: String, rhs: String) -> Bool {
        let lhsIndex = Constant.preferredStatisticOrder.firstIndex(of: lhs) ?? Int.max
        let rhsIndex = Constant.preferredStatisticOrder.firstIndex(of: rhs) ?? Int.max

        if lhsIndex != rhsIndex {
            return lhsIndex < rhsIndex
        }

        return lhs.localizedStandardCompare(rhs) == .orderedAscending
    }

    private func makeVenueSection(from fixture: SoccerMatchFixtureDetail) -> SoccerMatchDetailVenueViewData? {
        let venueParts = [fixture.venueName, fixture.venueCity]
            .compactMap { value in
                let trimmedValue = value?.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmedValue?.isEmpty == false ? trimmedValue : nil
            }

        guard !venueParts.isEmpty else {
            return nil
        }

        return SoccerMatchDetailVenueViewData(
            venueText: venueParts.joined(separator: ", ")
        )
    }

    // MARK: - Team Matching

    private func matchesTeam(_ lhs: SoccerMatchTeam, _ rhs: SoccerMatchTeam) -> Bool {
        if let lhsID = lhs.teamID,
           let rhsID = rhs.teamID {
            return lhsID == rhsID
        }

        return lhs.name.caseInsensitiveCompare(rhs.name) == .orderedSame
    }

    // MARK: - Helpers

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
}
