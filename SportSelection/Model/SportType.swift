//
//  SportType.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/23.
//

import Foundation

nonisolated struct SportType: Codable, Equatable, Hashable, Sendable {

    let sport: APISportsProduct

    var id: String {
        sport.id
    }

    var title: String {
        sport.title
    }

    var subtitle: String {
        sport.subtitle
    }

    var systemImageName: String {
        sport.systemImageName
    }

    var apiBaseURL: APISportsBaseURL {
        sport.apiBaseURL
    }
}

// MARK: - API

extension SportType {

    nonisolated var apiURL: URL? {
        apiBaseURL.url
    }
}

// MARK: - Local Catalog

extension SportType {

    nonisolated static let localCatalog: [SportType] = [
        SportType(sport: .americanFootball),
        SportType(sport: .soccer),
        SportType(sport: .basketball),
        SportType(sport: .baseball),
        SportType(sport: .hockey),
        SportType(sport: .volleyball),
        SportType(sport: .handball),
        SportType(sport: .rugby)
    ]
}
