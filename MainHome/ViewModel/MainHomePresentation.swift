//
//  MainHomePresentation.swift
//  NFSportApp
//
//  Created by Willy Hsu 2026/5/23.
//

import Foundation

nonisolated struct MainHomePresentation: Equatable, Sendable {

    let title: String
    let sections: [MainHomeSectionViewData]
}

nonisolated struct MainHomeSectionViewData: Equatable, Sendable {

    let title: String
    let items: [MainHomeGameViewData]
}

nonisolated struct MainHomeGameViewData: Equatable, Identifiable, Sendable {

    let id: Int
    let awayTeamName: String
    let homeTeamName: String
    let awayScoreText: String
    let homeScoreText: String
    let scheduledStartText: String
    let statusText: String
    let statusStyle: MainHomeGameStatusStyle
}

nonisolated enum MainHomeGameStatusStyle: Equatable, Sendable {

    case live
    case final
    case upcoming
    case neutral
}
