//
//  MatchFixturePhase.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/29.
//

import Foundation

// MARK: - MatchFixturePhase

nonisolated enum MatchFixturePhase: Equatable, Sendable {

    case scheduled
    case live(elapsedMinute: Int?, periodLabel: String?)
    case halfTime(elapsedMinute: Int?)
    case breakTime(elapsedMinute: Int?)
    case extraTime(elapsedMinute: Int?)
    case overtime(elapsedMinute: Int?, periodLabel: String?)
    case penalties(elapsedMinute: Int?)
    case finished
    case postponed
    case cancelled
    case suspended
    case neutral

    init(sport: MatchFixtureSport, snapshot: MatchFixtureStatusSnapshot) {
        switch sport {
        case .soccer:
            self = Self.resolveSoccerPhase(from: snapshot)

        case .basketball:
            self = Self.resolveBasketballPhase(from: snapshot)

        case .baseball:
            self = Self.resolveBaseballPhase(from: snapshot)
        }
    }
}

// MARK: - Display Policy

extension MatchFixturePhase {

    nonisolated struct DisplayPolicy: Equatable, Sendable {

        let showsHeaderScore: Bool
        let showsStatsSection: Bool
        let showsStatsFilter: Bool
        let showsScoreBreakdownInStats: Bool
        let showsDetailedStatistics: Bool
        let showsEventsSection: Bool
        let showsLineupsSection: Bool
        let statsEmptyTitle: String
        let statsEmptySubtitle: String
    }

    func displayPolicy(for sport: MatchFixtureSport) -> DisplayPolicy {
        switch sport {
        case .soccer:
            return soccerDisplayPolicy

        case .basketball, .baseball:
            return teamSportsDisplayPolicy
        }
    }

    nonisolated enum ScoreBreakdownStyle: Equatable, Sendable {
        case none
        case live
        case finished
    }

    var scoreBreakdownStyle: ScoreBreakdownStyle {
        switch self {
        case .scheduled, .postponed, .cancelled:
            return .none

        case .finished:
            return .finished

        case .live, .halfTime, .breakTime, .extraTime, .overtime, .penalties, .suspended, .neutral:
            return .live
        }
    }

    var navigationStatusStyle: MatchDetailNavigationStatusStyle {
        switch self {
        case .scheduled:
            return .upcoming

        case .live, .halfTime, .breakTime, .extraTime, .overtime, .penalties:
            return .live

        case .finished:
            return .final

        case .postponed:
            return .postponed

        case .cancelled:
            return .cancelled

        case .suspended, .neutral:
            return .neutral
        }
    }

    func statusText(
        fallbackStatusLong: String? = nil,
        fallbackStatusShort: String? = nil
    ) -> String {
        switch self {
        case .scheduled:
            return "Scheduled"

        case .live(let elapsedMinute, let periodLabel):
            if let periodLabel, !periodLabel.isEmpty {
                return periodLabel
            }
            if let elapsedMinute {
                return "\(elapsedMinute)'"
            }
            return "Live"

        case .halfTime(let elapsedMinute):
            if let elapsedMinute {
                return "HT \(elapsedMinute)'"
            }
            return "Half Time"

        case .breakTime:
            return "Break"

        case .extraTime(let elapsedMinute):
            if let elapsedMinute {
                return "ET \(elapsedMinute)'"
            }
            return "Extra Time"

        case .overtime(let elapsedMinute, let periodLabel):
            if let periodLabel, !periodLabel.isEmpty {
                return periodLabel
            }
            if let elapsedMinute {
                return "OT \(elapsedMinute)'"
            }
            return "Overtime"

        case .penalties(let elapsedMinute):
            if let elapsedMinute {
                return "PEN \(elapsedMinute)'"
            }
            return "Penalties"

        case .finished:
            return "Final"

        case .postponed:
            return "Postponed"

        case .cancelled:
            return "Cancelled"

        case .suspended:
            return "Suspended"

        case .neutral:
            if let fallbackStatusLong,
               !fallbackStatusLong.isEmpty {
                return fallbackStatusLong
            }

            if let fallbackStatusShort,
               !fallbackStatusShort.isEmpty {
                return fallbackStatusShort
            }

            return "Scheduled"
        }
    }

