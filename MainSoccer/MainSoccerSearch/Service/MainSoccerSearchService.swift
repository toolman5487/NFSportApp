//
//  MainSoccerSearchService.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/26.
//

import Foundation

// MARK: - MainSoccerSearchServicing

nonisolated protocol MainSoccerSearchServicing: Sendable {

    func searchTeams(
        matching searchText: String
    ) async throws -> [MainSoccerSearchTeam]
}

// MARK: - MainSoccerSearchService

nonisolated struct MainSoccerSearchService: MainSoccerSearchServicing {

    private let networkClient: NetworkServicing

    init(networkClient: NetworkServicing) {
        self.networkClient = networkClient
    }

    func searchTeams(
        matching searchText: String
    ) async throws -> [MainSoccerSearchTeam] {
        let endpoint = MainSoccerSearchEndpoint.teams(searchText: searchText)
        let response = try await networkClient.get(
            endpoint.path,
            queryItems: endpoint.queryItems,
            headers: [:],
            as: APISoccerSearchResponse<[APISoccerSearchTeamResponse]>.self
        )

        return response.response.compactMap(\.mainSoccerSearchTeam)
    }
}

// MARK: - API Soccer Search Response

private nonisolated struct APISoccerSearchResponse<Response: Decodable & Sendable>: Decodable, Sendable {

    let response: Response
}

// MARK: - API Soccer Team Response

private nonisolated struct APISoccerSearchTeamResponse: Decodable, Sendable {

    let team: APISoccerSearchTeamDetailResponse?
    let venue: APISoccerSearchVenueResponse?

    var mainSoccerSearchTeam: MainSoccerSearchTeam? {
        guard let id = team?.id,
              let name = team?.name,
              !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        return MainSoccerSearchTeam(
            id: id,
            name: name,
            code: team?.code,
            countryName: team?.country,
            city: venue?.city,
            venueName: venue?.name,
            logoURL: team?.logo.flatMap(URL.init(string:))
        )
    }
}

private nonisolated struct APISoccerSearchTeamDetailResponse: Decodable, Sendable {

    let id: Int?
    let name: String?
    let code: String?
    let country: String?
    let logo: String?
}

private nonisolated struct APISoccerSearchVenueResponse: Decodable, Sendable {

    let name: String?
    let city: String?
}
