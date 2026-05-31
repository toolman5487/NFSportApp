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
        apiEndpoint.path
    }

    var queryItems: [NetworkQueryItem] {
        apiEndpoint.queryItems
    }

    private var apiEndpoint: APISportsEndpoint {
        switch self {
        case .game(let id):
            return APISportsEndpoint(
                matchAPI: APISportsProduct.hockey.matchAPI,
                queryItems: [
                    NetworkQueryItem(
                        parameter: APISportsProduct.hockey.matchAPI.detailIDQueryParameter,
                        value: "\(id)"
                    )
                ]
            )
        }
    }
}
