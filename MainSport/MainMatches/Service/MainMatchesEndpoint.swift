//
//  MainMatchesEndpoint.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/25.
//

import Foundation

// MARK: - MainMatchesEndpoint

nonisolated enum MainMatchesEndpoint: Equatable, Sendable {

    case games(date: String, timezone: String)

    var path: String {
        apiEndpoint.path
    }

    var queryItems: [NetworkQueryItem] {
        apiEndpoint.queryItems
    }

    private var apiEndpoint: APISportsEndpoint {
        switch self {
        case .games(let date, let timezone):
            return APISportsEndpoint(
                matchAPI: .games,
                queryItems: [
                    NetworkQueryItem(parameter: .date, value: date),
                    NetworkQueryItem(parameter: .timezone, value: timezone)
                ]
            )
        }
    }
}
