//
//  APISportsMediaEndpoint.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/31.
//

import Foundation

// MARK: - APISportsMediaResource

nonisolated enum APISportsMediaResource: String, Codable, CaseIterable, Equatable, Hashable, Sendable {

    case players
    case teams
    case leagues
    case countries

    var pathComponent: String {
        rawValue
    }
}

// MARK: - APISportsMediaEndpoint

nonisolated enum APISportsMediaEndpoint: Equatable, Sendable {

    case image(product: APISportsProduct, resource: APISportsMediaResource, id: Int)
    case player(product: APISportsProduct, id: Int)
    case footballPlayer(id: Int)

    var url: URL? {
        guard let baseURL = APISportsBaseURL.media.url else {
            return nil
        }

        switch self {
        case .image(let product, let resource, let id):
            return makeImageURL(
                baseURL: baseURL,
                product: product,
                resource: resource,
                id: id
            )

        case .player(let product, let id):
            return APISportsMediaEndpoint
                .image(product: product, resource: .players, id: id)
                .url

        case .footballPlayer(let id):
            return APISportsMediaEndpoint
                .player(product: .soccer, id: id)
                .url
        }
    }

    private func makeImageURL(
        baseURL: URL,
        product: APISportsProduct,
        resource: APISportsMediaResource,
        id: Int
    ) -> URL {
        baseURL
            .appending(path: product.apiHostComponent)
            .appending(path: resource.pathComponent)
            .appending(path: "\(id).png")
    }
}