    func statsViewMetadata(hasRows: Bool, sport: MatchFixtureSport) -> (displayState: MatchDetailStatsDisplayState, showsFilter: Bool) {
        let policy = displayPolicy(for: sport)

        guard hasRows else {
            return (
                .empty(
                    title: policy.statsEmptyTitle,
                    subtitle: policy.statsEmptySubtitle
                ),
                false
            )
        }

        return (.content, policy.showsStatsFilter)
    }
}

// MARK: - Soccer Policy

private extension MatchFixturePhase {

    var soccerDisplayPolicy: DisplayPolicy {
        switch self {
        case .scheduled:
            return DisplayPolicy(
                showsHeaderScore: false,
                showsStatsSection: true,
                showsStatsFilter: false,
                showsScoreBreakdownInStats: false,
                showsDetailedStatistics: false,
                showsEventsSection: false,
                showsLineupsSection: true,
                statsEmptyTitle: "Match Not Started",
                statsEmptySubtitle: "Statistics will appear once the match kicks off."
            )

        case .live, .halfTime, .breakTime, .extraTime, .penalties:
            return DisplayPolicy(
                showsHeaderScore: true,
                showsStatsSection: true,
                showsStatsFilter: true,
                showsScoreBreakdownInStats: true,
                showsDetailedStatistics: true,
                showsEventsSection: true,
                showsLineupsSection: true,
                statsEmptyTitle: "No Stats Available",
                statsEmptySubtitle: "Live statistics are not available for this match yet."
            )

        case .finished:
            return DisplayPolicy(
                showsHeaderScore: true,
                showsStatsSection: true,
                showsStatsFilter: true,
                showsScoreBreakdownInStats: true,
                showsDetailedStatistics: true,
                showsEventsSection: true,
                showsLineupsSection: true,
                statsEmptyTitle: "No Stats Available",
                statsEmptySubtitle: "Match statistics are not available for this game."
            )

        case .postponed:
            return DisplayPolicy(
                showsHeaderScore: false,
                showsStatsSection: true,
                showsStatsFilter: false,
                showsScoreBreakdownInStats: false,
                showsDetailedStatistics: false,
                showsEventsSection: false,
                showsLineupsSection: false,
                statsEmptyTitle: "Match Postponed",
                statsEmptySubtitle: "This match has been postponed."
            )

        case .cancelled:
            return DisplayPolicy(
                showsHeaderScore: false,
                showsStatsSection: true,
                showsStatsFilter: false,
                showsScoreBreakdownInStats: false,
                showsDetailedStatistics: false,
                showsEventsSection: false,
                showsLineupsSection: false,
                statsEmptyTitle: "Match Cancelled",
                statsEmptySubtitle: "This match is no longer taking place."
            )

        case .suspended:
            return DisplayPolicy(
                showsHeaderScore: true,
                showsStatsSection: true,
                showsStatsFilter: true,
                showsScoreBreakdownInStats: true,
                showsDetailedStatistics: true,
                showsEventsSection: true,
                showsLineupsSection: true,
                statsEmptyTitle: "Match Suspended",
                statsEmptySubtitle: "Statistics may update when play resumes."
            )

        case .overtime, .neutral:
            return DisplayPolicy(
                showsHeaderScore: true,
                showsStatsSection: true,
                showsStatsFilter: true,
                showsScoreBreakdownInStats: true,
                showsDetailedStatistics: true,
                showsEventsSection: true,
                showsLineupsSection: true,
                statsEmptyTitle: "No Stats Available",
                statsEmptySubtitle: "Match statistics are not available for this game."
            )
        }
    }
}

// MARK: - Basketball / Baseball Policy

private extension MatchFixturePhase {

