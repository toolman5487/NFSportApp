//
//  BaseballMatchDetail.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/28.
//

import Foundation

// MARK: - Match Detail

nonisolated struct BaseballMatchDetail: Equatable, Sendable {

    let fixture: BaseballMatchFixtureDetail
}

// MARK: - Fixture

nonisolated struct BaseballMatchFixtureDetail: Equatable, Sendable {

    let id: Int
    let leagueName: String
    let leagueLogoURL: URL?
    let venueName: String?
    let scheduledStartDate: Date?
    let scheduledStartText: String?
    let statusLong: String?
    let statusShort: String?
    let elapsedMinute: Int?
    let homeTeam: BaseballMatchTeam
    let awayTeam: BaseballMatchTeam
    let score: BaseballMatchScore
}

nonisolated struct BaseballMatchTeam: Equatable, Identifiable, Sendable {

    var id: String {
        "\(teamID ?? -1)-\(name)"
    }

    let teamID: Int?
    let name: String
    let logoURL: URL?
}

nonisolated struct BaseballMatchScore: Equatable, Sendable {

    let home: Int?
    let away: Int?
}

