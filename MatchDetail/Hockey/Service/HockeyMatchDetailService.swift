//
//  HockeyMatchDetailService.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/28.
//

import Foundation

// MARK: - HockeyMatchDetailServicing

nonisolated protocol HockeyMatchDetailServicing: Sendable {

    func fetchMatchDetail(gameID: Int) async throws -> HockeyMatchDetail
}

// MARK: - HockeyMatchDetailService

nonisolated struct HockeyMatchDetailService: HockeyMatchDetailServicing {

    private let networkClient: NetworkServicing

    init(networkClient: NetworkServicing) {
        self.networkClient = networkClient
    }

    func fetchMatchDetail(gameID: Int) async throws -> HockeyMatchDetail {
        let game = try await fetchGame(from: .game(id: gameID))

        return HockeyMatchDetail(fixture: game)
    }

    private func fetchGame(from endpoint: HockeyMatchDetailEndpoint) async throws -> HockeyMatchFixtureDetail {
        let response = try await networkClient.get(
            endpoint.path,
            queryItems: endpoint.queryItems,
            headers: [:],
            as: APIHockeyMatchDetailResponse<[APIHockeyMatchGameResponse]>.self
        )

        guard let game = response.response.compactMap(\.domainFixture).first else {
            throw NetworkError.invalidResponse
        }

        return game
    }
}

// MARK: - API Response

private nonisolated struct APIHockeyMatchDetailResponse<Response: Decodable & Sendable>: Decodable, Sendable {

    let response: Response
}

// MARK: - Game Response

private nonisolated struct APIHockeyMatchGameResponse: Decodable, Sendable {

    let id: Int?
    let date: APIHockeyGameDateResponse?
    let time: String?
    let venue: APIHockeyVenueResponse?
    let status: APIHockeyMatchStatusResponse?
    let league: APIHockeyMatchLeagueResponse?
    let teams: APIHockeyMatchTeamsResponse?
    let scores: APIHockeyMatchScoresResponse?

    var domainFixture: HockeyMatchFixtureDetail? {
        guard let gameID = id,
              let homeTeam = teams?.home?.domainTeam,
              let awayTeam = teams?.away?.domainTeam else {
            return nil
        }

        return HockeyMatchFixtureDetail(
            id: gameID,
            leagueName: league?.displayName ?? "Other League",
            leagueLogoURL: league?.logoURL,
            venueName: venue?.name,
            scheduledStartDate: date?.startDate,
            scheduledStartText: time ?? date?.displayText,
            statusLong: status?.long,
            statusShort: status?.short?.displayValue,
            elapsedMinute: nil,
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            score: HockeyMatchScore(
                home: scores?.home?.intValue,
                away: scores?.away?.intValue
            )
        )
    }
}

private nonisolated struct APIHockeyMatchStatusResponse: Decodable, Sendable {

    let long: String?
    let short: APIHockeyFlexibleValueResponse?
}

private nonisolated struct APIHockeyMatchLeagueResponse: Decodable, Sendable {

    let displayName: String?
    let logo: String?

    var logoURL: URL? {
        guard let logo else {
            return nil
        }

        return URL(string: logo)
    }

    init(from decoder: Decoder) throws {
        let singleValueContainer = try decoder.singleValueContainer()

        if let value = try? singleValueContainer.decode(String.self) {
            displayName = value
            logo = nil
            return
        }

        let keyedContainer = try decoder.container(keyedBy: CodingKeys.self)
        displayName = try keyedContainer.decodeIfPresent(String.self, forKey: .name)
            ?? keyedContainer.decodeIfPresent(String.self, forKey: .type)
        logo = try keyedContainer.decodeIfPresent(String.self, forKey: .logo)
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case type
        case logo
    }
}

private nonisolated struct APIHockeyMatchTeamsResponse: Decodable, Sendable {

    let home: APIHockeyMatchTeamResponse?
    let away: APIHockeyMatchTeamResponse?

    enum CodingKeys: String, CodingKey {
        case home
        case away
        case visitors
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        home = try container.decodeIfPresent(APIHockeyMatchTeamResponse.self, forKey: .home)
        away = try container.decodeIfPresent(APIHockeyMatchTeamResponse.self, forKey: .away)
            ?? container.decodeIfPresent(APIHockeyMatchTeamResponse.self, forKey: .visitors)
    }
}

private nonisolated struct APIHockeyMatchTeamResponse: Decodable, Sendable {

    let id: Int?
    let name: String?
    let logo: String?

    var logoURL: URL? {
        guard let logo else {
            return nil
        }

        return URL(string: logo)
    }

    var domainTeam: HockeyMatchTeam? {
        guard let name else {
            return nil
        }

        return HockeyMatchTeam(
            teamID: id,
            name: name,
            logoURL: logoURL
        )
    }
}

private nonisolated struct APIHockeyMatchScoresResponse: Decodable, Sendable {

    let home: APIHockeyScoreValueResponse?
    let away: APIHockeyScoreValueResponse?

    enum CodingKeys: String, CodingKey {
        case home
        case away
        case visitors
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        home = try container.decodeIfPresent(APIHockeyScoreValueResponse.self, forKey: .home)
        away = try container.decodeIfPresent(APIHockeyScoreValueResponse.self, forKey: .away)
            ?? container.decodeIfPresent(APIHockeyScoreValueResponse.self, forKey: .visitors)
    }
}

private nonisolated struct APIHockeyScoreValueResponse: Decodable, Sendable {

    let intValue: Int?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            intValue = nil
            return
        }

        if let value = try? container.decode(Int.self) {
            intValue = value
            return
        }

        if let value = try? container.decode(String.self) {
            intValue = Int(value)
            return
        }

        if let object = try? container.decode(APIHockeyScoreObjectResponse.self) {
            intValue = object.intValue
            return
        }

        intValue = nil
    }
}

private nonisolated struct APIHockeyScoreObjectResponse: Decodable, Sendable {

    let points: Int?
    let total: Int?

    var intValue: Int? {
        points ?? total
    }
}

private nonisolated struct APIHockeyFlexibleValueResponse: Decodable, Sendable {

    let displayValue: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            displayValue = nil
            return
        }

        if let value = try? container.decode(String.self) {
            displayValue = value
            return
        }

        if let value = try? container.decode(Int.self) {
            displayValue = "\(value)"
            return
        }

        displayValue = nil
    }
}

private nonisolated struct APIHockeyGameDateResponse: Decodable, Sendable {

    let displayText: String?
    let startDate: Date?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            displayText = nil
            startDate = nil
            return
        }

        if let value = try? container.decode(String.self) {
            displayText = value
            startDate = Self.makeDate(from: value)
            return
        }

        if let object = try? container.decode(APIHockeyDateObjectResponse.self) {
            displayText = object.start
            startDate = object.start.flatMap(Self.makeDate(from:))
            return
        }

        displayText = nil
        startDate = nil
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

private nonisolated struct APIHockeyDateObjectResponse: Decodable, Sendable {

    let start: String?
}

private nonisolated struct APIHockeyVenueResponse: Decodable, Sendable {

    let name: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            name = nil
            return
        }

        if let value = try? container.decode(String.self) {
            name = value
            return
        }

        if let object = try? container.decode(APIHockeyVenueObjectResponse.self) {
            name = object.name
            return
        }

        name = nil
    }
}

private nonisolated struct APIHockeyVenueObjectResponse: Decodable, Sendable {

    let name: String?
}
