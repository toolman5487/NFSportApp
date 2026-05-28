//
//  HockeyMatchDetailVenueCell.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/28.
//

import UIKit

// MARK: - HockeyMatchDetailVenueCell

final class HockeyMatchDetailVenueCell: MatchBaseVenueCell {

    static let reuseIdentifier = "HockeyMatchDetailVenueCell"

    func configure(with viewData: HockeyMatchDetailVenueViewData) {
        configureVenueText(viewData.venueText)
    }
}

