//
//  SoccerMatchDetailSectionHeaderView.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/29.
//

import SnapKit
import UIKit

// MARK: - SoccerMatchDetailSectionHeaderView

final class SoccerMatchDetailSectionHeaderView: UICollectionReusableView {

    // MARK: - Constants

    static let reuseIdentifier = "SoccerMatchDetailSectionHeaderView"

    // MARK: - Layout Metrics

    private enum LayoutMetric {
        static let horizontalInset: CGFloat = 16
        static let verticalInset: CGFloat = 12
    }

    static var preferredHeight: CGFloat { 44 }

    // MARK: - UI Components

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.textColor = .primaryLabel
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
    }

    func configure(title: String) {
        titleLabel.text = title
    }

    // MARK: - Setup

    private func setupView() {
        backgroundColor = .systemBackground

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(LayoutMetric.horizontalInset)
            make.top.bottom.equalToSuperview().inset(LayoutMetric.verticalInset)
        }
    }
}
