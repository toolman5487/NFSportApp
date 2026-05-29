//
//  SoccerMatchDetailViewController.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/26.
//

import SnapKit
import UIKit

@MainActor
final class SoccerMatchDetailViewController: MatchBaseViewController {

    // MARK: - Layout Metrics

    private enum LayoutMetric {
        static let estimatedHeaderHeight: CGFloat = 360
        static let estimatedVenueHeight: CGFloat = 96
        static let estimatedFilterHeaderHeight: CGFloat = SoccerMatchFilterView.preferredHeight
        static let estimatedSectionHeaderHeight: CGFloat = SoccerMatchDetailSectionHeaderView.preferredHeight
        static let estimatedStatsRowHeight: CGFloat = 56
        static let estimatedStatsEmptyHeight: CGFloat = 200
        static let estimatedEventRowHeight: CGFloat = 72
        static let estimatedLineupRowHeight: CGFloat = 220
    }

    // MARK: - Properties

    private let viewModel: SoccerMatchDetailViewModel
    private var screenTitle: String
    private let navigationTitleView = MatchDetailNavigationTitleView()
    private var headerViewData: SoccerMatchDetailHeaderViewData?
    private var sections: [SoccerMatchDetailSectionViewData] = []
    private var selectedStatsFilter: SoccerMatchFilterOption = .total

    // MARK: - Initialization

