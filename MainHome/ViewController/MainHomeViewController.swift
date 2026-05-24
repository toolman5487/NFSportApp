//
//  MainHomeViewController.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/22.
//

import UIKit

@MainActor
final class MainHomeViewController: MainBaseViewController {

    // MARK: - Layout Metrics

    private enum LayoutMetric {
        static let horizontalInset: CGFloat = 16
        static let sectionTopInset: CGFloat = 8
        static let sectionBottomInset: CGFloat = 16
        static let itemSpacing: CGFloat = 8
        static let estimatedItemHeight: CGFloat = 136
        static let estimatedHeaderHeight: CGFloat = 40
    }

    // MARK: - Properties

    private let viewModel: MainHomeViewModel
    private var sections: [MainHomeSectionViewData] = []

    // MARK: - Initialization

    init(viewModel: MainHomeViewModel) {
        self.viewModel = viewModel
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
        title = viewModel.selectedSport.title
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.leftBarButtonItem = nil
    }

    override func registerReusableViews() {
        collectionView.register(
            MainHomeGameCell.self,
            forCellWithReuseIdentifier: MainHomeGameCell.reuseIdentifier
        )
        collectionView.register(
            MainHomeSectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: MainHomeSectionHeaderView.reuseIdentifier
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

        case .loading:
            renderLoadingState(.loading)

        case .loaded(let presentation):
            renderLoadingState(.idle)
            sections = presentation.sections
            collectionView.reloadData()
            updateNavigationTitle()

        case .empty(let message):
            sections = []
            collectionView.reloadData()
            updateNavigationTitle()
            renderLoadingState(.empty(message: message))

        case .failed(let message):
            sections = []
            collectionView.reloadData()
            updateNavigationTitle()
            renderLoadingState(.failed(message: message))
        }
    }

    private func updateNavigationTitle() {
        guard isNavigationBarCollapsed,
              let currentSectionTitle = currentPinnedSectionTitle() else {
            navigationItem.title = viewModel.selectedSport.title
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

    private func currentPinnedSectionTitle() -> String? {
        let topVisibleIndexPath = collectionView.indexPathsForVisibleItems.min { lhs, rhs in
            if lhs.section == rhs.section {
                return lhs.item < rhs.item
            }

            return lhs.section < rhs.section
        }

        guard let sectionIndex = topVisibleIndexPath?.section,
              sections.indices.contains(sectionIndex) else {
            return nil
        }

        return sections[sectionIndex].title
    }

    // MARK: - Layout

    override func makeSectionLayout(
        for sectionIndex: Int,
        environment: NSCollectionLayoutEnvironment
    ) -> NSCollectionLayoutSection {
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

    // MARK: - UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        sections.count
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        sections[section].items.count
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MainHomeGameCell.reuseIdentifier,
            for: indexPath
        ) as? MainHomeGameCell else {
            return UICollectionViewCell()
        }

        cell.configure(with: sections[indexPath.section].items[indexPath.item])
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader,
              let headerView = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: MainHomeSectionHeaderView.reuseIdentifier,
                for: indexPath
              ) as? MainHomeSectionHeaderView else {
            return UICollectionReusableView()
        }

        headerView.configure(title: sections[indexPath.section].title)
        return headerView
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateNavigationTitle()
    }
}
