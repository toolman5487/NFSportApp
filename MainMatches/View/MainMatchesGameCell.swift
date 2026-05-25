//
//  MainMatchesGameCell.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/25.
//

import SDWebImage
import SnapKit
import UIKit

// MARK: - MainMatchesGameCell

final class MainMatchesGameCell: UICollectionViewCell {

    static let reuseIdentifier = "MainMatchesGameCell"

    // MARK: - Layout Metrics

    private enum LayoutMetric {
        static let cardCornerRadius: CGFloat = 8
        static let contentInset: CGFloat = 16
        static let compactSpacing: CGFloat = 8
        static let rowSpacing: CGFloat = 12
        static let statusHorizontalInset: CGFloat = 8
        static let statusVerticalInset: CGFloat = 4
        static let separatorHeight: CGFloat = 1
    }

    // MARK: - UI Components

    private let leagueLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabelColor
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        return label
    }()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabelColor
        label.textAlignment = .right
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        return label
    }()

    private let statusContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 4
        view.layer.masksToBounds = true
        return view
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let awayRowView = MatchTeamRowView()
    private let homeRowView = MatchTeamRowView()

    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .separator.withAlphaComponent(0.32)
        return view
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
        statusLabel.text = nil
        leagueLabel.text = nil
        awayRowView.prepareForReuse()
        homeRowView.prepareForReuse()
    }

    // MARK: - Configuration

    func configure(with viewData: MainMatchesGameViewData) {
        timeLabel.text = viewData.timeText
        statusLabel.text = viewData.statusText
        leagueLabel.text = viewData.leagueName
        awayRowView.configure(
            teamName: viewData.awayTeamName,
            logoURL: viewData.awayTeamLogoURL,
            scoreText: viewData.awayScoreText
        )
        homeRowView.configure(
            teamName: viewData.homeTeamName,
            logoURL: viewData.homeTeamLogoURL,
            scoreText: viewData.homeScoreText
        )
        applyStatusStyle(viewData.statusStyle)
    }

    // MARK: - Setup

    private func setupView() {
        isAccessibilityElement = true
        accessibilityTraits = .button

        contentView.backgroundColor = .secondaryBackgroundColor
        contentView.layer.cornerRadius = LayoutMetric.cardCornerRadius
        contentView.layer.masksToBounds = true

        contentView.addSubview(timeLabel)
        contentView.addSubview(leagueLabel)
        contentView.addSubview(statusContainerView)
        statusContainerView.addSubview(statusLabel)
        contentView.addSubview(awayRowView)
        contentView.addSubview(separatorView)
        contentView.addSubview(homeRowView)

        leagueLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(LayoutMetric.contentInset)
            make.trailing.lessThanOrEqualTo(timeLabel.snp.leading).offset(-LayoutMetric.compactSpacing)
        }

        timeLabel.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(LayoutMetric.contentInset)
            make.width.greaterThanOrEqualTo(48)
        }

        statusContainerView.snp.makeConstraints { make in
            make.top.equalTo(leagueLabel.snp.bottom).offset(LayoutMetric.compactSpacing)
            make.leading.equalToSuperview().inset(LayoutMetric.contentInset)
            make.trailing.lessThanOrEqualToSuperview().inset(LayoutMetric.contentInset)
        }

        statusLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(LayoutMetric.statusVerticalInset)
            make.leading.trailing.equalToSuperview().inset(LayoutMetric.statusHorizontalInset)
        }

        awayRowView.snp.makeConstraints { make in
            make.top.equalTo(statusContainerView.snp.bottom).offset(LayoutMetric.rowSpacing)
            make.trailing.equalToSuperview().inset(LayoutMetric.contentInset)
            make.leading.equalToSuperview().inset(LayoutMetric.contentInset)
        }

        separatorView.snp.makeConstraints { make in
            make.top.equalTo(awayRowView.snp.bottom).offset(LayoutMetric.compactSpacing)
            make.leading.trailing.equalTo(awayRowView)
            make.height.equalTo(LayoutMetric.separatorHeight)
        }

        homeRowView.snp.makeConstraints { make in
            make.top.equalTo(separatorView.snp.bottom).offset(LayoutMetric.compactSpacing)
            make.leading.trailing.equalTo(awayRowView)
            make.bottom.equalToSuperview().inset(LayoutMetric.contentInset)
        }
    }

    // MARK: - Status Style

    private func applyStatusStyle(_ style: MainMatchesGameStatusStyle) {
        switch style {
        case .live:
            statusContainerView.backgroundColor = .systemRed.withAlphaComponent(0.18)
            statusLabel.textColor = .systemRed

        case .final:
            statusContainerView.backgroundColor = .secondaryLabelColor.withAlphaComponent(0.16)
            statusLabel.textColor = .secondaryLabelColor

        case .upcoming:
            statusContainerView.backgroundColor = .systemBlue.withAlphaComponent(0.18)
            statusLabel.textColor = .systemBlue

        case .neutral:
            statusContainerView.backgroundColor = .tertiarySystemFill
            statusLabel.textColor = .secondaryLabelColor
        }
    }
}

