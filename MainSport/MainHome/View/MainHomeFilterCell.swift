//
//  MainHomeFilterCell.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/24.
//

import SkeletonView
import SnapKit
import UIKit

// MARK: - MainHomeFilterCell

final class MainHomeFilterCell: UICollectionViewCell {

    static let reuseIdentifier = "MainHomeFilterCell"

    // MARK: - Layout Metrics

    private enum LayoutMetric {
        static let optionHeight: CGFloat = 44
        static let optionMinWidth: CGFloat = 64
        static let optionHorizontalInset: CGFloat = 12
        static let iconSize: CGFloat = 14
        static let iconSpacing: CGFloat = 6
        static let optionSpacing: CGFloat = 8
        static let verticalInset: CGFloat = 8
    }

    // MARK: - Properties

    var onFilterSelected: ((MainHomeFilterOption) -> Void)?

    private var options: [MainHomeFilterOptionViewData] = []

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
            MainHomeFilterOptionCell.self,
            forCellWithReuseIdentifier: MainHomeFilterOptionCell.reuseIdentifier
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

    func configure(with viewData: MainHomeFilterViewData) {
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

extension MainHomeFilterCell: UICollectionViewDataSource {

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
            withReuseIdentifier: MainHomeFilterOptionCell.reuseIdentifier,
            for: indexPath
        ) as? MainHomeFilterOptionCell else {
            return UICollectionViewCell()
        }

        cell.configure(with: options[indexPath.item])
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension MainHomeFilterCell: UICollectionViewDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        onFilterSelected?(options[indexPath.item].option)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension MainHomeFilterCell: UICollectionViewDelegateFlowLayout {

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

// MARK: - MainHomeFilterOptionCell

private final class MainHomeFilterOptionCell: UICollectionViewCell {

    static let reuseIdentifier = "MainHomeFilterOptionCell"

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

    func configure(with viewData: MainHomeFilterOptionViewData) {
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
            make.centerY.equalToSuperview()
            titleLeadingConstraint = make.leading.equalTo(iconImageView.snp.trailing)
                .offset(LayoutMetric.iconSpacing)
                .constraint
            make.trailing.equalToSuperview().inset(LayoutMetric.horizontalInset)
        }
    }

    // MARK: - Selection State

    private func applySelectionState(_ isSelected: Bool) {
        switch isSelected {
        case true:
            contentView.backgroundColor = .primaryLabel
            contentView.layer.borderColor = UIColor.primaryLabel.cgColor
            iconImageView.tintColor = .backgroundColor
            titleLabel.textColor = .backgroundColor
            accessibilityTraits.insert(.selected)

        case false:
            contentView.backgroundColor = .secondaryBackgroundColor
            contentView.layer.borderColor = UIColor.separator.withAlphaComponent(0.36).cgColor
            iconImageView.tintColor = .primaryLabel
            titleLabel.textColor = .primaryLabel
            accessibilityTraits.remove(.selected)
        }
    }
}

// MARK: - MainHomeFilterSkeletonCell

final class MainHomeFilterSkeletonCell: UICollectionViewCell {

    static let reuseIdentifier = "MainHomeFilterSkeletonCell"

    // MARK: - Layout Metrics

    private enum LayoutMetric {
        static let optionHeight: CGFloat = 44
        static let optionSpacing: CGFloat = 8
        static let verticalInset: CGFloat = 8
    }

    // MARK: - UI Components

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: makeSkeletonOptionViews())
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fillEqually
        stackView.spacing = LayoutMetric.optionSpacing
        stackView.isSkeletonable = true
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

    override func didMoveToWindow() {
        super.didMoveToWindow()

        switch window {
        case .some:
            contentView.layoutIfNeeded()
            contentView.showAnimatedGradientSkeleton()

        case .none:
            contentView.hideSkeleton()
        }
    }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        contentView.hideSkeleton()
    }

    // MARK: - Setup

    private func setupView() {
        contentView.backgroundColor = .clear
        contentView.isSkeletonable = true
        contentView.addSubview(stackView)

        stackView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(LayoutMetric.verticalInset)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(LayoutMetric.optionHeight)
        }
    }

    // MARK: - Factory

    private func makeSkeletonOptionViews() -> [UIView] {
        (0..<4).map { _ in
            let view = MainHomeSkeletonFactory.makeSkeletonView(cornerRadius: 22)
            view.snp.makeConstraints { make in
                make.height.equalTo(LayoutMetric.optionHeight)
            }
            return view
        }
    }
}

// MARK: - MainHomeSkeletonFactory

enum MainHomeSkeletonFactory {

    static func makeSkeletonView(cornerRadius: Float = 8) -> UIView {
        let view = UIView()
        view.backgroundColor = .tertiarySystemFill
        view.isSkeletonable = true
        view.skeletonCornerRadius = cornerRadius
        view.layer.cornerRadius = CGFloat(cornerRadius)
        view.layer.masksToBounds = true
        return view
    }
}
