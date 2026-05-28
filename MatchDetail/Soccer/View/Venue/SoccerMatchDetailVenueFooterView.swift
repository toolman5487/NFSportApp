//
//  SoccerMatchDetailVenueFooterView.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/28.
//

import UIKit

// MARK: - SoccerMatchDetailVenueFooterView

final class SoccerMatchDetailVenueFooterView: MatchBaseVenueFooterView {

    static let reuseIdentifier = "SoccerMatchDetailVenueFooterView"

    func configure(with viewData: SoccerMatchDetailVenueViewData) {
        configureVenueText(viewData.venueText)
    }
}
