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
    }

    // MARK: - Properties

    private let viewModel: BaseballMatchDetailViewModel
    private let navigationTitleView = MatchDetailNavigationTitleView()
    private var screenTitle: String
    private var headerViewData: BaseballMatchDetailHeaderViewData?
    private var sections: [BaseballMatchDetailSectionViewData] = []

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
            BaseballMatchDetailVenueCell.self,
            forCellWithReuseIdentifier: BaseballMatchDetailVenueCell.reuseIdentifier
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
        case .some(.header(let viewData)):
            return viewData.venue == nil ? 0 : 1

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
                itemHeight: .estimated(LayoutMetric.estimatedVenueHeight)
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

        case .none:
            return makeListSectionLayout()
        }
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        switch sectionViewData(at: indexPath.section) {
        case .some(.header(let viewData)):
            guard let venue = viewData.venue,
                  let cell = collectionView.dequeueReusableCell(
                      withReuseIdentifier: BaseballMatchDetailVenueCell.reuseIdentifier,
                      for: indexPath
                  ) as? BaseballMatchDetailVenueCell else {
                return UICollectionViewCell()
            }
            cell.configure(with: venue)
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
        case .some(.header(let viewData)):
            guard let headerView = collectionView.dequeueReusableSupplementaryView(
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
            headerViewData = presentation.sections.compactMap { section -> BaseballMatchDetailHeaderViewData? in
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
