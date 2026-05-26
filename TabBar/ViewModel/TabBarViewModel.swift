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

extension TabBarViewState {
    var selectedTab: AppTab {
        switch self {
        case .idle(let selectedTab),
                .loading(let selectedTab),
                .loaded(let selectedTab, _),
                .failed(let selectedTab, _):
            return selectedTab
        }
    }
    
    var badges: [AppTab: Int] {
        switch self {
        case .loaded(_, let badges):
            return badges
        default:
            return [:]
        }
    }
    
    func updatingSelectedTab(_ selectedTab: AppTab) -> TabBarViewState {
        switch self {
        case .idle:
            return .idle(selectedTab: selectedTab)
        case .loading:
            return .loading(selectedTab: selectedTab)
        case .loaded(_, let badges):
            return .loaded(selectedTab: selectedTab, badges: badges)
        case .failed(_, let message):
            return .failed(selectedTab: selectedTab, message: message)
        }
    }
}

// MARK: - Presentation

struct TabBarPresentation: Sendable {
    let selectedTab: AppTab
    let badges: [AppTab: Int]
}

// MARK: - Page Transition

enum TabBarPageTransitionDirection: Sendable {
    case forward
    case reverse
}

struct TabBarPageTransition: Sendable {
    let targetTab: AppTab
    let direction: TabBarPageTransitionDirection
    let isAnimated: Bool
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
    
    private(set) var state: TabBarViewState {
        didSet {
            onStateChange?(state)
        }
    }
    
    var onStateChange: ((TabBarViewState) -> Void)?

    let tabs: [AppTab]

    private let badgeService: TabBarBadgeServicing
    private var currentDisplayedTab: AppTab?
    private var pendingTabSelection: AppTab?
    private var isGestureTransitionInProgress = false
    private var isProgrammaticTransitionInProgress = false
    
    var presentation: TabBarPresentation {
        TabBarPresentation(
            selectedTab: state.selectedTab,
            badges: state.badges
        )
    }

    // MARK: - Initialization

    init(
        tabs: [AppTab],
        initialSelectedTab: AppTab,
        badgeService: TabBarBadgeServicing
    ) {
        self.tabs = tabs
        self.state = .idle(selectedTab: initialSelectedTab)
        self.badgeService = badgeService
    }
    
    // MARK: - Public Methods
    
    func loadInitialState() async {
        state = .loading(selectedTab: state.selectedTab)
        
        do {
            let badges = try await badgeService.fetchBadges()
            state = .loaded(selectedTab: state.selectedTab, badges: badges)
        } catch {
            state = .failed(selectedTab: state.selectedTab, message: error.localizedDescription)
            AppLogger.logUIError(
                error,
                message: "TabBar loading failed",
                metadata: "tab=\(state.selectedTab.title)"
            )
        }
    }
    
    func handleTabSelection(_ tab: AppTab) {
        guard !isPageTransitionInProgress else {
            pendingTabSelection = tab
            return
        }
        
        updateSelectedTabIfNeeded(tab)
    }
    
    func makePageTransition() -> TabBarPageTransition? {
        let selectedTab = state.selectedTab
        
        guard currentDisplayedTab != selectedTab else {
            if pendingTabSelection == selectedTab {
                pendingTabSelection = nil
            }
            return nil
        }
        
        guard !isPageTransitionInProgress else {
            pendingTabSelection = selectedTab
            return nil
        }
        
        let transition = TabBarPageTransition(
            targetTab: selectedTab,
            direction: makePageTransitionDirection(to: selectedTab),
            isAnimated: shouldAnimatePageTransition(to: selectedTab)
        )
        
        isProgrammaticTransitionInProgress = transition.isAnimated
        
        if !transition.isAnimated {
            currentDisplayedTab = transition.targetTab
        }
        
        return transition
    }
    
    func handleProgrammaticTransitionCompletion(visibleTab: AppTab?) {
        isProgrammaticTransitionInProgress = false
        syncDisplayedTab(with: visibleTab)
        applyPendingTabSelectionIfNeeded()
    }
    
    func handleGestureTransitionWillStart() {
        isGestureTransitionInProgress = true
    }
    
    func handleGestureTransitionCompletion(visibleTab: AppTab?, didComplete: Bool) {
        isGestureTransitionInProgress = false
        syncDisplayedTab(with: visibleTab)
        
        guard didComplete, let visibleTab else {
            applyPendingTabSelectionIfNeeded()
            return
        }
        
        updateSelectedTabIfNeeded(visibleTab)
        applyPendingTabSelectionIfNeeded()
    }
    
    // MARK: - Private Methods
    
    private func updateSelectedTabIfNeeded(_ tab: AppTab) {
        guard state.selectedTab != tab else {
            return
        }
        
        state = state.updatingSelectedTab(tab)
    }
    
    private func makePageTransitionDirection(to tab: AppTab) -> TabBarPageTransitionDirection {
        guard let currentDisplayedTab,
              let currentIndex = tabs.firstIndex(of: currentDisplayedTab),
              let targetIndex = tabs.firstIndex(of: tab) else {
            return .forward
        }
        
        switch targetIndex >= currentIndex {
        case true:
            return .forward
        case false:
            return .reverse
        }
    }
    
    private func shouldAnimatePageTransition(to tab: AppTab) -> Bool {
        guard let currentDisplayedTab,
              let currentIndex = tabs.firstIndex(of: currentDisplayedTab),
              let targetIndex = tabs.firstIndex(of: tab) else {
            return false
        }
        
        let tabDistance = abs(targetIndex - currentIndex)
        return tabDistance == 1
    }
    
    private func syncDisplayedTab(with visibleTab: AppTab?) {
        guard let visibleTab else {
            return
        }
        
        currentDisplayedTab = visibleTab
    }
    
    private func applyPendingTabSelectionIfNeeded() {
        guard !isPageTransitionInProgress else {
            return
        }
        
        guard let pendingTabSelection else {
            return
        }
        
        self.pendingTabSelection = nil
        
        guard pendingTabSelection != currentDisplayedTab else {
            return
        }
        
        updateSelectedTabIfNeeded(pendingTabSelection)
    }
    
    // MARK: - Private Properties
    
    private var isPageTransitionInProgress: Bool {
        isGestureTransitionInProgress || isProgrammaticTransitionInProgress
    }
}
