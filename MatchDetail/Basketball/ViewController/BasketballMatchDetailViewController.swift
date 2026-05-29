//
//  BasketballMatchDetailViewController.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/27.
//

import SnapKit
import UIKit

@MainActor
final class BasketballMatchDetailViewController: MatchBaseViewController {

    // MARK: - Layout Metrics

    private enum LayoutMetric {
        static let estimatedHeaderHeight: CGFloat = 360
        static let estimatedVenueHeight: CGFloat = 96
        static let estimatedFilterHeaderHeight: CGFloat = BasketballMatchFilterView.preferredHeight
        static let estimatedStatsRowHeight: CGFloat = 56
        static let estimatedStatsEmptyHeight: CGFloat = 200
    }

    private enum StatsEmptyContent {
        static let title = "No Stats Available"
        static let subtitle = "Player statistics are not available for this game."
    }

    // MARK: - Properties

    private let viewModel: BasketballMatchDetailViewModel
    private let navigationTitleView = MatchDetailNavigationTitleView()
    private var screenTitle: String
    private var headerViewData: BasketballMatchDetailHeaderViewData?
    private var sections: [BasketballMatchDetailSectionViewData] = []
    private var selectedStatsFilter: BasketballMatchFilterOption = .total

    // MARK: - Initialization

    init(viewModel: BasketballMatchDetailViewModel) {
        self.viewModel = viewModel
        self.screenTitle = viewModel.title
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    override func setupMatchNavigation() {
        title = screenTitle
        navigationItem.largeTitleDisplayMode = .never
    }

    override func registerReusableViews() {
        collectionView.register(
            BasketballMatchScoreHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: BasketballMatchScoreHeaderView.reuseIdentifier
        )
        collectionView.register(
            BasketballMatchDetailVenueFooterView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: BasketballMatchDetailVenueFooterView.reuseIdentifier
        )
        collectionView.register(
            BasketballMatchFilterView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: BasketballMatchFilterView.reuseIdentifier
        )
        collectionView.register(
            BasketballMatchStatsRowCell.self,
            forCellWithReuseIdentifier: BasketballMatchStatsRowCell.reuseIdentifier
        )
        collectionView.register(
            BasketballMatchStatsEmptyCell.self,
            forCellWithReuseIdentifier: BasketballMatchStatsEmptyCell.reuseIdentifier
        )
    }

    override func bindViewModel() {
        super.bindViewModel()

        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }

        render(viewModel.state)

        Task { [weak self] in
            await self?.viewModel.loadMatchDetail()
        }
    }

