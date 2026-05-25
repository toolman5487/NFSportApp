//
//  MainHomeViewController.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/22.
//

import SDWebImage
import SnapKit
import UIKit

// MARK: - MainHomeViewController

@MainActor
final class MainHomeViewController: MainBaseViewController {

    // MARK: - Layout Metrics

    private enum LayoutMetric {
        static let horizontalInset: CGFloat = 16
        static let sectionTopInset: CGFloat = 8
        static let sectionBottomInset: CGFloat = 16
        static let itemSpacing: CGFloat = 8
        static let estimatedFilterHeight: CGFloat = 60
        static let estimatedItemHeight: CGFloat = 136
        static let estimatedHeaderHeight: CGFloat = 56
    }

    // MARK: - Properties

    private let viewModel: MainHomeViewModel
    private let navigationTitleView = MainHomeNavigationTitleView()
    private var screenTitle: String
    private var sections: [MainHomeContentSectionViewData] = []

    // MARK: - Initialization

    init(viewModel: MainHomeViewModel) {
        self.viewModel = viewModel
        self.screenTitle = viewModel.title
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        Task { [weak self] in
            guard let self else {
                return
            }

            await viewModel.loadDashboard()
        }
    }

    // MARK: - Setup

    override func setupMainNavigation() {
        title = screenTitle
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.leftBarButtonItem = nil
    }

    override func registerReusableViews() {
        collectionView.register(
            MainHomeFilterCell.self,
            forCellWithReuseIdentifier: MainHomeFilterCell.reuseIdentifier
        )
        collectionView.register(
            MainHomeFilterSkeletonCell.self,
            forCellWithReuseIdentifier: MainHomeFilterSkeletonCell.reuseIdentifier
        )
        collectionView.register(
            MainHomeGameCell.self,
            forCellWithReuseIdentifier: MainHomeGameCell.reuseIdentifier
        )
        collectionView.register(
            MainHomeLoadingBackgroundCell.self,
            forCellWithReuseIdentifier: MainHomeLoadingBackgroundCell.reuseIdentifier
        )
        collectionView.register(
            MainHomeSectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: MainHomeSectionHeaderView.reuseIdentifier
        )
        collectionView.register(
            MainHomeSectionSkeletonHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: MainHomeSectionSkeletonHeaderView.reuseIdentifier
        )
    }

    override func bindViewModel() {
        super.bindViewModel()

        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }

