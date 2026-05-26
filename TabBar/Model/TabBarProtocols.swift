//
//  TabBarProtocols.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/26.
//

import UIKit

struct TabBarItemConfiguration: Sendable {
    let title: String
    let systemImageName: String
}

@MainActor
protocol TabBarItemConfigurable: AnyObject {
    var tabBarItemConfiguration: TabBarItemConfiguration { get }
}

@MainActor
protocol TabBarSelectionHandling: AnyObject {
    func shouldSelectTab() -> Bool
    func didSelectTab()
}

extension TabBarSelectionHandling {
    func shouldSelectTab() -> Bool {
        true
    }

    func didSelectTab() {}
}

@MainActor
protocol TabBarContentScrollable: AnyObject {
    var isScrolledAwayFromTop: Bool { get }
    func scrollToTop(animated: Bool)
}

@MainActor
protocol TabBarRootReselectHandling: AnyObject {
    func handleRootTabReselection() async
    func refreshOnTabReselection() async
}

extension TabBarRootReselectHandling where Self: TabBarContentScrollable {

    func handleRootTabReselection() async {
        let shouldAnimateScroll = isScrolledAwayFromTop
        scrollToTop(animated: shouldAnimateScroll)

        if shouldAnimateScroll {
            try? await Task.sleep(nanoseconds: 250_000_000)
        }

        await refreshOnTabReselection()
    }

    func refreshOnTabReselection() async {}
}
