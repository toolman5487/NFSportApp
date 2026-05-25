//
//  MainSoccerHomeViewController.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/25.
//

import UIKit

// MARK: - MainSoccerHomeViewController

@MainActor
final class MainSoccerHomeViewController: MainBaseViewController {

    // MARK: - Layout Metrics

    private enum LayoutMetric {
        static let horizontalInset: CGFloat = 16
        static let sectionTopInset: CGFloat = 8
        static let sectionBottomInset: CGFloat = 16
        static let itemSpacing: CGFloat = 8
        static let headerHeight: CGFloat = 36
        static let liveHeroHeight: CGFloat = 176
        static let liveHeroWidthFraction: CGFloat = 0.88
        static let fixtureRowHeight: CGFloat = 136
        static let fallbackHeight: CGFloat = fixtureRowHeight
    }

    // MARK: - Properties

    private let viewModel: MainSoccerHomeViewModel
    private var screenTitle: String
    private var sections: [MainSoccerHomeSection] = []

    // MARK: - Initialization

    init(viewModel: MainSoccerHomeViewModel) {
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
            MainSoccerLiveHeroCell.self,
            forCellWithReuseIdentifier: MainSoccerLiveHeroCell.reuseIdentifier
        )
        collectionView.register(
            MainSoccerEmptyStateCell.self,
            forCellWithReuseIdentifier: MainSoccerEmptyStateCell.reuseIdentifier
        )
        collectionView.register(
            MainSoccerFixtureCell.self,
            forCellWithReuseIdentifier: MainSoccerFixtureCell.reuseIdentifier
        )
        collectionView.register(
            MainSoccerHomeSectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: MainSoccerHomeSectionHeaderView.reuseIdentifier
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

    private func render(_ state: MainSoccerHomeViewState) {
        switch state {
        case .idle:
            renderLoadingState(.idle)

        case .loading:
            renderLoadingState(.loading)

        case .loaded(let presentation):
            renderLoadingState(.idle)
            applyPresentation(presentation)

        case .failed(let message):
            screenTitle = viewModel.title
            title = screenTitle
            sections = []
            collectionView.reloadData()
            updateNavigationTitle()
            renderLoadingState(.failed(message: message))
        }
    }

    private func applyPresentation(_ presentation: MainSoccerHomePresentation) {
        screenTitle = presentation.title
        title = presentation.title
        sections = presentation.sections
        collectionView.reloadData()
        updateNavigationTitle()
    }

    // MARK: - Section Access

    private func updateNavigationTitle() {
        guard isNavigationBarCollapsed,
              let currentSectionTitle = currentVisibleSectionTitle() else {
            navigationItem.title = screenTitle
            return
        }

        navigationItem.title = currentSectionTitle
    }

    private var isNavigationBarCollapsed: Bool {
        guard let navigationBar = navigationController?.navigationBar else {
            return false
        }

        return navigationBar.bounds.height <= 44.5
    }

    private func currentVisibleSectionTitle() -> String? {
        let topVisibleIndexPath = collectionView.indexPathsForVisibleItems.min { lhs, rhs in
            if lhs.section == rhs.section {
                return lhs.item < rhs.item
            }

            return lhs.section < rhs.section
        }

        guard let sectionIndex = topVisibleIndexPath?.section else {
            return nil
        }

        return section(at: sectionIndex)?.title
    }

    private func section(at index: Int) -> MainSoccerHomeSection? {
        guard sections.indices.contains(index) else {
            return nil
        }

        return sections[index]
    }

    private func item(at indexPath: IndexPath) -> MainSoccerHomeItem? {
        guard let section = section(at: indexPath.section),
              section.items.indices.contains(indexPath.item) else {
            return nil
        }

        return section.items[indexPath.item]
    }

    // MARK: - Layout

    override func makeSectionLayout(
        for sectionIndex: Int,
        environment: NSCollectionLayoutEnvironment
    ) -> NSCollectionLayoutSection {
        switch section(at: sectionIndex) {
        case .some(.liveMatches):
            return makeLiveMatchesSectionLayout()

        case .some(.today):
            return makeListSectionLayout(
                estimatedHeight: LayoutMetric.fixtureRowHeight,
                includesHeader: true
            )

        case .none:
            return makeListSectionLayout(
                estimatedHeight: LayoutMetric.fallbackHeight,
                includesHeader: false
            )
        }
    }

    private func makeLiveMatchesSectionLayout() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(LayoutMetric.liveHeroHeight)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(LayoutMetric.liveHeroWidthFraction),
            heightDimension: .estimated(LayoutMetric.liveHeroHeight)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(
            top: LayoutMetric.sectionTopInset,
            leading: LayoutMetric.horizontalInset,
            bottom: LayoutMetric.sectionBottomInset,
            trailing: LayoutMetric.horizontalInset
        )
        section.interGroupSpacing = LayoutMetric.itemSpacing
        section.orthogonalScrollingBehavior = .groupPagingCentered
        section.boundarySupplementaryItems = [makeSectionHeaderItem()]
        return section
    }

