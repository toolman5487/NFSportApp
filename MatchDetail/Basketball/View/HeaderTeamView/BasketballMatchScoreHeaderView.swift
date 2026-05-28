//
//  BasketballMatchScoreHeaderCell.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/27.
//

import SnapKit
import UIKit

// MARK: - BasketballMatchScoreHeaderView

final class BasketballMatchScoreHeaderView: UICollectionReusableView {

    static let reuseIdentifier = "BasketballMatchScoreHeaderView"

    private enum LayoutMetric {
        static let cardCornerRadius: CGFloat = 12
        static let contentInset: CGFloat = 16
        static let compactSpacing: CGFloat = 8
        static let teamSpacing: CGFloat = 12
        static let minimumScoreWidth: CGFloat = 120
        static let minimumScoreLabelWidth: CGFloat = 44
    }

    private let homeTeamView = BasketballMatchScoreHeaderTeamView()
    private let awayTeamView = BasketballMatchScoreHeaderTeamView()

    private let homeScoreLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .title1)
        label.textColor = .primaryLabel
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let scoreDividerLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .title1)
        label.textColor = .secondaryLabelColor
        label.textAlignment = .center
        label.text = "-"
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let awayScoreLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .title1)
        label.textColor = .primaryLabel
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private lazy var scoreStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [homeScoreLabel, scoreDividerLabel, awayScoreLabel])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
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
        homeScoreLabel.text = nil
        awayScoreLabel.text = nil
        homeTeamView.prepareForReuse()
        awayTeamView.prepareForReuse()
    }

    func configure(with viewData: BasketballMatchDetailHeaderViewData) {
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
    }

    private func setupView() {
        backgroundColor = .systemBackground

        homeScoreLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        awayScoreLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        scoreDividerLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        homeTeamView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        awayTeamView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        addSubview(homeTeamView)
        addSubview(scoreStackView)
        addSubview(awayTeamView)

        homeScoreLabel.snp.makeConstraints { make in
            make.width.equalTo(awayScoreLabel)
            make.width.greaterThanOrEqualTo(LayoutMetric.minimumScoreLabelWidth)
        }

        homeTeamView.snp.makeConstraints { make in
            make.top.leading.bottom.equalToSuperview().inset(LayoutMetric.contentInset)
        }

        scoreStackView.snp.makeConstraints { make in
            make.leading.equalTo(homeTeamView.snp.trailing).offset(LayoutMetric.teamSpacing)
            make.centerY.equalTo(homeTeamView)
            make.width.greaterThanOrEqualTo(LayoutMetric.minimumScoreWidth)
        }

        awayTeamView.snp.makeConstraints { make in
            make.leading.equalTo(scoreStackView.snp.trailing).offset(LayoutMetric.teamSpacing)
            make.trailing.equalToSuperview().inset(LayoutMetric.contentInset)
            make.top.bottom.equalTo(homeTeamView)
            make.width.equalTo(homeTeamView)
        }
    }
}
