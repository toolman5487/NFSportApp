//
//  TabBarChildViewControllerFactory.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/25.
//

import UIKit

// MARK: - Root View Controller

@MainActor
protocol TabBarRootViewController: UIViewController, TabBarItemConfigurable, TabBarSelectionHandling {}

// MARK: - Configuration

struct TabBarConfiguration {
    let tabs: [AppTab]
    let initialSelectedTab: AppTab
    let navigationControllersByTab: [AppTab: UINavigationController]
}

@MainActor
protocol TabBarConfigurationBuilding {
    func makeTabBarConfiguration(
        onSportSelectionRequested: (() -> Void)?
    ) -> TabBarConfiguration
}

// MARK: - Main Sport

@MainActor
struct MainSportTabBarConfigurationBuilder: TabBarConfigurationBuilding {

    private let selectedSport: SportType
    private let sportScopedNetworkClient: NetworkServicing

    init(
        selectedSport: SportType,
        sportScopedNetworkClient: NetworkServicing
    ) {
        self.selectedSport = selectedSport
        self.sportScopedNetworkClient = sportScopedNetworkClient
    }

    func makeTabBarConfiguration(
        onSportSelectionRequested: (() -> Void)?
    ) -> TabBarConfiguration {
        let tabs = MainSportTab.allCases.map(AppTab.mainSport)
        let navigationControllersByTab = Dictionary(uniqueKeysWithValues: tabs.map { tab in
            (
                tab,
                makeNavigationController(
                    rootViewController: makeRootViewController(
                        for: tab,
                        onSportSelectionRequested: onSportSelectionRequested
                    )
                )
            )
        })

        return TabBarConfiguration(
            tabs: tabs,
            initialSelectedTab: tabs[0],
            navigationControllersByTab: navigationControllersByTab
        )
    }

    private func makeRootViewController(
        for tab: AppTab,
        onSportSelectionRequested: (() -> Void)?
    ) -> TabBarRootViewController {
        guard case .mainSport(let mainSportTab) = tab else {
            fatalError("Unexpected non-main-sport tab in MainSportTabBarConfigurationBuilder")
        }

        let makeMatchDetailViewController: ((Int) -> UIViewController) = { gameID in
            switch selectedSport.id {
            case "basketball":
                let detailService = BasketballMatchDetailService(networkClient: sportScopedNetworkClient)
                let detailViewModel = BasketballMatchDetailViewModel(
                    gameID: gameID,
                    detailService: detailService
                )
                return BasketballMatchDetailViewController(viewModel: detailViewModel)

            case "baseball":
                let detailService = BaseballMatchDetailService(networkClient: sportScopedNetworkClient)
                let detailViewModel = BaseballMatchDetailViewModel(
                    gameID: gameID,
                    detailService: detailService
                )
                return BaseballMatchDetailViewController(viewModel: detailViewModel)

            case "football", "hockey", "volleyball", "handball", "rugby":
                return PlaceholderViewController(
                    title: "\(selectedSport.title) Match Detail",
                    tabBarItemConfiguration: TabBarItemConfiguration(
                        title: selectedSport.title,
                        systemImageName: selectedSport.systemImageName
                    )
                )

            default:
                return PlaceholderViewController(
                    title: "\(selectedSport.title) Match Detail",
                    tabBarItemConfiguration: TabBarItemConfiguration(
                        title: selectedSport.title,
                        systemImageName: selectedSport.systemImageName
                    )
                )
            }
        }

        switch mainSportTab {
        case .home:
            let homeService = MainHomeService(networkClient: sportScopedNetworkClient)
            let homeViewModel = MainHomeViewModel(
                selectedSport: selectedSport,
                homeService: homeService
            )
            let homeViewController = MainHomeViewController(viewModel: homeViewModel)
            homeViewController.onSportSelectionRequested = onSportSelectionRequested
            homeViewController.makeMatchDetailViewController = makeMatchDetailViewController
            return homeViewController

        case .matches:
            let matchesService = MainMatchesService(networkClient: sportScopedNetworkClient)
            let matchesViewModel = MainMatchesViewModel(
                selectedSport: selectedSport,
                scheduleService: matchesService
            )
            let matchesViewController = MainMatchesViewController(viewModel: matchesViewModel)
            matchesViewController.onSportSelectionRequested = onSportSelectionRequested
            matchesViewController.makeMatchDetailViewController = makeMatchDetailViewController
            return matchesViewController

        case .search:
            let searchService = MainSearchService(networkClient: sportScopedNetworkClient)
            let searchViewModel = MainSearchViewModel(
                selectedSport: selectedSport,
                searchService: searchService
            )
            let searchViewController = MainSearchViewController(viewModel: searchViewModel)
            searchViewController.onSportSelectionRequested = onSportSelectionRequested
            return searchViewController
        }
    }
}

