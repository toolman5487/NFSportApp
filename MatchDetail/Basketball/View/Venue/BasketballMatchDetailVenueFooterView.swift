//
//  BasketballMatchDetailVenueFooterView.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/28.
//

import UIKit

// MARK: - BasketballMatchDetailVenueFooterView

final class BasketballMatchDetailVenueFooterView: MatchBaseVenueFooterView {

    static let reuseIdentifier = "BasketballMatchDetailVenueFooterView"

    func configure(with viewData: BasketballMatchDetailVenueViewData) {
        configureVenueText(viewData.venueText)
    }
}
