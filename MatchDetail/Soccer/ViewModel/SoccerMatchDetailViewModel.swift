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

        if let statisticsSection = makeStatisticsSection(from: detail) {
            sections.append(.statistics(statisticsSection))
        }

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

    // MARK: - Section Builders

    private func makeStatisticsSection(from detail: SoccerMatchDetail) -> SoccerMatchDetailStatisticsSectionViewData? {
        guard let homeStatistics = detail.statistics.first(where: { matchesTeam($0.team, detail.fixture.homeTeam) }),
              let awayStatistics = detail.statistics.first(where: { matchesTeam($0.team, detail.fixture.awayTeam) }) else {
            return nil
        }

        let homeValuesByType = Dictionary(uniqueKeysWithValues: homeStatistics.statistics.map { ($0.type, $0.value) })
        let awayValuesByType = Dictionary(uniqueKeysWithValues: awayStatistics.statistics.map { ($0.type, $0.value) })
        let allTypes = Array(Set(homeValuesByType.keys).union(awayValuesByType.keys))
        let orderedTypes = allTypes.sorted(by: compareStatisticType)

        let rows: [SoccerMatchDetailStatisticRowViewData] = orderedTypes.compactMap { type -> SoccerMatchDetailStatisticRowViewData? in
            let homeValue = homeValuesByType[type] ?? nil
            let awayValue = awayValuesByType[type] ?? nil

            guard homeValue != nil || awayValue != nil else {
                return nil
            }

            return SoccerMatchDetailStatisticRowViewData(
                title: type,
                homeValueText: homeValue ?? "-",
                awayValueText: awayValue ?? "-"
            )
        }

        guard !rows.isEmpty else {
            return nil
        }

        return SoccerMatchDetailStatisticsSectionViewData(
            title: "Statistics",
            rows: rows
        )
    }

    private func compareStatisticType(lhs: String, rhs: String) -> Bool {
        let lhsIndex = Constant.preferredStatisticOrder.firstIndex(of: lhs) ?? Int.max
        let rhsIndex = Constant.preferredStatisticOrder.firstIndex(of: rhs) ?? Int.max

        if lhsIndex != rhsIndex {
            return lhsIndex < rhsIndex
        }

        return lhs.localizedStandardCompare(rhs) == .orderedAscending
    }

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
                    teamName: event.team?.name,
                    title: event.detail ?? event.type,
                    subtitle: makeEventSubtitle(from: event)
                )
            }
        )
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
        let primaryText = event.playerName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let assistText = event.assistName?.trimmingCharacters(in: .whitespacesAndNewlines)

        switch (primaryText?.isEmpty == false ? primaryText : nil, assistText?.isEmpty == false ? assistText : nil) {
        case (.some(let playerName), .some(let assistName)):
            return "\(playerName) · Assist: \(assistName)"

        case (.some(let playerName), .none):
            return playerName

        case (.none, .some(let assistName)):
            return "Assist: \(assistName)"

        case (.none, .none):
            return event.comments
        }
    }

    private func makeLineupsSection(from detail: SoccerMatchDetail) -> SoccerMatchDetailLineupsSectionViewData? {
        let homeLineup = detail.lineups.first { matchesTeam($0.team, detail.fixture.homeTeam) }
        let awayLineup = detail.lineups.first { matchesTeam($0.team, detail.fixture.awayTeam) }

        guard homeLineup != nil || awayLineup != nil else {
            return nil
        }

        return SoccerMatchDetailLineupsSectionViewData(
            title: "Lineups",
            home: homeLineup.map(makeLineupViewData),
            away: awayLineup.map(makeLineupViewData)
        )
    }

    private func makeLineupViewData(from lineup: SoccerMatchLineup) -> SoccerMatchDetailLineupViewData {
        SoccerMatchDetailLineupViewData(
            teamName: lineup.team.name,
            formationText: lineup.formation,
            coachName: lineup.coachName,
            starters: lineup.startXI.map(\.name),
            substitutes: lineup.substitutes.map(\.name)
        )
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
