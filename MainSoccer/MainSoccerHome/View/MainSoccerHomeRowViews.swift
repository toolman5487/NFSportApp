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
        static let timeWidth: CGFloat = 52
        static let spacing: CGFloat = 12
    }

    // MARK: - UI Components

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabelColor
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        return label
    }()

    private let matchupLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .primaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        return label
    }()

    private let leagueLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabelColor
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        return label
    }()

    private lazy var textStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [matchupLabel, leagueLabel])
        stackView.axis = .vertical
        stackView.spacing = 4
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

    override func prepareForReuse() {
        super.prepareForReuse()
        timeLabel.text = nil
        matchupLabel.text = nil
        leagueLabel.text = nil
    }

    // MARK: - Configuration

    func configure(with viewData: MainSoccerFixtureViewData) {
        timeLabel.text = viewData.timeText
        matchupLabel.text = "\(viewData.homeTeamName) vs \(viewData.awayTeamName)"
        leagueLabel.text = viewData.leagueName
    }

    // MARK: - Setup

    private func setupView() {
        contentView.addSubview(timeLabel)
        contentView.addSubview(textStackView)

        timeLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(MainSoccerHomeCardCell.LayoutMetric.contentInset)
            make.centerY.equalToSuperview()
            make.width.equalTo(LayoutMetric.timeWidth)
        }

        textStackView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(MainSoccerHomeCardCell.LayoutMetric.contentInset)
            make.leading.equalTo(timeLabel.snp.trailing).offset(LayoutMetric.spacing)
            make.trailing.equalToSuperview().inset(MainSoccerHomeCardCell.LayoutMetric.contentInset)
        }
    }
}

// MARK: - MainSoccerLeagueCell

final class MainSoccerLeagueCell: MainSoccerHomeCardCell {

    static let reuseIdentifier = "MainSoccerLeagueCell"

    // MARK: - Layout Metrics

    private enum LayoutMetric {
        static let iconSize: CGFloat = 36
        static let iconImageSize: CGFloat = 20
        static let spacing: CGFloat = 12
    }

    // MARK: - UI Components

    private let iconContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .tertiarySystemFill
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        return view
    }()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .primaryLabel
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .primaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        return label
    }()

    private let regionLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabelColor
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        return label
    }()

    private lazy var textStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [nameLabel, regionLabel])
        stackView.axis = .vertical
        stackView.spacing = 4
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

    override func prepareForReuse() {
        super.prepareForReuse()
        iconImageView.sd_cancelCurrentImageLoad()
        iconImageView.image = nil
        nameLabel.text = nil
        regionLabel.text = nil
    }

    // MARK: - Configuration

    func configure(with viewData: MainSoccerTopLeagueViewData) {
        let fallbackImage = UIImage(systemName: viewData.systemImageName)

        switch viewData.logoURL {
        case .some(let logoURL):
            iconImageView.sd_setImage(with: logoURL, placeholderImage: fallbackImage)

        case .none:
            iconImageView.sd_cancelCurrentImageLoad()
            iconImageView.image = fallbackImage
        }

        nameLabel.text = viewData.name
        regionLabel.text = viewData.region
    }

    // MARK: - Setup

    private func setupView() {
        contentView.addSubview(iconContainerView)
        iconContainerView.addSubview(iconImageView)
        contentView.addSubview(textStackView)

        iconContainerView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(MainSoccerHomeCardCell.LayoutMetric.contentInset)
            make.centerY.equalToSuperview()
            make.size.equalTo(LayoutMetric.iconSize)
        }

        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(LayoutMetric.iconImageSize)
        }

        textStackView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(MainSoccerHomeCardCell.LayoutMetric.contentInset)
            make.leading.equalTo(iconContainerView.snp.trailing).offset(LayoutMetric.spacing)
            make.trailing.equalToSuperview().inset(MainSoccerHomeCardCell.LayoutMetric.contentInset)
        }
    }
}

// MARK: - MainSoccerStandingCell

final class MainSoccerStandingCell: MainSoccerHomeCardCell {

    static let reuseIdentifier = "MainSoccerStandingCell"

    // MARK: - Layout Metrics

    private enum LayoutMetric {
        static let rankWidth: CGFloat = 32
        static let pointsWidth: CGFloat = 44
        static let spacing: CGFloat = 12
    }

    // MARK: - UI Components

    private let rankLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabelColor
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        return label
    }()

    private let teamLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .primaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        return label
    }()

    private let recordLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabelColor
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        return label
    }()

    private let pointsLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .primaryLabel
        label.textAlignment = .right
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        return label
    }()

    private lazy var textStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [teamLabel, recordLabel])
        stackView.axis = .vertical
        stackView.spacing = 4
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

    override func prepareForReuse() {
        super.prepareForReuse()
        rankLabel.text = nil
        teamLabel.text = nil
        recordLabel.text = nil
        pointsLabel.text = nil
    }

    // MARK: - Configuration

    func configure(with viewData: MainSoccerStandingRowViewData) {
        rankLabel.text = viewData.rankText
        teamLabel.text = viewData.teamName
        recordLabel.text = viewData.recordText
        pointsLabel.text = viewData.pointsText
    }

    // MARK: - Setup

    private func setupView() {
        contentView.addSubview(rankLabel)
        contentView.addSubview(textStackView)
        contentView.addSubview(pointsLabel)

        rankLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(MainSoccerHomeCardCell.LayoutMetric.contentInset)
            make.centerY.equalToSuperview()
            make.width.equalTo(LayoutMetric.rankWidth)
        }

        pointsLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(MainSoccerHomeCardCell.LayoutMetric.contentInset)
            make.centerY.equalToSuperview()
            make.width.equalTo(LayoutMetric.pointsWidth)
        }

        textStackView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(MainSoccerHomeCardCell.LayoutMetric.contentInset)
            make.leading.equalTo(rankLabel.snp.trailing).offset(LayoutMetric.spacing)
            make.trailing.equalTo(pointsLabel.snp.leading).offset(-LayoutMetric.spacing)
        }
    }
}
