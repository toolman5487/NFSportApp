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
        static let estimatedFilterHeaderHeight: CGFloat = SoccerMatchStatsFilterView.preferredHeight
        static let estimatedSectionHeaderHeight: CGFloat = SoccerMatchDetailSectionHeaderView.preferredHeight
        static let estimatedStatsResultHeight: CGFloat = 56
        static let estimatedStatsEmptyHeight: CGFloat = 200
        static let estimatedEventRowHeight: CGFloat = 72
        static let estimatedLineupsHeight: CGFloat = 880
    }

    // MARK: - Properties

    private let viewModel: SoccerMatchDetailViewModel
    private var screenTitle: String
    private let navigationTitleView = MatchDetailNavigationTitleView()
    private let leagueNavigationTitleView = MatchDetailLeagueNavigationTitleView()
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
            SoccerMatchStatsFilterView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: SoccerMatchStatsFilterView.reuseIdentifier
        )
        collectionView.register(
            SoccerMatchDetailSectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: SoccerMatchDetailSectionHeaderView.reuseIdentifier
        )
        collectionView.register(
            SoccerMatchStatsResultCollectionCell.self,
            forCellWithReuseIdentifier: SoccerMatchStatsResultCollectionCell.reuseIdentifier
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

        case .some(.stats):
            return 1

        case .some(.events(let viewData)):
            return viewData.items.count

        case .some(.lineups):
            return 1

        case .none:
            return 0
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
            let itemHeight: NSCollectionLayoutDimension = viewData.hasContent(for: selectedStatsFilter)
                ? .estimated(LayoutMetric.estimatedStatsResultHeight)
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
                filterHeader.zIndex = 10
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
            let section = makeListSectionLayout(itemHeight: .estimated(LayoutMetric.estimatedLineupsHeight))
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
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        header.zIndex = 1
        return header
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        switch sectionViewData(at: indexPath.section) {
        case .some(.header):
            return UICollectionViewCell()

        case .some(.stats(let viewData)):
            return makeStatsResultCell(for: viewData, at: indexPath)

        case .some(.events(let viewData)):
            return makeEventCell(for: viewData, at: indexPath)

        case .some(.lineups(let viewData)):
            return makeLineupCell(for: viewData, at: indexPath)

        case .none:
            return UICollectionViewCell()
        }
    }

    private func makeStatsResultCell(
        for viewData: SoccerMatchDetailStatsViewData,
        at indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard viewData.hasContent(for: selectedStatsFilter) else {
            return makeStatsEmptyCell(for: viewData, at: indexPath)
        }

        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: SoccerMatchStatsResultCollectionCell.reuseIdentifier,
            for: indexPath
        ) as? SoccerMatchStatsResultCollectionCell else {
            return UICollectionViewCell()
        }

        let teamNames = statsResultTeamNames(for: viewData)
        cell.configure(
            contents: viewData.resultContents(for: selectedStatsFilter),
            leadingTeamName: teamNames.leading,
            centerTeamName: teamNames.center,
            trailingTeamName: teamNames.trailing
        )
        return cell
    }

    private func statsResultTeamNames(
        for viewData: SoccerMatchDetailStatsViewData
    ) -> (leading: String?, center: String?, trailing: String?) {
        switch selectedStatsFilter {
        case .home:
            return (nil, viewData.homeTeamName, nil)
        case .total:
            return (viewData.homeTeamName, nil, viewData.awayTeamName)
        case .away:
            return (nil, viewData.awayTeamName, nil)
        }
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
        ) as? SoccerMatchLineupTeamCell else {
            return UICollectionViewCell()
        }

        cell.configure(with: viewData)
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

        let emptyCellText = viewData.emptyCellText
        cell.configure(title: emptyCellText.title, subtitle: emptyCellText.subtitle)

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
            return makeStatsFilterView(
                for: viewData,
                kind: kind,
                at: indexPath
            )

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

    private func makeStatsFilterView(
        for viewData: SoccerMatchDetailStatsViewData,
        kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard viewData.showsFilter,
              let filterView = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: SoccerMatchStatsFilterView.reuseIdentifier,
                for: indexPath
              ) as? SoccerMatchStatsFilterView else {
            return UICollectionReusableView()
        }

        filterView.configure(
            selectedOption: selectedStatsFilter,
            homeTeamName: viewData.homeTeamName,
            homeTeamLogoURL: viewData.homeTeamLogoURL,
            awayTeamName: viewData.awayTeamName,
            awayTeamLogoURL: viewData.awayTeamLogoURL
        )
        filterView.onFilterChanged = { [weak self] option in
            self?.applyStatsFilter(option, section: indexPath.section)
        }
        return filterView
    }

    private func applyStatsFilter(
        _ option: SoccerMatchFilterOption,
        section: Int
    ) {
        guard selectedStatsFilter != option else {
            return
        }

        selectedStatsFilter = option
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.performBatchUpdates {
            collectionView.reloadSections(IndexSet(integer: section))
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
            headerViewData = presentation.headerViewData
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
        guard let headerViewData else {
            navigationItem.titleView = nil
            navigationItem.title = screenTitle
            return
        }

        guard isScrolledAwayFromTop else {
            leagueNavigationTitleView.configure(
                title: screenTitle,
                logoURL: headerViewData.leagueLogoURL
            )
            navigationItem.title = nil
            navigationItem.titleView = leagueNavigationTitleView
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
