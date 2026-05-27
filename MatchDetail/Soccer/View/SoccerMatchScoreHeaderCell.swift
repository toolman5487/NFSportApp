//
//  SoccerMatchScoreHeaderCell.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/26.
//

import SDWebImage
import SnapKit
import UIKit

// MARK: - SoccerMatchScoreHeaderCell

final class SoccerMatchScoreHeaderCell: UICollectionViewCell {

    static let reuseIdentifier = "SoccerMatchScoreHeaderCell"

    private enum LayoutMetric {
        static let cardCornerRadius: CGFloat = 12
        static let contentInset: CGFloat = 16
        static let headerSpacing: CGFloat = 12
        static let compactSpacing: CGFloat = 8
        static let teamSpacing: CGFloat = 12
        static let statusHorizontalInset: CGFloat = 8
        static let statusVerticalInset: CGFloat = 4
        static let teamLogoSize: CGFloat = 40
        static let scoreWidth: CGFloat = 88
    }

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

    private let venueLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabelColor
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }()

    private let homeTeamView = SoccerMatchScoreHeaderTeamView()
    private let awayTeamView = SoccerMatchScoreHeaderTeamView()

    private let homeScoreLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(ofSize: 34, weight: .semibold)
        label.textColor = .primaryLabel
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let scoreDividerLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .title2)
        label.textColor = .secondaryLabelColor
        label.textAlignment = .center
        label.text = "-"
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let awayScoreLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(ofSize: 34, weight: .semibold)
        label.textColor = .primaryLabel
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private lazy var scoreStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [homeScoreLabel, scoreDividerLabel, awayScoreLabel])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fillEqually
        stackView.spacing = LayoutMetric.compactSpacing
        return stackView
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
        statusLabel.text = nil
        venueLabel.text = nil
        homeScoreLabel.text = nil
        awayScoreLabel.text = nil
        homeTeamView.prepareForReuse()
        awayTeamView.prepareForReuse()
    }

    func configure(with viewData: SoccerMatchDetailHeaderViewData) {
        statusLabel.text = viewData.statusText
        venueLabel.text = viewData.venueText
        venueLabel.isHidden = viewData.venueText == nil
        homeScoreLabel.text = viewData.homeScoreText
        awayScoreLabel.text = viewData.awayScoreText
        homeTeamView.configure(
            teamName: viewData.homeTeamName,
            logoURL: viewData.homeTeamLogoURL
        )
        awayTeamView.configure(
            teamName: viewData.awayTeamName,
            logoURL: viewData.awayTeamLogoURL
        )

        applyStatusStyle(viewData.statusStyle)
    }

    private func setupView() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.layer.cornerRadius = LayoutMetric.cardCornerRadius
        contentView.layer.masksToBounds = true

        contentView.addSubview(statusContainerView)
        statusContainerView.addSubview(statusLabel)

        contentView.addSubview(venueLabel)
        contentView.addSubview(homeTeamView)
        contentView.addSubview(scoreStackView)
        contentView.addSubview(awayTeamView)

        statusContainerView.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(LayoutMetric.contentInset)
        }

        statusLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(LayoutMetric.statusVerticalInset)
            make.leading.trailing.equalToSuperview().inset(LayoutMetric.statusHorizontalInset)
        }

        venueLabel.snp.makeConstraints { make in
            make.top.equalTo(statusContainerView.snp.bottom).offset(LayoutMetric.headerSpacing)
            make.leading.trailing.equalToSuperview().inset(LayoutMetric.contentInset)
        }

        homeTeamView.snp.makeConstraints { make in
            make.top.equalTo(venueLabel.snp.bottom).offset(LayoutMetric.headerSpacing)
            make.leading.equalToSuperview().inset(LayoutMetric.contentInset)
            make.bottom.equalToSuperview().inset(LayoutMetric.contentInset)
        }

        scoreStackView.snp.makeConstraints { make in
            make.leading.equalTo(homeTeamView.snp.trailing).offset(LayoutMetric.teamSpacing)
            make.centerY.equalTo(homeTeamView)
            make.width.equalTo(LayoutMetric.scoreWidth)
        }

        awayTeamView.snp.makeConstraints { make in
            make.leading.equalTo(scoreStackView.snp.trailing).offset(LayoutMetric.teamSpacing)
            make.trailing.equalToSuperview().inset(LayoutMetric.contentInset)
            make.top.bottom.equalTo(homeTeamView)
            make.width.equalTo(homeTeamView)
        }
    }

    private func applyStatusStyle(_ style: SoccerMatchDetailHeaderStatusStyle) {
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

private final class SoccerMatchScoreHeaderTeamView: UIView {

    private enum LayoutMetric {
        static let spacing: CGFloat = 8
        static let logoSize: CGFloat = 40
    }

    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.isHidden = true
        return imageView
    }()

    private let teamNameLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .primaryLabel
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 2
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
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
    }

    func configure(teamName: String, logoURL: URL?) {
        teamNameLabel.text = teamName

        if let logoURL {
            logoImageView.sd_setImage(with: logoURL)
            logoImageView.isHidden = false
        } else {
            logoImageView.sd_cancelCurrentImageLoad()
            logoImageView.image = nil
            logoImageView.isHidden = true
        }
    }

    private func setupView() {
        let stackView = UIStackView(arrangedSubviews: [logoImageView, teamNameLabel])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = LayoutMetric.spacing

        addSubview(stackView)

        logoImageView.snp.makeConstraints { make in
            make.width.height.equalTo(LayoutMetric.logoSize)
        }

        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
