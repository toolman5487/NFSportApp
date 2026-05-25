//
//  MainSoccerHomeCellSupport.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/25.
//

import UIKit

// MARK: - Label Factory

enum MainSoccerHomeLabelFactory {

    static func makeTitleLabel() -> UILabel {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .primaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        return label
    }

    static func makePrimaryLabel() -> UILabel {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .primaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        return label
    }

    static func makeSecondaryLabel() -> UILabel {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabelColor
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        return label
    }

    static func makeEmptyLabel() -> UILabel {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .secondaryLabelColor
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        return label
    }
}
