//
//  MatchBaseViewController.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/26.
//

import SDWebImage
import SnapKit
import UIKit

// MARK: - MatchBaseViewController

@MainActor
class MatchBaseViewController: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    // MARK: - Layout Metrics

    private enum LayoutMetric {
        static let sectionInset: CGFloat = 8
        static let interGroupSpacing: CGFloat = 8
        static let estimatedItemHeight: CGFloat = 56
    }

    // MARK: - Properties

    private(set) lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: makeCollectionViewLayout()
        )
        collectionView.backgroundColor = .systemBackground
        collectionView.alwaysBounceVertical = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.contentInsetAdjustmentBehavior = .automatic
        collectionView.keyboardDismissMode = .onDrag
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()

    // MARK: - Override Points

    final override func setupNavigation() {
        super.setupNavigation()

        setupMatchNavigation()
    }

    final override func setupView() {
        super.setupView()

        view.addSubview(collectionView)
        registerReusableViews()
        configureCollectionView()
        setupContentView()
    }

    final override func setupConstraints() {
        super.setupConstraints()

        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        setupContentConstraints()
    }

    func setupMatchNavigation() {}

    func registerReusableViews() {}

    func configureCollectionView() {}

    func setupContentView() {}

    func setupContentConstraints() {}

    func handleMatchScrollDidScroll(_ scrollView: UIScrollView) {}

    func makeCollectionViewLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { [weak self] sectionIndex, environment in
            self?.makeSectionLayout(for: sectionIndex, environment: environment)
        }
    }

    func makeSectionLayout(
        for sectionIndex: Int,
        environment: NSCollectionLayoutEnvironment
    ) -> NSCollectionLayoutSection {
        makeListSectionLayout()
    }

    func makeListSectionLayout(
        itemHeight: NSCollectionLayoutDimension = .estimated(LayoutMetric.estimatedItemHeight),
        contentInsets: NSDirectionalEdgeInsets = NSDirectionalEdgeInsets(
            top: LayoutMetric.sectionInset,
            leading: LayoutMetric.sectionInset,
            bottom: LayoutMetric.sectionInset,
            trailing: LayoutMetric.sectionInset
        ),
        interGroupSpacing: CGFloat = LayoutMetric.interGroupSpacing
    ) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: itemHeight
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = contentInsets
        section.interGroupSpacing = interGroupSpacing
        return section
    }

    func isLastSection(_ sectionIndex: Int, numberOfSections: Int) -> Bool {
        numberOfSections > 0 && sectionIndex == numberOfSections - 1
    }

    func shouldShowVenueFooter(
        at sectionIndex: Int,
        numberOfSections: Int,
        hasVenue: Bool
    ) -> Bool {
        isLastSection(sectionIndex, numberOfSections: numberOfSections) && hasVenue
    }

    func makeVenueFooterBoundaryItem(
        estimatedHeight: CGFloat
    ) -> NSCollectionLayoutBoundarySupplementaryItem {
        let footerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(estimatedHeight)
        )
        return NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: footerSize,
            elementKind: UICollectionView.elementKindSectionFooter,
            alignment: .bottom
        )
    }

    func appendVenueFooterIfNeeded(
        to section: NSCollectionLayoutSection,
        sectionIndex: Int,
        numberOfSections: Int,
        hasVenue: Bool,
        estimatedHeight: CGFloat
    ) -> NSCollectionLayoutSection {
        guard shouldShowVenueFooter(
            at: sectionIndex,
            numberOfSections: numberOfSections,
            hasVenue: hasVenue
        ) else {
            return section
        }

        var boundaryItems = section.boundarySupplementaryItems
        boundaryItems.append(makeVenueFooterBoundaryItem(estimatedHeight: estimatedHeight))
        section.boundarySupplementaryItems = boundaryItems
        return section
    }

    var isScrolledAwayFromTop: Bool {
        collectionView.contentOffset.y > -collectionView.adjustedContentInset.top
    }

    func scrollToTop(animated: Bool) {
        let topContentOffset = CGPoint(
            x: 0,
            y: -collectionView.adjustedContentInset.top
        )
        collectionView.setContentOffset(topContentOffset, animated: animated)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        handleMatchScrollDidScroll(scrollView)
    }
}

// MARK: - UICollectionViewDataSource

extension MatchBaseViewController {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        0
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        fatalError("Subclasses must override cellForItemAt when providing collection view items.")
    }
}

// MARK: - MatchDetailNavigationTitleView

@MainActor
final class MatchDetailNavigationTitleView: UIView {

    // MARK: - Layout Metrics

