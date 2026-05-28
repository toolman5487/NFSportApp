//
//  SoccerMatchDetailVenueCell.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/28.
//

import SnapKit
import UIKit

// MARK: - SoccerMatchDetailVenueCell

final class SoccerMatchDetailVenueCell: UICollectionViewCell {

    static let reuseIdentifier = "SoccerMatchDetailVenueCell"

    private enum LayoutMetric {
        static let contentInset: CGFloat = 16
        static let iconSize: CGFloat = 20
        static let itemSpacing: CGFloat = 12
        static let stackSpacing: CGFloat = 4
        static let verticalInset: CGFloat = 16
        static let cornerRadius: CGFloat = 12
    }

    private let iconImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "mappin.and.ellipse"))
        imageView.tintColor = .secondaryLabelColor
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabelColor
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let venueLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .primaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }()

    private lazy var textStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, venueLabel])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = LayoutMetric.stackSpacing
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
        titleLabel.text = nil
        venueLabel.text = nil
    }

    func configure(with viewData: SoccerMatchDetailVenueViewData) {
        titleLabel.text = viewData.title
        venueLabel.text = viewData.venueText
    }

    private func setupView() {
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = LayoutMetric.cornerRadius
        contentView.layer.masksToBounds = true

        contentView.addSubview(iconImageView)
        contentView.addSubview(textStackView)

        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(LayoutMetric.contentInset)
            make.top.equalToSuperview().inset(LayoutMetric.verticalInset)
            make.width.height.equalTo(LayoutMetric.iconSize)
        }

        textStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(LayoutMetric.verticalInset)
            make.leading.equalTo(iconImageView.snp.trailing).offset(LayoutMetric.itemSpacing)
            make.trailing.equalToSuperview().inset(LayoutMetric.contentInset)
            make.bottom.equalToSuperview().inset(LayoutMetric.verticalInset)
        }
    }
}
