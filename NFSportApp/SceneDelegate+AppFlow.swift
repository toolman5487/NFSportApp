//
//  SceneDelegate+AppFlow.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/26.
//

import UIKit

extension SceneDelegate {

    func makeSportSelectionViewController() -> UIViewController {
        let viewModel = SportSelectionViewModel(
            sportCatalogService: LocalSportCatalogService()
        )
        let viewController = SportSelectionViewController(viewModel: viewModel)

        viewController.onSportSelected = { [weak self] sport in
            self?.selectSport(sport)
        }

        return makeNavigationController(rootViewController: viewController)
    }

    func selectSport(_ sport: SportType) {
        Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            await sportSessionStore.selectSport(sport)
            showTabBar(for: sport)
        }
    }

    func showTabBar(for sport: SportType) {
        let configurationBuilder = makeTabBarConfigurationBuilder(for: sport)
        let configuration = configurationBuilder.makeTabBarConfiguration(
            onSportSelectionRequested: { [weak self] in
                self?.showSportSelection()
            }
        )
        let viewModel = TabBarViewModel(
            tabs: configuration.tabs,
            initialSelectedTab: configuration.initialSelectedTab,
            badgeService: MockTabBarBadgeService()
        )
        let viewController = TabBarContainerViewController(
            viewModel: viewModel,
            configuration: configuration
        )

        window?.rootViewController = viewController
    }

    func makeTabBarConfigurationBuilder(for sport: SportType) -> TabBarConfigurationBuilding {
        switch sport.id {
        case "soccer":
            return MainSoccerTabBarConfigurationBuilder(
                selectedSport: sport,
                sportScopedNetworkClient: sportScopedNetworkClient
            )

        default:
            return MainSportTabBarConfigurationBuilder(
                selectedSport: sport,
                sportScopedNetworkClient: sportScopedNetworkClient
            )
        }
    }

    func showSportSelection() {
        Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            await sportSessionStore.clearSelectedSport()
            window?.rootViewController = makeSportSelectionViewController()
        }
    }

    func makeNavigationController(rootViewController: UIViewController) -> UINavigationController {
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
}
