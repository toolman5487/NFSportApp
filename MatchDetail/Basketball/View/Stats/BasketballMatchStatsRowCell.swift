//
//  BasketballMatchStatsRowCell.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/29.
//

import SnapKit
import UIKit

// MARK: - BasketballMatchStatsRowCell

final class BasketballMatchStatsRowCell: UICollectionViewCell {

    // MARK: - Constants

    static let reuseIdentifier = "BasketballMatchStatsRowCell"

    // MARK: - Layout Metrics

    private enum LayoutMetric {
        static let horizontalInset: CGFloat = 12
        static let verticalInset: CGFloat = 8
        static let valueWidth: CGFloat = 56
        static let barHeight: CGFloat = 6
        static let barCornerRadius: CGFloat = 3
        static let barSpacing: CGFloat = 4
        static let titleBottomSpacing: CGFloat = 8
        static let minBarRatio: CGFloat = 0.02
    }

    // MARK: - UI Components

    private let homeValueLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .primaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .left
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .secondaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        return label
    }()

    private let awayValueLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .primaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .right
        return label
    }()

    private let homeBarView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBlue
        view.layer.cornerRadius = LayoutMetric.barCornerRadius
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        return view
    }()

    private let awayBarView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemRed
        view.layer.cornerRadius = LayoutMetric.barCornerRadius
        view.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        return view
    }()

    private let barContainerView = UIView()

    private var barHeightConstraint: Constraint?

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
        homeValueLabel.text = nil
        awayValueLabel.text = nil
        titleLabel.text = nil
    }

    // MARK: - Configuration

    func configure(with viewData: BasketballMatchStatsComparisonRowViewData) {
        homeValueLabel.isHidden = false
        barContainerView.isHidden = false
        barHeightConstraint?.update(offset: LayoutMetric.barHeight)

        homeValueLabel.text = viewData.homeValue
        awayValueLabel.text = viewData.awayValue
        titleLabel.text = viewData.title

        let ratio = CGFloat(viewData.homeRatio)
        let clampedRatio = min(max(ratio, LayoutMetric.minBarRatio), 1 - LayoutMetric.minBarRatio)

        homeBarView.snp.remakeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(clampedRatio)
        }

        awayBarView.snp.remakeConstraints { make in
            make.trailing.top.bottom.equalToSuperview()
            make.leading.equalTo(homeBarView.snp.trailing).offset(LayoutMetric.barSpacing)
        }
    }

    func configure(with viewData: BasketballMatchStatsValueRowViewData) {
        homeValueLabel.isHidden = true
        barContainerView.isHidden = true
        barHeightConstraint?.update(offset: 0)

        titleLabel.text = viewData.title
        awayValueLabel.text = viewData.value
    }

    // MARK: - Setup

    private func setupView() {
        contentView.backgroundColor = .clear

        contentView.addSubview(homeValueLabel)
        contentView.addSubview(titleLabel)
        contentView.addSubview(awayValueLabel)
        contentView.addSubview(barContainerView)
        barContainerView.addSubview(homeBarView)
        barContainerView.addSubview(awayBarView)

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(LayoutMetric.verticalInset)
            make.centerX.equalToSuperview()
        }

        homeValueLabel.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.leading.equalToSuperview().inset(LayoutMetric.horizontalInset)
            make.width.greaterThanOrEqualTo(LayoutMetric.valueWidth)
        }

        awayValueLabel.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.trailing.equalToSuperview().inset(LayoutMetric.horizontalInset)
            make.width.greaterThanOrEqualTo(LayoutMetric.valueWidth)
        }

        barContainerView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(LayoutMetric.titleBottomSpacing)
            make.leading.trailing.equalToSuperview().inset(LayoutMetric.horizontalInset)
            barHeightConstraint = make.height.equalTo(LayoutMetric.barHeight).constraint
            make.bottom.equalToSuperview().inset(LayoutMetric.verticalInset)
        }

        homeBarView.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.5)
        }

        awayBarView.snp.makeConstraints { make in
            make.trailing.top.bottom.equalToSuperview()
            make.leading.equalTo(homeBarView.snp.trailing).offset(LayoutMetric.barSpacing)
        }
    }
}
