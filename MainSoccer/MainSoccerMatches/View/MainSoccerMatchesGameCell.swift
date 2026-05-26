//
//  MainSoccerMatchesGameCell.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/26.
//

import SDWebImage
import SnapKit
import UIKit

// MARK: - MainSoccerMatchesGameCell

final class MainSoccerMatchesGameCell: UICollectionViewCell {

    static let reuseIdentifier = "MainSoccerMatchesGameCell"

    private enum LayoutMetric {
        static let cardCornerRadius: CGFloat = 8
        static let contentInset: CGFloat = 16
        static let compactSpacing: CGFloat = 8
        static let rowSpacing: CGFloat = 12
        static let statusHorizontalInset: CGFloat = 8
        static let statusVerticalInset: CGFloat = 4
        static let separatorHeight: CGFloat = 1
    }

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

    private let awayRowView = MainSoccerMatchesTeamRowView()
    private let homeRowView = MainSoccerMatchesTeamRowView()

    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .separator.withAlphaComponent(0.32)
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        timeLabel.text = nil
        statusLabel.text = nil
        leagueLabel.text = nil
        awayRowView.prepareForReuse()
        homeRowView.prepareForReuse()
    }

    func configure(with viewData: MainSoccerMatchesGameViewData) {
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

    private func applyStatusStyle(_ style: MainSoccerMatchesGameStatusStyle) {
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

private final class MainSoccerMatchesTeamRowView: UIView {

    private enum LayoutMetric {
        static let logoSize: CGFloat = 24
        static let logoSpacing: CGFloat = 8
        static let scoreLeadingSpacing: CGFloat = 12
        static let scoreWidth: CGFloat = 48
    }

    private var logoWidthConstraint: Constraint?
    private var teamLeadingConstraint: Constraint?

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

    init() {
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func prepareForReuse() {
        logoImageView.sd_cancelCurrentImageLoad()
        logoImageView.image = nil
        logoImageView.isHidden = true
        teamNameLabel.text = nil
        scoreLabel.text = nil
    }

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
