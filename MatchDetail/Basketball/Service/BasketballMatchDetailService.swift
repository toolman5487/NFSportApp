//
//  BasketballMatchDetailService.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/27.
//

import Foundation

// MARK: - BasketballMatchDetailServicing

nonisolated protocol BasketballMatchDetailServicing: Sendable {

    func fetchMatchDetail(gameID: Int) async throws -> BasketballMatchDetail
}

// MARK: - Stat Parsing

private nonisolated func basketballStatValue(_ value: APIBasketballFlexibleValue?) -> Double? {
    value?.doubleValue
}

// MARK: - BasketballMatchDetailService

nonisolated struct BasketballMatchDetailService: BasketballMatchDetailServicing {

    private let networkClient: NetworkServicing

    init(networkClient: NetworkServicing) {
        self.networkClient = networkClient
    }

    func fetchMatchDetail(gameID: Int) async throws -> BasketballMatchDetail {
        async let game = fetchGame(from: .game(id: gameID))
        async let players = fetchPlayers(from: .players(gameID: gameID))

        let fixture = try await game
        let playersByTeam = (try? await players) ?? []

        return BasketballMatchDetail(
            fixture: fixture,
            playersByTeam: playersByTeam
        )
    }

    private func fetchGame(from endpoint: BasketballMatchDetailEndpoint) async throws -> BasketballMatchFixtureDetail {
        let response = try await networkClient.get(
            endpoint.path,
            queryItems: endpoint.queryItems,
            headers: [:],
            as: APIBasketballMatchDetailResponse<[APIBasketballMatchGameResponse]>.self
        )

        guard let game = response.response.compactMap(\.domainFixture).first else {
            throw NetworkError.invalidResponse
        }

        return game
    }

    private func fetchPlayers(from endpoint: BasketballMatchDetailEndpoint) async throws -> [BasketballMatchTeamPlayers] {
        let response = try await networkClient.get(
            endpoint.path,
            queryItems: endpoint.queryItems,
            headers: [:],
            as: APIBasketballMatchDetailResponse<[APIBasketballMatchTeamPlayersResponse]>.self
        )

        return response.response.compactMap(\.domainTeamPlayers)
    }
}

// MARK: - API Response

private nonisolated struct APIBasketballMatchDetailResponse<Response: Decodable & Sendable>: Decodable, Sendable {

    let response: Response
}

// MARK: - Game Response

private nonisolated struct APIBasketballMatchGameResponse: Decodable, Sendable {

    let id: Int?
    let date: String?
    let time: String?
    let venue: String?
    let status: APIBasketballMatchStatusResponse?
    let league: APIBasketballMatchLeagueResponse?
    let teams: APIBasketballMatchTeamsResponse?
    let scores: APIBasketballMatchScoresResponse?

    var domainFixture: BasketballMatchFixtureDetail? {
        guard let gameID = id,
              let homeTeam = teams?.home.domainTeam,
              let awayTeam = teams?.away.domainTeam else {
            return nil
        }

        return BasketballMatchFixtureDetail(
            id: gameID,
            leagueName: league?.name ?? "Other League",
            leagueLogoURL: league?.logoURL,
            venueName: venue,
            scheduledStartDate: date.flatMap(Self.makeDate(from:)),
            scheduledStartText: Self.makeScheduledStartText(date: date, time: time),
            statusLong: status?.long,
            statusShort: status?.short,
            elapsedMinute: nil,
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            score: BasketballMatchScore(
                home: scores?.home?.domainTeamScore ?? BasketballMatchTeamScore(total: nil, periods: []),
                away: scores?.away?.domainTeamScore ?? BasketballMatchTeamScore(total: nil, periods: [])
            )
        )
    }

    private static func makeScheduledStartText(date: String?, time: String?) -> String? {
        switch (date, time) {
        case (.some(let date), .some(let time)):
            return "\(date) \(time)"

        case (.some(let date), .none):
            return date

        case (.none, .some(let time)):
            return time

        case (.none, .none):
            return nil
        }
    }

    private static func makeDate(from value: String) -> Date? {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]

        if let date = isoFormatter.date(from: value) {
            return date
        }

        isoFormatter.formatOptions = [.withInternetDateTime]
        return isoFormatter.date(from: value)
    }
}

