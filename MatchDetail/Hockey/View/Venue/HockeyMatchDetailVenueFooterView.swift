//
//  HockeyMatchDetailVenueFooterView.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/28.
//

import UIKit

// MARK: - HockeyMatchDetailVenueFooterView

final class HockeyMatchDetailVenueFooterView: MatchBaseVenueFooterView {

    static let reuseIdentifier = "HockeyMatchDetailVenueFooterView"

    func configure(with viewData: HockeyMatchDetailVenueViewData) {
        configureVenueText(viewData.venueText)
    }
}

