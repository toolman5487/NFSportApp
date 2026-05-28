//
//  SoccerMatchDetailVenueCell.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/28.
//

import UIKit

// MARK: - SoccerMatchDetailVenueCell

final class SoccerMatchDetailVenueCell: MatchBaseVenueCell {

    static let reuseIdentifier = "SoccerMatchDetailVenueCell"

    func configure(with viewData: SoccerMatchDetailVenueViewData) {
        configureVenueText(viewData.venueText)
    }
}