private nonisolated struct APIBasketballMatchStatusResponse: Decodable, Sendable {

    let long: String?
    let short: String?
    let timer: String?
}

private nonisolated struct APIBasketballMatchLeagueResponse: Decodable, Sendable {

    let name: String?
    let logo: String?

    var logoURL: URL? {
        guard let logo else {
            return nil
        }

        return URL(string: logo)
    }
}

private nonisolated struct APIBasketballMatchTeamsResponse: Decodable, Sendable {

    let home: APIBasketballMatchTeamResponse
    let away: APIBasketballMatchTeamResponse
}

private nonisolated struct APIBasketballMatchTeamResponse: Decodable, Sendable {

    let id: Int?
    let name: String?
    let logo: String?

    var logoURL: URL? {
        guard let logo else {
            return nil
        }

        return URL(string: logo)
    }

    var domainTeam: BasketballMatchTeam? {
        guard let name else {
            return nil
        }

        return BasketballMatchTeam(
            teamID: id,
            name: name,
            logoURL: logoURL
        )
    }
}

private nonisolated struct APIBasketballMatchScoresResponse: Decodable, Sendable {

    let home: APIBasketballMatchTeamScoreResponse?
    let away: APIBasketballMatchTeamScoreResponse?
}

private nonisolated struct APIBasketballMatchTeamScoreResponse: Decodable, Sendable {

    let total: Int?
    let quarter1: Int?
    let quarter2: Int?
    let quarter3: Int?
    let quarter4: Int?
    let overTime: Int?

    private enum CodingKeys: String, CodingKey {
        case total
        case quarter1 = "quarter_1"
        case quarter2 = "quarter_2"
        case quarter3 = "quarter_3"
        case quarter4 = "quarter_4"
        case overTime = "over_time"
    }

    var domainTeamScore: BasketballMatchTeamScore {
        BasketballMatchTeamScore(
            total: total,
            periods: Self.makePeriodScores(
                quarter1: quarter1,
                quarter2: quarter2,
                quarter3: quarter3,
                quarter4: quarter4,
                overTime: overTime
            )
        )
    }

    private static func makePeriodScores(
        quarter1: Int?,
        quarter2: Int?,
        quarter3: Int?,
        quarter4: Int?,
        overTime: Int?
    ) -> [BasketballMatchPeriodScore] {
        let definitions: [(String, Int?)] = [
            ("Q1", quarter1),
            ("Q2", quarter2),
            ("Q3", quarter3),
            ("Q4", quarter4),
            ("OT", overTime)
        ]

        return definitions.compactMap { label, value in
            guard value != nil else {
                return nil
            }

            return BasketballMatchPeriodScore(label: label, points: value)
        }
    }
}

// MARK: - Players Response

private nonisolated struct APIBasketballMatchTeamPlayersResponse: Decodable, Sendable {

    let team: APIBasketballMatchTeamResponse?
    let players: [APIBasketballMatchPlayerResponse]?

    var domainTeamPlayers: BasketballMatchTeamPlayers? {
        guard let team = team?.domainTeam else {
            return nil
        }

        return BasketballMatchTeamPlayers(
            team: team,
            players: players?.compactMap(\.domainPlayer) ?? []
        )
    }
}

private nonisolated struct APIBasketballMatchPlayerResponse: Decodable, Sendable {

    let id: Int?
    let name: String?
    let photo: String?
    let number: Int?
    let pos: String?
    let statistics: [APIBasketballMatchPlayerStatisticsResponse]?

    var domainPlayer: BasketballMatchPlayer? {
        guard let name else {
            return nil
        }

        return BasketballMatchPlayer(
            playerID: id,
            name: name,
            photoURL: photo.flatMap(URL.init(string:)),
            number: number,
            position: pos,
            statistics: statistics?.map(\.domainStatistics) ?? []
        )
    }
}

