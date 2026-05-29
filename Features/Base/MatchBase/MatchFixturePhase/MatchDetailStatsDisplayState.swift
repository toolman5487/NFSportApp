//
//  MatchDetailStatsDisplayState.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/29.
//

import Foundation

// MARK: - MatchDetailStatsDisplayState

nonisolated enum MatchDetailStatsDisplayState: Equatable, Sendable {

    case content
    case empty(title: String, subtitle: String)
}
