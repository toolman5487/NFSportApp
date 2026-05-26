//
//  MainSearchService.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/26.
//

import Foundation

// MARK: - MainSearchServicing

nonisolated protocol MainSearchServicing: Sendable {

    func searchTeams(
        matching searchText: String
    ) async throws -> [MainSearchTeam]
}

// MARK: - MainSearchService

nonisolated struct MainSearchService: MainSearchServicing {

    private let networkClient: NetworkServicing

    init(networkClient: NetworkServicing) {
        self.networkClient = networkClient
    }

    func searchTeams(
        matching searchText: String
    ) async throws -> [MainSearchTeam] {
        let endpoint = MainSearchEndpoint.teams(searchText: searchText)
        let response = try await networkClient.get(
            endpoint.path,
            queryItems: endpoint.queryItems,
            headers: [:],
            as: APISportsResponse<[APISportsTeamResponse]>.self
        )

        return response.response.compactMap(\.mainSearchTeam)
    }
}

// MARK: - API-Sports Response

private nonisolated struct APISportsResponse<Response: Decodable & Sendable>: Decodable, Sendable {

    let response: Response
}

// MARK: - API-Sports Team

private nonisolated struct APISportsTeamResponse: Decodable, Sendable {

    let id: Int?
    let name: String?
    let code: String?
    let city: String?
    let country: APISportsTeamCountryResponse?
    let logo: String?

    var mainSearchTeam: MainSearchTeam? {
        guard let id,
              let name,
              !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        return MainSearchTeam(
            id: id,
            name: name,
            code: code,
            city: city,
            countryName: country?.displayName,
            logoURL: logo.flatMap(URL.init(string:))
        )
    }
}

// MARK: - API-Sports Team Country

private nonisolated struct APISportsTeamCountryResponse: Decodable, Sendable {

    let name: String?
    let code: String?

    private enum CodingKeys: String, CodingKey {
        case name
        case code
    }

    init(from decoder: Decoder) throws {
        if let singleValueContainer = try? decoder.singleValueContainer(),
           let countryName = try? singleValueContainer.decode(String.self) {
            self.name = countryName
            self.code = nil
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.code = try container.decodeIfPresent(String.self, forKey: .code)
    }

    var displayName: String? {
        let values = [
            name,
            code
        ].compactMap { value -> String? in
            guard let value,
                  !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return nil
            }

            return value
        }

        return values.first
    }
}
