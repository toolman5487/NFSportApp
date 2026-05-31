//
//  SportSessionStore.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/23.
//

import Foundation

nonisolated enum SportSessionError: Error, Equatable, LocalizedError, Sendable {

    case missingSelectedSport
    case invalidBaseURL(APISportsBaseURL)

    var errorDescription: String? {
        switch self {
        case .missingSelectedSport:
            return "No sport is currently selected."
        case .invalidBaseURL(let baseURL):
            return "Sport API host is invalid: \(baseURL.host)"
        }
    }
}

nonisolated protocol SportSessionStoring: Sendable {

    func selectSport(_ sport: SportType) async
    func clearSelectedSport() async
    func selectedSport() async -> SportType?
    func selectedBaseURL() async throws -> URL
}

actor SportSessionStore: SportSessionStoring {

    // MARK: - State

    private var currentSport: SportType?

    // MARK: - Public Methods

    func selectSport(_ sport: SportType) async {
        currentSport = sport
    }

    func clearSelectedSport() async {
        currentSport = nil
    }

    func selectedSport() async -> SportType? {
        currentSport
    }

    func selectedBaseURL() async throws -> URL {
        guard let currentSport else {
            throw SportSessionError.missingSelectedSport
        }

        guard let baseURL = currentSport.apiURL else {
            throw SportSessionError.invalidBaseURL(currentSport.apiBaseURL)
        }

        return baseURL
    }
}
