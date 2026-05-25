//
//  MainSoccerHomePresentation.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/25.
//

import Foundation

// MARK: - MainSoccerHomePresentation

nonisolated struct MainSoccerHomePresentation: Equatable, Sendable {

    let title: String
    let sections: [MainSoccerHomeContentSectionViewData]

    var hasLeagueSections: Bool {
        sections.contains { section in
            switch section {
            case .filter, .filterSkeleton, .leagueSkeleton:
                return false

            case .league:
                return true
            }
        }
    }

    static func loading(title: String) -> MainSoccerHomePresentation {
        MainSoccerHomePresentation(
            title: title,
            sections: [
                .filterSkeleton,
                .leagueSkeleton(MainSoccerHomeLeagueSkeletonViewData(itemCount: 3)),
                .leagueSkeleton(MainSoccerHomeLeagueSkeletonViewData(itemCount: 2))
            ]
        )
    }
}

// MARK: - Content Section

nonisolated enum MainSoccerHomeContentSectionViewData: Equatable, Sendable {

    case filter(MainHomeFilterViewData)
    case league(MainHomeSectionViewData)
    case filterSkeleton
    case leagueSkeleton(MainSoccerHomeLeagueSkeletonViewData)

    var itemCount: Int {
        switch self {
        case .filter, .filterSkeleton:
            return 1

        case .league(let sectionViewData):
            return sectionViewData.items.count

        case .leagueSkeleton(let viewData):
            return viewData.itemCount
        }
    }
}

// MARK: - League Skeleton

nonisolated struct MainSoccerHomeLeagueSkeletonViewData: Equatable, Sendable {

    let itemCount: Int
}