    private enum LayoutMetric {
        static let logoSize: CGFloat = 20
        static let spacing: CGFloat = 8
        static let badgeHorizontalInset: CGFloat = 10
        static let badgeVerticalInset: CGFloat = 6
        static let badgeCornerRadius: CGFloat = 10
    }

    // MARK: - UI Components

    private let leadingLogoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.tintColor = .primaryLabel
        return imageView
    }()

    private let leadingScoreLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .primaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        return label
    }()

    private let trailingLogoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.tintColor = .primaryLabel
        return imageView
    }()

    private let statusContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = LayoutMetric.badgeCornerRadius
        view.layer.masksToBounds = true
        view.isHidden = true
        return view
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let trailingScoreLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .primaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        return label
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(
            arrangedSubviews: [
                leadingLogoImageView,
                leadingScoreLabel,
                statusContainerView,
                trailingScoreLabel,
                trailingLogoImageView
            ]
        )
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = LayoutMetric.spacing
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

    // MARK: - Configuration

    func configure(
        leadingLogoURL: URL?,
        leadingScoreText: String,
        trailingLogoURL: URL?
    ) {
        configure(
            leadingLogoURL: leadingLogoURL,
            leadingScoreText: leadingScoreText,
            trailingLogoURL: trailingLogoURL,
            trailingScoreText: "-",
            navigationBadgeViewData: nil
        )
    }

    func configure(
        leadingLogoURL: URL?,
        leadingScoreText: String,
        trailingLogoURL: URL?,
        trailingScoreText: String,
        navigationBadgeViewData: MatchDetailNavigationBadgeViewData?
    ) {
        leadingScoreLabel.text = leadingScoreText
        trailingScoreLabel.text = trailingScoreText
        configureLogoImageView(leadingLogoImageView, with: leadingLogoURL)
        configureLogoImageView(trailingLogoImageView, with: trailingLogoURL)
        configureStatus(with: navigationBadgeViewData)
    }

    // MARK: - Private Methods

    private func configureLogoImageView(_ imageView: UIImageView, with logoURL: URL?) {
        let fallbackImage = UIImage(systemName: "sportscourt")?.withRenderingMode(.alwaysTemplate)

        switch logoURL {
        case .some(let logoURL):
            imageView.sd_setImage(with: logoURL, placeholderImage: fallbackImage)

        case .none:
            imageView.sd_cancelCurrentImageLoad()
            imageView.image = fallbackImage
        }
    }

    // MARK: - Setup

    private func setupView() {
        statusContainerView.addSubview(statusLabel)
        addSubview(stackView)

        leadingLogoImageView.snp.makeConstraints { make in
            make.width.height.equalTo(LayoutMetric.logoSize)
        }

        trailingLogoImageView.snp.makeConstraints { make in
            make.width.height.equalTo(LayoutMetric.logoSize)
        }

        statusLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(
                top: LayoutMetric.badgeVerticalInset,
                left: LayoutMetric.badgeHorizontalInset,
                bottom: LayoutMetric.badgeVerticalInset,
                right: LayoutMetric.badgeHorizontalInset
            ))
        }

        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - Status Style

    private func configureStatus(with navigationBadgeViewData: MatchDetailNavigationBadgeViewData?) {
        guard let navigationBadgeViewData else {
            statusLabel.text = nil
            statusContainerView.isHidden = true
            return
        }

        statusLabel.text = navigationBadgeViewData.text
        applyStatusStyle(navigationBadgeViewData.style)
        statusContainerView.isHidden = false
    }

    private func applyStatusStyle(_ style: MatchDetailNavigationStatusStyle) {
        switch style {
        case .live:
            statusContainerView.backgroundColor = UIColor.systemRed.withAlphaComponent(0.14)
            statusLabel.textColor = .systemRed
        case .final:
            statusContainerView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.14)
            statusLabel.textColor = .systemGreen
        case .upcoming:
            statusContainerView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.14)
            statusLabel.textColor = .systemBlue
        case .postponed:
            statusContainerView.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.14)
            statusLabel.textColor = .systemOrange
        case .cancelled:
            statusContainerView.backgroundColor = UIColor.systemGray3.withAlphaComponent(0.24)
            statusLabel.textColor = .secondaryLabel
        case .neutral:
            statusContainerView.backgroundColor = UIColor.secondarySystemFill
            statusLabel.textColor = .secondaryLabel
        }
    }
}

nonisolated enum MatchDetailNavigationStatusStyle: Equatable, Sendable {
    case live
    case final
    case upcoming
    case postponed
    case cancelled
    case neutral
}

nonisolated struct MatchDetailNavigationBadgeViewData: Equatable, Sendable {
    let text: String
    let style: MatchDetailNavigationStatusStyle
}
