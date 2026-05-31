//
//  BaseballMatchDetailEndpoint.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/28.
//

import Foundation

// MARK: - BaseballMatchDetailEndpoint

nonisolated enum BaseballMatchDetailEndpoint: Equatable, Sendable {

    case game(id: Int)
    case players(gameID: Int)

    var path: String {
        switch self {
        case .game:
            return APISportsProduct.baseball.matchAPI.path
        case .players:
            return APISportsAPIResource.players.path
        }
    }

    var queryItems: [NetworkQueryItem] {
        switch self {
        case .game(let id):
            return [
                NetworkQueryItem(
                    name: APISportsProduct.baseball.matchAPI.detailIDQueryName,
                    value: "\(id)"
                )
            ]
        case .players(let gameID):
            return [
                NetworkQueryItem(
                    name: APISportsProduct.baseball.matchAPI.relatedDetailQueryName,
                    value: "\(gameID)"
                )
            ]
        }
    }
}
