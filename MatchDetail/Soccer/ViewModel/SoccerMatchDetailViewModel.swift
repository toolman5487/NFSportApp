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

    init(
        fixtureID: Int,
        detailService: SoccerMatchDetailServicing
    ) {
        self.fixtureID = fixtureID
        self.detailService = detailService
    }

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
        SoccerMatchDetailHeaderViewData(
            leagueName: fixture.leagueName,
            leagueLogoURL: fixture.leagueLogoURL,
            statusText: makeStatusText(from: fixture),
            statusStyle: makeStatusStyle(from: fixture),
            timeText: makeTimeText(
                from: fixture.scheduledStartDate,
                fallback: fixture.scheduledStartText ?? "TBD"
            ),
            venueText: makeVenueText(from: fixture),
            homeTeamName: fixture.homeTeam.name,
            homeTeamLogoURL: fixture.homeTeam.logoURL,
            awayTeamName: fixture.awayTeam.name,
            awayTeamLogoURL: fixture.awayTeam.logoURL,
            homeScoreText: fixture.score.home.map(String.init) ?? "-",
            awayScoreText: fixture.score.away.map(String.init) ?? "-"
        )
    }

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

    private func matchesTeam(_ lhs: SoccerMatchTeam, _ rhs: SoccerMatchTeam) -> Bool {
        if let lhsID = lhs.teamID,
           let rhsID = rhs.teamID {
            return lhsID == rhsID
        }

        return lhs.name == rhs.name
    }

    private func makeStatusText(from fixture: SoccerMatchFixtureDetail) -> String {
        if let elapsedMinute = fixture.elapsedMinute,
           let statusShort = fixture.statusShort?.lowercased(),
           statusShort == "1h" || statusShort == "2h" || statusShort == "et" || statusShort == "bt" || statusShort == "p" {
            return "\(elapsedMinute)'"
        }

        return fixture.statusShort ?? fixture.statusLong ?? "Scheduled"
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

        default:
            return .neutral
        }
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

    private func makeVenueText(from fixture: SoccerMatchFixtureDetail) -> String? {
        let components: [String] = [
            fixture.venueName?.trimmingCharacters(in: .whitespacesAndNewlines),
            fixture.venueCity?.trimmingCharacters(in: .whitespacesAndNewlines)
        ].compactMap { component in
            guard let component,
                  !component.isEmpty else {
                return nil
            }

            return component
        }

        guard !components.isEmpty else {
            return nil
        }

        return components.joined(separator: " · ")
    }
}
