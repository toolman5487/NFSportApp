//
//  MainSearchTeam.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/26.
//

import Foundation

nonisolated struct MainSearchTeam: Equatable, Sendable {

    let id: Int
    let name: String
    let code: String?
    let city: String?
    let countryName: String?
    let logoURL: URL?
}
