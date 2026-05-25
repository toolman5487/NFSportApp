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

    private enum SportRootFlow {
        case standard
        case soccer

        init(sportID: String) {
            switch sportID {
            case "soccer":
                self = .soccer

            default:
                self = .standard
            }
        }
    }

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
        switch SportRootFlow(sportID: selectedSport.id) {
        case .standard:
            return makeStandardRootViewController(
                for: tab,
                onSportSelectionRequested: onSportSelectionRequested
            )

        case .soccer:
            return makeSoccerRootViewController(
                for: tab,
                onSportSelectionRequested: onSportSelectionRequested
            )
        }
    }

    private func makeStandardRootViewController(
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

    private func makeSoccerRootViewController(
        for tab: AppTab,
        onSportSelectionRequested: (() -> Void)?
    ) -> UIViewController {
        switch tab {
        case .home:
            let homeService = MainSoccerHomeService(networkClient: sportScopedNetworkClient)
            let homeViewModel = MainSoccerHomeViewModel(
                selectedSport: selectedSport,
                homeService: homeService
            )
            let homeViewController = MainSoccerHomeViewController(viewModel: homeViewModel)
            homeViewController.onSportSelectionRequested = onSportSelectionRequested
            return homeViewController

        case .matches:
            let matchesService = MainSoccerMatchesService(networkClient: sportScopedNetworkClient)
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
