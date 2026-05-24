//
//  MainHomeService.swift
//  NFSportApp
//
//  Created by Willy Hsu 2026/5/23.
//

import Foundation

nonisolated protocol MainHomeServicing: Sendable {

    func fetchDashboard(
        for sport: SportType,
        date: Date
    ) async throws -> MainHomeDashboard
}

nonisolated struct MainHomeService: MainHomeServicing {

    // MARK: - Dependencies

    private let networkClient: NetworkServicing

    // MARK: - Initialization

    init(networkClient: NetworkServicing) {
        self.networkClient = networkClient
    }

    // MARK: - Public Methods

    func fetchDashboard(
        for sport: SportType,
        date: Date
    ) async throws -> MainHomeDashboard {
        async let liveGames = fetchGames(from: .liveGames)
        async let todayGames = fetchGames(from: .games(date: makeAPIDateString(from: date)))

        return try await MainHomeDashboard(
            sport: sport,
            liveGames: liveGames,
            todayGames: todayGames
        )
    }

    // MARK: - Private Methods

    private func fetchGames(from endpoint: MainHomeEndpoint) async throws -> [MainHomeGame] {
        let response = try await networkClient.get(
            endpoint.path,
            queryItems: endpoint.queryItems,
            headers: [:],
            as: APISportsResponse<[APISportsGameResponse]>.self
        )

        return response.response.compactMap(\.mainHomeGame)
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

// MARK: - API-Sports DTO

private nonisolated struct APISportsResponse<Response: Decodable & Sendable>: Decodable, Sendable {

    let response: Response
}

private nonisolated struct APISportsGameResponse: Decodable, Sendable {

    let id: Int?
    let date: APISportsGameDateResponse?
    let time: String?
    let league: APISportsLeagueResponse?
    let status: APISportsGameStatusResponse?
    let teams: APISportsGameTeamsResponse?
    let scores: APISportsGameScoresResponse?

    var mainHomeGame: MainHomeGame? {
        guard let id,
              let homeName = teams?.home.name,
              let awayName = teams?.away.name else {
            return nil
        }

        return MainHomeGame(
            id: id,
            leagueName: league?.displayName ?? "Other League",
            homeTeamName: homeName,
            awayTeamName: awayName,
            scheduledStartText: time ?? date?.displayText,
            statusDescription: status?.long ?? status?.short?.displayValue,
            homeScore: scores?.home?.displayValue,
            awayScore: scores?.away?.displayValue
        )
    }
}

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

private nonisolated struct APISportsGameDateResponse: Decodable, Sendable {

    let displayText: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            displayText = nil
            return
        }

        if let value = try? container.decode(String.self) {
            displayText = value
            return
        }

        if let object = try? container.decode(APISportsGameDateObjectResponse.self) {
            displayText = object.start
            return
        }

        displayText = nil
    }
}

private nonisolated struct APISportsGameDateObjectResponse: Decodable, Sendable {

    let start: String?
}

private nonisolated struct APISportsGameStatusResponse: Decodable, Sendable {

    let long: String?
    let short: APISportsFlexibleValueResponse?
}

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

    let id: Int?
    let name: String?
    let logo: String?
}

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
