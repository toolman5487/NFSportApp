//
//  SceneDelegate.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/21.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    // MARK: - Dependencies

    let sportSessionStore = SportSessionStore()
    lazy var sportScopedNetworkClient: NetworkServicing = SportScopedNetworkClient(
        sportSessionStore: sportSessionStore,
        defaultHeadersProvider: AppConfiguration.apiSportsDefaultHeaders
    )

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
