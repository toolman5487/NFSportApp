//
//  MainSoccerHomeCardCell.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/25.
//

import UIKit

// MARK: - MainSoccerHomeCardCell

class MainSoccerHomeCardCell: UICollectionViewCell {

    // MARK: - Layout Metrics

    enum LayoutMetric {
        static let cornerRadius: CGFloat = 8
        static let contentInset: CGFloat = 16
    }

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCardAppearance()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupCardAppearance() {
        contentView.backgroundColor = .secondaryBackgroundColor
        contentView.layer.cornerRadius = LayoutMetric.cornerRadius
        contentView.layer.masksToBounds = true
    }
}