private nonisolated struct APIBasketballMatchPlayerStatisticsResponse: Decodable, Sendable {

    let points: APIBasketballFlexibleValue?
    let fieldGoals: APIBasketballGoalGroupResponse?
    let threePointGoals: APIBasketballGoalGroupResponse?
    let freeThrowGoals: APIBasketballGoalGroupResponse?
    let rebounds: APIBasketballReboundsGroupResponse?
    let assists: APIBasketballFlexibleValue?
    let steals: APIBasketballFlexibleValue?
    let blocks: APIBasketballFlexibleValue?
    let turnovers: APIBasketballFlexibleValue?
    let fieldGoalsMade: APIBasketballFlexibleValue?
    let fieldGoalsAttempted: APIBasketballFlexibleValue?
    let threePointsMade: APIBasketballFlexibleValue?
    let threePointsAttempted: APIBasketballFlexibleValue?
    let freeThrowsMade: APIBasketballFlexibleValue?
    let freeThrowsAttempted: APIBasketballFlexibleValue?
    let totalRebounds: APIBasketballFlexibleValue?

    private enum CodingKeys: String, CodingKey {
        case points
        case fieldGoals = "field_goals"
        case threePointGoals = "threepoint_goals"
        case freeThrowGoals = "freethrows_goals"
        case rebounds
        case assists
        case steals
        case blocks
        case turnovers
        case fieldGoalsMade = "fgm"
        case fieldGoalsAttempted = "fga"
        case threePointsMade = "tpm"
        case threePointsAttempted = "tpa"
        case freeThrowsMade = "ftm"
        case freeThrowsAttempted = "fta"
        case totalRebounds = "totReb"
    }

    var domainStatistics: BasketballMatchPlayerStatistics {
        let made = fieldGoals?.made ?? fieldGoalsMade
        let attempted = fieldGoals?.attempts ?? fieldGoalsAttempted
        let tpm = threePointGoals?.made ?? threePointsMade
        let tpa = threePointGoals?.attempts ?? threePointsAttempted
        let ftm = freeThrowGoals?.made ?? freeThrowsMade
        let fta = freeThrowGoals?.attempts ?? freeThrowsAttempted

        return BasketballMatchPlayerStatistics(
            points: basketballStatValue(points),
            fieldGoalsMade: basketballStatValue(made),
            fieldGoalsAttempted: basketballStatValue(attempted),
            threePointsMade: basketballStatValue(tpm),
            threePointsAttempted: basketballStatValue(tpa),
            freeThrowsMade: basketballStatValue(ftm),
            freeThrowsAttempted: basketballStatValue(fta),
            rebounds: basketballStatValue(rebounds?.total ?? totalRebounds),
            assists: basketballStatValue(assists),
            steals: basketballStatValue(steals),
            blocks: basketballStatValue(blocks),
            turnovers: basketballStatValue(turnovers)
        )
    }
}

private nonisolated struct APIBasketballGoalGroupResponse: Decodable, Sendable {

    let total: APIBasketballFlexibleValue?
    let attempts: APIBasketballFlexibleValue?

    var made: APIBasketballFlexibleValue? { total }
}

private nonisolated struct APIBasketballReboundsGroupResponse: Decodable, Sendable {

    let total: APIBasketballFlexibleValue?
}

// MARK: - Flexible Value

private nonisolated enum APIBasketballFlexibleValue: Decodable, Sendable {

    case number(Double)
    case text(String)
    case none

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .none
            return
        }

        if let doubleValue = try? container.decode(Double.self) {
            self = .number(doubleValue)
            return
        }

        if let intValue = try? container.decode(Int.self) {
            self = .number(Double(intValue))
            return
        }

        if let stringValue = try? container.decode(String.self) {
            self = .text(stringValue)
            return
        }

        self = .none
    }

    var doubleValue: Double? {
        switch self {
        case .number(let value):
            return value
        case .text(let value):
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "%", with: "")
            return Double(trimmed)
        case .none:
            return nil
        }
    }
}
