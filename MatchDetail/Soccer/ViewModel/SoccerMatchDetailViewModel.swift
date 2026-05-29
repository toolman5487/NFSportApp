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
        var sections: [SoccerMatchDetailSectionViewData] = [
            .header(makeHeaderViewData(from: detail.fixture))
        ]

        sections.append(.stats(makeStatsViewData(from: detail)))

        if let eventsSection = makeEventsSection(from: detail.events) {
            sections.append(.events(eventsSection))
        }

        if let lineupsSection = makeLineupsSection(from: detail) {
            sections.append(.lineups(lineupsSection))
        }

        return SoccerMatchDetailPresentation(
            title: detail.fixture.leagueName,
            sections: sections
        )
    }

    private func makeHeaderViewData(from fixture: SoccerMatchFixtureDetail) -> SoccerMatchDetailHeaderViewData {
        let statusStyle = makeStatusStyle(from: fixture)
        let statusText = makeStatusText(from: fixture)

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
            homeScoreText: fixture.score.home.map(String.init) ?? "-",
            awayScoreText: fixture.score.away.map(String.init) ?? "-",
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

    private func makeEventsSection(from events: [SoccerMatchEvent]) -> SoccerMatchDetailEventsSectionViewData? {
        guard !events.isEmpty else {
            return nil
        }

        return SoccerMatchDetailEventsSectionViewData(
            title: "Events",
            items: events.map { event in
                SoccerMatchDetailEventViewData(
                    id: event.id,
                    timeText: makeEventTimeText(from: event),
                    title: makeEventTitle(from: event),
                    subtitle: makeEventSubtitle(from: event)
                )
            }
        )
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

        var teams: [SoccerMatchDetailLineupViewData] = []

        if let homeLineup {
            teams.append(makeLineupViewData(from: homeLineup))
        }

        if let awayLineup {
            teams.append(makeLineupViewData(from: awayLineup))
        }

        guard !teams.isEmpty else {
            return nil
        }

        return SoccerMatchDetailLineupsSectionViewData(
            title: "Lineups",
            teams: teams
        )
    }

    private func makeLineupViewData(from lineup: SoccerMatchLineup) -> SoccerMatchDetailLineupViewData {
        SoccerMatchDetailLineupViewData(
            teamName: lineup.team.name,
            formationText: lineup.formation,
            coachName: lineup.coachName,
            starters: lineup.startXI.map(formatLineupPlayer),
            substitutes: lineup.substitutes.map(formatLineupPlayer)
        )
    }

    private func formatLineupPlayer(_ player: SoccerMatchLineupPlayer) -> String {
        if let number = player.number {
            return "#\(number) \(player.name)"
        }

        return player.name
    }

    // MARK: - Stats Aggregation

    private func makeStatsViewData(from detail: SoccerMatchDetail) -> SoccerMatchDetailStatsViewData {
        let fixture = detail.fixture

        guard let homeStatistics = detail.statistics.first(where: { matchesTeam($0.team, fixture.homeTeam) }),
              let awayStatistics = detail.statistics.first(where: { matchesTeam($0.team, fixture.awayTeam) }) else {
            return makeScoreOnlyStatsViewData(from: fixture)
        }

        let homeValuesByType = Dictionary(uniqueKeysWithValues: homeStatistics.statistics.map { ($0.type, $0.value) })
        let awayValuesByType = Dictionary(uniqueKeysWithValues: awayStatistics.statistics.map { ($0.type, $0.value) })
        let allTypes = Array(Set(homeValuesByType.keys).union(awayValuesByType.keys))
        let orderedTypes = allTypes.sorted(by: compareStatisticType)

        var comparisonRows: [SoccerMatchStatsComparisonRowViewData] = []
        var homeRows: [SoccerMatchStatsValueRowViewData] = []
        var awayRows: [SoccerMatchStatsValueRowViewData] = []

        appendGoalsRows(
            from: fixture.score,
            comparisonRows: &comparisonRows,
            homeRows: &homeRows,
            awayRows: &awayRows
        )

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

        return SoccerMatchDetailStatsViewData(
            homeTeamName: fixture.homeTeam.name,
            awayTeamName: fixture.awayTeam.name,
            comparisonRows: comparisonRows,
            homeRows: homeRows,
            awayRows: awayRows
        )
    }

    private func makeScoreOnlyStatsViewData(
        from fixture: SoccerMatchFixtureDetail
    ) -> SoccerMatchDetailStatsViewData {
        var comparisonRows: [SoccerMatchStatsComparisonRowViewData] = []
        var homeRows: [SoccerMatchStatsValueRowViewData] = []
        var awayRows: [SoccerMatchStatsValueRowViewData] = []

        appendGoalsRows(
            from: fixture.score,
            comparisonRows: &comparisonRows,
            homeRows: &homeRows,
            awayRows: &awayRows
        )

        return SoccerMatchDetailStatsViewData(
            homeTeamName: fixture.homeTeam.name,
            awayTeamName: fixture.awayTeam.name,
            comparisonRows: comparisonRows,
            homeRows: homeRows,
            awayRows: awayRows
        )
    }

    private func appendGoalsRows(
        from score: SoccerMatchScore,
        comparisonRows: inout [SoccerMatchStatsComparisonRowViewData],
        homeRows: inout [SoccerMatchStatsValueRowViewData],
        awayRows: inout [SoccerMatchStatsValueRowViewData]
    ) {
        guard score.home != nil || score.away != nil else {
            return
        }

        let homeGoals = Double(score.home ?? 0)
        let awayGoals = Double(score.away ?? 0)

        comparisonRows.append(
            makeRatioComparisonRow(
                title: "Goals",
                home: homeGoals,
                away: awayGoals,
                homeDisplay: formatOptionalCount(score.home),
                awayDisplay: formatOptionalCount(score.away)
            )
        )
        homeRows.append(
            SoccerMatchStatsValueRowViewData(
                title: "Goals",
                value: formatOptionalCount(score.home)
            )
        )
        awayRows.append(
            SoccerMatchStatsValueRowViewData(
                title: "Goals",
                value: formatOptionalCount(score.away)
            )
        )
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

        return lhs.name == rhs.name
    }

    // MARK: - Status Mapping

    private func makeStatusText(from fixture: SoccerMatchFixtureDetail) -> String {
        let statusShort = fixture.statusShort?.lowercased()
        let statusLong = fixture.statusLong?.lowercased()
        let normalizedStatus = statusShort ?? statusLong

        if let elapsedMinute = fixture.elapsedMinute,
           let normalizedStatus,
           normalizedStatus == "1h"
            || normalizedStatus == "2h"
            || normalizedStatus == "et"
            || normalizedStatus == "bt"
            || normalizedStatus == "live" {
            return "\(elapsedMinute)'"
        }

        guard let normalizedStatus else {
            return "Scheduled"
        }

        switch normalizedStatus {
        case "ns", "not started":
            return "Scheduled"
        case "tbd", "time to be defined":
            return "TBD"
        case "1h", "2h", "live":
            return "Live"
        case "ht", "half time":
            return "Half Time"
        case "et", "extra time":
            return "Extra Time"
        case "bt", "break time":
            return "Break"
        case "p", "pen", "penalty in progress":
            return "Penalties"
        case "ft", "aet", "aft", "final", "match finished":
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

    private func makeStatusStyle(from fixture: SoccerMatchFixtureDetail) -> SoccerMatchDetailHeaderStatusStyle {
        let normalizedStatus = fixture.statusShort?.lowercased() ?? fixture.statusLong?.lowercased()

        guard let normalizedStatus else {
            return .neutral
        }

        switch normalizedStatus {
        case let status where status.contains("1h")
            || status.contains("2h")
            || status.contains("half")
            || status.contains("live")
            || status.contains("et")
            || status.contains("bt")
            || status.contains("p"):
            return .live

        case let status where status.contains("ft")
            || status.contains("aet")
            || status.contains("pen")
            || status.contains("finish")
            || status.contains("final")
            || status.contains("ended"):
            return .final

        case let status where status.contains("ns")
            || status.contains("scheduled")
            || status.contains("not started")
            || status.contains("time to be defined"):
            return .upcoming

        case let status where status.contains("postponed")
            || status == "pst":
            return .postponed

        case let status where status.contains("cancel")
            || status.contains("abandoned")
            || status.contains("suspended")
            || status.contains("interrupted")
            || status == "abd"
            || status == "int"
            || status == "canc"
            || status == "susp":
            return .cancelled

        default:
            return .neutral
        }
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
