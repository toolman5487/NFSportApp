//
//  SportCatalogService.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/23.
//

import Foundation

nonisolated protocol SportCatalogServicing: Sendable {

    func fetchSports() async throws -> [SportType]
}

nonisolated struct LocalSportCatalogService: SportCatalogServicing {

    func fetchSports() async throws -> [SportType] {
        SportType.localCatalog
    }
}
