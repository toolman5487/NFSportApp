//
//  TabBarChildViewControllerFactory.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/25.
//

import UIKit

// MARK: - TabBarChildViewControllerFactory

@MainActor
protocol TabBarChildViewControllerFactory {
    func makeNavigationController(
        for tab: AppTab,
        onSportSelectionRequested: (() -> Void)?
    ) -> UINavigationController
}

// MARK: - DefaultTabBarChildViewControllerFactory

@MainActor
struct DefaultTabBarChildViewControllerFactory: TabBarChildViewControllerFactory {

    private let selectedSport: SportType
    private let sportScopedNetworkClient: NetworkServicing

    init(
        selectedSport: SportType,
        sportScopedNetworkClient: NetworkServicing
    ) {
        self.selectedSport = selectedSport
        self.sportScopedNetworkClient = sportScopedNetworkClient
    }

    func makeNavigationController(
        for tab: AppTab,
        onSportSelectionRequested: (() -> Void)?
    ) -> UINavigationController {
        let rootViewController = makeRootViewController(
            for: tab,
            onSportSelectionRequested: onSportSelectionRequested
        )
        rootViewController.navigationItem.largeTitleDisplayMode = .always

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

    private func makeRootViewController(
        for tab: AppTab,
        onSportSelectionRequested: (() -> Void)?
    ) -> UIViewController {
        switch tab {
        case .home:
            let homeService = MainHomeService(networkClient: sportScopedNetworkClient)
            let homeViewModel = MainHomeViewModel(
                selectedSport: selectedSport,
                homeService: homeService
            )
            let homeViewController = MainHomeViewController(viewModel: homeViewModel)
            homeViewController.onSportSelectionRequested = onSportSelectionRequested
            return homeViewController

        case .matches:
            let matchesService = MainMatchesService(networkClient: sportScopedNetworkClient)
            let matchesViewModel = MainMatchesViewModel(
                selectedSport: selectedSport,
                scheduleService: matchesService
            )
            let matchesViewController = MainMatchesViewController(viewModel: matchesViewModel)
            matchesViewController.onSportSelectionRequested = onSportSelectionRequested
            return matchesViewController

        case .favorites:
            return PlaceholderViewController(title: tab.title)
        }
    }
}
