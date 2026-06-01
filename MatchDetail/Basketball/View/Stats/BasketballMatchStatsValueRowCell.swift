//
//  BasketballMatchStatsValueRowCell.swift
//  NFSportApp
//
//  Created by Codex on 2026/6/1.
//

import SnapKit
import UIKit

// MARK: - BasketballMatchStatsValueRowCell

final class BasketballMatchStatsValueRowCell: UICollectionViewCell {

    // MARK: - Constants

    static let reuseIdentifier = "BasketballMatchStatsValueRowCell"

    // MARK: - Layout Metrics

    private enum LayoutMetric {
        static let horizontalInset: CGFloat = 12
        static let verticalInset: CGFloat = 12
        static let valueWidth: CGFloat = 56
        static let cornerRadius: CGFloat = 12
    }

    // MARK: - UI Components

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .primaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        return label
    }()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .secondaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .right
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
        valueLabel.text = nil
    }

    // MARK: - Configuration

    func configure(with viewData: BasketballMatchStatsValueRowViewData) {
        titleLabel.text = viewData.title
        valueLabel.text = viewData.value
    }

    // MARK: - Setup

    private func setupView() {
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = LayoutMetric.cornerRadius

        contentView.addSubview(titleLabel)
        contentView.addSubview(valueLabel)

        titleLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(LayoutMetric.verticalInset)
            make.leading.equalToSuperview().inset(LayoutMetric.horizontalInset)
            make.trailing.lessThanOrEqualTo(valueLabel.snp.leading).offset(-LayoutMetric.horizontalInset)
        }

        valueLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(LayoutMetric.horizontalInset)
            make.width.greaterThanOrEqualTo(LayoutMetric.valueWidth)
        }
    }
}
