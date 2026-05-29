//
//  SoccerMatchStatsEmptyCell.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/29.
//

import SnapKit
import UIKit

// MARK: - SoccerMatchStatsEmptyCell

final class SoccerMatchStatsEmptyCell: UICollectionViewCell {

    // MARK: - Constants

    static let reuseIdentifier = "SoccerMatchStatsEmptyCell"

    // MARK: - Layout Metrics

    private enum LayoutMetric {
        static let contentInset: CGFloat = 24
    }

    // MARK: - UI Components

    private let stateView = ContentStateView()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration

    func configure(title: String, subtitle: String?) {
        stateView.render(
            .message(
                style: .information,
                systemImageName: "chart.bar",
                title: title,
                subtitle: subtitle
            )
        )
    }

    // MARK: - Setup

    private func setupView() {
        contentView.backgroundColor = .clear

        contentView.addSubview(stateView)

        stateView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(LayoutMetric.contentInset)
        }
    }
}
