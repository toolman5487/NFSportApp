//
//  MainSoccerSearchTeam.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/26.
//

import Foundation

nonisolated struct MainSoccerSearchTeam: Equatable, Sendable {

    let id: Int
    let name: String
    let code: String?
    let countryName: String?
    let city: String?
    let venueName: String?
    let logoURL: URL?
}
