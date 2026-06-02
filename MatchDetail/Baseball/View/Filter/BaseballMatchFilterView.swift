//
//  BaseballMatchFilterView.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/28.
//

import SDWebImage
import SnapKit
import UIKit

// MARK: - BaseballMatchFilterView

final class BaseballMatchFilterView: UICollectionReusableView {

    // MARK: - Constants

    static let reuseIdentifier = "BaseballMatchFilterView"

    // MARK: - Layout Metrics

    private enum LayoutMetric {
        static let contentInset: CGFloat = 16
        static let optionHeight: CGFloat = 44
        static let optionSpacing: CGFloat = 8
        static let verticalInset: CGFloat = 4
    }

    static var preferredHeight: CGFloat {
        LayoutMetric.verticalInset * 2 + LayoutMetric.optionHeight
    }

    // MARK: - Properties

    var onFilterChanged: ((BaseballMatchFilterOption) -> Void)?

    private let options = BaseballMatchFilterOption.allCases
    private var selectedOption: BaseballMatchFilterOption = .total
    private var homeTeamName: String?
    private var homeTeamLogoURL: URL?
    private var awayTeamName: String?
    private var awayTeamLogoURL: URL?

    // MARK: - UI Components

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = LayoutMetric.optionSpacing
        layout.minimumInteritemSpacing = LayoutMetric.optionSpacing
        layout.sectionInset = UIEdgeInsets(
            top: 0,
            left: LayoutMetric.contentInset,
            bottom: 0,
            right: LayoutMetric.contentInset
        )

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.bounces = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            BaseballMatchFilterOptionCell.self,
            forCellWithReuseIdentifier: BaseballMatchFilterOptionCell.reuseIdentifier
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

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    // MARK: - Configuration

    override func prepareForReuse() {
        super.prepareForReuse()
        onFilterChanged = nil
        selectedOption = .total
        homeTeamName = nil
        homeTeamLogoURL = nil
        awayTeamName = nil
        awayTeamLogoURL = nil
    }

    func configure(
        selectedOption: BaseballMatchFilterOption,
        homeTeamName: String?,
        homeTeamLogoURL: URL?,
        awayTeamName: String?,
        awayTeamLogoURL: URL?
    ) {
        self.selectedOption = selectedOption
        self.homeTeamName = homeTeamName
        self.homeTeamLogoURL = homeTeamLogoURL
        self.awayTeamName = awayTeamName
        self.awayTeamLogoURL = awayTeamLogoURL
        collectionView.reloadData()
    }

    // MARK: - Setup

    private func setupView() {
        backgroundColor = .systemBackground

        addSubview(collectionView)

        collectionView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview().inset(LayoutMetric.verticalInset)
            make.height.equalTo(LayoutMetric.optionHeight)
        }
    }
}

// MARK: - UICollectionViewDataSource

extension BaseballMatchFilterView: UICollectionViewDataSource {

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
            withReuseIdentifier: BaseballMatchFilterOptionCell.reuseIdentifier,
            for: indexPath
        ) as? BaseballMatchFilterOptionCell else {
            return UICollectionViewCell()
        }

        let option = options[indexPath.item]
        let title = option.title(homeTeamName: homeTeamName, awayTeamName: awayTeamName)
        let logoURL: URL?

        switch option {
        case .total:
            logoURL = nil
        case .home:
            logoURL = homeTeamLogoURL
        case .away:
            logoURL = awayTeamLogoURL
        }

        cell.configure(title: title, logoURL: logoURL, isSelected: option == selectedOption)
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension BaseballMatchFilterView: UICollectionViewDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        let option = options[indexPath.item]
        guard option != selectedOption else {
            return
        }

        selectedOption = option
        collectionView.reloadData()
        onFilterChanged?(option)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension BaseballMatchFilterView: UICollectionViewDelegateFlowLayout {

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let sectionInset = LayoutMetric.contentInset
        let spacing = LayoutMetric.optionSpacing
        let itemCount = CGFloat(options.count)
        let totalSpacing = spacing * max(0, itemCount - 1)
        let availableWidth = collectionView.bounds.width - sectionInset * 2 - totalSpacing
        let itemWidth = floor(availableWidth / itemCount)

        return CGSize(width: itemWidth, height: LayoutMetric.optionHeight)
    }
}

// MARK: - BaseballMatchFilterOptionCell

private final class BaseballMatchFilterOptionCell: UICollectionViewCell {

    // MARK: - Constants

    static let reuseIdentifier = "BaseballMatchFilterOptionCell"

    // MARK: - Layout Metrics

    private enum LayoutMetric {
        static let logoSize: CGFloat = 24
        static let horizontalInset: CGFloat = 8
        static let borderWidth: CGFloat = 1
    }

    // MARK: - UI Components

    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.82
        label.numberOfLines = 1
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
        logoImageView.sd_cancelCurrentImageLoad()
        logoImageView.image = nil
        logoImageView.isHidden = true
        titleLabel.text = nil
        titleLabel.isHidden = false
        accessibilityTraits.remove(.selected)
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.layer.cornerRadius = contentView.bounds.height / 2
    }

    // MARK: - Configuration

    func configure(title: String, logoURL: URL?, isSelected: Bool) {
        if let logoURL {
            logoImageView.sd_setImage(with: logoURL)
            logoImageView.isHidden = false
            titleLabel.isHidden = true
        } else {
            logoImageView.sd_cancelCurrentImageLoad()
            logoImageView.image = nil
            logoImageView.isHidden = true
            titleLabel.text = title
            titleLabel.isHidden = false
        }

        accessibilityLabel = title
        applySelectionState(isSelected)
    }

    // MARK: - Setup

    private func setupView() {
        isAccessibilityElement = true
        accessibilityTraits = .button

        contentView.layer.masksToBounds = true
        contentView.layer.borderWidth = LayoutMetric.borderWidth
        contentView.addSubview(logoImageView)
        contentView.addSubview(titleLabel)

        logoImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(LayoutMetric.logoSize)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(LayoutMetric.horizontalInset)
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
            accessibilityTraits.insert(.selected)

        case false:
            contentView.backgroundColor = .secondaryBackgroundColor
            contentView.layer.borderColor = UIColor.separator.withAlphaComponent(0.24).cgColor
            titleLabel.textColor = .primaryLabel
        }
    }
}
