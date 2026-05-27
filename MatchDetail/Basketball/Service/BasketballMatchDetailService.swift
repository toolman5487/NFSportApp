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

// MARK: - BasketballMatchDetailService

nonisolated struct BasketballMatchDetailService: BasketballMatchDetailServicing {

    private let networkClient: NetworkServicing

    init(networkClient: NetworkServicing) {
        self.networkClient = networkClient
    }

    func fetchMatchDetail(gameID: Int) async throws -> BasketballMatchDetail {
        let game = try await fetchGame(from: .game(id: gameID))

        return BasketballMatchDetail(fixture: game)
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
            scheduledStartDate: date.flatMap(Self.makeDate(from:)),
            scheduledStartText: Self.makeScheduledStartText(date: date, time: time),
            statusLong: status?.long,
            statusShort: status?.short,
            elapsedMinute: nil,
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            score: BasketballMatchScore(
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
}