// MARK: - Main Soccer

@MainActor
struct MainSoccerTabBarConfigurationBuilder: TabBarConfigurationBuilding {

    private let selectedSport: SportType
    private let sportScopedNetworkClient: NetworkServicing

    init(
        selectedSport: SportType,
        sportScopedNetworkClient: NetworkServicing
    ) {
        self.selectedSport = selectedSport
        self.sportScopedNetworkClient = sportScopedNetworkClient
    }

    func makeTabBarConfiguration(
        onSportSelectionRequested: (() -> Void)?
    ) -> TabBarConfiguration {
        let tabs = MainSoccerTab.allCases.map(AppTab.mainSoccer)
        let navigationControllersByTab = Dictionary(uniqueKeysWithValues: tabs.map { tab in
            (
                tab,
                makeNavigationController(
                    rootViewController: makeRootViewController(
                        for: tab,
                        onSportSelectionRequested: onSportSelectionRequested
                    )
                )
            )
        })

        return TabBarConfiguration(
            tabs: tabs,
            initialSelectedTab: tabs[0],
            navigationControllersByTab: navigationControllersByTab
        )
    }

    private func makeRootViewController(
        for tab: AppTab,
        onSportSelectionRequested: (() -> Void)?
    ) -> TabBarRootViewController {
        guard case .mainSoccer(let mainSoccerTab) = tab else {
            fatalError("Unexpected non-soccer tab in MainSoccerTabBarConfigurationBuilder")
        }

        let makeMatchDetailViewController: (Int) -> UIViewController = { fixtureID in
            let detailService = SoccerMatchDetailService(networkClient: sportScopedNetworkClient)
            let detailViewModel = SoccerMatchDetailViewModel(
                fixtureID: fixtureID,
                detailService: detailService
            )
            return SoccerMatchDetailViewController(viewModel: detailViewModel)
        }

        switch mainSoccerTab {
        case .home:
            let homeService = MainSoccerHomeService(networkClient: sportScopedNetworkClient)
            let homeViewModel = MainSoccerHomeViewModel(
                selectedSport: selectedSport,
                homeService: homeService
            )
            let homeViewController = MainSoccerHomeViewController(viewModel: homeViewModel)
            homeViewController.onSportSelectionRequested = onSportSelectionRequested
            homeViewController.makeMatchDetailViewController = makeMatchDetailViewController
            return homeViewController

        case .matches:
            let matchesService = MainSoccerMatchesService(networkClient: sportScopedNetworkClient)
            let matchesViewModel = MainSoccerMatchesViewModel(
                selectedSport: selectedSport,
                scheduleService: matchesService
            )
            let matchesViewController = MainSoccerMatchesViewController(viewModel: matchesViewModel)
            matchesViewController.onSportSelectionRequested = onSportSelectionRequested
            matchesViewController.makeMatchDetailViewController = makeMatchDetailViewController
            return matchesViewController

        case .search:
            let searchService = MainSoccerSearchService(networkClient: sportScopedNetworkClient)
            let searchViewModel = MainSoccerSearchViewModel(
                selectedSport: selectedSport,
                searchService: searchService
            )
            let searchViewController = MainSoccerSearchViewController(viewModel: searchViewModel)
            searchViewController.onSportSelectionRequested = onSportSelectionRequested
            return searchViewController
        }
    }
}

// MARK: - Navigation Controller

private func makeNavigationController(
    rootViewController: UIViewController
) -> UINavigationController {
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
