//
//  MainMatchesSectionHeaderView.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/25.
//

import SnapKit
import UIKit

// MARK: - MainMatchesSectionHeaderView

final class MainMatchesSectionHeaderView: UICollectionReusableView {

    static let reuseIdentifier = "MainMatchesSectionHeaderView"

    // MARK: - Layout Metrics

    private enum LayoutMetric {
        static let horizontalInset: CGFloat = 16
        static let verticalInset: CGFloat = 8
        static let spacing: CGFloat = 8
    }

    // MARK: - UI Components

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .title3)
        label.textColor = .primaryLabel
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabelColor
        label.textAlignment = .right
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

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        subtitleLabel.text = nil
    }

    // MARK: - Configuration

    func configure(with viewData: MainMatchesScheduleGroupViewData) {
        titleLabel.text = viewData.title
        subtitleLabel.text = viewData.subtitle
    }

    // MARK: - Setup

    private func setupView() {
        backgroundColor = .backgroundColor
        addSubview(titleLabel)
        addSubview(subtitleLabel)

        titleLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(LayoutMetric.verticalInset)
            make.leading.equalToSuperview().inset(LayoutMetric.horizontalInset)
            make.trailing.lessThanOrEqualTo(subtitleLabel.snp.leading).offset(-LayoutMetric.spacing)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.trailing.equalToSuperview().inset(LayoutMetric.horizontalInset)
        }
    }
}
