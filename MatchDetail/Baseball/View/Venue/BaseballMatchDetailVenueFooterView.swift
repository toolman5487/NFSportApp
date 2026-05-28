//
//  BaseballMatchDetailVenueFooterView.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/28.
//

import UIKit

// MARK: - BaseballMatchDetailVenueFooterView

final class BaseballMatchDetailVenueFooterView: MatchBaseVenueFooterView {

    static let reuseIdentifier = "BaseballMatchDetailVenueFooterView"

    func configure(with viewData: BaseballMatchDetailVenueViewData) {
        configureVenueText(viewData.venueText)
    }
}

