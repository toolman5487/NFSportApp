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

// MARK: - Stat Parsing

private nonisolated func baseballStatValue(_ value: APIBaseballFlexibleValue?) -> Double? {
    value?.doubleValue
}

// MARK: - BaseballMatchDetailService

nonisolated struct BaseballMatchDetailService: BaseballMatchDetailServicing {

    private let networkClient: NetworkServicing

    init(networkClient: NetworkServicing) {
        self.networkClient = networkClient
    }

    func fetchMatchDetail(gameID: Int) async throws -> BaseballMatchDetail {
        async let game = fetchGame(from: .game(id: gameID))
        async let players = fetchPlayers(from: .players(gameID: gameID))

        let fixture = try await game
        let playersByTeam = (try? await players) ?? []

        return BaseballMatchDetail(
            fixture: fixture,
            playersByTeam: playersByTeam
        )
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

    private func fetchPlayers(from endpoint: BaseballMatchDetailEndpoint) async throws -> [BaseballMatchTeamPlayers] {
        let response = try await networkClient.get(
            endpoint.path,
            queryItems: endpoint.queryItems,
            headers: [:],
            as: APIBaseballMatchDetailResponse<[APIBaseballMatchTeamPlayersResponse]>.self
        )

        return response.response.compactMap(\.domainTeamPlayers)
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
                home: scores?.home?.domainLineScore ?? BaseballMatchTeamLineScore(runs: nil, hits: nil, errors: nil, innings: []),
                away: scores?.away?.domainLineScore ?? BaseballMatchTeamLineScore(runs: nil, hits: nil, errors: nil, innings: [])
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
    let hits: Int?
    let errors: Int?
    let innings: [String: Int?]?

    var domainLineScore: BaseballMatchTeamLineScore {
        BaseballMatchTeamLineScore(
            runs: total,
            hits: hits,
            errors: errors,
            innings: Self.makeInningScores(from: innings)
        )
    }

    private static func makeInningScores(from innings: [String: Int?]?) -> [BaseballMatchPeriodScore] {
        guard let innings else {
            return []
        }

        let orderedKeys = (1...9).map(String.init) + ["extra"]
        return orderedKeys.compactMap { key in
            guard innings.keys.contains(key) else {
                return nil
            }

            let label = key == "extra" ? "Extra" : "Inning \(key)"
            return BaseballMatchPeriodScore(label: label, runs: innings[key] ?? nil)
        }
    }
}

// MARK: - Players Response

private nonisolated struct APIBaseballMatchTeamPlayersResponse: Decodable, Sendable {

    let team: APIBaseballMatchTeamResponse?
    let players: [APIBaseballMatchPlayerResponse]?

    var domainTeamPlayers: BaseballMatchTeamPlayers? {
        guard let team = team?.domainTeam else {
            return nil
        }

        return BaseballMatchTeamPlayers(
            team: team,
            players: players?.compactMap(\.domainPlayer) ?? []
        )
    }
}

private nonisolated struct APIBaseballMatchPlayerResponse: Decodable, Sendable {

    let id: Int?
    let name: String?
    let photo: String?
    let number: Int?
    let pos: String?
    let statistics: [APIBaseballMatchPlayerStatisticsResponse]?

    var domainPlayer: BaseballMatchPlayer? {
        guard let name else {
            return nil
        }

        return BaseballMatchPlayer(
            playerID: id,
            name: name,
            photoURL: photo.flatMap(URL.init(string:)),
            number: number,
            position: pos,
            statistics: statistics?.map(\.domainStatistics) ?? []
        )
    }
}

private nonisolated struct APIBaseballMatchPlayerStatisticsResponse: Decodable, Sendable {

    let batting: APIBaseballMatchBattingResponse?
    let pitching: APIBaseballMatchPitchingResponse?
    let fielding: APIBaseballMatchFieldingResponse?

    var domainStatistics: BaseballMatchPlayerStatistics {
        BaseballMatchPlayerStatistics(
            batting: batting?.domainStats ?? BaseballMatchBattingStats(
                atBats: nil,
                hits: nil,
                runs: nil,
                homeRuns: nil,
                runsBattedIn: nil,
                walks: nil,
                strikeouts: nil,
                stolenBases: nil
            ),
            pitching: pitching?.domainStats ?? BaseballMatchPitchingStats(
                inningsPitched: nil,
                hits: nil,
                earnedRuns: nil,
                walks: nil,
                strikeouts: nil
            ),
            fielding: fielding?.domainStats ?? BaseballMatchFieldingStats(
                putouts: nil,
                assists: nil,
                errors: nil
            )
        )
    }
}

private nonisolated struct APIBaseballMatchBattingResponse: Decodable, Sendable {

    let atBats: APIBaseballFlexibleValue?
    let hits: APIBaseballFlexibleValue?
    let runs: APIBaseballFlexibleValue?
    let homeRuns: APIBaseballFlexibleValue?
    let runsBattedIn: APIBaseballFlexibleValue?
    let walks: APIBaseballFlexibleValue?
    let strikeouts: APIBaseballFlexibleValue?
    let stolenBases: APIBaseballFlexibleValue?

    private enum CodingKeys: String, CodingKey {
        case atBats = "at_bats"
        case hits
        case runs
        case homeRuns = "home_runs"
        case runsBattedIn = "rbi"
        case walks = "base_on_balls"
        case strikeouts = "strikeouts"
        case stolenBases = "stolen_bases"
    }

    var domainStats: BaseballMatchBattingStats {
        BaseballMatchBattingStats(
            atBats: baseballStatValue(atBats),
            hits: baseballStatValue(hits),
            runs: baseballStatValue(runs),
            homeRuns: baseballStatValue(homeRuns),
            runsBattedIn: baseballStatValue(runsBattedIn),
            walks: baseballStatValue(walks),
            strikeouts: baseballStatValue(strikeouts),
            stolenBases: baseballStatValue(stolenBases)
        )
    }
}

private nonisolated struct APIBaseballMatchPitchingResponse: Decodable, Sendable {

    let inningsPitched: APIBaseballFlexibleValue?
    let hits: APIBaseballFlexibleValue?
    let earnedRuns: APIBaseballFlexibleValue?
    let walks: APIBaseballFlexibleValue?
    let strikeouts: APIBaseballFlexibleValue?

    private enum CodingKeys: String, CodingKey {
        case inningsPitched = "innings_pitched"
        case hits
        case earnedRuns = "earned_runs"
        case walks = "base_on_balls"
        case strikeouts = "strikeouts"
    }

    var domainStats: BaseballMatchPitchingStats {
        BaseballMatchPitchingStats(
            inningsPitched: baseballStatValue(inningsPitched),
            hits: baseballStatValue(hits),
            earnedRuns: baseballStatValue(earnedRuns),
            walks: baseballStatValue(walks),
            strikeouts: baseballStatValue(strikeouts)
        )
    }
}

private nonisolated struct APIBaseballMatchFieldingResponse: Decodable, Sendable {

    let putouts: APIBaseballFlexibleValue?
    let assists: APIBaseballFlexibleValue?
    let errors: APIBaseballFlexibleValue?

    private enum CodingKeys: String, CodingKey {
        case putouts
        case assists
        case errors
    }

    var domainStats: BaseballMatchFieldingStats {
        BaseballMatchFieldingStats(
            putouts: baseballStatValue(putouts),
            assists: baseballStatValue(assists),
            errors: baseballStatValue(errors)
        )
    }
}

// MARK: - Flexible Value

private nonisolated enum APIBaseballFlexibleValue: Decodable, Sendable {

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
            return Double(trimmed)
        case .none:
            return nil
        }
    }
}

