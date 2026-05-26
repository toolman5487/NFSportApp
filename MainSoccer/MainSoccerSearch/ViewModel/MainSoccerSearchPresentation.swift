//
//  MainSoccerSearchPresentation.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/26.
//

import Foundation

nonisolated struct MainSoccerSearchPresentation: Equatable, Sendable {

    let query: String
    let teams: [MainSoccerSearchTeamViewData]
}

nonisolated struct MainSoccerSearchTeamViewData: Equatable, Sendable {

    let id: Int
    let name: String
    let subtitle: String
    let logoURL: URL?
    let fallbackSystemImageName: String
}
