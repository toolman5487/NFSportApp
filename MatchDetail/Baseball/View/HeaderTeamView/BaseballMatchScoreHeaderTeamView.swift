//
//  BaseballMatchScoreHeaderTeamView.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/28.
//

import SDWebImage
import SnapKit
import UIKit

// MARK: - BaseballMatchScoreHeaderTeamView

final class BaseballMatchScoreHeaderTeamView: UIView {

    // MARK: - Layout Metrics

    private enum LayoutMetric {
        static let spacing: CGFloat = 8
        static let logoSize: CGFloat = 40
    }

    // MARK: - UI Components

    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.isHidden = true
        return imageView
    }()

    private let teamNameLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .primaryLabel
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 2
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

    // MARK: - Configuration

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

    // MARK: - Setup

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

