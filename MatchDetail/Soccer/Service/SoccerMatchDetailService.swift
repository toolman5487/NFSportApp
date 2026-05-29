//
//  SoccerMatchDetailService.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/26.
//

import Foundation

// MARK: - SoccerMatchDetailServicing

nonisolated protocol SoccerMatchDetailServicing: Sendable {

    func fetchMatchDetail(fixtureID: Int) async throws -> SoccerMatchDetail
}

// MARK: - SoccerMatchDetailService

nonisolated struct SoccerMatchDetailService: SoccerMatchDetailServicing {

    private let networkClient: NetworkServicing

    init(networkClient: NetworkServicing) {
        self.networkClient = networkClient
    }

    func fetchMatchDetail(fixtureID: Int) async throws -> SoccerMatchDetail {
        async let fixturePayload = fetchFixturePayload(from: .fixture(id: fixtureID))
        async let statistics = fetchStatistics(from: .statistics(fixtureID: fixtureID))
        async let events = fetchEvents(from: .events(fixtureID: fixtureID))
        async let lineups = fetchLineups(from: .lineups(fixtureID: fixtureID))

        let resolvedFixturePayload = try await fixturePayload
        let dedicatedStatistics = (try? await statistics) ?? []
        let resolvedStatistics = dedicatedStatistics.isEmpty
            ? resolvedFixturePayload.embeddedStatistics
            : dedicatedStatistics
        let resolvedEvents = (try? await events) ?? []
        let resolvedLineups = (try? await lineups) ?? []

        return SoccerMatchDetail(
            fixture: resolvedFixturePayload.fixture,
            statistics: resolvedStatistics,
            events: resolvedEvents,
            lineups: resolvedLineups
        )
    }

    private func fetchFixturePayload(
        from endpoint: SoccerMatchDetailEndpoint
    ) async throws -> APISoccerFixturePayload {
        let response = try await networkClient.get(
            endpoint.path,
            queryItems: endpoint.queryItems,
            headers: [:],
            as: APISoccerMatchDetailResponse<[APISoccerMatchFixtureResponse]>.self
        )

        guard let payload = response.response.compactMap(\.domainPayload).first else {
            throw NetworkError.invalidResponse
        }

        return payload
    }

    private func fetchStatistics(from endpoint: SoccerMatchDetailEndpoint) async throws -> [SoccerMatchTeamStatistics] {
        let response = try await networkClient.get(
            endpoint.path,
            queryItems: endpoint.queryItems,
            headers: [:],
            as: APISoccerMatchDetailResponse<[APISoccerMatchStatisticsResponse]>.self
        )

        return response.response.compactMap(\.domainStatistics)
    }

    private func fetchEvents(from endpoint: SoccerMatchDetailEndpoint) async throws -> [SoccerMatchEvent] {
        let response = try await networkClient.get(
            endpoint.path,
            queryItems: endpoint.queryItems,
            headers: [:],
            as: APISoccerMatchDetailResponse<[APISoccerMatchEventResponse]>.self
        )

        return response.response.compactMap(\.domainEvent)
    }

    private func fetchLineups(from endpoint: SoccerMatchDetailEndpoint) async throws -> [SoccerMatchLineup] {
        let response = try await networkClient.get(
            endpoint.path,
            queryItems: endpoint.queryItems,
            headers: [:],
            as: APISoccerMatchDetailResponse<[APISoccerMatchLineupResponse]>.self
        )

        return response.response.compactMap(\.domainLineup)
    }
}

// MARK: - API Response

private nonisolated struct APISoccerMatchDetailResponse<Response: Decodable & Sendable>: Decodable, Sendable {

    let response: Response
}

// MARK: - Fixture Payload

private nonisolated struct APISoccerFixturePayload: Sendable {

    let fixture: SoccerMatchFixtureDetail
    let embeddedStatistics: [SoccerMatchTeamStatistics]
}

// MARK: - Fixture Response

