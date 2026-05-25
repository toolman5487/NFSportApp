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

    // MARK: - Constants

    private static let topLeagueIDs = [39, 140, 135, 78, 61, 2]
    private static let maximumTopLeagueCount = 4

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
        async let topLeagues = fetchTopLeagues()

        let resolvedLiveFixtures = try await liveFixtures
        let resolvedTodayFixtures = try await todayFixtures
        let resolvedTopLeagues = try await topLeagues
        let standingsPayload = await fetchFirstAvailableStandings(from: resolvedTopLeagues)

        return MainSoccerHomeDashboard(
            sport: sport,
            date: date,
            liveFixtures: resolvedLiveFixtures,
            todayFixtures: resolvedTodayFixtures,
            topLeagues: resolvedTopLeagues,
            standingsTitle: standingsPayload?.title,
            standings: standingsPayload?.rows ?? []
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

    // MARK: - Leagues

    private func fetchTopLeagues() async throws -> [MainSoccerLeague] {
        let endpoint = MainSoccerHomeEndpoint.currentLeagues
        let response = try await networkClient.get(
            endpoint.path,
            queryItems: endpoint.queryItems,
            headers: [:],
            as: APISoccerResponse<[APISoccerLeagueResponse]>.self
        )
        var leaguesByID: [Int: MainSoccerLeague] = [:]
        for response in response.response {
            guard let league = response.domainLeague,
                  leaguesByID[league.id] == nil else {
                continue
            }

            leaguesByID[league.id] = league
        }

        return Self.topLeagueIDs
            .compactMap { leaguesByID[$0] }
            .prefix(Self.maximumTopLeagueCount)
            .map { $0 }
    }

    // MARK: - Standings

    private func fetchFirstAvailableStandings(
        from leagues: [MainSoccerLeague]
    ) async -> (title: String, rows: [MainSoccerStandingRow])? {
        for league in leagues where league.supportsStandings {
            guard let season = league.currentSeason,
                  let rows = try? await fetchStandings(leagueID: league.id, season: season),
                  !rows.isEmpty else {
                continue
            }

            return (league.name, rows)
        }

        return nil
    }

    private func fetchStandings(
        leagueID: Int,
        season: Int
    ) async throws -> [MainSoccerStandingRow] {
        let endpoint = MainSoccerHomeEndpoint.standings(
            leagueID: leagueID,
            season: season
        )
        let response = try await networkClient.get(
            endpoint.path,
            queryItems: endpoint.queryItems,
            headers: [:],
            as: APISoccerResponse<[APISoccerStandingsResponse]>.self
        )

        return response.response.first?.rows ?? []
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

// MARK: - Leagues Response

private nonisolated struct APISoccerLeagueResponse: Decodable, Sendable {

    let league: APISoccerLeagueDetailResponse?
    let country: APISoccerCountryResponse?
    let seasons: [APISoccerSeasonResponse]

    var domainLeague: MainSoccerLeague? {
        guard let id = league?.id,
              let name = league?.name else {
            return nil
        }

        let currentSeason = seasons.first(where: \.isCurrent) ?? seasons.first
        return MainSoccerLeague(
            id: id,
            name: name,
            countryName: country?.name,
            logoURL: league?.logoURL,
            currentSeason: currentSeason?.year,
            supportsStandings: currentSeason?.coverage.standings ?? false
        )
    }
}

private nonisolated struct APISoccerLeagueDetailResponse: Decodable, Sendable {

    let id: Int?
    let name: String?
    let logo: String?

    var logoURL: URL? {
        guard let logo else {
            return nil
        }

        return URL(string: logo)
    }
}

private nonisolated struct APISoccerCountryResponse: Decodable, Sendable {

    let name: String?
}

private nonisolated struct APISoccerSeasonResponse: Decodable, Sendable {

    let year: Int?
    let current: Bool?
    let coverage: APISoccerCoverageResponse

    var isCurrent: Bool {
        current == true
    }
}

private nonisolated struct APISoccerCoverageResponse: Decodable, Sendable {

    let standings: Bool
}

// MARK: - Standings Response

private nonisolated struct APISoccerStandingsResponse: Decodable, Sendable {

    let league: APISoccerStandingsLeagueResponse?

    var rows: [MainSoccerStandingRow] {
        league?.standings.first?.compactMap(\.row) ?? []
    }
}

private nonisolated struct APISoccerStandingsLeagueResponse: Decodable, Sendable {

    let standings: [[APISoccerStandingRowResponse]]
}

private nonisolated struct APISoccerStandingRowResponse: Decodable, Sendable {

    let rank: Int?
    let team: APISoccerStandingTeamResponse?
    let points: Int?
    let goalsDiff: Int?
    let all: APISoccerStandingStatsResponse?

    var row: MainSoccerStandingRow? {
        guard let rank,
              let teamName = team?.name,
              let points else {
            return nil
        }

        return MainSoccerStandingRow(
            rank: rank,
            teamName: teamName,
            teamLogoURL: team?.logoURL,
            points: points,
            played: all?.played,
            wins: all?.win,
            draws: all?.draw,
            losses: all?.lose,
            goalsDifference: goalsDiff
        )
    }
}

private nonisolated struct APISoccerStandingTeamResponse: Decodable, Sendable {

    let name: String?
    let logo: String?

    var logoURL: URL? {
        guard let logo else {
            return nil
        }

        return URL(string: logo)
    }
}

private nonisolated struct APISoccerStandingStatsResponse: Decodable, Sendable {

    let played: Int?
    let win: Int?
    let draw: Int?
    let lose: Int?
}