    // MARK: - UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        sections.count
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch sectionViewData(at: section) {
        case .some(.header):
            return 0

        case .some(.stats(let viewData)):
            return statsItemCount(for: viewData)

        case .none:
            return 0
        }
    }

    private func statsItemCount(for viewData: BasketballMatchDetailStatsViewData) -> Int {
        let rowCount = statsRowCount(for: viewData)
        return rowCount > 0 ? rowCount : 1
    }

    private func statsHasContent(for viewData: BasketballMatchDetailStatsViewData) -> Bool {
        statsRowCount(for: viewData) > 0
    }

    private func statsRowCount(for viewData: BasketballMatchDetailStatsViewData) -> Int {
        switch selectedStatsFilter {
        case .total:
            return viewData.comparisonRows.count
        case .home:
            return viewData.homeRows.count
        case .away:
            return viewData.awayRows.count
        }
    }

    // MARK: - Layout

    override func makeSectionLayout(
        for sectionIndex: Int,
        environment: NSCollectionLayoutEnvironment
    ) -> NSCollectionLayoutSection {
        switch sectionViewData(at: sectionIndex) {
        case .some(.header):
            let section = makeListSectionLayout()
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
            return appendVenueFooterIfNeeded(
                to: section,
                sectionIndex: sectionIndex,
                numberOfSections: sections.count,
                hasVenue: headerViewData?.venue != nil,
                estimatedHeight: LayoutMetric.estimatedVenueHeight
            )

        case .some(.stats(let viewData)):
            let itemHeight: NSCollectionLayoutDimension = statsHasContent(for: viewData)
                ? .estimated(LayoutMetric.estimatedStatsRowHeight)
                : .estimated(LayoutMetric.estimatedStatsEmptyHeight)
            let section = makeListSectionLayout(itemHeight: itemHeight)
            let filterHeaderSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .estimated(LayoutMetric.estimatedFilterHeaderHeight)
            )
            let filterHeader = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: filterHeaderSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top
            )
            filterHeader.pinToVisibleBounds = true
            filterHeader.zIndex = 2
            section.boundarySupplementaryItems = [filterHeader]
            return appendVenueFooterIfNeeded(
                to: section,
                sectionIndex: sectionIndex,
                numberOfSections: sections.count,
                hasVenue: headerViewData?.venue != nil,
                estimatedHeight: LayoutMetric.estimatedVenueHeight
            )

        case .none:
            return makeListSectionLayout()
        }
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        switch sectionViewData(at: indexPath.section) {
        case .some(.header):
            return UICollectionViewCell()

        case .some(.stats(let viewData)):
            return makeStatsCell(for: viewData, at: indexPath)

        case .none:
            return UICollectionViewCell()
        }
    }

    private func makeStatsCell(
        for viewData: BasketballMatchDetailStatsViewData,
        at indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard statsHasContent(for: viewData) else {
            return makeStatsEmptyCell(at: indexPath)
        }

        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: BasketballMatchStatsRowCell.reuseIdentifier,
            for: indexPath
        ) as? BasketballMatchStatsRowCell else {
            return UICollectionViewCell()
        }

        switch selectedStatsFilter {
        case .total:
            guard viewData.comparisonRows.indices.contains(indexPath.item) else {
                return cell
            }
            cell.configure(with: viewData.comparisonRows[indexPath.item])

        case .home:
            guard viewData.homeRows.indices.contains(indexPath.item) else {
                return cell
            }
            cell.configure(with: viewData.homeRows[indexPath.item])

        case .away:
            guard viewData.awayRows.indices.contains(indexPath.item) else {
                return cell
            }
            cell.configure(with: viewData.awayRows[indexPath.item])
        }

        return cell
    }

    private func makeStatsEmptyCell(at indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: BasketballMatchStatsEmptyCell.reuseIdentifier,
            for: indexPath
        ) as? BasketballMatchStatsEmptyCell else {
            return UICollectionViewCell()
        }

        cell.configure(
            title: StatsEmptyContent.title,
            subtitle: StatsEmptyContent.subtitle
        )
        return cell
    }

    // MARK: - Supplementary Views

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader
                || kind == UICollectionView.elementKindSectionFooter else {
            return UICollectionReusableView()
        }

        switch sectionViewData(at: indexPath.section) {
        case .some(.stats):
            if kind == UICollectionView.elementKindSectionFooter,
               shouldShowVenueFooter(
                   at: indexPath.section,
                   numberOfSections: sections.count,
                   hasVenue: headerViewData?.venue != nil
               ),
               let venue = headerViewData?.venue,
               let footerView = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: BasketballMatchDetailVenueFooterView.reuseIdentifier,
                for: indexPath
               ) as? BasketballMatchDetailVenueFooterView {
                footerView.configure(with: venue)
                return footerView
            }

            guard let filterView = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: BasketballMatchFilterView.reuseIdentifier,
                for: indexPath
            ) as? BasketballMatchFilterView else {
                return UICollectionReusableView()
            }

            filterView.configure(selectedOption: selectedStatsFilter)
            filterView.onFilterChanged = { [weak self] option in
                guard let self, self.selectedStatsFilter != option else {
                    return
                }

                self.selectedStatsFilter = option
                self.collectionView.reloadSections(IndexSet(integer: indexPath.section))
            }
            return filterView

        case .some(.header(let viewData)):
            guard kind == UICollectionView.elementKindSectionHeader,
                  let headerView = collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: BasketballMatchScoreHeaderView.reuseIdentifier,
                    for: indexPath
                  ) as? BasketballMatchScoreHeaderView else {
                return UICollectionReusableView()
            }

            headerView.configure(with: viewData)
            return headerView

        case .none:
            return UICollectionReusableView()
        }
    }

    // MARK: - Rendering

    private func render(_ state: BasketballMatchDetailViewState) {
        switch state {
        case .idle:
            headerViewData = nil
            updateNavigationTitle()
            renderLoadingState(.idle)

        case .loading:
            headerViewData = nil
            updateNavigationTitle()
            renderLoadingState(.loading)

        case .loaded(let presentation):
            screenTitle = presentation.title
            title = presentation.title
            headerViewData = presentation.sections.compactMap { section -> BasketballMatchDetailHeaderViewData? in
                guard case .header(let viewData) = section else {
                    return nil
                }

                return viewData
            }.first
            sections = presentation.sections
            collectionView.reloadData()
            updateNavigationTitle()
            renderLoadingState(.idle)

        case .failed(let message):
            headerViewData = nil
            sections = []
            collectionView.reloadData()
            updateNavigationTitle()
            renderLoadingState(.failed(message: message))
        }
    }

    // MARK: - Navigation Title

    private func updateNavigationTitle() {
        guard isScrolledAwayFromTop,
              let headerViewData else {
            navigationItem.titleView = nil
            navigationItem.title = screenTitle
            return
        }

        navigationTitleView.configure(
            leadingLogoURL: headerViewData.homeTeamLogoURL,
            leadingScoreText: headerViewData.homeScoreText,
            trailingLogoURL: headerViewData.awayTeamLogoURL,
            trailingScoreText: headerViewData.awayScoreText,
            navigationBadgeViewData: headerViewData.navigationBadgeViewData
        )
        navigationItem.title = nil
        navigationItem.titleView = navigationTitleView
    }

    // MARK: - Section Access

    private func sectionViewData(at index: Int) -> BasketballMatchDetailSectionViewData? {
        guard sections.indices.contains(index) else {
            return nil
        }

        return sections[index]
    }

    // MARK: - UIScrollViewDelegate

    override func handleMatchScrollDidScroll(_ scrollView: UIScrollView) {
        updateNavigationTitle()
    }
}