    init(viewModel: SoccerMatchDetailViewModel) {
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
            SoccerMatchDetailVenueFooterView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: SoccerMatchDetailVenueFooterView.reuseIdentifier
        )
        collectionView.register(
            SoccerMatchScoreHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: SoccerMatchScoreHeaderView.reuseIdentifier
        )
        collectionView.register(
            SoccerMatchFilterView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: SoccerMatchFilterView.reuseIdentifier
        )
        collectionView.register(
            SoccerMatchDetailSectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: SoccerMatchDetailSectionHeaderView.reuseIdentifier
        )
        collectionView.register(
            SoccerMatchStatsRowCell.self,
            forCellWithReuseIdentifier: SoccerMatchStatsRowCell.reuseIdentifier
        )
        collectionView.register(
            SoccerMatchStatsEmptyCell.self,
            forCellWithReuseIdentifier: SoccerMatchStatsEmptyCell.reuseIdentifier
        )
        collectionView.register(
            SoccerMatchEventRowCell.self,
            forCellWithReuseIdentifier: SoccerMatchEventRowCell.reuseIdentifier
        )
        collectionView.register(
            SoccerMatchLineupTeamCell.self,
            forCellWithReuseIdentifier: SoccerMatchLineupTeamCell.reuseIdentifier
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

        case .some(.events(let viewData)):
            return viewData.items.count

        case .some(.lineups(let viewData)):
            return viewData.teams.count

        case .none:
            return 0
        }
    }

    private func statsItemCount(for viewData: SoccerMatchDetailStatsViewData) -> Int {
        switch viewData.displayState {
        case .empty:
            return 1

        case .content:
            let rowCount = statsRowCount(for: viewData)
            return rowCount > 0 ? rowCount : 1
        }
    }

    private func statsHasContent(for viewData: SoccerMatchDetailStatsViewData) -> Bool {
        switch viewData.displayState {
        case .empty:
            return false

        case .content:
            return statsRowCount(for: viewData) > 0
        }
    }

    private func statsRowCount(for viewData: SoccerMatchDetailStatsViewData) -> Int {
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
            let section = makeListSectionLayout(
                contentInsets: NSDirectionalEdgeInsets(
                    top: 0,
                    leading: 16,
                    bottom: 16,
                    trailing: 16
                ),
                interGroupSpacing: 0
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

        case .some(.stats(let viewData)):
            let itemHeight: NSCollectionLayoutDimension = statsHasContent(for: viewData)
                ? .estimated(LayoutMetric.estimatedStatsRowHeight)
                : .estimated(LayoutMetric.estimatedStatsEmptyHeight)
            let section = makeListSectionLayout(itemHeight: itemHeight)
            if viewData.showsFilter {
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
            }
            return appendVenueFooterIfNeeded(
                to: section,
                sectionIndex: sectionIndex,
                numberOfSections: sections.count,
                hasVenue: headerViewData?.venue != nil,
                estimatedHeight: LayoutMetric.estimatedVenueHeight
            )

        case .some(.events):
            let section = makeListSectionLayout(itemHeight: .estimated(LayoutMetric.estimatedEventRowHeight))
            section.boundarySupplementaryItems = [makeSectionTitleHeaderItem()]
            return appendVenueFooterIfNeeded(
                to: section,
                sectionIndex: sectionIndex,
                numberOfSections: sections.count,
                hasVenue: headerViewData?.venue != nil,
                estimatedHeight: LayoutMetric.estimatedVenueHeight
            )

        case .some(.lineups):
            let section = makeListSectionLayout(itemHeight: .estimated(LayoutMetric.estimatedLineupRowHeight))
            section.boundarySupplementaryItems = [makeSectionTitleHeaderItem()]
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

    private func makeSectionTitleHeaderItem() -> NSCollectionLayoutBoundarySupplementaryItem {
        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(LayoutMetric.estimatedSectionHeaderHeight)
        )
        return NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
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

        case .some(.events(let viewData)):
            return makeEventCell(for: viewData, at: indexPath)

        case .some(.lineups(let viewData)):
            return makeLineupCell(for: viewData, at: indexPath)

        case .none:
            return UICollectionViewCell()
        }
    }

    private func makeStatsCell(
        for viewData: SoccerMatchDetailStatsViewData,
        at indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard statsHasContent(for: viewData) else {
            return makeStatsEmptyCell(for: viewData, at: indexPath)
        }

        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: SoccerMatchStatsRowCell.reuseIdentifier,
            for: indexPath
        ) as? SoccerMatchStatsRowCell else {
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

    private func makeEventCell(
        for viewData: SoccerMatchDetailEventsSectionViewData,
        at indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: SoccerMatchEventRowCell.reuseIdentifier,
            for: indexPath
        ) as? SoccerMatchEventRowCell,
              viewData.items.indices.contains(indexPath.item) else {
            return UICollectionViewCell()
        }

        cell.configure(with: viewData.items[indexPath.item])
        return cell
    }

    private func makeLineupCell(
        for viewData: SoccerMatchDetailLineupsSectionViewData,
        at indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: SoccerMatchLineupTeamCell.reuseIdentifier,
            for: indexPath
        ) as? SoccerMatchLineupTeamCell,
              viewData.teams.indices.contains(indexPath.item) else {
            return UICollectionViewCell()
        }

        cell.configure(with: viewData.teams[indexPath.item])
        return cell
    }

    private func makeStatsEmptyCell(
        for viewData: SoccerMatchDetailStatsViewData,
        at indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: SoccerMatchStatsEmptyCell.reuseIdentifier,
            for: indexPath
        ) as? SoccerMatchStatsEmptyCell else {
            return UICollectionViewCell()
        }

        switch viewData.displayState {
        case .empty(let title, let subtitle):
            cell.configure(title: title, subtitle: subtitle)

        case .content:
            cell.configure(
                title: "No Stats Available",
                subtitle: "Match statistics are not available for this game."
            )
        }

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

        if kind == UICollectionView.elementKindSectionFooter,
           shouldShowVenueFooter(
               at: indexPath.section,
               numberOfSections: sections.count,
               hasVenue: headerViewData?.venue != nil
           ),
           let venue = headerViewData?.venue,
           let footerView = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: SoccerMatchDetailVenueFooterView.reuseIdentifier,
            for: indexPath
           ) as? SoccerMatchDetailVenueFooterView {
            footerView.configure(with: venue)
            return footerView
        }

        switch sectionViewData(at: indexPath.section) {
        case .some(.stats(let viewData)):
            guard viewData.showsFilter,
                  let filterView = collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: SoccerMatchFilterView.reuseIdentifier,
                    for: indexPath
                  ) as? SoccerMatchFilterView else {
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

        case .some(.events(let viewData)):
            return dequeueSectionTitleHeader(
                collectionView: collectionView,
                kind: kind,
                indexPath: indexPath,
                title: viewData.title
            )

        case .some(.lineups(let viewData)):
            return dequeueSectionTitleHeader(
                collectionView: collectionView,
                kind: kind,
                indexPath: indexPath,
                title: viewData.title
            )

        case .some(.header(let viewData)):
            guard let headerView = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: SoccerMatchScoreHeaderView.reuseIdentifier,
                for: indexPath
            ) as? SoccerMatchScoreHeaderView else {
                return UICollectionReusableView()
            }

            headerView.configure(with: viewData)
            return headerView

        case .none:
            return UICollectionReusableView()
        }
    }

    private func dequeueSectionTitleHeader(
        collectionView: UICollectionView,
        kind: String,
        indexPath: IndexPath,
        title: String
    ) -> UICollectionReusableView {
        guard let headerView = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: SoccerMatchDetailSectionHeaderView.reuseIdentifier,
            for: indexPath
        ) as? SoccerMatchDetailSectionHeaderView else {
            return UICollectionReusableView()
        }

        headerView.configure(title: title)
        return headerView
    }

    // MARK: - Rendering

    private func render(_ state: SoccerMatchDetailViewState) {
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
            headerViewData = presentation.sections.compactMap { section -> SoccerMatchDetailHeaderViewData? in
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

    private func sectionViewData(at index: Int) -> SoccerMatchDetailSectionViewData? {
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
