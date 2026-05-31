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
        apiEndpoint.path
    }

    var queryItems: [NetworkQueryItem] {
        apiEndpoint.queryItems
    }

    private var apiEndpoint: APISportsEndpoint {
        switch self {
        case .game(let id):
            return APISportsEndpoint(
                matchAPI: APISportsProduct.baseball.matchAPI,
                queryItems: [
                    NetworkQueryItem(
                        parameter: APISportsProduct.baseball.matchAPI.detailIDQueryParameter,
                        value: "\(id)"
                    )
                ]
            )

        case .players(let gameID):
            return APISportsEndpoint(
                resource: .players,
                queryItems: [
                    NetworkQueryItem(
                        parameter: APISportsProduct.baseball.matchAPI.relatedDetailQueryParameter,
                        value: "\(gameID)"
                    )
                ]
            )
        }
    }
}
