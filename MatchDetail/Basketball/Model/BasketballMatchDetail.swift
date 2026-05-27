//
//  BasketballMatchDetail.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/27.
//

import Foundation

// MARK: - Match Detail

nonisolated struct BasketballMatchDetail: Equatable, Sendable {

    let fixture: BasketballMatchFixtureDetail
}

// MARK: - Fixture

nonisolated struct BasketballMatchFixtureDetail: Equatable, Sendable {

    let id: Int
    let leagueName: String
    let leagueLogoURL: URL?
    let scheduledStartDate: Date?
    let scheduledStartText: String?
    let statusLong: String?
    let statusShort: String?
    let elapsedMinute: Int?
    let homeTeam: BasketballMatchTeam
    let awayTeam: BasketballMatchTeam
    let score: BasketballMatchScore
}

nonisolated struct BasketballMatchTeam: Equatable, Identifiable, Sendable {

    var id: String {
        "\(teamID ?? -1)-\(name)"
    }

    let teamID: Int?
    let name: String
    let logoURL: URL?
}

nonisolated struct BasketballMatchScore: Equatable, Sendable {

    let home: Int?
    let away: Int?
}
