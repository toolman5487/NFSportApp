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
    private let sportScopedNetworkClient: NetworkServicing

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
        Dictionary(uniqueKeysWithValues: AppTab.allCases.map { tab in
            (tab, makeNavigationController(for: tab))
        })
    }()

    private lazy var tabByViewControllerIdentifier: [ObjectIdentifier: AppTab] = {
        Dictionary(uniqueKeysWithValues: childViewControllersByTab.map { tab, viewController in
            (ObjectIdentifier(viewController), tab)
        })
    }()

    // MARK: - Callbacks

    var onSportSelectionRequested: (() -> Void)?

    // MARK: - Initialization

    init(
        viewModel: TabBarViewModel,
        sportScopedNetworkClient: NetworkServicing
    ) {
        self.viewModel = viewModel
        self.sportScopedNetworkClient = sportScopedNetworkClient
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

        tabBarView.onTabSelected = { [weak self] tab in
            self?.viewModel.handleTabSelection(tab)
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
        tabBarView.render(items: presentation.items)
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
        }
    }

    // MARK: - Navigation

    private func makeNavigationController(for tab: AppTab) -> UINavigationController {
        let rootViewController = makeRootViewController(for: tab)
        rootViewController.navigationItem.largeTitleDisplayMode = .always

        if let mainBaseViewController = rootViewController as? MainBaseViewController {
            mainBaseViewController.onSportSelectionRequested = { [weak self] in
                self?.onSportSelectionRequested?()
            }
        }

        let navigationController = UINavigationController(rootViewController: rootViewController)
        navigationController.navigationBar.prefersLargeTitles = true
        navigationController.navigationBar.tintColor = .primaryLabel

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.shadowColor = .clear
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.primaryLabel]
        appearance.titleTextAttributes = [.foregroundColor: UIColor.primaryLabel]

        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
        navigationController.navigationBar.compactAppearance = appearance

        return navigationController
    }

    private func makeRootViewController(for tab: AppTab) -> UIViewController {
        switch tab {
        case .home:
            let homeService = MainHomeService(networkClient: sportScopedNetworkClient)
            let homeViewModel = MainHomeViewModel(
                selectedSport: viewModel.selectedSport,
                homeService: homeService
            )
            return MainHomeViewController(viewModel: homeViewModel)
        case .matches, .leagues, .favorites:
            return PlaceholderViewController(title: tab.title)
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
}

// MARK: - UIPageViewControllerDataSource

extension TabBarContainerViewController: UIPageViewControllerDataSource {

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore currentViewController: UIViewController
    ) -> UIViewController? {
        guard let currentTab = tab(for: currentViewController) else {
            return nil
        }

        let previousTab = AppTab(rawValue: currentTab.rawValue - 1)
        return makeViewController(for: previousTab)
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter currentViewController: UIViewController
    ) -> UIViewController? {
        guard let currentTab = tab(for: currentViewController) else {
            return nil
        }

        let nextTab = AppTab(rawValue: currentTab.rawValue + 1)
        return makeViewController(for: nextTab)
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
    }
}
