//
//  SoccerMatchDetail.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/26.
//

import Foundation

// MARK: - Match Detail

nonisolated struct SoccerMatchDetail: Equatable, Sendable {

    let fixture: SoccerMatchFixtureDetail
    let statistics: [SoccerMatchTeamStatistics]
    let events: [SoccerMatchEvent]
    let lineups: [SoccerMatchLineup]
}

// MARK: - Fixture

nonisolated struct SoccerMatchFixtureDetail: Equatable, Sendable {

    let id: Int
    let leagueName: String
    let leagueLogoURL: URL?
    let referee: String?
    let venueName: String?
    let venueCity: String?
    let scheduledStartDate: Date?
    let scheduledStartText: String?
    let statusLong: String?
    let statusShort: String?
    let elapsedMinute: Int?
    let homeTeam: SoccerMatchTeam
    let awayTeam: SoccerMatchTeam
    let score: SoccerMatchScore
}

nonisolated struct SoccerMatchTeam: Equatable, Identifiable, Sendable {

    var id: String {
        "\(teamID ?? -1)-\(name)"
    }

    let teamID: Int?
    let name: String
    let logoURL: URL?
}

nonisolated struct SoccerMatchScore: Equatable, Sendable {

    let home: Int?
    let away: Int?
    let halftime: SoccerMatchScoreLine?
    let fulltime: SoccerMatchScoreLine?
    let extratime: SoccerMatchScoreLine?
    let penalty: SoccerMatchScoreLine?
}

nonisolated struct SoccerMatchScoreLine: Equatable, Sendable {

    let home: Int?
    let away: Int?

    var hasValue: Bool {
        home != nil || away != nil
    }
}

// MARK: - Statistics

nonisolated struct SoccerMatchTeamStatistics: Equatable, Sendable {

    let team: SoccerMatchTeam
    let statistics: [SoccerMatchStatistic]
}

nonisolated struct SoccerMatchStatistic: Equatable, Identifiable, Sendable {

    var id: String {
        type
    }

    let type: String
    let value: String?
}

// MARK: - Events

nonisolated struct SoccerMatchEvent: Equatable, Identifiable, Sendable {

    var id: String {
        [
            "\(elapsedMinute ?? -1)",
            "\(extraMinute ?? -1)",
            team?.id ?? "unknown-team",
            type,
            detail ?? "",
            playerName ?? ""
        ].joined(separator: "|")
    }

    let elapsedMinute: Int?
    let extraMinute: Int?
    let team: SoccerMatchTeam?
    let playerName: String?
    let assistName: String?
    let type: String
    let detail: String?
    let comments: String?
}

// MARK: - Lineups

nonisolated struct SoccerMatchLineup: Equatable, Sendable {

    let team: SoccerMatchTeam
    let coachName: String?
    let formation: String?
    let startXI: [SoccerMatchLineupPlayer]
    let substitutes: [SoccerMatchLineupPlayer]
}

nonisolated struct SoccerMatchLineupPlayer: Equatable, Identifiable, Sendable {

    var id: String {
        [
            "\(playerID ?? -1)",
            name,
            "\(number ?? -1)",
            position ?? "",
            grid ?? ""
        ].joined(separator: "|")
    }

    let playerID: Int?
    let name: String
    let number: Int?
    let position: String?
    let grid: String?
    let photoURL: URL?
}