    var teamSportsDisplayPolicy: DisplayPolicy {
        switch self {
        case .scheduled:
            return DisplayPolicy(
                showsHeaderScore: false,
                showsStatsSection: true,
                showsStatsFilter: false,
                showsScoreBreakdownInStats: false,
                showsDetailedStatistics: false,
                showsEventsSection: false,
                showsLineupsSection: false,
                statsEmptyTitle: "Game Not Started",
                statsEmptySubtitle: "Statistics will appear once the game begins."
            )

        case .live, .halfTime, .breakTime, .extraTime, .overtime:
            return DisplayPolicy(
                showsHeaderScore: true,
                showsStatsSection: true,
                showsStatsFilter: true,
                showsScoreBreakdownInStats: false,
                showsDetailedStatistics: true,
                showsEventsSection: false,
                showsLineupsSection: false,
                statsEmptyTitle: "No Stats Available",
                statsEmptySubtitle: "Live statistics are not available for this game yet."
            )

        case .finished:
            return DisplayPolicy(
                showsHeaderScore: true,
                showsStatsSection: true,
                showsStatsFilter: true,
                showsScoreBreakdownInStats: false,
                showsDetailedStatistics: true,
                showsEventsSection: false,
                showsLineupsSection: false,
                statsEmptyTitle: "No Stats Available",
                statsEmptySubtitle: "Game statistics are not available for this matchup."
            )

        case .postponed:
            return DisplayPolicy(
                showsHeaderScore: false,
                showsStatsSection: true,
                showsStatsFilter: false,
                showsScoreBreakdownInStats: false,
                showsDetailedStatistics: false,
                showsEventsSection: false,
                showsLineupsSection: false,
                statsEmptyTitle: "Game Postponed",
                statsEmptySubtitle: "This game has been postponed."
            )

        case .cancelled:
            return DisplayPolicy(
                showsHeaderScore: false,
                showsStatsSection: true,
                showsStatsFilter: false,
                showsScoreBreakdownInStats: false,
                showsDetailedStatistics: false,
                showsEventsSection: false,
                showsLineupsSection: false,
                statsEmptyTitle: "Game Cancelled",
                statsEmptySubtitle: "This game is no longer taking place."
            )

        case .penalties, .suspended, .neutral:
            return DisplayPolicy(
                showsHeaderScore: true,
                showsStatsSection: true,
                showsStatsFilter: true,
                showsScoreBreakdownInStats: false,
                showsDetailedStatistics: true,
                showsEventsSection: false,
                showsLineupsSection: false,
                statsEmptyTitle: "No Stats Available",
                statsEmptySubtitle: "Game statistics are not available for this matchup."
            )
        }
    }
}

// MARK: - Phase Resolution

private extension MatchFixturePhase {

    nonisolated static func resolveSoccerPhase(from snapshot: MatchFixtureStatusSnapshot) -> MatchFixturePhase {
        guard let normalizedStatus = normalizedStatus(from: snapshot) else {
            return .neutral
        }

        switch normalizedStatus {
        case "ns", "not started", "tbd", "time to be defined":
            return .scheduled

        case "1h", "2h", "live":
            return .live(elapsedMinute: snapshot.elapsedMinute, periodLabel: nil)

        case "ht", "half time":
            return .halfTime(elapsedMinute: snapshot.elapsedMinute)

        case "bt", "break time":
            return .breakTime(elapsedMinute: snapshot.elapsedMinute)

        case "et", "extra time":
            return .extraTime(elapsedMinute: snapshot.elapsedMinute)

        case "p", "pen", "penalty in progress":
            return .penalties(elapsedMinute: snapshot.elapsedMinute)

        case "ft", "aet", "aft", "final", "match finished":
            return .finished

        case "pst", "postponed":
            return .postponed

        case "canc", "cancelled", "abandoned", "abd":
            return .cancelled

        case "int", "interrupted", "susp", "suspended":
            return .suspended

        default:
            return resolveSoccerFallback(normalizedStatus, snapshot: snapshot)
        }
    }

    nonisolated static func resolveSoccerFallback(
        _ normalizedStatus: String,
        snapshot: MatchFixtureStatusSnapshot
    ) -> MatchFixturePhase {
        if normalizedStatus.contains("1h")
            || normalizedStatus.contains("2h")
            || normalizedStatus.contains("live")
            || normalizedStatus.contains("et")
            || normalizedStatus.contains("bt")
            || normalizedStatus == "p" {
            return .live(elapsedMinute: snapshot.elapsedMinute, periodLabel: nil)
        }

        if normalizedStatus.contains("finish")
            || normalizedStatus.contains("final")
            || normalizedStatus.contains("ended")
            || normalizedStatus == "ft"
            || normalizedStatus == "aet"
            || normalizedStatus == "aft" {
            return .finished
        }

        if normalizedStatus.contains("postponed") || normalizedStatus == "pst" {
            return .postponed
        }

        if normalizedStatus.contains("cancel") || normalizedStatus.contains("abandoned") {
            return .cancelled
        }

        if normalizedStatus.contains("susp") || normalizedStatus.contains("interrupt") {
            return .suspended
        }

        if normalizedStatus.contains("ns")
            || normalizedStatus.contains("scheduled")
            || normalizedStatus.contains("not started") {
            return .scheduled
        }

        return .neutral
    }

