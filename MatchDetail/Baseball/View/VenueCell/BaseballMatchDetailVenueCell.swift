//
//  BaseballMatchDetailVenueCell.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/28.
//

import UIKit

final class BaseballMatchDetailVenueCell: MatchBaseVenueCell {

    static let reuseIdentifier = "BaseballMatchDetailVenueCell"

    func configure(with viewData: BaseballMatchDetailVenueViewData) {
        configureVenueText(viewData.venueText)
    }
}

