//
//  MainSoccerHomeRowViews.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/25.
//

import SDWebImage
import SnapKit
import UIKit

// MARK: - MainSoccerFixtureCell

final class MainSoccerFixtureCell: MainSoccerHomeCardCell {

    static let reuseIdentifier = "MainSoccerFixtureCell"

    // MARK: - Layout Metrics

    private enum LayoutMetric {
        static let compactSpacing: CGFloat = 8
        static let rowSpacing: CGFloat = 12
        static let scoreWidth: CGFloat = 48
        static let statusHorizontalInset: CGFloat = 8
        static let statusVerticalInset: CGFloat = 4
    }

    // MARK: - UI Components

    private let statusContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 6
        view.layer.masksToBounds = true
        return view
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        return label
    }()

    private let scheduledStartLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabelColor
        label.textAlignment = .right
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 2
        return label
    }()

    private let awayRowView = MainSoccerTeamScoreRowView(roleText: "AWAY")
    private let homeRowView = MainSoccerTeamScoreRowView(roleText: "HOME")

    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .separator.withAlphaComponent(0.32)
        return view
    }()

    private let leagueLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabelColor
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
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

    override func prepareForReuse() {
        super.prepareForReuse()
        statusLabel.text = nil
        scheduledStartLabel.text = nil
        leagueLabel.text = nil
        awayRowView.prepareForReuse()
        homeRowView.prepareForReuse()
    }

    // MARK: - Configuration

    func configure(with viewData: MainSoccerFixtureViewData) {
        statusLabel.text = viewData.statusText.uppercased()
        scheduledStartLabel.text = viewData.timeText
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
        contentView.addSubview(statusContainerView)
        statusContainerView.addSubview(statusLabel)
        contentView.addSubview(scheduledStartLabel)
        contentView.addSubview(leagueLabel)
        contentView.addSubview(awayRowView)
        contentView.addSubview(separatorView)
        contentView.addSubview(homeRowView)

        statusContainerView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(MainSoccerHomeCardCell.LayoutMetric.contentInset)
            make.trailing.lessThanOrEqualTo(scheduledStartLabel.snp.leading).offset(-LayoutMetric.compactSpacing)
        }

        statusLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(LayoutMetric.statusVerticalInset)
            make.leading.trailing.equalToSuperview().inset(LayoutMetric.statusHorizontalInset)
        }

        scheduledStartLabel.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(MainSoccerHomeCardCell.LayoutMetric.contentInset)
            make.leading.greaterThanOrEqualTo(contentView.snp.centerX)
        }

        leagueLabel.snp.makeConstraints { make in
            make.top.equalTo(statusContainerView.snp.bottom).offset(LayoutMetric.compactSpacing)
            make.leading.equalToSuperview().inset(MainSoccerHomeCardCell.LayoutMetric.contentInset)
            make.trailing.equalToSuperview().inset(MainSoccerHomeCardCell.LayoutMetric.contentInset)
        }

        awayRowView.snp.makeConstraints { make in
            make.top.equalTo(leagueLabel.snp.bottom).offset(LayoutMetric.rowSpacing)
            make.leading.trailing.equalToSuperview().inset(MainSoccerHomeCardCell.LayoutMetric.contentInset)
        }

        separatorView.snp.makeConstraints { make in
            make.top.equalTo(awayRowView.snp.bottom).offset(LayoutMetric.compactSpacing)
            make.leading.trailing.equalTo(awayRowView)
            make.height.equalTo(1)
        }

        homeRowView.snp.makeConstraints { make in
            make.top.equalTo(separatorView.snp.bottom).offset(LayoutMetric.compactSpacing)
            make.leading.trailing.equalTo(awayRowView)
            make.bottom.equalToSuperview().inset(MainSoccerHomeCardCell.LayoutMetric.contentInset)
        }
    }

    private func applyStatusStyle(_ style: MainSoccerFixtureStatusStyle) {
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

// MARK: - MainSoccerTeamScoreRowView

private final class MainSoccerTeamScoreRowView: UIView {

    private enum LayoutMetric {
        static let roleWidth: CGFloat = 44
        static let teamLeadingSpacing: CGFloat = 8
        static let logoSize: CGFloat = 24
        static let logoSpacing: CGFloat = 8
        static let scoreLeadingSpacing: CGFloat = 12
        static let scoreWidth: CGFloat = 48
    }

    private let roleText: String
    private var logoWidthConstraint: Constraint?
    private var teamLeadingConstraint: Constraint?

    private let roleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption2)
        label.textColor = .tertiaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        return label
    }()

    private let teamNameLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .primaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 2
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

    init(roleText: String) {
        self.roleText = roleText
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
        roleLabel.text = roleText

        addSubview(roleLabel)
        addSubview(logoImageView)
        addSubview(teamNameLabel)
        addSubview(scoreLabel)

        roleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
            make.width.equalTo(LayoutMetric.roleWidth)
        }

        logoImageView.snp.makeConstraints { make in
            make.leading.equalTo(roleLabel.snp.trailing).offset(LayoutMetric.teamLeadingSpacing)
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

// MARK: - UIImageView

extension UIImageView {

    func setSoccerTeamLogo(
        with logoURL: URL?,
        placeholderSystemName: String = "shield.fill"
    ) {
        let placeholderImage = UIImage(systemName: placeholderSystemName)
        tintColor = .secondaryLabelColor
        contentMode = .scaleAspectFit

        switch logoURL {
        case .some(let logoURL):
            sd_setImage(with: logoURL, placeholderImage: placeholderImage)

        case .none:
            sd_cancelCurrentImageLoad()
            image = placeholderImage
        }
    }

    func resetSoccerTeamLogo() {
        sd_cancelCurrentImageLoad()
        image = nil
    }
}