private nonisolated struct APISoccerMatchFixtureResponse: Decodable, Sendable {

    let fixture: APISoccerMatchFixtureInfoResponse?
    let league: APISoccerMatchLeagueResponse?
    let teams: APISoccerMatchTeamsResponse?
    let goals: APISoccerMatchGoalsResponse?
    let score: APISoccerMatchScoreBreakdownResponse?
    let statistics: [APISoccerMatchStatisticsResponse]?

    var domainPayload: APISoccerFixturePayload? {
        guard let fixtureID = fixture?.id,
              let homeTeam = teams?.home.domainTeam,
              let awayTeam = teams?.away.domainTeam else {
            return nil
        }

        let fulltime = score?.fulltime?.domainScoreLine
        let primaryHome = goals?.home ?? fulltime?.home
        let primaryAway = goals?.away ?? fulltime?.away

        return APISoccerFixturePayload(
            fixture: SoccerMatchFixtureDetail(
                id: fixtureID,
                leagueName: league?.name ?? "Other League",
                leagueLogoURL: league?.logoURL,
                referee: fixture?.referee,
                venueName: fixture?.venue?.name,
                venueCity: fixture?.venue?.city,
                scheduledStartDate: fixture?.date.flatMap(Self.makeDate(from:)),
                scheduledStartText: fixture?.date,
                statusLong: fixture?.status?.long,
                statusShort: fixture?.status?.short,
                elapsedMinute: fixture?.status?.elapsed,
                homeTeam: homeTeam,
                awayTeam: awayTeam,
                score: SoccerMatchScore(
                    home: primaryHome,
                    away: primaryAway,
                    halftime: score?.halftime?.domainScoreLine,
                    fulltime: fulltime,
                    extratime: score?.extratime?.domainScoreLine,
                    penalty: score?.penalty?.domainScoreLine
                )
            ),
            embeddedStatistics: statistics?.compactMap(\.domainStatistics) ?? []
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

private nonisolated struct APISoccerMatchFixtureInfoResponse: Decodable, Sendable {

    let id: Int?
    let referee: String?
    let date: String?
    let venue: APISoccerMatchVenueResponse?
    let status: APISoccerMatchStatusResponse?
}

private nonisolated struct APISoccerMatchVenueResponse: Decodable, Sendable {

    let name: String?
    let city: String?
}

private nonisolated struct APISoccerMatchStatusResponse: Decodable, Sendable {

    let long: String?
    let short: String?
    let elapsed: Int?
}

private nonisolated struct APISoccerMatchLeagueResponse: Decodable, Sendable {

    let name: String?
    let logo: String?

    var logoURL: URL? {
        guard let logo else {
            return nil
        }

        return URL(string: logo)
    }
}

private nonisolated struct APISoccerMatchTeamsResponse: Decodable, Sendable {

    let home: APISoccerMatchTeamResponse
    let away: APISoccerMatchTeamResponse
}

private nonisolated struct APISoccerMatchTeamResponse: Decodable, Sendable {

    let id: Int?
    let name: String?
    let logo: String?

    var logoURL: URL? {
        guard let logo else {
            return nil
        }

        return URL(string: logo)
    }

    var domainTeam: SoccerMatchTeam? {
        guard let name else {
            return nil
        }

        return SoccerMatchTeam(
            teamID: id,
            name: name,
            logoURL: logoURL
        )
    }
}

private nonisolated struct APISoccerMatchGoalsResponse: Decodable, Sendable {

    let home: Int?
    let away: Int?

    var domainScoreLine: SoccerMatchScoreLine {
        SoccerMatchScoreLine(home: home, away: away)
    }
}

private nonisolated struct APISoccerMatchScoreBreakdownResponse: Decodable, Sendable {

    let halftime: APISoccerMatchGoalsResponse?
    let fulltime: APISoccerMatchGoalsResponse?
    let extratime: APISoccerMatchGoalsResponse?
    let penalty: APISoccerMatchGoalsResponse?
}

// MARK: - Statistics Response

private nonisolated struct APISoccerMatchStatisticsResponse: Decodable, Sendable {

    let team: APISoccerMatchTeamResponse?
    let statistics: [APISoccerMatchStatisticResponse]?

    var domainStatistics: SoccerMatchTeamStatistics? {
        guard let team = team?.domainTeam else {
            return nil
        }

        return SoccerMatchTeamStatistics(
            team: team,
            statistics: statistics?.compactMap(\.domainStatistic) ?? []
        )
    }
}

private nonisolated struct APISoccerMatchStatisticResponse: Decodable, Sendable {

    let type: String?
    let value: APISoccerMatchFlexibleValueResponse?

    var domainStatistic: SoccerMatchStatistic? {
        guard let type, !type.isEmpty else {
            return nil
        }

        return SoccerMatchStatistic(
            type: type,
            value: value?.displayText
        )
    }
}

private nonisolated struct APISoccerMatchFlexibleValueResponse: Decodable, Sendable {

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

        if let value = try? container.decode(Int.self) {
            displayText = "\(value)"
            return
        }

        if let value = try? container.decode(Double.self) {
            displayText = String(value)
            return
        }

        if let value = try? container.decode(Bool.self) {
            displayText = value ? "true" : "false"
            return
        }

        displayText = nil
    }
}

// MARK: - Events Response

private nonisolated struct APISoccerMatchEventResponse: Decodable, Sendable {

    let time: APISoccerMatchEventTimeResponse?
    let team: APISoccerMatchTeamResponse?
    let player: APISoccerMatchNamedPersonResponse?
    let assist: APISoccerMatchNamedPersonResponse?
    let type: String?
    let detail: String?
    let comments: String?

    var domainEvent: SoccerMatchEvent? {
        guard let type else {
            return nil
        }

        return SoccerMatchEvent(
            elapsedMinute: time?.elapsed,
            extraMinute: time?.extra,
            team: team?.domainTeam,
            playerName: player?.name,
            assistName: assist?.name,
            type: type,
            detail: detail,
            comments: comments
        )
    }
}

private nonisolated struct APISoccerMatchEventTimeResponse: Decodable, Sendable {

    let elapsed: Int?
    let extra: Int?
}

private nonisolated struct APISoccerMatchNamedPersonResponse: Decodable, Sendable {

    let name: String?
}

// MARK: - Lineups Response

private nonisolated struct APISoccerMatchLineupResponse: Decodable, Sendable {

    let team: APISoccerMatchTeamResponse?
    let coach: APISoccerMatchCoachResponse?
    let formation: String?
    let startXI: [APISoccerMatchLineupPlayerContainerResponse]?
    let substitutes: [APISoccerMatchLineupPlayerContainerResponse]?

    var domainLineup: SoccerMatchLineup? {
        guard let team = team?.domainTeam else {
            return nil
        }

        return SoccerMatchLineup(
            team: team,
            coachName: coach?.name,
            formation: formation,
            startXI: startXI?.compactMap(\.player?.domainPlayer) ?? [],
            substitutes: substitutes?.compactMap(\.player?.domainPlayer) ?? []
        )
    }
}

private nonisolated struct APISoccerMatchCoachResponse: Decodable, Sendable {

    let name: String?
}

private nonisolated struct APISoccerMatchLineupPlayerContainerResponse: Decodable, Sendable {

    let player: APISoccerMatchLineupPlayerResponse?
}

private nonisolated struct APISoccerMatchLineupPlayerResponse: Decodable, Sendable {

    let id: Int?
    let name: String?
    let number: Int?
    let pos: String?
    let grid: String?

    var domainPlayer: SoccerMatchLineupPlayer? {
        guard let name else {
            return nil
        }

        return SoccerMatchLineupPlayer(
            playerID: id,
            name: name,
            number: number,
            position: pos,
            grid: grid
        )
    }
}
