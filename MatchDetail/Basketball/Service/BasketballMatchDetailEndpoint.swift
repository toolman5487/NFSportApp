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
        apiEndpoint.path
    }

    var queryItems: [NetworkQueryItem] {
        apiEndpoint.queryItems
    }

    private var apiEndpoint: APISportsEndpoint {
        switch self {
        case .game(let id):
            return APISportsEndpoint(
                matchAPI: APISportsProduct.basketball.matchAPI,
                queryItems: [
                    NetworkQueryItem(
                        parameter: APISportsProduct.basketball.matchAPI.detailIDQueryParameter,
                        value: "\(id)"
                    )
                ]
            )

        case .teamStatistics(let gameID):
            return APISportsEndpoint(
                resource: .gameTeamStatistics,
                queryItems: [
                    NetworkQueryItem(
                        parameter: APISportsProduct.basketball.matchAPI.detailIDQueryParameter,
                        value: "\(gameID)"
                    )
                ]
            )

        case .players(let gameID):
            return APISportsEndpoint(
                resource: .players,
                queryItems: [
                    NetworkQueryItem(
                        parameter: APISportsProduct.basketball.matchAPI.relatedDetailQueryParameter,
                        value: "\(gameID)"
                    )
                ]
            )
        }
    }

}
