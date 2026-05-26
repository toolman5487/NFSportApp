//
//  MainSoccerMatchesDatePickerCell.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/26.
//

import SnapKit
import UIKit

// MARK: - MainSoccerMatchesDatePickerCell

final class MainSoccerMatchesDatePickerCell: UICollectionViewCell {

    static let reuseIdentifier = "MainSoccerMatchesDatePickerCell"

    private enum LayoutMetric {
        static let itemHeight: CGFloat = 72
        static let itemSpacing: CGFloat = 4
        static let verticalInset: CGFloat = 8
        static let headerHeight: CGFloat = 32
        static let headerBottomSpacing: CGFloat = 8
        static let pageButtonSize: CGFloat = 32
        static let pageButtonCornerRadius: CGFloat = 8
        static let headerSpacing: CGFloat = 8
    }

    var onDateSelected: ((Date) -> Void)?
    var onPreviousPageSelected: (() -> Void)?
    var onNextPageSelected: (() -> Void)?

    private var dates: [MainSoccerMatchesDateItemViewData] = []

    private let previousPageButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = .primaryLabel
        button.backgroundColor = .secondaryBackgroundColor
        button.layer.cornerRadius = LayoutMetric.pageButtonCornerRadius
        button.layer.masksToBounds = true
        return button
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .primaryLabel
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        return label
    }()

    private let nextPageButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        button.tintColor = .primaryLabel
        button.backgroundColor = .secondaryBackgroundColor
        button.layer.cornerRadius = LayoutMetric.pageButtonCornerRadius
        button.layer.masksToBounds = true
        return button
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = LayoutMetric.itemSpacing
        layout.minimumInteritemSpacing = LayoutMetric.itemSpacing

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = false
        collectionView.isScrollEnabled = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            MainSoccerMatchesDateItemCell.self,
            forCellWithReuseIdentifier: MainSoccerMatchesDateItemCell.reuseIdentifier
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
        onDateSelected = nil
        onPreviousPageSelected = nil
        onNextPageSelected = nil
    }

    func configure(with viewData: MainSoccerMatchesDatePickerViewData) {
        titleLabel.text = viewData.title
        dates = viewData.dates
        collectionView.reloadData()
    }

    private func setupView() {
        contentView.backgroundColor = .clear
        contentView.addSubview(previousPageButton)
        contentView.addSubview(titleLabel)
        contentView.addSubview(nextPageButton)
        contentView.addSubview(collectionView)

        previousPageButton.addTarget(
            self,
            action: #selector(handlePreviousPageButtonTap),
            for: .touchUpInside
        )
        nextPageButton.addTarget(
            self,
            action: #selector(handleNextPageButtonTap),
            for: .touchUpInside
        )

        previousPageButton.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(LayoutMetric.verticalInset)
            make.leading.equalToSuperview()
            make.width.height.equalTo(LayoutMetric.pageButtonSize)
        }

        nextPageButton.snp.makeConstraints { make in
            make.top.equalTo(previousPageButton)
            make.trailing.equalToSuperview()
            make.width.height.equalTo(LayoutMetric.pageButtonSize)
        }

        titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(previousPageButton)
            make.leading.equalTo(previousPageButton.snp.trailing).offset(LayoutMetric.headerSpacing)
            make.trailing.equalTo(nextPageButton.snp.leading).offset(-LayoutMetric.headerSpacing)
            make.height.equalTo(LayoutMetric.headerHeight)
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(previousPageButton.snp.bottom).offset(LayoutMetric.headerBottomSpacing)
            make.bottom.equalToSuperview().inset(LayoutMetric.verticalInset)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(LayoutMetric.itemHeight)
        }
    }

    @objc
    private func handlePreviousPageButtonTap() {
        onPreviousPageSelected?()
    }

    @objc
    private func handleNextPageButtonTap() {
        onNextPageSelected?()
    }
}

extension MainSoccerMatchesDatePickerCell: UICollectionViewDataSource {

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        dates.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MainSoccerMatchesDateItemCell.reuseIdentifier,
            for: indexPath
        ) as? MainSoccerMatchesDateItemCell else {
            return UICollectionViewCell()
        }

        cell.configure(with: dates[indexPath.item])
        return cell
    }
}

extension MainSoccerMatchesDatePickerCell: UICollectionViewDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        onDateSelected?(dates[indexPath.item].date)
    }
}

extension MainSoccerMatchesDatePickerCell: UICollectionViewDelegateFlowLayout {

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let itemCount = max(dates.count, 1)
        let totalSpacing = LayoutMetric.itemSpacing * CGFloat(itemCount - 1)
        let width = max(1, floor((collectionView.bounds.width - totalSpacing) / CGFloat(itemCount)))
        return CGSize(width: width, height: LayoutMetric.itemHeight)
    }
}

private final class MainSoccerMatchesDateItemCell: UICollectionViewCell {

    static let reuseIdentifier = "MainSoccerMatchesDateItemCell"

    private enum LayoutMetric {
        static let cornerRadius: CGFloat = 8
        static let borderWidth: CGFloat = 1
        static let verticalInset: CGFloat = 8
        static let horizontalInset: CGFloat = 8
        static let stackSpacing: CGFloat = 4
    }

    private let weekdayLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption2)
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let dayLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .title3)
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let monthLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption2)
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [weekdayLabel, dayLabel, monthLabel])
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
        weekdayLabel.text = nil
        dayLabel.text = nil
        monthLabel.text = nil
        accessibilityTraits.remove(.selected)
    }

    func configure(with viewData: MainSoccerMatchesDateItemViewData) {
        weekdayLabel.text = viewData.weekdayText
        dayLabel.text = viewData.dayText
        monthLabel.text = viewData.monthText
        applySelectionState(viewData.isSelected)
    }

    private func setupView() {
        isAccessibilityElement = true
        accessibilityTraits = .button

        contentView.layer.cornerRadius = LayoutMetric.cornerRadius
        contentView.layer.masksToBounds = true
        contentView.layer.borderWidth = LayoutMetric.borderWidth
        contentView.addSubview(stackView)

        stackView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(LayoutMetric.verticalInset)
            make.leading.trailing.equalToSuperview().inset(LayoutMetric.horizontalInset)
        }
    }

    private func applySelectionState(_ isSelected: Bool) {
        switch isSelected {
        case true:
            contentView.backgroundColor = .primaryLabel
            contentView.layer.borderColor = UIColor.primaryLabel.cgColor
            weekdayLabel.textColor = .backgroundColor
            dayLabel.textColor = .backgroundColor
            monthLabel.textColor = .backgroundColor
            accessibilityTraits.insert(.selected)

        case false:
            contentView.backgroundColor = .secondaryBackgroundColor
            contentView.layer.borderColor = UIColor.separator.withAlphaComponent(0.24).cgColor
            weekdayLabel.textColor = .secondaryLabelColor
            dayLabel.textColor = .primaryLabel
            monthLabel.textColor = .tertiaryLabel
        }
    }
}