// MARK: - MatchTeamRowView

private final class MatchTeamRowView: UIView {

    // MARK: - Layout Metrics

    private enum LayoutMetric {
        static let logoSize: CGFloat = 24
        static let logoSpacing: CGFloat = 8
        static let scoreLeadingSpacing: CGFloat = 12
        static let scoreWidth: CGFloat = 48
    }

    // MARK: - Properties

    private var logoWidthConstraint: Constraint?
    private var teamLeadingConstraint: Constraint?

    // MARK: - UI Components

    private let teamNameLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .primaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.isHidden = true
        return imageView
    }()

    private let scoreLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .title3)
        label.textColor = .primaryLabel
        label.textAlignment = .right
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        return label
    }()

    // MARK: - Initialization

    init() {
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Reuse

    func prepareForReuse() {
        logoImageView.sd_cancelCurrentImageLoad()
        logoImageView.image = nil
        logoImageView.isHidden = true
        teamNameLabel.text = nil
        scoreLabel.text = nil
    }

    // MARK: - Configuration

    func configure(
        teamName: String,
        logoURL: URL?,
        scoreText: String
    ) {
        teamNameLabel.text = teamName
        scoreLabel.text = scoreText

        switch logoURL {
        case .some(let logoURL):
            logoImageView.isHidden = false
            logoWidthConstraint?.update(offset: LayoutMetric.logoSize)
            teamLeadingConstraint?.update(offset: LayoutMetric.logoSpacing)
            logoImageView.sd_setImage(with: logoURL)

        case .none:
            logoImageView.sd_cancelCurrentImageLoad()
            logoImageView.image = nil
            logoImageView.isHidden = true
            logoWidthConstraint?.update(offset: 0)
            teamLeadingConstraint?.update(offset: 0)
        }
    }

    // MARK: - Setup

    private func setupView() {
        addSubview(logoImageView)
        addSubview(teamNameLabel)
        addSubview(scoreLabel)

        logoImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            logoWidthConstraint = make.width.equalTo(LayoutMetric.logoSize).constraint
            make.height.equalTo(LayoutMetric.logoSize)
        }

        teamNameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            teamLeadingConstraint = make.leading.equalTo(logoImageView.snp.trailing)
                .offset(LayoutMetric.logoSpacing)
                .constraint
            make.trailing.lessThanOrEqualTo(scoreLabel.snp.leading).offset(-LayoutMetric.scoreLeadingSpacing)
            make.bottom.equalToSuperview()
        }

        scoreLabel.snp.makeConstraints { make in
            make.top.trailing.bottom.equalToSuperview()
            make.width.equalTo(LayoutMetric.scoreWidth)
        }
    }
}
