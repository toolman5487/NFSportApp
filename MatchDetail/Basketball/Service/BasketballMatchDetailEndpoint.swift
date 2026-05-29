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
