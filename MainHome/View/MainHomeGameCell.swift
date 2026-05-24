//
//  MainHomeGameCell.swift
//  NFSportApp
//
//  Created by Willy Hsu 2026/5/23.
//

import SnapKit
import UIKit

// MARK: - MainHomeGameCell

final class MainHomeGameCell: UICollectionViewCell {

    static let reuseIdentifier = "MainHomeGameCell"

    // MARK: - Layout Metrics

    private enum LayoutMetric {
        static let cardCornerRadius: CGFloat = 8
        static let contentInset: CGFloat = 16
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

    private let awayRowView = TeamScoreRowView(roleText: "AWAY")
    private let homeRowView = TeamScoreRowView(roleText: "HOME")

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
        statusLabel.text = nil
        scheduledStartLabel.text = nil
        awayRowView.prepareForReuse()
        homeRowView.prepareForReuse()
    }

    // MARK: - Configuration

    func configure(with viewData: MainHomeGameViewData) {
        statusLabel.text = viewData.statusText.uppercased()
        scheduledStartLabel.text = viewData.scheduledStartText
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

        contentView.addSubview(statusContainerView)
        statusContainerView.addSubview(statusLabel)
        contentView.addSubview(scheduledStartLabel)
        contentView.addSubview(awayRowView)
        contentView.addSubview(separatorView)
        contentView.addSubview(homeRowView)

        statusContainerView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(LayoutMetric.contentInset)
            make.trailing.lessThanOrEqualTo(scheduledStartLabel.snp.leading).offset(-LayoutMetric.compactSpacing)
        }

        statusLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(LayoutMetric.statusVerticalInset)
            make.leading.trailing.equalToSuperview().inset(LayoutMetric.statusHorizontalInset)
        }

        scheduledStartLabel.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(LayoutMetric.contentInset)
            make.leading.greaterThanOrEqualTo(contentView.snp.centerX)
        }

        awayRowView.snp.makeConstraints { make in
            make.top.equalTo(statusContainerView.snp.bottom).offset(LayoutMetric.rowSpacing)
            make.leading.trailing.equalToSuperview().inset(LayoutMetric.contentInset)
        }

        separatorView.snp.makeConstraints { make in
            make.top.equalTo(awayRowView.snp.bottom).offset(LayoutMetric.compactSpacing)
            make.leading.trailing.equalTo(awayRowView)
            make.height.equalTo(1)
        }

        homeRowView.snp.makeConstraints { make in
            make.top.equalTo(separatorView.snp.bottom).offset(LayoutMetric.compactSpacing)
            make.leading.trailing.equalTo(awayRowView)
            make.bottom.equalToSuperview().inset(LayoutMetric.contentInset)
        }
    }

    // MARK: - Status Style

    private func applyStatusStyle(_ style: MainHomeGameStatusStyle) {
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

// MARK: - TeamScoreRowView

private final class TeamScoreRowView: UIView {

    // MARK: - Layout Metrics

    private enum LayoutMetric {
        static let roleWidth: CGFloat = 44
        static let teamLeadingSpacing: CGFloat = 8
        static let scoreLeadingSpacing: CGFloat = 12
        static let scoreWidth: CGFloat = 48
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
        label.font = .preferredFont(forTextStyle: .title3)
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
