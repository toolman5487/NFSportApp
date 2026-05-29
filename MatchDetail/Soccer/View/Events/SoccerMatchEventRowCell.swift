//
//  SoccerMatchEventRowCell.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/29.
//

import SnapKit
import UIKit

// MARK: - SoccerMatchEventRowCell

final class SoccerMatchEventRowCell: UICollectionViewCell {

    // MARK: - Constants

    static let reuseIdentifier = "SoccerMatchEventRowCell"

    // MARK: - Layout Metrics

    private enum LayoutMetric {
        static let horizontalInset: CGFloat = 16
        static let verticalInset: CGFloat = 10
        static let timeWidth: CGFloat = 44
        static let spacing: CGFloat = 8
    }

    // MARK: - UI Components

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .secondaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = .primaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .secondaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
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
        timeLabel.text = nil
        titleLabel.text = nil
        subtitleLabel.text = nil
        subtitleLabel.isHidden = true
    }

    // MARK: - Configuration

    func configure(with viewData: SoccerMatchDetailEventViewData) {
        timeLabel.text = viewData.timeText
        titleLabel.text = viewData.title

        if let subtitle = viewData.subtitle,
           !subtitle.isEmpty {
            subtitleLabel.text = subtitle
            subtitleLabel.isHidden = false
        } else {
            subtitleLabel.isHidden = true
        }
    }

    // MARK: - Setup

    private func setupView() {
        contentView.backgroundColor = .secondaryBackgroundColor
        contentView.layer.cornerRadius = 12

        contentView.addSubview(timeLabel)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)

        timeLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(LayoutMetric.horizontalInset)
            make.top.equalToSuperview().inset(LayoutMetric.verticalInset)
            make.width.equalTo(LayoutMetric.timeWidth)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(timeLabel.snp.trailing).offset(LayoutMetric.spacing)
            make.trailing.equalToSuperview().inset(LayoutMetric.horizontalInset)
            make.top.equalToSuperview().inset(LayoutMetric.verticalInset)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.bottom.equalToSuperview().inset(LayoutMetric.verticalInset)
        }
    }
}
