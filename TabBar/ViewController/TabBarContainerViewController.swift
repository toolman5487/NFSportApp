//
//  TabBarContainerViewController.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/22.
//

import SnapKit
import UIKit

@MainActor
final class TabBarContainerViewController: UIViewController {

    // MARK: - Dependencies

    private let viewModel: TabBarViewModel
    private let configuration: TabBarConfiguration

    // MARK: - UI Components

    private let contentContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private let tabBarView: TabBarView = {
        let view = TabBarView()
        view.backgroundColor = .clear
        return view
    }()

    private lazy var pageViewController: UIPageViewController = {
        let pageViewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal
        )
        pageViewController.dataSource = self
        pageViewController.delegate = self
        pageViewController.view.backgroundColor = .clear
        return pageViewController
    }()

    // MARK: - Child View Controllers

    private lazy var childViewControllersByTab: [AppTab: UINavigationController] = {
        configuration.navigationControllersByTab
    }()

    private lazy var rootViewControllersByTab: [AppTab: TabBarRootViewController] = {
        Dictionary(uniqueKeysWithValues: childViewControllersByTab.compactMap { tab, navigationController in
            guard let rootViewController = navigationController.viewControllers.first as? TabBarRootViewController else {
                return nil
            }

            return (tab, rootViewController)
        })
    }()

    private lazy var tabByViewControllerIdentifier: [ObjectIdentifier: AppTab] = {
        Dictionary(uniqueKeysWithValues: childViewControllersByTab.map { tab, viewController in
            (ObjectIdentifier(viewController), tab)
        })
    }()

    // MARK: - Initialization

    init(
        viewModel: TabBarViewModel,
        configuration: TabBarConfiguration
    ) {
        self.viewModel = viewModel
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        bindViewModel()

        Task { [weak self] in
            guard let self else {
                return
            }

            await viewModel.loadInitialState()
        }
    }

    // MARK: - Setup

    private func setupView() {
        view.backgroundColor = .backgroundColor

        view.addSubview(contentContainerView)
        view.addSubview(tabBarView)
        setupPageViewController()

        contentContainerView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(tabBarView.snp.top)
        }

        tabBarView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-48)
        }

        tabBarView.onTabSelected = { [weak self] event in
            self?.handleTabSelectionEvent(event)
        }
    }

    private func setupPageViewController() {
        addChild(pageViewController)
        contentContainerView.addSubview(pageViewController.view)

        pageViewController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        pageViewController.didMove(toParent: self)
    }

    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] _ in
            self?.render()
        }

        render()
    }

    // MARK: - Rendering

    private func render() {
        let presentation = viewModel.presentation
        tabBarView.render(items: makeTabBarItems(from: presentation))
        displayContent()
    }

    private func displayContent() {
        guard let transition = viewModel.makePageTransition(),
              let nextViewController = childViewControllersByTab[transition.targetTab] else {
            return
        }

        let navigationDirection = makeNavigationDirection(from: transition.direction)

        guard transition.isAnimated else {
            pageViewController.setViewControllers(
                [nextViewController],
                direction: navigationDirection,
                animated: false
            )
            viewModel.handleProgrammaticTransitionCompletion(visibleTab: transition.targetTab)
            notifyDidSelectTab(transition.targetTab)
            return
        }

        pageViewController.setViewControllers(
            [nextViewController],
            direction: navigationDirection,
            animated: true
        ) { [weak self] _ in
            guard let self else {
                return
            }

            self.viewModel.handleProgrammaticTransitionCompletion(visibleTab: self.visibleTab)
            self.notifyDidSelectTab(self.visibleTab)
        }
    }

    private func makeNavigationDirection(
        from direction: TabBarPageTransitionDirection
    ) -> UIPageViewController.NavigationDirection {
        switch direction {
        case .forward:
            return .forward
        case .reverse:
            return .reverse
        }
    }

    private func tab(for viewController: UIViewController) -> AppTab? {
        tabByViewControllerIdentifier[ObjectIdentifier(viewController)]
    }

    private func makeViewController(for tab: AppTab?) -> UIViewController? {
        guard let tab else {
            return nil
        }

        return childViewControllersByTab[tab]
    }

    private var visibleTab: AppTab? {
        guard let visibleViewController = pageViewController.viewControllers?.first else {
            return nil
        }

        return tab(for: visibleViewController)
    }

    private func handleTabSelectionEvent(_ event: TabBarSelectionEvent) {
        guard shouldSelectTab(event.tab) else {
            return
        }

        switch event.isReselection {
        case true:
            handleTabReselection(for: event.tab)

        case false:
            viewModel.handleTabSelection(event.tab)
        }
    }

    private func handleTabReselection(for tab: AppTab) {
        guard visibleTab == tab,
              let navigationController = childViewControllersByTab[tab] else {
            return
        }

        guard navigationController.viewControllers.count == 1 else {
            navigationController.popToRootViewController(animated: true)
            return
        }

        guard let rootViewController = navigationController.viewControllers.first as? TabBarRootReselectHandling else {
            return
        }

        Task {
            await rootViewController.handleRootTabReselection()
        }
    }

    private func makeTabBarItems(from presentation: TabBarPresentation) -> [TabBarItemViewData] {
        configuration.tabs.compactMap { tab in
            guard let rootViewController = rootViewControllersByTab[tab] else {
                return nil
            }

            let configuration = rootViewController.tabBarItemConfiguration

            return TabBarItemViewData(
                tab: tab,
                title: configuration.title,
                systemImageName: configuration.systemImageName,
                badgeCount: presentation.badges[tab, default: 0],
                isSelected: presentation.selectedTab == tab
            )
        }
    }

    private func shouldSelectTab(_ tab: AppTab) -> Bool {
        rootViewControllersByTab[tab]?.shouldSelectTab() ?? true
    }

    private func notifyDidSelectTab(_ tab: AppTab?) {
        guard let tab,
              let rootViewController = rootViewControllersByTab[tab] else {
            return
        }

        rootViewController.didSelectTab()
    }
}

// MARK: - UIPageViewControllerDataSource

extension TabBarContainerViewController: UIPageViewControllerDataSource {

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore currentViewController: UIViewController
    ) -> UIViewController? {
        guard let currentTab = tab(for: currentViewController),
              let currentIndex = configuration.tabs.firstIndex(of: currentTab),
              currentIndex > 0 else {
            return nil
        }

        return makeViewController(for: configuration.tabs[currentIndex - 1])
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter currentViewController: UIViewController
    ) -> UIViewController? {
        guard let currentTab = tab(for: currentViewController),
              let currentIndex = configuration.tabs.firstIndex(of: currentTab),
              currentIndex < configuration.tabs.count - 1 else {
            return nil
        }

        return makeViewController(for: configuration.tabs[currentIndex + 1])
    }
}

// MARK: - UIPageViewControllerDelegate

extension TabBarContainerViewController: UIPageViewControllerDelegate {

    func pageViewController(
        _ pageViewController: UIPageViewController,
        willTransitionTo pendingViewControllers: [UIViewController]
    ) {
        viewModel.handleGestureTransitionWillStart()
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        viewModel.handleGestureTransitionCompletion(
            visibleTab: visibleTab,
            didComplete: finished && completed
        )

        guard finished && completed else {
            return
        }

        notifyDidSelectTab(visibleTab)
    }
}
