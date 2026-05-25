//
//  MainMatchesGameCell.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/25.
//

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
        static let timeColumnWidth: CGFloat = 64
        static let dividerWidth: CGFloat = 1
        static let scoreWidth: CGFloat = 44
        static let statusHorizontalInset: CGFloat = 8
        static let statusVerticalInset: CGFloat = 4
    }

    // MARK: - UI Components

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .primaryLabel
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 2
        return label
    }()

    private let statusContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 6
        view.layer.masksToBounds = true
        return view
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption2)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        return label
    }()

    private let dividerView: UIView = {
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

    private let awayRowView = MatchTeamRowView(roleText: "AWAY")
    private let homeRowView = MatchTeamRowView(roleText: "HOME")

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
        statusLabel.text = viewData.statusText.uppercased()
        leagueLabel.text = viewData.leagueName
        awayRowView.configure(teamName: viewData.awayTeamName, scoreText: viewData.awayScoreText)
        homeRowView.configure(teamName: viewData.homeTeamName, scoreText: viewData.homeScoreText)
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
        contentView.addSubview(statusContainerView)
        statusContainerView.addSubview(statusLabel)
        contentView.addSubview(dividerView)
        contentView.addSubview(leagueLabel)
        contentView.addSubview(awayRowView)
        contentView.addSubview(homeRowView)

        timeLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(LayoutMetric.contentInset)
            make.width.equalTo(LayoutMetric.timeColumnWidth)
        }

        statusContainerView.snp.makeConstraints { make in
            make.top.equalTo(timeLabel.snp.bottom).offset(LayoutMetric.compactSpacing)
            make.centerX.equalTo(timeLabel)
            make.bottom.lessThanOrEqualToSuperview().inset(LayoutMetric.contentInset)
        }

        statusLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(LayoutMetric.statusVerticalInset)
            make.leading.trailing.equalToSuperview().inset(LayoutMetric.statusHorizontalInset)
        }

        dividerView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(LayoutMetric.contentInset)
            make.leading.equalTo(timeLabel.snp.trailing).offset(LayoutMetric.contentInset)
            make.width.equalTo(LayoutMetric.dividerWidth)
        }

        leagueLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(LayoutMetric.contentInset)
            make.leading.equalTo(dividerView.snp.trailing).offset(LayoutMetric.contentInset)
            make.trailing.equalToSuperview().inset(LayoutMetric.contentInset)
        }

        awayRowView.snp.makeConstraints { make in
            make.top.equalTo(leagueLabel.snp.bottom).offset(LayoutMetric.rowSpacing)
            make.leading.trailing.equalTo(leagueLabel)
        }

        homeRowView.snp.makeConstraints { make in
            make.top.equalTo(awayRowView.snp.bottom).offset(LayoutMetric.compactSpacing)
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
        static let roleWidth: CGFloat = 44
        static let teamLeadingSpacing: CGFloat = 8
        static let scoreLeadingSpacing: CGFloat = 12
        static let scoreWidth: CGFloat = 44
    }

    // MARK: - Properties

    private let roleText: String

    // MARK: - UI Components

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

    private let scoreLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .primaryLabel
        label.textAlignment = .right
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        return label
    }()

    // MARK: - Initialization

    init(roleText: String) {
        self.roleText = roleText
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Reuse

    func prepareForReuse() {
        teamNameLabel.text = nil
        scoreLabel.text = nil
    }

    // MARK: - Configuration

    func configure(teamName: String, scoreText: String) {
        teamNameLabel.text = teamName
        scoreLabel.text = scoreText
    }

    // MARK: - Setup

    private func setupView() {
        roleLabel.text = roleText

        addSubview(roleLabel)
        addSubview(teamNameLabel)
        addSubview(scoreLabel)

        roleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
            make.width.equalTo(LayoutMetric.roleWidth)
        }

        teamNameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalTo(roleLabel.snp.trailing).offset(LayoutMetric.teamLeadingSpacing)
            make.trailing.lessThanOrEqualTo(scoreLabel.snp.leading).offset(-LayoutMetric.scoreLeadingSpacing)
            make.bottom.equalToSuperview()
        }

        scoreLabel.snp.makeConstraints { make in
            make.top.trailing.bottom.equalToSuperview()
            make.width.equalTo(LayoutMetric.scoreWidth)
        }
    }
}
