//
//  MainSoccerHomeService.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/25.
//

import Foundation

// MARK: - MainSoccerHomeServicing

nonisolated protocol MainSoccerHomeServicing: Sendable {

    func fetchDashboard(
        for sport: SportType,
        date: Date
    ) async throws -> MainSoccerHomeDashboard
}

// MARK: - MainSoccerHomeService

nonisolated struct MainSoccerHomeService: MainSoccerHomeServicing {

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
    ) async throws -> MainSoccerHomeDashboard {
        let timezone = TimeZone.current.identifier

        async let liveFixtures = fetchFixtures(from: .liveFixtures(timezone: timezone))
        async let todayFixtures = fetchFixtures(
            from: .fixtures(
                date: makeAPIDateString(from: date),
                timezone: timezone
            )
        )

        let resolvedLiveFixtures = try await liveFixtures
        let resolvedTodayFixtures = try await todayFixtures

        return MainSoccerHomeDashboard(
            sport: sport,
            date: date,
            liveFixtures: resolvedLiveFixtures,
            todayFixtures: resolvedTodayFixtures
        )
    }

    // MARK: - Fixtures

    private func fetchFixtures(from endpoint: MainSoccerHomeEndpoint) async throws -> [MainSoccerFixture] {
        let response = try await networkClient.get(
            endpoint.path,
            queryItems: endpoint.queryItems,
            headers: [:],
            as: APISoccerResponse<[APISoccerFixtureResponse]>.self
        )

        return response.response.compactMap(\.domainFixture)
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

private nonisolated struct APISoccerResponse<Response: Decodable & Sendable>: Decodable, Sendable {

    let response: Response
}

// MARK: - Fixtures Response

private nonisolated struct APISoccerFixtureResponse: Decodable, Sendable {

    let fixture: APISoccerFixtureDetailResponse?
    let league: APISoccerFixtureLeagueResponse?
    let teams: APISoccerFixtureTeamsResponse?
    let goals: APISoccerGoalsResponse?

    var domainFixture: MainSoccerFixture? {
        guard let id = fixture?.id,
              let homeTeamName = teams?.home.name,
              let awayTeamName = teams?.away.name else {
            return nil
        }

        return MainSoccerFixture(
            id: id,
            leagueName: league?.name ?? "Other League",
            leagueLogoURL: league?.logoURL,
            scheduledStartDate: fixture?.date.flatMap(Self.makeDate(from:)),
            scheduledStartText: fixture?.date,
            statusLong: fixture?.status?.long,
            statusShort: fixture?.status?.short,
            elapsedMinute: fixture?.status?.elapsed,
            homeTeamName: homeTeamName,
            homeTeamLogoURL: teams?.home.logoURL,
            awayTeamName: awayTeamName,
            awayTeamLogoURL: teams?.away.logoURL,
            homeScore: goals?.home,
            awayScore: goals?.away
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

private nonisolated struct APISoccerFixtureDetailResponse: Decodable, Sendable {

    let id: Int?
    let date: String?
    let status: APISoccerFixtureStatusResponse?
}

private nonisolated struct APISoccerFixtureStatusResponse: Decodable, Sendable {

    let long: String?
    let short: String?
    let elapsed: Int?
}

private nonisolated struct APISoccerFixtureLeagueResponse: Decodable, Sendable {

    let name: String?
    let logo: String?

    var logoURL: URL? {
        guard let logo else {
            return nil
        }

        return URL(string: logo)
    }
}

private nonisolated struct APISoccerFixtureTeamsResponse: Decodable, Sendable {

    let home: APISoccerTeamResponse
    let away: APISoccerTeamResponse
}

private nonisolated struct APISoccerTeamResponse: Decodable, Sendable {

    let name: String?
    let logo: String?

    var logoURL: URL? {
        guard let logo else {
            return nil
        }

        return URL(string: logo)
    }
}

private nonisolated struct APISoccerGoalsResponse: Decodable, Sendable {

    let home: Int?
    let away: Int?
}
