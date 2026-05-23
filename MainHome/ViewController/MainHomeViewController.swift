//
//  MainHomeViewController.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/22.
//

import UIKit

@MainActor
final class MainHomeViewController: MainBaseViewController {

    // MARK: - Properties

    private let selectedSport: SportType

    // MARK: - Initialization

    init(selectedSport: SportType) {
        self.selectedSport = selectedSport
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupMainNavigation() {
        title = selectedSport.title
    }
}