        render(viewModel.state)
    }

    // MARK: - Rendering

    private func render(_ state: MainHomeViewState) {
        switch state {
        case .idle:
            renderLoadingState(.idle)

        case .loading(let presentation):
            renderLoadingState(.idle)
            applyPresentation(presentation)

        case .loaded(let presentation):
            renderLoadingState(.idle)
            applyPresentation(presentation)

        case .empty(let presentation, let message):
            applyPresentation(presentation)
            renderLoadingState(.empty(message: message))

        case .failed(let message):
            screenTitle = viewModel.title
            title = screenTitle
            sections = []
            collectionView.reloadData()
            updateNavigationTitle()
            renderLoadingState(.failed(message: message))
        }
    }

    // MARK: - Presentation

    private func applyPresentation(_ presentation: MainHomePresentation) {
        screenTitle = presentation.title
        title = presentation.title
        sections = presentation.sections
        collectionView.reloadData()
        updateNavigationTitle()
    }

    // MARK: - Navigation Title

    private func updateNavigationTitle() {
        guard isNavigationBarCollapsed,
              let currentSection = currentVisibleSection() else {
            navigationItem.titleView = nil
            navigationItem.title = screenTitle
            return
        }

        navigationTitleView.configure(
            title: currentSection.title,
            logoURL: currentSection.logoURL,
            fallbackSystemImageName: currentSection.fallbackSystemImageName
        )
        navigationItem.title = nil
        navigationItem.titleView = navigationTitleView
    }

    private var isNavigationBarCollapsed: Bool {
        guard let navigationBar = navigationController?.navigationBar else {
            return false
        }

        return navigationBar.bounds.height <= 44.5
    }

    // MARK: - Section Access

    private func currentVisibleSection() -> MainHomeSectionViewData? {
        let topVisibleIndexPath = collectionView.indexPathsForVisibleItems.min { lhs, rhs in
            if lhs.section == rhs.section {
                return lhs.item < rhs.item
            }

            return lhs.section < rhs.section
        }

        guard let sectionIndex = topVisibleIndexPath?.section,
              case .some(.league(let sectionViewData)) = sectionViewData(at: sectionIndex) else {
            return nil
        }

        return sectionViewData
    }

    private func sectionViewData(at index: Int) -> MainHomeContentSectionViewData? {
        guard sections.indices.contains(index) else {
            return nil
        }

        return sections[index]
    }

    // MARK: - Layout

    override func makeSectionLayout(
        for sectionIndex: Int,
        environment: NSCollectionLayoutEnvironment
    ) -> NSCollectionLayoutSection {
        switch sectionViewData(at: sectionIndex) {
        case .some(.filter), .some(.filterSkeleton):
            return makeFilterSectionLayout()

        case .some(.league), .some(.leagueSkeleton), .none:
            return makeLeagueSectionLayout()
        }
    }

    private func makeLeagueSectionLayout() -> NSCollectionLayoutSection {
        let section = makeListSectionLayout(
            itemHeight: .estimated(LayoutMetric.estimatedItemHeight),
            contentInsets: NSDirectionalEdgeInsets(
                top: LayoutMetric.sectionTopInset,
                leading: LayoutMetric.horizontalInset,
                bottom: LayoutMetric.sectionBottomInset,
                trailing: LayoutMetric.horizontalInset
            ),
            interGroupSpacing: LayoutMetric.itemSpacing
        )
        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(LayoutMetric.estimatedHeaderHeight)
        )
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        section.boundarySupplementaryItems = [header]
        return section
    }

    private func makeFilterSectionLayout() -> NSCollectionLayoutSection {
        makeListSectionLayout(
            itemHeight: .estimated(LayoutMetric.estimatedFilterHeight),
            contentInsets: NSDirectionalEdgeInsets(
                top: LayoutMetric.sectionTopInset,
                leading: LayoutMetric.horizontalInset,
                bottom: 0,
                trailing: LayoutMetric.horizontalInset
            ),
            interGroupSpacing: 0
        )
    }

    // MARK: - UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        sections.count
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        sectionViewData(at: section)?.itemCount ?? 0
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        switch sectionViewData(at: indexPath.section) {
        case .some(.filter(let filterViewData)):
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MainHomeFilterCell.reuseIdentifier,
                for: indexPath
            ) as? MainHomeFilterCell else {
                return UICollectionViewCell()
            }

            cell.configure(with: filterViewData)
            cell.onFilterSelected = { [weak self] action in
                self?.viewModel.selectFilterOption(action)
            }
            return cell

        case .some(.filterSkeleton):
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MainHomeFilterSkeletonCell.reuseIdentifier,
                for: indexPath
            ) as? MainHomeFilterSkeletonCell else {
                return UICollectionViewCell()
            }

            return cell

        case .some(.league(let sectionViewData)):
            guard sectionViewData.items.indices.contains(indexPath.item),
                  let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: MainHomeGameCell.reuseIdentifier,
                    for: indexPath
                  ) as? MainHomeGameCell else {
                return UICollectionViewCell()
            }

            cell.configure(with: sectionViewData.items[indexPath.item])
            return cell

        case .some(.leagueSkeleton):
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MainHomeLoadingBackgroundCell.reuseIdentifier,
                for: indexPath
            ) as? MainHomeLoadingBackgroundCell else {
                return UICollectionViewCell()
            }

            return cell

        case .none:
            return UICollectionViewCell()
        }
    }

    // MARK: - Supplementary Views

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }

        switch sectionViewData(at: indexPath.section) {
        case .some(.league(let sectionViewData)):
            guard let headerView = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: MainHomeSectionHeaderView.reuseIdentifier,
                for: indexPath
              ) as? MainHomeSectionHeaderView else {
                return UICollectionReusableView()
            }

            headerView.configure(
                title: sectionViewData.title,
                logoURL: sectionViewData.logoURL,
                fallbackSystemImageName: sectionViewData.fallbackSystemImageName
            )
            return headerView

        case .some(.leagueSkeleton):
            guard let headerView = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: MainHomeSectionSkeletonHeaderView.reuseIdentifier,
                for: indexPath
              ) as? MainHomeSectionSkeletonHeaderView else {
                return UICollectionReusableView()
            }

            return headerView

        case .some(.filter), .some(.filterSkeleton), .none:
            return UICollectionReusableView()
        }
    }

    // MARK: - UIScrollViewDelegate

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateNavigationTitle()
    }
}

// MARK: - MainHomeNavigationTitleView

private final class MainHomeNavigationTitleView: UIView {

    // MARK: - Layout Metrics

    private enum LayoutMetric {
        static let logoSize: CGFloat = 20
        static let spacing: CGFloat = 8
    }

    // MARK: - UI Components

    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.tintColor = .primaryLabel
        imageView.isHidden = true
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .primaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.lineBreakMode = .byTruncatingTail
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [logoImageView, titleLabel])
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
        title: String,
        logoURL: URL?,
        fallbackSystemImageName: String
    ) {
        titleLabel.text = title
        let fallbackImage = makeFallbackImage(systemImageName: fallbackSystemImageName)

        switch logoURL {
        case .some(let logoURL):
            logoImageView.isHidden = false
            logoImageView.sd_setImage(with: logoURL, placeholderImage: fallbackImage)

        case .none:
            logoImageView.sd_cancelCurrentImageLoad()
            logoImageView.image = fallbackImage
            logoImageView.isHidden = false
        }
    }

    // MARK: - Private Methods

    private func makeFallbackImage(systemImageName: String) -> UIImage? {
        let image = UIImage(systemName: systemImageName)
            ?? UIImage(systemName: "sportscourt")
            ?? UIImage(systemName: "trophy")
        return image?.withRenderingMode(.alwaysTemplate)
    }

    // MARK: - Setup

    private func setupView() {
        addSubview(stackView)

        logoImageView.snp.makeConstraints { make in
            make.width.height.equalTo(LayoutMetric.logoSize)
        }

        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
