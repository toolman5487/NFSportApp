//
//  HockeyMatchDetail.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/28.
//

import Foundation

// MARK: - Match Detail

nonisolated struct HockeyMatchDetail: Equatable, Sendable {

    let fixture: HockeyMatchFixtureDetail
}

// MARK: - Fixture

nonisolated struct HockeyMatchFixtureDetail: Equatable, Sendable {

    let id: Int
    let leagueName: String
    let leagueLogoURL: URL?
    let venueName: String?
    let scheduledStartDate: Date?
    let scheduledStartText: String?
    let statusLong: String?
    let statusShort: String?
    let elapsedMinute: Int?
    let homeTeam: HockeyMatchTeam
    let awayTeam: HockeyMatchTeam
    let score: HockeyMatchScore
}

nonisolated struct HockeyMatchTeam: Equatable, Identifiable, Sendable {

    var id: String {
        "\(teamID ?? -1)-\(name)"
    }

    let teamID: Int?
    let name: String
    let logoURL: URL?
}

nonisolated struct HockeyMatchScore: Equatable, Sendable {

    let home: Int?
    let away: Int?
}

