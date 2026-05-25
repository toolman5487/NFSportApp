//
//  MainMatchesFilterCell.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/25.
//

import SnapKit
import UIKit

// MARK: - MainMatchesFilterCell

final class MainMatchesFilterCell: UICollectionViewCell {

    static let reuseIdentifier = "MainMatchesFilterCell"

    // MARK: - Layout Metrics

    private enum LayoutMetric {
        static let optionHeight: CGFloat = 44
        static let optionMinWidth: CGFloat = 76
        static let optionHorizontalInset: CGFloat = 12
        static let iconSize: CGFloat = 14
        static let iconSpacing: CGFloat = 6
        static let optionSpacing: CGFloat = 8
        static let verticalInset: CGFloat = 8
    }

    // MARK: - Properties

    var onFilterSelected: ((MainMatchesFilterOption) -> Void)?

    private var options: [MainMatchesFilterOptionViewData] = []

    // MARK: - UI Components

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
            MainMatchesFilterOptionCell.self,
            forCellWithReuseIdentifier: MainMatchesFilterOptionCell.reuseIdentifier
        )
        return collectionView
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
        onFilterSelected = nil
    }

    // MARK: - Configuration

    func configure(with viewData: MainMatchesFilterViewData) {
        options = viewData.options
        collectionView.reloadData()
    }

    // MARK: - Setup

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

// MARK: - UICollectionViewDataSource

extension MainMatchesFilterCell: UICollectionViewDataSource {

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
            withReuseIdentifier: MainMatchesFilterOptionCell.reuseIdentifier,
            for: indexPath
        ) as? MainMatchesFilterOptionCell else {
            return UICollectionViewCell()
        }

        cell.configure(with: options[indexPath.item])
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension MainMatchesFilterCell: UICollectionViewDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        onFilterSelected?(options[indexPath.item].option)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension MainMatchesFilterCell: UICollectionViewDelegateFlowLayout {

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let option = options[indexPath.item]
        let font = UIFont.preferredFont(forTextStyle: .subheadline)
        let titleWidth = (option.title as NSString).size(withAttributes: [.font: font]).width
        let iconWidth = option.systemImageName == nil
            ? 0
            : LayoutMetric.iconSize + LayoutMetric.iconSpacing
        let width = max(
            LayoutMetric.optionMinWidth,
            ceil(titleWidth) + iconWidth + LayoutMetric.optionHorizontalInset * 2
        )

        return CGSize(width: width, height: LayoutMetric.optionHeight)
    }
}

// MARK: - MainMatchesFilterOptionCell

private final class MainMatchesFilterOptionCell: UICollectionViewCell {

    static let reuseIdentifier = "MainMatchesFilterOptionCell"

    // MARK: - Layout Metrics

    private enum LayoutMetric {
        static let horizontalInset: CGFloat = 12
        static let iconSize: CGFloat = 14
        static let iconSpacing: CGFloat = 6
        static let borderWidth: CGFloat = 1
    }

    // MARK: - Properties

    private var iconWidthConstraint: Constraint?
    private var titleLeadingConstraint: Constraint?

    // MARK: - UI Components

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
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(
            pointSize: 12,
            weight: .semibold
        )
        imageView.isHidden = true
        return imageView
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
        iconImageView.image = nil
        iconImageView.isHidden = true
        titleLabel.text = nil
        accessibilityTraits.remove(.selected)
    }

    // MARK: - Configuration

    func configure(with viewData: MainMatchesFilterOptionViewData) {
        if let systemImageName = viewData.systemImageName {
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

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.layer.cornerRadius = contentView.bounds.height / 2
    }

    // MARK: - Setup

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

    // MARK: - State

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
