//
//  BaseballMatchDetailViewController.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/28.
//

import SnapKit
import UIKit

@MainActor
final class BaseballMatchDetailViewController: MatchBaseViewController {

    // MARK: - Layout Metrics

    private enum LayoutMetric {
        static let estimatedHeaderHeight: CGFloat = 360
        static let estimatedVenueHeight: CGFloat = 96
        static let estimatedFilterHeaderHeight: CGFloat = BaseballMatchFilterView.preferredHeight
        static let estimatedStatsResultHeight: CGFloat = 56
        static let estimatedStatsEmptyHeight: CGFloat = 200
    }

    // MARK: - Properties

    private let viewModel: BaseballMatchDetailViewModel
    private let navigationTitleView = MatchDetailNavigationTitleView()
    private let leagueNavigationTitleView = MatchDetailLeagueNavigationTitleView()
    private var screenTitle: String
    private var headerViewData: BaseballMatchDetailHeaderViewData?
    private var sections: [BaseballMatchDetailSectionViewData] = []
    private var selectedStatsFilter: BaseballMatchFilterOption = .total

    // MARK: - Initialization

    init(viewModel: BaseballMatchDetailViewModel) {
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
            BaseballMatchScoreHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: BaseballMatchScoreHeaderView.reuseIdentifier
        )
        collectionView.register(
            BaseballMatchDetailVenueFooterView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: BaseballMatchDetailVenueFooterView.reuseIdentifier
        )
        collectionView.register(
            BaseballMatchFilterView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: BaseballMatchFilterView.reuseIdentifier
        )
        collectionView.register(
            BaseballMatchStatsResultCollectionCell.self,
            forCellWithReuseIdentifier: BaseballMatchStatsResultCollectionCell.reuseIdentifier
        )
        collectionView.register(
            BaseballMatchStatsEmptyCell.self,
            forCellWithReuseIdentifier: BaseballMatchStatsEmptyCell.reuseIdentifier
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
            return makeStatsResultCell(for: viewData, at: indexPath)

        case .none:
            return UICollectionViewCell()
        }
    }

    private func makeStatsResultCell(
        for viewData: BaseballMatchDetailStatsViewData,
        at indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard viewData.hasContent(for: selectedStatsFilter) else {
            return makeStatsEmptyCell(for: viewData, at: indexPath)
        }

        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: BaseballMatchStatsResultCollectionCell.reuseIdentifier,
            for: indexPath
        ) as? BaseballMatchStatsResultCollectionCell else {
            return UICollectionViewCell()
        }

        cell.configure(contents: viewData.resultContents(for: selectedStatsFilter))
        return cell
    }

    private func makeStatsEmptyCell(
        for viewData: BaseballMatchDetailStatsViewData,
        at indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: BaseballMatchStatsEmptyCell.reuseIdentifier,
            for: indexPath
        ) as? BaseballMatchStatsEmptyCell else {
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
            withReuseIdentifier: BaseballMatchDetailVenueFooterView.reuseIdentifier,
            for: indexPath
           ) as? BaseballMatchDetailVenueFooterView {
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

        case .some(.header(let viewData)):
            guard kind == UICollectionView.elementKindSectionHeader,
                  let headerView = collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: BaseballMatchScoreHeaderView.reuseIdentifier,
                    for: indexPath
                  ) as? BaseballMatchScoreHeaderView else {
                return UICollectionReusableView()
            }

            headerView.configure(with: viewData)
            return headerView

        case .none:
            return UICollectionReusableView()
        }
    }

    private func makeStatsFilterView(
        for viewData: BaseballMatchDetailStatsViewData,
        kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard viewData.showsFilter,
              kind == UICollectionView.elementKindSectionHeader,
              let filterView = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: BaseballMatchFilterView.reuseIdentifier,
                for: indexPath
              ) as? BaseballMatchFilterView else {
            return UICollectionReusableView()
        }

        filterView.configure(
            selectedOption: selectedStatsFilter,
            homeTeamName: viewData.homeTeamName,
            awayTeamName: viewData.awayTeamName
        )
        filterView.onFilterChanged = { [weak self] option in
            self?.applyStatsFilter(option, section: indexPath.section)
        }
        return filterView
    }

    private func applyStatsFilter(
        _ option: BaseballMatchFilterOption,
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

    // MARK: - Rendering

    private func render(_ state: BaseballMatchDetailViewState) {
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

    private func sectionViewData(at index: Int) -> BaseballMatchDetailSectionViewData? {
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
