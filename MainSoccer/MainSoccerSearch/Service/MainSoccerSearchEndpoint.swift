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
        apiEndpoint.path
    }

    var queryItems: [NetworkQueryItem] {
        apiEndpoint.queryItems
    }

    private var apiEndpoint: APISportsEndpoint {
        switch self {
        case .teams(let searchText):
            return APISportsEndpoint(
                resource: .teams,
                queryItems: [
                    NetworkQueryItem(parameter: .search, value: searchText)
                ]
            )
        }
    }
}
