//
//  SoccerMatchDetailEndpoint.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/26.
//

import Foundation

// MARK: - SoccerMatchDetailEndpoint

nonisolated enum SoccerMatchDetailEndpoint: Equatable, Sendable {

    case fixture(id: Int)
    case statistics(fixtureID: Int)
    case events(fixtureID: Int)
    case lineups(fixtureID: Int)

    var path: String {
        apiEndpoint.path
    }

    var queryItems: [NetworkQueryItem] {
        apiEndpoint.queryItems
    }

    private var apiEndpoint: APISportsEndpoint {
        switch self {
        case .fixture(let id):
            return APISportsEndpoint(
                matchAPI: APISportsProduct.soccer.matchAPI,
                queryItems: [
                    NetworkQueryItem(
                        parameter: APISportsProduct.soccer.matchAPI.detailIDQueryParameter,
                        value: "\(id)"
                    )
                ]
            )

        case .statistics(let fixtureID):
            return makeRelatedDetailEndpoint(
                resource: .fixtureStatistics,
                fixtureID: fixtureID
            )

        case .events(let fixtureID):
            return makeRelatedDetailEndpoint(
                resource: .fixtureEvents,
                fixtureID: fixtureID
            )

        case .lineups(let fixtureID):
            return makeRelatedDetailEndpoint(
                resource: .fixtureLineups,
                fixtureID: fixtureID
            )
        }
    }

    private func makeRelatedDetailEndpoint(
        resource: APISportsAPIResource,
        fixtureID: Int
    ) -> APISportsEndpoint {
        APISportsEndpoint(
            resource: resource,
            queryItems: [
                NetworkQueryItem(
                    parameter: APISportsProduct.soccer.matchAPI.relatedDetailQueryParameter,
                    value: "\(fixtureID)"
                )
            ]
        )
    }
}
