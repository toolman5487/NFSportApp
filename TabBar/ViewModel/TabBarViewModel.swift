//
//  TabBarViewModel.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/22.
//

import Foundation

// MARK: - State

enum TabBarViewState: Sendable {

    case idle(selectedTab: AppTab)
    case loading(selectedTab: AppTab)
    case loaded(selectedTab: AppTab, badges: [AppTab: Int])
    case failed(selectedTab: AppTab, message: String)
}

// MARK: - Badge Service

protocol TabBarBadgeServicing: Sendable {

    func fetchBadges() async throws -> [AppTab: Int]
}

struct MockTabBarBadgeService: TabBarBadgeServicing {

    func fetchBadges() async throws -> [AppTab: Int] {
        [:]
    }
}

// MARK: - TabBarViewModel

@MainActor
final class TabBarViewModel {

    // MARK: - Properties

    private(set) var state: TabBarViewState = .idle(selectedTab: .home) {
        didSet {
            onStateChange?(state)
        }
    }

    var onStateChange: ((TabBarViewState) -> Void)?

    private let badgeService: TabBarBadgeServicing

    // MARK: - Initialization

    init(badgeService: TabBarBadgeServicing) {
        self.badgeService = badgeService
    }

    // MARK: - Public Methods

    func loadInitialState() async {
        state = .loading(selectedTab: currentSelectedTab)

        do {
            let badges = try await badgeService.fetchBadges()
            state = .loaded(selectedTab: currentSelectedTab, badges: badges)
        } catch {
            state = .failed(selectedTab: currentSelectedTab, message: error.localizedDescription)
            AppLogger.logUIError(
                error,
                message: "TabBar loading failed",
                metadata: "tab=\(currentSelectedTab.title)"
            )
        }
    }

    func selectTab(_ tab: AppTab) {
        switch state {
        case .idle:
            state = .idle(selectedTab: tab)
        case .loading:
            state = .loading(selectedTab: tab)
        case .loaded(_, let badges):
            state = .loaded(selectedTab: tab, badges: badges)
        case .failed(_, let message):
            state = .failed(selectedTab: tab, message: message)
        }
    }

    func makeItemViewData() -> [TabBarItemViewData] {
        let selectedTab = currentSelectedTab
        let badges = currentBadges

        return AppTab.allCases.map { tab in
            TabBarItemViewData(
                tab: tab,
                title: tab.title,
                systemImageName: tab.systemImageName,
                badgeCount: badges[tab, default: 0],
                isSelected: selectedTab == tab
            )
        }
    }

    // MARK: - Private Properties

    private var currentSelectedTab: AppTab {
        switch state {
        case .idle(let selectedTab),
             .loading(let selectedTab),
             .loaded(let selectedTab, _),
             .failed(let selectedTab, _):
            return selectedTab
        }
    }

    private var currentBadges: [AppTab: Int] {
        switch state {
        case .loaded(_, let badges):
            return badges
        default:
            return [:]
        }
    }
}
