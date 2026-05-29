//
//  MatchFixtureStatusSnapshot.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/29.
//

import Foundation

// MARK: - MatchFixtureStatusSnapshot

nonisolated struct MatchFixtureStatusSnapshot: Equatable, Sendable {

    let statusShort: String?
    let statusLong: String?
    let elapsedMinute: Int?
}

// MARK: - Factory

extension MatchFixtureStatusSnapshot {

    nonisolated static func make(
        statusShort: String?,
        statusLong: String?,
        elapsedMinute: Int? = nil
    ) -> MatchFixtureStatusSnapshot {
        MatchFixtureStatusSnapshot(
            statusShort: statusShort,
            statusLong: statusLong,
            elapsedMinute: elapsedMinute
        )
    }
}
