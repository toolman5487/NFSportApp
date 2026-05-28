//
//  MstchBaseVenueCell.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/28.
//

import SnapKit
import UIKit

class MatchBaseVenueFooterView: UICollectionReusableView {

    private enum LayoutMetric {
        static let contentInset: CGFloat = 16
        static let iconSize: CGFloat = 16
        static let itemSpacing: CGFloat = 12
        static let verticalInset: CGFloat = 16
        static let cornerRadius: CGFloat = 12
    }
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "mappin.and.ellipse"))
        imageView.tintColor = .systemRed
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let venueLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .primaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [iconImageView, venueLabel])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = LayoutMetric.itemSpacing
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
        venueLabel.text = nil
    }

    func configureVenueText(_ text: String) {
        venueLabel.text = text
    }

    private func setupView() {
        backgroundColor = .systemBackground

        addSubview(contentStackView)

        iconImageView.snp.makeConstraints { make in
            make.width.height.equalTo(LayoutMetric.iconSize)
        }

        contentStackView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(LayoutMetric.verticalInset)
            make.leading.trailing.equalToSuperview().inset(LayoutMetric.contentInset)
        }
    }
}
