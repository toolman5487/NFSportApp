//
//  MainSoccerSearchEndpoint.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/26.
//

import Foundation

// MARK: - MainSoccerSearchEndpoint

nonisolated enum MainSoccerSearchEndpoint: Equatable, Sendable {

    case teams(searchText: String)

    var path: String {
        switch self {
        case .teams:
            return APISportsAPIResource.teams.path
        }
    }

    var queryItems: [NetworkQueryItem] {
        switch self {
        case .teams(let searchText):
            return [
                NetworkQueryItem(name: "search", value: searchText)
            ]
        }
    }
}
