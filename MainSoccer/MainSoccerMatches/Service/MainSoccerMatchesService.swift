//
//  MainSoccerMatchesService.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/25.
//

import Foundation

// MARK: - MainSoccerMatchesServicing

nonisolated protocol MainSoccerMatchesServicing: Sendable {

    func fetchSchedule(
        for sport: SportType,
        date: Date
    ) async throws -> MainSoccerMatchesSchedule
}

// MARK: - MainSoccerMatchesService

nonisolated struct MainSoccerMatchesService: MainSoccerMatchesServicing {

    // MARK: - Dependencies

    private let networkClient: NetworkServicing

    // MARK: - Initialization

    init(networkClient: NetworkServicing) {
        self.networkClient = networkClient
    }

    // MARK: - Public Methods

    func fetchSchedule(
        for sport: SportType,
        date: Date
    ) async throws -> MainSoccerMatchesSchedule {
        let endpoint = MainSoccerMatchesEndpoint.fixtures(
            date: makeAPIDateString(from: date),
            timezone: TimeZone.current.identifier
        )
        let response = try await networkClient.get(
            endpoint.path,
            queryItems: endpoint.queryItems,
            headers: [:],
            as: APISoccerMatchesResponse<[APISoccerMatchesFixtureResponse]>.self
        )

        return MainSoccerMatchesSchedule(
            sport: sport,
            date: date,
            games: response.response.compactMap(\.mainMatchesGame)
        )
    }

    // MARK: - Date

    private func makeAPIDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - API Response

private nonisolated struct APISoccerMatchesResponse<Response: Decodable & Sendable>: Decodable, Sendable {

    let response: Response
}

// MARK: - Fixture Response

private nonisolated struct APISoccerMatchesFixtureResponse: Decodable, Sendable {

    let fixture: APISoccerMatchesFixtureDetailResponse?
    let league: APISoccerMatchesLeagueResponse?
    let teams: APISoccerMatchesTeamsResponse?
    let goals: APISoccerMatchesGoalsResponse?

    var mainMatchesGame: MainSoccerMatchesGame? {
        guard let id = fixture?.id,
              let homeTeamName = teams?.home.name,
              let awayTeamName = teams?.away.name else {
            return nil
        }

        return MainSoccerMatchesGame(
            id: id,
            leagueName: league?.name ?? "Other League",
            leagueLogoURL: league?.logoURL,
            scheduledStartDate: fixture?.date.flatMap(Self.makeDate(from:)),
            scheduledStartText: fixture?.date ?? "TBD",
            statusDescription: fixture?.status?.long ?? fixture?.status?.short,
            homeTeamName: homeTeamName,
            homeTeamLogoURL: teams?.home.logoURL,
            awayTeamName: awayTeamName,
            awayTeamLogoURL: teams?.away.logoURL,
            homeScore: goals?.home.map(String.init),
            awayScore: goals?.away.map(String.init)
        )
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

private nonisolated struct APISoccerMatchesFixtureDetailResponse: Decodable, Sendable {

    let id: Int?
    let date: String?
    let status: APISoccerMatchesStatusResponse?
}

private nonisolated struct APISoccerMatchesStatusResponse: Decodable, Sendable {

    let long: String?
    let short: String?
}

private nonisolated struct APISoccerMatchesLeagueResponse: Decodable, Sendable {

    let name: String?
    let logo: String?

    var logoURL: URL? {
        guard let logo else {
            return nil
        }

        return URL(string: logo)
    }
}

private nonisolated struct APISoccerMatchesTeamsResponse: Decodable, Sendable {

    let home: APISoccerMatchesTeamResponse
    let away: APISoccerMatchesTeamResponse
}

private nonisolated struct APISoccerMatchesTeamResponse: Decodable, Sendable {

    let name: String?
    let logo: String?

    var logoURL: URL? {
        guard let logo else {
            return nil
        }

        return URL(string: logo)
    }
}

private nonisolated struct APISoccerMatchesGoalsResponse: Decodable, Sendable {

    let home: Int?
    let away: Int?
}
