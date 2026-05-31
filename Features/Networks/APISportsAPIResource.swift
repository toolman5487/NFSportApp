//
//  APISportsAPIResource.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/31.
//

import Foundation

// MARK: - APISportsAPIResource

nonisolated enum APISportsAPIResource: String, Equatable, Hashable, Sendable {

    // MARK: Catalog

    case countries
    case leagues
    case seasons
    case standings
    case teams
    case players
    case coaches
    case venues

    // MARK: Match

    case games
    case fixtures
    case fixtureRounds = "fixtures/rounds"
    case fixtureHeadToHead = "fixtures/headtohead"

    // MARK: Match Detail

    case gameStatistics = "games/statistics"
    case gameTeamStatistics = "games/statistics/teams"
    case fixtureStatistics = "fixtures/statistics"
    case fixtureEvents = "fixtures/events"
    case fixtureLineups = "fixtures/lineups"
    case fixturePlayers = "fixtures/players"

    // MARK: Team & Player Detail

    case teamStatistics = "teams/statistics"
    case playerSeasons = "players/seasons"
    case transfers
    case trophies
    case sidelined
    case injuries

    // MARK: Forecast & Odds

    case predictions
    case odds
    case liveOdds = "odds/live"
    case bookmakers
    case bets

    var path: String {
        rawValue
    }
}

// MARK: - APISportsMatchAPI

nonisolated enum APISportsMatchAPI: Equatable, Hashable, Sendable {

    case games
    case fixtures

    var resource: APISportsAPIResource {
        switch self {
        case .games:
            return .games
        case .fixtures:
            return .fixtures
        }
    }

    var detailIDQueryName: String {
        switch self {
        case .games,
             .fixtures:
            return "id"
        }
    }

    var relatedDetailQueryName: String {
        switch self {
        case .games:
            return "game"
        case .fixtures:
            return "fixture"
        }
    }

    var path: String {
        resource.path
    }
}
