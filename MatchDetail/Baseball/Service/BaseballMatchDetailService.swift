//
//  BaseballMatchDetailService.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/28.
//

import Foundation

// MARK: - BaseballMatchDetailServicing

nonisolated protocol BaseballMatchDetailServicing: Sendable {

    func fetchMatchDetail(gameID: Int) async throws -> BaseballMatchDetail
}

// MARK: - BaseballMatchDetailService

nonisolated struct BaseballMatchDetailService: BaseballMatchDetailServicing {

    private let networkClient: NetworkServicing

    init(networkClient: NetworkServicing) {
        self.networkClient = networkClient
    }

    func fetchMatchDetail(gameID: Int) async throws -> BaseballMatchDetail {
        let game = try await fetchGame(from: .game(id: gameID))
        return BaseballMatchDetail(fixture: game)
    }

    private func fetchGame(from endpoint: BaseballMatchDetailEndpoint) async throws -> BaseballMatchFixtureDetail {
        let response = try await networkClient.get(
            endpoint.path,
            queryItems: endpoint.queryItems,
            headers: [:],
            as: APIBaseballMatchDetailResponse<[APIBaseballMatchGameResponse]>.self
        )

        guard let game = response.response.compactMap(\.domainFixture).first else {
            throw NetworkError.invalidResponse
        }

        return game
    }
}

// MARK: - API Response

private nonisolated struct APIBaseballMatchDetailResponse<Response: Decodable & Sendable>: Decodable, Sendable {

    let response: Response
}

// MARK: - Game Response

private nonisolated struct APIBaseballMatchGameResponse: Decodable, Sendable {

    let id: Int?
    let date: String?
    let time: String?
    let venue: String?
    let status: APIBaseballMatchStatusResponse?
    let league: APIBaseballMatchLeagueResponse?
    let teams: APIBaseballMatchTeamsResponse?
    let scores: APIBaseballMatchScoresResponse?

    var domainFixture: BaseballMatchFixtureDetail? {
        guard let gameID = id,
              let homeTeam = teams?.home.domainTeam,
              let awayTeam = teams?.away.domainTeam else {
            return nil
        }

        return BaseballMatchFixtureDetail(
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
            score: BaseballMatchScore(
                home: scores?.home?.total,
                away: scores?.away?.total
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

private nonisolated struct APIBaseballMatchStatusResponse: Decodable, Sendable {

    let long: String?
    let short: String?
    let timer: String?
}

private nonisolated struct APIBaseballMatchLeagueResponse: Decodable, Sendable {

    let name: String?
    let logo: String?

    var logoURL: URL? {
        guard let logo else {
            return nil
        }
        return URL(string: logo)
    }
}

private nonisolated struct APIBaseballMatchTeamsResponse: Decodable, Sendable {

    let home: APIBaseballMatchTeamResponse
    let away: APIBaseballMatchTeamResponse
}

private nonisolated struct APIBaseballMatchTeamResponse: Decodable, Sendable {

    let id: Int?
    let name: String?
    let logo: String?

    var logoURL: URL? {
        guard let logo else {
            return nil
        }
        return URL(string: logo)
    }

    var domainTeam: BaseballMatchTeam? {
        guard let name else {
            return nil
        }
        return BaseballMatchTeam(
            teamID: id,
            name: name,
            logoURL: logoURL
        )
    }
}

private nonisolated struct APIBaseballMatchScoresResponse: Decodable, Sendable {

    let home: APIBaseballMatchTeamScoreResponse?
    let away: APIBaseballMatchTeamScoreResponse?
}

private nonisolated struct APIBaseballMatchTeamScoreResponse: Decodable, Sendable {

    let total: Int?
}

