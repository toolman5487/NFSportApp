//
//  SceneDelegate.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/21.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.overrideUserInterfaceStyle = .dark
        let rootViewController = makeSportSelectionViewController()
        window.rootViewController = rootViewController
        window.makeKeyAndVisible()
        self.window = window
    }

    func sceneDidDisconnect(_ scene: UIScene) {}

    func sceneDidBecomeActive(_ scene: UIScene) {}

    func sceneWillResignActive(_ scene: UIScene) {}

    func sceneWillEnterForeground(_ scene: UIScene) {}

    func sceneDidEnterBackground(_ scene: UIScene) {}
}

// MARK: - Factory

private extension SceneDelegate {

    func makeSportSelectionViewController() -> UIViewController {
        let viewModel = SportSelectionViewModel(
            sportCatalogService: LocalSportCatalogService()
        )
        let viewController = SportSelectionViewController(viewModel: viewModel)

        viewController.onSportSelected = { [weak self] sport in
            self?.showTabBar(for: sport)
        }

        return makeNavigationController(rootViewController: viewController)
    }

    func showTabBar(for sport: SportType) {
        let viewModel = TabBarViewModel(
            selectedSport: sport,
            badgeService: MockTabBarBadgeService()
        )
        let viewController = TabBarContainerViewController(viewModel: viewModel)
        viewController.onSportSelectionRequested = { [weak self] in
            self?.showSportSelection()
        }

        window?.rootViewController = viewController
    }

    func showSportSelection() {
        window?.rootViewController = makeSportSelectionViewController()
    }

    func makeNavigationController(rootViewController: UIViewController) -> UINavigationController {
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
}
