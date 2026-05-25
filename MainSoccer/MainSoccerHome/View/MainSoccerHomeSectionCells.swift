//
//  MainSoccerHomeSectionCells.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/25.
//

import SnapKit
import UIKit

// MARK: - MainSoccerLiveHeroCell

final class MainSoccerLiveHeroCell: MainSoccerHomeCardCell {

    static let reuseIdentifier = "MainSoccerLiveHeroCell"

    // MARK: - Layout Metrics

    private enum LayoutMetric {
        static let badgeHorizontalInset: CGFloat = 8
        static let badgeVerticalInset: CGFloat = 4
        static let contentSpacing: CGFloat = 12
        static let scoreSpacing: CGFloat = 8
        static let scoreTopPadding: CGFloat = 12
        static let stackSpacing: CGFloat = 12
        static let contentInset: CGFloat = MainSoccerHomeCardCell.LayoutMetric.contentInset
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

    private let matchupLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .title3)
        label.textColor = .primaryLabel
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 2
        return label
    }()

    private let scoreLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .largeTitle)
        label.textColor = .primaryLabel
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        return label
    }()

    private let badgeContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemRed.withAlphaComponent(0.18)
        view.layer.cornerRadius = 6
        view.layer.masksToBounds = true
        return view
    }()

    private let badgeLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .systemRed
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        return label
    }()

    private lazy var headerStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [leagueLabel, badgeContainerView])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 8
        return stackView
    }()

    private lazy var scoreStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [matchupLabel, scoreLabel])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = LayoutMetric.scoreSpacing
        return stackView
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [headerStackView, scoreStackView])
        stackView.axis = .vertical
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

    override func prepareForReuse() {
        super.prepareForReuse()
        leagueLabel.text = nil
        badgeLabel.text = nil
        matchupLabel.text = nil
        scoreLabel.text = nil
    }

    // MARK: - Configuration

    func configure(with viewData: MainSoccerLiveMatchViewData) {
        leagueLabel.text = viewData.leagueName
        badgeLabel.text = viewData.minuteText
        matchupLabel.text = "\(viewData.homeTeamName) vs \(viewData.awayTeamName)"
        scoreLabel.text = viewData.scoreText
    }

    // MARK: - Setup

    private func setupView() {
        badgeContainerView.addSubview(badgeLabel)
        contentView.addSubview(contentStackView)

        leagueLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        badgeContainerView.setContentCompressionResistancePriority(.required, for: .horizontal)

        badgeLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(LayoutMetric.badgeVerticalInset)
            make.leading.trailing.equalToSuperview().inset(LayoutMetric.badgeHorizontalInset)
        }

        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(LayoutMetric.contentInset)
        }
    }
}

// MARK: - MainSoccerEmptyStateCell

final class MainSoccerEmptyStateCell: MainSoccerHomeCardCell {

    static let reuseIdentifier = "MainSoccerEmptyStateCell"

    // MARK: - UI Components

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
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
        messageLabel.text = nil
    }

    // MARK: - Configuration

    func configure(with viewData: MainSoccerEmptyStateViewData) {
        messageLabel.text = viewData.message
    }

    // MARK: - Setup

    private func setupView() {
        contentView.addSubview(messageLabel)

        messageLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(MainSoccerHomeCardCell.LayoutMetric.contentInset)
        }
    }
}

// MARK: - MainSoccerHomeSectionHeaderView

final class MainSoccerHomeSectionHeaderView: UICollectionReusableView {

    static let reuseIdentifier = "MainSoccerHomeSectionHeaderView"

    // MARK: - Layout Metrics

    private enum LayoutMetric {
        static let horizontalInset: CGFloat = 16
        static let verticalInset: CGFloat = 4
    }

    // MARK: - UI Components

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .primaryLabel
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
        titleLabel.text = nil
    }

    // MARK: - Configuration

    func configure(title: String) {
        titleLabel.text = title
    }

    // MARK: - Setup

    private func setupView() {
        addSubview(titleLabel)

        titleLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(LayoutMetric.verticalInset)
            make.leading.trailing.equalToSuperview().inset(LayoutMetric.horizontalInset)
        }
    }
}
