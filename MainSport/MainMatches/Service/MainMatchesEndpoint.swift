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
        switch self {
        case .games:
            return APISportsMatchAPI.games.path
        }
    }

    var queryItems: [NetworkQueryItem] {
        switch self {
        case .games(let date, let timezone):
            return [
                NetworkQueryItem(name: "date", value: date),
                NetworkQueryItem(name: "timezone", value: timezone)
            ]
        }
    }
}
