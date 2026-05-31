//
//  BasketballMatchDetailEndpoint.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/27.
//

import Foundation

// MARK: - BasketballMatchDetailEndpoint

nonisolated enum BasketballMatchDetailEndpoint: Equatable, Sendable {

    case game(id: Int)
    case teamStatistics(gameID: Int)
    case players(gameID: Int)

    var path: String {
        switch self {
        case .game:
            return APISportsProduct.basketball.matchAPI.path
        case .teamStatistics:
            return APISportsAPIResource.gameTeamStatistics.path
        case .players:
            return APISportsAPIResource.players.path
        }
    }

    var queryItems: [NetworkQueryItem] {
        switch self {
        case .game(let id):
            return [
                NetworkQueryItem(
                    name: APISportsProduct.basketball.matchAPI.detailIDQueryName,
                    value: "\(id)"
                )
            ]
        case .teamStatistics(let gameID):
            return [
                NetworkQueryItem(
                    name: APISportsProduct.basketball.matchAPI.detailIDQueryName,
                    value: "\(gameID)"
                )
            ]
        case .players(let gameID):
            return [
                NetworkQueryItem(
                    name: APISportsProduct.basketball.matchAPI.relatedDetailQueryName,
                    value: "\(gameID)"
                )
            ]
        }
    }
}
