//
//  MainSoccerMatchesFilterCell.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/26.
//

import SDWebImage
import SnapKit
import UIKit

// MARK: - MainSoccerMatchesFilterCell

final class MainSoccerMatchesFilterCell: UICollectionViewCell {

    static let reuseIdentifier = "MainSoccerMatchesFilterCell"

    private enum LayoutMetric {
        static let optionHeight: CGFloat = 44
        static let optionMinWidth: CGFloat = 44
        static let optionHorizontalInset: CGFloat = 12
        static let iconSize: CGFloat = 24
        static let iconSpacing: CGFloat = 8
        static let optionSpacing: CGFloat = 8
        static let verticalInset: CGFloat = 8
    }

    var onFilterSelected: ((MainSoccerMatchesFilterOption) -> Void)?

    private var options: [MainSoccerMatchesFilterOptionViewData] = []

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = LayoutMetric.optionSpacing
        layout.minimumInteritemSpacing = LayoutMetric.optionSpacing

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            MainSoccerMatchesFilterOptionCell.self,
            forCellWithReuseIdentifier: MainSoccerMatchesFilterOptionCell.reuseIdentifier
        )
        return collectionView
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
        onFilterSelected = nil
    }

    func configure(with viewData: MainSoccerMatchesFilterViewData) {
        options = viewData.options
        collectionView.reloadData()
    }

    private func setupView() {
        contentView.backgroundColor = .clear
        contentView.addSubview(collectionView)

        collectionView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(LayoutMetric.verticalInset)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(LayoutMetric.optionHeight)
        }
    }
}

extension MainSoccerMatchesFilterCell: UICollectionViewDataSource {

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        options.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MainSoccerMatchesFilterOptionCell.reuseIdentifier,
            for: indexPath
        ) as? MainSoccerMatchesFilterOptionCell else {
            return UICollectionViewCell()
        }

        cell.configure(with: options[indexPath.item])
        return cell
    }
}

extension MainSoccerMatchesFilterCell: UICollectionViewDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        onFilterSelected?(options[indexPath.item].option)
    }
}

extension MainSoccerMatchesFilterCell: UICollectionViewDelegateFlowLayout {

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let option = options[indexPath.item]
        let font = UIFont.preferredFont(forTextStyle: .subheadline)
        let titleWidth = (option.title as NSString).size(withAttributes: [.font: font]).width
        let iconWidth = option.systemImageName == nil && option.logoURL == nil
            ? 0
            : LayoutMetric.iconSize + LayoutMetric.iconSpacing
        let width = max(
            LayoutMetric.optionMinWidth,
            ceil(titleWidth) + iconWidth + LayoutMetric.optionHorizontalInset * 2
        )

        return CGSize(width: width, height: LayoutMetric.optionHeight)
    }
}

private final class MainSoccerMatchesFilterOptionCell: UICollectionViewCell {

    static let reuseIdentifier = "MainSoccerMatchesFilterOptionCell"

    private enum LayoutMetric {
        static let iconSize: CGFloat = 24
        static let horizontalInset: CGFloat = 12
        static let iconSpacing: CGFloat = 8
        static let borderWidth: CGFloat = 1
    }

    private var iconWidthConstraint: Constraint?
    private var titleLeadingConstraint: Constraint?

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = false
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(
            pointSize: 18,
            weight: .semibold
        )
        imageView.isHidden = true
        return imageView
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
        iconImageView.sd_cancelCurrentImageLoad()
        iconImageView.image = nil
        iconImageView.isHidden = true
        titleLabel.text = nil
        accessibilityTraits.remove(.selected)
    }

    func configure(with viewData: MainSoccerMatchesFilterOptionViewData) {
        if let logoURL = viewData.logoURL {
            iconImageView.sd_setImage(with: logoURL)
            iconImageView.tintColor = nil
            iconImageView.isHidden = false
            iconWidthConstraint?.update(offset: LayoutMetric.iconSize)
            titleLeadingConstraint?.update(offset: LayoutMetric.iconSpacing)
        } else if let systemImageName = viewData.systemImageName {
            iconImageView.image = UIImage(systemName: systemImageName)
            iconImageView.isHidden = false
            iconWidthConstraint?.update(offset: LayoutMetric.iconSize)
            titleLeadingConstraint?.update(offset: LayoutMetric.iconSpacing)
        } else {
            iconImageView.image = nil
            iconImageView.isHidden = true
            iconWidthConstraint?.update(offset: 0)
            titleLeadingConstraint?.update(offset: 0)
        }

        titleLabel.text = viewData.title
        applySelectionState(viewData.isSelected)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.layer.cornerRadius = contentView.bounds.height / 2
    }

    private func setupView() {
        isAccessibilityElement = true
        accessibilityTraits = .button

        contentView.layer.masksToBounds = true
        contentView.layer.borderWidth = LayoutMetric.borderWidth
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)

        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(LayoutMetric.horizontalInset)
            make.centerY.equalToSuperview()
            iconWidthConstraint = make.width.equalTo(LayoutMetric.iconSize).constraint
            make.height.equalTo(LayoutMetric.iconSize)
        }

        titleLabel.snp.makeConstraints { make in
            titleLeadingConstraint = make.leading.equalTo(iconImageView.snp.trailing)
                .offset(LayoutMetric.iconSpacing)
                .constraint
            make.trailing.equalToSuperview().inset(LayoutMetric.horizontalInset)
            make.centerY.equalToSuperview()
        }
    }

    private func applySelectionState(_ isSelected: Bool) {
        switch isSelected {
        case true:
            contentView.backgroundColor = .primaryLabel
            contentView.layer.borderColor = UIColor.primaryLabel.cgColor
            titleLabel.textColor = .backgroundColor
            iconImageView.tintColor = .backgroundColor
            accessibilityTraits.insert(.selected)

        case false:
            contentView.backgroundColor = .secondaryBackgroundColor
            contentView.layer.borderColor = UIColor.separator.withAlphaComponent(0.24).cgColor
            titleLabel.textColor = .primaryLabel
            iconImageView.tintColor = .secondaryLabelColor
        }
    }
}
