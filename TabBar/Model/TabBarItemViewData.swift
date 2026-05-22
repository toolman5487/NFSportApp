//
//  TabBarItemViewData.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/22.
//

import Foundation

struct TabBarItemViewData: Sendable {

    let tab: AppTab
    let title: String
    let systemImageName: String
    let badgeCount: Int
    let isSelected: Bool
}
