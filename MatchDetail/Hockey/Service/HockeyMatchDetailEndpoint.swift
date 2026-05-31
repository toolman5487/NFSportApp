//
//  HockeyMatchDetailEndpoint.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/28.
//

import Foundation

// MARK: - HockeyMatchDetailEndpoint

nonisolated enum HockeyMatchDetailEndpoint: Equatable, Sendable {

    case game(id: Int)

    var path: String {
        switch self {
        case .game:
            return APISportsProduct.hockey.matchAPI.path
        }
    }

    var queryItems: [NetworkQueryItem] {
        switch self {
        case .game(let id):
            return [
                NetworkQueryItem(
                    name: APISportsProduct.hockey.matchAPI.detailIDQueryName,
                    value: "\(id)"
                )
            ]
        }
    }
}
