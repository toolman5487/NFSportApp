//
//  APISportsBaseURL.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/31.
//

import Foundation

// MARK: - APISportsAPIVersion

nonisolated enum APISportsAPIVersion: String, Codable, CaseIterable, Equatable, Hashable, Sendable {

    case v1
    case v2
    case v3
}

// MARK: - APISportsProduct

nonisolated enum APISportsProduct: String, Codable, CaseIterable, Equatable, Hashable, Sendable {

    case americanFootball
    case soccer
    case basketball
    case baseball
    case hockey
    case volleyball
    case handball
    case rugby

    var id: String {
        switch self {
        case .americanFootball:
            return "football"
        case .soccer:
            return "soccer"
        case .basketball:
            return "basketball"
        case .baseball:
            return "baseball"
        case .hockey:
            return "hockey"
        case .volleyball:
            return "volleyball"
        case .handball:
            return "handball"
        case .rugby:
            return "rugby"
        }
    }

    var title: String {
        switch self {
        case .americanFootball:
            return "Football"
        case .soccer:
            return "Soccer"
        case .basketball:
            return "Basketball"
        case .baseball:
            return "Baseball"
        case .hockey:
            return "Hockey"
        case .volleyball:
            return "Volleyball"
        case .handball:
            return "Handball"
        case .rugby:
            return "Rugby"
        }
    }

    var subtitle: String {
        switch self {
        case .soccer:
            return "Fixtures, scores, and leagues"
        default:
            return "Games, schedules, and standings"
        }
    }

    var systemImageName: String {
        switch self {
        case .americanFootball:
            return "football.fill"
        case .soccer:
            return "soccerball.inverse"
        case .basketball:
            return "basketball.fill"
        case .baseball:
            return "baseball.fill"
        case .hockey:
            return "hockey.puck.fill"
        case .volleyball:
            return "volleyball.fill"
        case .handball:
            return "figure.handball"
        case .rugby:
            return "rugbyball.fill"
        }
    }

    var apiVersion: APISportsAPIVersion {
        switch self {
        case .soccer:
            return .v3
        case .americanFootball,
             .basketball,
             .baseball,
             .hockey,
             .volleyball,
             .handball,
             .rugby:
            return .v1
        }
    }

    var apiHostComponent: String {
        switch self {
        case .americanFootball:
            return "american-football"
        case .soccer:
            return "football"
        case .basketball:
            return "basketball"
        case .baseball:
            return "baseball"
        case .hockey:
            return "hockey"
        case .volleyball:
            return "volleyball"
        case .handball:
            return "handball"
        case .rugby:
            return "rugby"
        }
    }

    var apiBaseURL: APISportsBaseURL {
        .api(version: apiVersion, product: self)
    }

    var matchAPI: APISportsMatchAPI {
        switch self {
        case .soccer:
            return .fixtures
        case .americanFootball,
             .basketball,
             .baseball,
             .hockey,
             .volleyball,
             .handball,
             .rugby:
            return .games
        }
    }
}

// MARK: - APISportsBaseURL

nonisolated enum APISportsBaseURL: Codable, Equatable, Hashable, Sendable {

    case api(version: APISportsAPIVersion, product: APISportsProduct)
    case media

    var host: String {
        switch self {
        case .api(let version, let product):
            return "\(version.rawValue).\(product.apiHostComponent).api-sports.io"
        case .media:
            return "media.api-sports.io"
        }
    }

    var url: URL? {
        URL(string: "https://\(host)")
    }
}