    nonisolated static func resolveBasketballPhase(from snapshot: MatchFixtureStatusSnapshot) -> MatchFixturePhase {
        guard let normalizedStatus = normalizedStatus(from: snapshot) else {
            return .neutral
        }

        if isBasketballLiveStatus(normalizedStatus) {
            return .live(
                elapsedMinute: snapshot.elapsedMinute,
                periodLabel: basketballPeriodLabel(from: normalizedStatus)
            )
        }

        switch normalizedStatus {
        case "ns", "not started":
            return .scheduled

        case "tbd", "time to be defined":
            return .scheduled

        case "ht", "half time":
            return .halfTime(elapsedMinute: snapshot.elapsedMinute)

        case "ot", "overtime", "after overtime":
            return .overtime(
                elapsedMinute: snapshot.elapsedMinute,
                periodLabel: basketballPeriodLabel(from: normalizedStatus)
            )

        case "bt", "break time":
            return .breakTime(elapsedMinute: snapshot.elapsedMinute)

        case "ft", "aot", "final":
            return .finished

        case "pst", "postponed":
            return .postponed

        case "canc", "cancelled", "abd", "abandoned", "susp", "suspended":
            return .cancelled

        default:
            return .neutral
        }
    }

    nonisolated static func resolveBaseballPhase(from snapshot: MatchFixtureStatusSnapshot) -> MatchFixturePhase {
        guard let normalizedStatus = normalizedStatus(from: snapshot) else {
            return .neutral
        }

        if isBaseballLiveStatus(normalizedStatus) {
            return .live(
                elapsedMinute: snapshot.elapsedMinute,
                periodLabel: baseballLivePeriodLabel(from: snapshot)
            )
        }

        switch normalizedStatus {
        case "ns", "not started":
            return .scheduled

        case "tbd", "time to be defined":
            return .scheduled

        case "ht", "half time":
            return .halfTime(elapsedMinute: snapshot.elapsedMinute)

        case "bt", "break time":
            return .breakTime(elapsedMinute: snapshot.elapsedMinute)

        case "ft", "aet", "aft", "aot", "after overtime", "final", "match finished":
            return .finished

        case "pst", "postponed":
            return .postponed

        case "canc", "cancelled", "abandoned", "abd":
            return .cancelled

        case "int", "interrupted", "susp", "suspended":
            return .suspended

        default:
            if normalizedStatus.contains("finish")
                || normalizedStatus.contains("final")
                || normalizedStatus.contains("ended")
                || normalizedStatus.contains("after") {
                return .finished
            }

            if normalizedStatus.contains("postponed") || normalizedStatus == "pst" {
                return .postponed
            }

            if normalizedStatus.contains("cancel") || normalizedStatus.contains("abandoned") {
                return .cancelled
            }

            if normalizedStatus.contains("susp") || normalizedStatus.contains("interrupt") {
                return .suspended
            }

            if normalizedStatus.contains("ns")
                || normalizedStatus.contains("scheduled")
                || normalizedStatus.contains("not started")
                || normalizedStatus.contains("tbd") {
                return .scheduled
            }

            return .neutral
        }
    }

    nonisolated static func normalizedStatus(from snapshot: MatchFixtureStatusSnapshot) -> String? {
        let statusShort = snapshot.statusShort?.lowercased()
        let statusLong = snapshot.statusLong?.lowercased()
        return statusShort ?? statusLong
    }

    nonisolated static func isBasketballLiveStatus(_ status: String) -> Bool {
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

    nonisolated static func basketballPeriodLabel(from status: String) -> String? {
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

    nonisolated static func isBaseballLiveStatus(_ status: String) -> Bool {
        status.contains("live")
            || status.contains("in progress")
            || status.contains("inning")
            || status.contains("top")
            || status.contains("bottom")
            || status.contains("mid")
    }

    nonisolated static func baseballLivePeriodLabel(from snapshot: MatchFixtureStatusSnapshot) -> String? {
        let candidates = [snapshot.statusLong, snapshot.statusShort]

        return candidates
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }
    }
}
