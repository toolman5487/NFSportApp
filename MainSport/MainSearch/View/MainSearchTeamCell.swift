//
//  MainSearchTeamCell.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/26.
//

import SDWebImage
import SnapKit
import UIKit

final class MainSearchTeamCell: UICollectionViewCell {

    // MARK: - Constants

    static let reuseIdentifier = "MainSearchTeamCell"

    private enum LayoutMetric {
        static let contentInset: CGFloat = 16
        static let logoSize: CGFloat = 44
        static let cornerRadius: CGFloat = 8
        static let spacing: CGFloat = 12
        static let textSpacing: CGFloat = 4
    }

    // MARK: - UI Components

    private let logoBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .tertiarySystemBackground
        view.layer.cornerRadius = LayoutMetric.logoSize / 2
        return view
    }()

    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.tintColor = .secondaryLabelColor
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .primaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 2
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabelColor
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        return label
    }()

    private lazy var textStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [nameLabel, subtitleLabel])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = LayoutMetric.textSpacing
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

    // MARK: - Lifecycle

    override func prepareForReuse() {
        super.prepareForReuse()
        logoImageView.sd_cancelCurrentImageLoad()
        logoImageView.image = nil
        nameLabel.text = nil
        subtitleLabel.text = nil
    }

    // MARK: - Public Methods

    func configure(with viewData: MainSearchTeamViewData) {
        nameLabel.text = viewData.name
        subtitleLabel.text = viewData.subtitle

        let fallbackImage = UIImage(systemName: viewData.fallbackSystemImageName)

        if let logoURL = viewData.logoURL {
            logoImageView.sd_setImage(
                with: logoURL,
                placeholderImage: fallbackImage
            )
        } else {
            logoImageView.image = fallbackImage
        }
    }

    // MARK: - Setup

    private func setupView() {
        contentView.backgroundColor = .secondaryBackgroundColor
        contentView.layer.cornerRadius = LayoutMetric.cornerRadius
        contentView.layer.masksToBounds = true

        contentView.addSubview(logoBackgroundView)
        logoBackgroundView.addSubview(logoImageView)
        contentView.addSubview(textStackView)

        logoBackgroundView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(LayoutMetric.contentInset)
            make.centerY.equalToSuperview()
            make.size.equalTo(LayoutMetric.logoSize)
        }

        logoImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }

        textStackView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(LayoutMetric.contentInset)
            make.leading.equalTo(logoBackgroundView.snp.trailing).offset(LayoutMetric.spacing)
            make.trailing.equalToSuperview().inset(LayoutMetric.contentInset)
        }
    }
}
