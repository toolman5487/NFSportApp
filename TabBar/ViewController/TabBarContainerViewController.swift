//
//  TabBarContainerViewController.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/22.
//

import SnapKit
import UIKit

final class TabBarContainerViewController: UIViewController {

    // MARK: - Properties

    private let viewModel: TabBarViewModel

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

    private lazy var childViewControllersByTab: [AppTab: UINavigationController] = {
        Dictionary(uniqueKeysWithValues: AppTab.allCases.map { tab in
            (tab, makeNavigationController(for: tab))
        })
    }()

    private var currentChildViewController: UIViewController?

    // MARK: - Initialization

    init(viewModel: TabBarViewModel) {
        self.viewModel = viewModel
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

        viewModel.selectTab(.home)

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

        contentContainerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(tabBarView.snp.top)
        }

        tabBarView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-48)
        }

        tabBarView.onTabSelected = { [weak self] tab in
            self?.viewModel.selectTab(tab)
        }
    }

    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }

        render(viewModel.state)
    }

    // MARK: - Rendering

    private func render(_ state: TabBarViewState) {
        tabBarView.render(items: viewModel.makeItemViewData())

        switch state {
        case .idle(let selectedTab):
            displayContent(for: selectedTab)
        case .loading(let selectedTab):
            displayContent(for: selectedTab)
        case .loaded(let selectedTab, _):
            displayContent(for: selectedTab)
        case .failed(let selectedTab, _):
            displayContent(for: selectedTab)
        }
    }

    private func displayContent(for tab: AppTab) {
        guard let nextViewController = childViewControllersByTab[tab] else {
            return
        }

        guard currentChildViewController !== nextViewController else {
            return
        }

        currentChildViewController?.willMove(toParent: nil)
        currentChildViewController?.view.removeFromSuperview()
        currentChildViewController?.removeFromParent()

        addChild(nextViewController)
        contentContainerView.addSubview(nextViewController.view)

        nextViewController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        nextViewController.didMove(toParent: self)
        currentChildViewController = nextViewController
    }

    // MARK: - Navigation

    private func makeNavigationController(for tab: AppTab) -> UINavigationController {
        let rootViewController = makeRootViewController(for: tab)
        rootViewController.navigationItem.largeTitleDisplayMode = .always

        let navigationController = UINavigationController(rootViewController: rootViewController)
        navigationController.navigationBar.prefersLargeTitles = true
        navigationController.navigationBar.tintColor = .primaryLabel

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
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
            return MainHomeViewController()
        case .matches, .leagues, .favorites:
            return PlaceholderViewController(title: tab.title)
        }
    }
}
