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
            return "games"
        case .players:
            return "players"
        }
    }

    var queryItems: [NetworkQueryItem] {
        switch self {
        case .game(let id):
            return [
                NetworkQueryItem(name: "id", value: "\(id)")
            ]
        case .players(let gameID):
            return [
                NetworkQueryItem(name: "game", value: "\(gameID)")
            ]
        }
    }
}

