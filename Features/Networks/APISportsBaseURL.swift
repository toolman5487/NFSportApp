//
//  APISportsBaseURL.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/31.
//

import Foundation

// MARK: - APISportsBaseURL

nonisolated enum APISportsBaseURL: String, Codable, Equatable, Hashable, Sendable {

    case americanFootball = "v1.american-football.api-sports.io"
    case soccer = "v3.football.api-sports.io"
    case basketball = "v1.basketball.api-sports.io"
    case baseball = "v1.baseball.api-sports.io"
    case hockey = "v1.hockey.api-sports.io"
    case volleyball = "v1.volleyball.api-sports.io"
    case handball = "v1.handball.api-sports.io"
    case rugby = "v1.rugby.api-sports.io"
    case media = "media.api-sports.io"

    var host: String {
        rawValue
    }

    var url: URL? {
        URL(string: "https://\(host)")
    }
}
