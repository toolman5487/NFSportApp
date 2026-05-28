//
//  BasketballMatchDetailVenueCell.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/28.
//

import UIKit

// MARK: - BasketballMatchDetailVenueCell

final class BasketballMatchDetailVenueCell: MatchBaseVenueCell {

    static let reuseIdentifier = "BasketballMatchDetailVenueCell"

    func configure(with viewData: BasketballMatchDetailVenueViewData) {
        configureVenueText(viewData.venueText)
    }
}
