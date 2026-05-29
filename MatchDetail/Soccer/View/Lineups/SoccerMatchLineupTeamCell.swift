//
//  SoccerMatchLineupTeamCell.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/29.
//

import SnapKit
import UIKit

// MARK: - SoccerMatchLineupTeamCell

final class SoccerMatchLineupTeamCell: UICollectionViewCell {

    // MARK: - Constants

    static let reuseIdentifier = "SoccerMatchLineupTeamCell"

    // MARK: - Layout Metrics

    private enum LayoutMetric {
        static let horizontalInset: CGFloat = 16
        static let verticalInset: CGFloat = 12
        static let rowSpacing: CGFloat = 8
    }

    // MARK: - UI Components

    private let teamNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .primaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }()

    private let metaLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .secondaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }()

    private let startersTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .primaryLabel
        label.text = "Starters"
        return label
    }()

    private let startersLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .primaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }()

    private let substitutesTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .primaryLabel
        label.text = "Substitutes"
        return label
    }()

    private let substitutesLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .primaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
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

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        teamNameLabel.text = nil
        metaLabel.text = nil
        metaLabel.isHidden = true
        startersLabel.text = nil
        substitutesTitleLabel.isHidden = true
        substitutesLabel.text = nil
        substitutesLabel.isHidden = true
    }

    // MARK: - Configuration

    func configure(with viewData: SoccerMatchDetailLineupViewData) {
        teamNameLabel.text = viewData.teamName

        var metaParts: [String] = []
        if let formation = viewData.formationText, !formation.isEmpty {
            metaParts.append("Formation: \(formation)")
        }
        if let coach = viewData.coachName, !coach.isEmpty {
            metaParts.append("Coach: \(coach)")
        }

        if metaParts.isEmpty {
            metaLabel.isHidden = true
        } else {
            metaLabel.text = metaParts.joined(separator: " · ")
            metaLabel.isHidden = false
        }

        startersLabel.text = formatPlayers(viewData.starters)

        switch viewData.layoutState {
        case .startersOnly:
            substitutesTitleLabel.isHidden = true
            substitutesLabel.isHidden = true
            substitutesLabel.text = nil

        case .withSubstitutes:
            substitutesTitleLabel.isHidden = false
            substitutesLabel.isHidden = false
            substitutesLabel.text = formatPlayers(viewData.substitutes)
        }

        updateLineupConstraints(for: viewData.layoutState)
    }

    // MARK: - Setup

    private func setupView() {
        contentView.backgroundColor = .secondaryBackgroundColor
        contentView.layer.cornerRadius = 12

        contentView.addSubview(teamNameLabel)
        contentView.addSubview(metaLabel)
        contentView.addSubview(startersTitleLabel)
        contentView.addSubview(startersLabel)
        contentView.addSubview(substitutesTitleLabel)
        contentView.addSubview(substitutesLabel)

        teamNameLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(LayoutMetric.horizontalInset)
        }

        metaLabel.snp.makeConstraints { make in
            make.top.equalTo(teamNameLabel.snp.bottom).offset(4)
            make.leading.trailing.equalTo(teamNameLabel)
        }

    }

    private func updateLineupConstraints(for layoutState: SoccerMatchLineupLayoutState) {
        let startersTopAnchor = metaLabel.isHidden
            ? teamNameLabel.snp.bottom
            : metaLabel.snp.bottom

        startersTitleLabel.snp.remakeConstraints { make in
            make.top.equalTo(startersTopAnchor).offset(LayoutMetric.rowSpacing)
            make.leading.trailing.equalTo(teamNameLabel)
        }

        switch layoutState {
        case .startersOnly:
            startersLabel.snp.remakeConstraints { make in
                make.top.equalTo(startersTitleLabel.snp.bottom).offset(4)
                make.leading.trailing.equalTo(teamNameLabel)
                make.bottom.equalToSuperview().inset(LayoutMetric.verticalInset)
            }

            substitutesTitleLabel.snp.remakeConstraints { make in
                make.leading.trailing.equalTo(teamNameLabel)
            }

            substitutesLabel.snp.remakeConstraints { make in
                make.leading.trailing.equalTo(teamNameLabel)
            }

        case .withSubstitutes:
            startersLabel.snp.remakeConstraints { make in
                make.top.equalTo(startersTitleLabel.snp.bottom).offset(4)
                make.leading.trailing.equalTo(teamNameLabel)
            }

            substitutesTitleLabel.snp.remakeConstraints { make in
                make.top.equalTo(startersLabel.snp.bottom).offset(LayoutMetric.rowSpacing)
                make.leading.trailing.equalTo(teamNameLabel)
            }

            substitutesLabel.snp.remakeConstraints { make in
                make.top.equalTo(substitutesTitleLabel.snp.bottom).offset(4)
                make.leading.trailing.equalTo(teamNameLabel)
                make.bottom.equalToSuperview().inset(LayoutMetric.verticalInset)
            }
        }
    }

    private func formatPlayers(_ players: [String]) -> String {
        guard !players.isEmpty else {
            return "-"
        }

        return players.joined(separator: "\n")
    }
}
