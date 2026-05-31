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
        static let horizontalInset: CGFloat = 12
        static let verticalInset: CGFloat = 8
        static let centerWidth: CGFloat = 56
        static let iconSize: CGFloat = 28
        static let lineWidth: CGFloat = 2
        static let contentSpacing: CGFloat = 4
    }

    // MARK: - UI Components

    private let homeContentView = UIView()
    private let awayContentView = UIView()
    private let centerView = UIView()

    private let topLineView: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        return view
    }()

    private let bottomLineView: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        return view
    }()

    private let iconContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondaryBackgroundColor
        view.layer.cornerRadius = LayoutMetric.iconSize / 2
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.separator.withAlphaComponent(0.28).cgColor
        return view
    }()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .primaryLabel
        return imageView
    }()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        return label
    }()

    private let homeTitleLabel = SoccerMatchEventRowCell.makeTitleLabel(alignment: .right)
    private let homeSubtitleLabel = SoccerMatchEventRowCell.makeSubtitleLabel(alignment: .right)
    private let awayTitleLabel = SoccerMatchEventRowCell.makeTitleLabel(alignment: .left)
    private let awaySubtitleLabel = SoccerMatchEventRowCell.makeSubtitleLabel(alignment: .left)

    private lazy var homeStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [homeTitleLabel, homeSubtitleLabel])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = LayoutMetric.contentSpacing
        return stackView
    }()

    private lazy var awayStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [awayTitleLabel, awaySubtitleLabel])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = LayoutMetric.contentSpacing
        return stackView
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
        iconImageView.image = nil
        resetLabel(homeTitleLabel)
        resetLabel(homeSubtitleLabel)
        resetLabel(awayTitleLabel)
        resetLabel(awaySubtitleLabel)
        homeContentView.isHidden = true
        awayContentView.isHidden = true
    }

    // MARK: - Configuration

    func configure(with viewData: SoccerMatchDetailEventViewData) {
        timeLabel.text = viewData.timeText
        iconImageView.image = UIImage(systemName: viewData.iconSystemName)

        switch viewData.side {
        case .home:
            configureContent(
                titleLabel: homeTitleLabel,
                subtitleLabel: homeSubtitleLabel,
                title: viewData.title,
                subtitle: viewData.subtitle
            )
            homeContentView.isHidden = false
            awayContentView.isHidden = true

        case .away:
            configureContent(
                titleLabel: awayTitleLabel,
                subtitleLabel: awaySubtitleLabel,
                title: viewData.title,
                subtitle: viewData.subtitle
            )
            homeContentView.isHidden = true
            awayContentView.isHidden = false

        case .neutral:
            configureContent(
                titleLabel: awayTitleLabel,
                subtitleLabel: awaySubtitleLabel,
                title: viewData.title,
                subtitle: viewData.subtitle
            )
            homeContentView.isHidden = true
            awayContentView.isHidden = false
        }
    }

    private func configureContent(
        titleLabel: UILabel,
        subtitleLabel: UILabel,
        title: String,
        subtitle: String?
    ) {
        titleLabel.text = title

        if let subtitle, !subtitle.isEmpty {
            subtitleLabel.text = subtitle
            subtitleLabel.isHidden = false
        } else {
            subtitleLabel.isHidden = true
        }
    }

    // MARK: - Setup

    private func setupView() {
        contentView.backgroundColor = .clear

        contentView.addSubview(homeContentView)
        contentView.addSubview(centerView)
        contentView.addSubview(awayContentView)
        homeContentView.addSubview(homeStackView)
        awayContentView.addSubview(awayStackView)
        centerView.addSubview(topLineView)
        centerView.addSubview(bottomLineView)
        centerView.addSubview(iconContainerView)
        centerView.addSubview(timeLabel)
        iconContainerView.addSubview(iconImageView)

        homeContentView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(LayoutMetric.horizontalInset)
            make.trailing.equalTo(centerView.snp.leading)
            make.top.bottom.equalToSuperview().inset(LayoutMetric.verticalInset)
        }

        centerView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.equalTo(LayoutMetric.centerWidth)
        }

        awayContentView.snp.makeConstraints { make in
            make.leading.equalTo(centerView.snp.trailing)
            make.trailing.equalToSuperview().inset(LayoutMetric.horizontalInset)
            make.top.bottom.equalToSuperview().inset(LayoutMetric.verticalInset)
        }

        homeStackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(LayoutMetric.horizontalInset)
            make.centerY.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }

        awayStackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(LayoutMetric.horizontalInset)
            make.centerY.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }

        iconContainerView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-8)
            make.width.height.equalTo(LayoutMetric.iconSize)
        }

        iconImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(6)
        }

        timeLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(iconContainerView.snp.bottom).offset(2)
            make.leading.trailing.equalToSuperview()
        }

        topLineView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalTo(iconContainerView.snp.top)
            make.centerX.equalTo(iconContainerView)
            make.width.equalTo(LayoutMetric.lineWidth)
        }

        bottomLineView.snp.makeConstraints { make in
            make.top.equalTo(iconContainerView.snp.bottom)
            make.bottom.equalToSuperview()
            make.centerX.equalTo(iconContainerView)
            make.width.equalTo(LayoutMetric.lineWidth)
        }
    }

    // MARK: - Factories

    private static func makeTitleLabel(alignment: NSTextAlignment) -> UILabel {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .primaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.textAlignment = alignment
        return label
    }

    private static func makeSubtitleLabel(alignment: NSTextAlignment) -> UILabel {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.textAlignment = alignment
        return label
    }

    private func resetLabel(_ label: UILabel) {
        label.text = nil
        label.isHidden = false
    }
}