    private func makeListSectionLayout(
        estimatedHeight: CGFloat,
        includesHeader: Bool
    ) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(estimatedHeight)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(
            top: LayoutMetric.sectionTopInset,
            leading: LayoutMetric.horizontalInset,
            bottom: LayoutMetric.sectionBottomInset,
            trailing: LayoutMetric.horizontalInset
        )
        section.interGroupSpacing = LayoutMetric.itemSpacing

        if includesHeader {
            section.boundarySupplementaryItems = [makeSectionHeaderItem()]
        }

        return section
    }

    private func makeSectionHeaderItem() -> NSCollectionLayoutBoundarySupplementaryItem {
        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(LayoutMetric.headerHeight)
        )
        return NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
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
        switch self.section(at: section) {
        case .some(let section):
            return section.items.count

        case .none:
            return 0
        }
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        switch item(at: indexPath) {
        case .some(.liveHero(let viewData)):
            return configuredCell(
                MainSoccerLiveHeroCell.self,
                reuseIdentifier: MainSoccerLiveHeroCell.reuseIdentifier,
                collectionView: collectionView,
                indexPath: indexPath
            ) { $0.configure(with: viewData) }

        case .some(.empty(let viewData)):
            return configuredCell(
                MainSoccerEmptyStateCell.self,
                reuseIdentifier: MainSoccerEmptyStateCell.reuseIdentifier,
                collectionView: collectionView,
                indexPath: indexPath
            ) { $0.configure(with: viewData) }

        case .some(.fixture(let viewData)):
            return configuredCell(
                MainSoccerFixtureCell.self,
                reuseIdentifier: MainSoccerFixtureCell.reuseIdentifier,
                collectionView: collectionView,
                indexPath: indexPath
            ) { $0.configure(with: viewData) }

        case .none:
            return UICollectionViewCell()
        }
    }

    // MARK: - Cell Dequeue

    private func configuredCell<Cell: UICollectionViewCell>(
        _ cellType: Cell.Type,
        reuseIdentifier: String,
        collectionView: UICollectionView,
        indexPath: IndexPath,
        configure: (Cell) -> Void
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: reuseIdentifier,
            for: indexPath
        ) as? Cell else {
            return UICollectionViewCell()
        }

        configure(cell)
        return cell
    }
}

// MARK: - Supplementary Views

extension MainSoccerHomeViewController {

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader,
              let title = section(at: indexPath.section)?.title,
              let headerView = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: MainSoccerHomeSectionHeaderView.reuseIdentifier,
                for: indexPath
              ) as? MainSoccerHomeSectionHeaderView else {
            return UICollectionReusableView()
        }

        headerView.configure(title: title)
        return headerView
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateNavigationTitle()
    }
}
