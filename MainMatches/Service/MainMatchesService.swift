//
//  MainMatchesService.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/25.
//

import Foundation

// MARK: - MainMatchesServicing

nonisolated protocol MainMatchesServicing: Sendable {

    func fetchSchedule(
        for sport: SportType,
        date: Date
    ) async throws -> MainMatchesSchedule
}

// MARK: - MainMatchesService

nonisolated struct MainMatchesService: MainMatchesServicing {

    private let networkClient: NetworkServicing

    init(networkClient: NetworkServicing) {
        self.networkClient = networkClient
    }

    func fetchSchedule(
        for sport: SportType,
        date: Date
    ) async throws -> MainMatchesSchedule {
        let endpoint = MainMatchesEndpoint.games(date: makeAPIDateString(from: date))
        let response = try await networkClient.get(
            endpoint.path,
            queryItems: endpoint.queryItems,
            headers: [:],
            as: APISportsResponse<[APISportsGameResponse]>.self
        )

        return MainMatchesSchedule(
            sport: sport,
            date: date,
            games: response.response.compactMap(\.mainMatchesGame)
        )
    }

    private func makeAPIDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - API-Sports Response

private nonisolated struct APISportsResponse<Response: Decodable & Sendable>: Decodable, Sendable {

    let response: Response
}

// MARK: - API-Sports Game

private nonisolated struct APISportsGameResponse: Decodable, Sendable {

    let id: Int?
    let date: APISportsGameDateResponse?
    let time: String?
    let league: APISportsLeagueResponse?
    let status: APISportsGameStatusResponse?
    let teams: APISportsGameTeamsResponse?
    let scores: APISportsGameScoresResponse?

    var mainMatchesGame: MainMatchesGame? {
        guard let id,
              let homeTeamName = teams?.home.name,
              let awayTeamName = teams?.away.name else {
            return nil
        }

        return MainMatchesGame(
            id: id,
            leagueName: league?.displayName ?? "Other League",
            scheduledStartDate: date?.startDate,
            scheduledStartText: time ?? date?.displayText ?? "TBD",
            statusDescription: status?.long ?? status?.short?.displayValue,
            homeTeamName: homeTeamName,
            awayTeamName: awayTeamName,
            homeScore: scores?.home?.displayValue,
            awayScore: scores?.away?.displayValue
        )
    }
}

// MARK: - API-Sports League

private nonisolated struct APISportsLeagueResponse: Decodable, Sendable {

    let displayName: String?

    init(from decoder: Decoder) throws {
        let singleValueContainer = try decoder.singleValueContainer()

        if let value = try? singleValueContainer.decode(String.self) {
            displayName = value
            return
        }

        let keyedContainer = try decoder.container(keyedBy: CodingKeys.self)
        displayName = try keyedContainer.decodeIfPresent(String.self, forKey: .name)
            ?? keyedContainer.decodeIfPresent(String.self, forKey: .type)
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case type
    }
}

// MARK: - API-Sports Date

private nonisolated struct APISportsGameDateResponse: Decodable, Sendable {

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
            startDate = APISportsGameDateResponse.makeDate(from: value)
            return
        }

        if let object = try? container.decode(APISportsGameDateObjectResponse.self) {
            displayText = object.start
            startDate = object.start.flatMap(APISportsGameDateResponse.makeDate(from:))
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

private nonisolated struct APISportsGameDateObjectResponse: Decodable, Sendable {

    let start: String?
}

// MARK: - API-Sports Status

private nonisolated struct APISportsGameStatusResponse: Decodable, Sendable {

    let long: String?
    let short: APISportsFlexibleValueResponse?
}

// MARK: - API-Sports Teams

private nonisolated struct APISportsGameTeamsResponse: Decodable, Sendable {

    let home: APISportsTeamResponse
    let away: APISportsTeamResponse

    enum CodingKeys: String, CodingKey {
        case home
        case away
        case visitors
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        home = try container.decode(APISportsTeamResponse.self, forKey: .home)

        if let away = try container.decodeIfPresent(APISportsTeamResponse.self, forKey: .away) {
            self.away = away
            return
        }

        away = try container.decode(APISportsTeamResponse.self, forKey: .visitors)
    }
}

private nonisolated struct APISportsTeamResponse: Decodable, Sendable {

    let name: String?
}

// MARK: - API-Sports Scores

private nonisolated struct APISportsGameScoresResponse: Decodable, Sendable {

    let home: APISportsScoreValueResponse?
    let away: APISportsScoreValueResponse?

    enum CodingKeys: String, CodingKey {
        case home
        case away
        case visitors
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        home = try container.decodeIfPresent(APISportsScoreValueResponse.self, forKey: .home)
        away = try container.decodeIfPresent(APISportsScoreValueResponse.self, forKey: .away)
            ?? container.decodeIfPresent(APISportsScoreValueResponse.self, forKey: .visitors)
    }
}

private nonisolated struct APISportsScoreValueResponse: Decodable, Sendable {

    let displayValue: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            displayValue = nil
            return
        }

        if let value = try? container.decode(Int.self) {
            displayValue = "\(value)"
            return
        }

        if let value = try? container.decode(String.self) {
            displayValue = value
            return
        }

        if let object = try? container.decode(APISportsScoreObjectResponse.self) {
            displayValue = object.displayValue
            return
        }

        displayValue = nil
    }
}

private nonisolated struct APISportsScoreObjectResponse: Decodable, Sendable {

    let points: Int?
    let total: Int?

    var displayValue: String? {
        if let points {
            return "\(points)"
        }

        if let total {
            return "\(total)"
        }

        return nil
    }
}

// MARK: - API-Sports Flexible Value

private nonisolated struct APISportsFlexibleValueResponse: Decodable, Sendable {

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
