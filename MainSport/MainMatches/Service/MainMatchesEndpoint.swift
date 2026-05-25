//
//  MainMatchesEndpoint.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/25.
//

import Foundation

// MARK: - MainMatchesEndpoint

nonisolated enum MainMatchesEndpoint: Equatable, Sendable {

    case games(date: String)

    var path: String {
        switch self {
        case .games:
            return "games"
        }
    }

    var queryItems: [NetworkQueryItem] {
        switch self {
        case .games(let date):
            return [
                NetworkQueryItem(name: "date", value: date)
            ]
        }
    }
}
