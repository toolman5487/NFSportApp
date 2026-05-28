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

    private enum LayoutMetric {
        static let estimatedHeaderHeight: CGFloat = 300
        static let estimatedVenueHeight: CGFloat = 96
    }

    private let viewModel: BasketballMatchDetailViewModel
    private var sections: [BasketballMatchDetailSectionViewData] = []

    init(viewModel: BasketballMatchDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupMatchNavigation() {
        title = viewModel.title
        navigationItem.largeTitleDisplayMode = .never
    }

    override func registerReusableViews() {
        collectionView.register(
            BasketballMatchScoreHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: BasketballMatchScoreHeaderView.reuseIdentifier
        )
        collectionView.register(
            BasketballMatchDetailVenueCell.self,
            forCellWithReuseIdentifier: BasketballMatchDetailVenueCell.reuseIdentifier
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

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        sections.count
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch sectionViewData(at: section) {
        case .some(.header):
            return 1

        case .none:
            return 0
        }
    }

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
            header.pinToVisibleBounds = true
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
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: BasketballMatchDetailVenueCell.reuseIdentifier,
                for: indexPath
            ) as? BasketballMatchDetailVenueCell else {
                return UICollectionViewCell()
            }
            cell.configure(with: viewData.venue)
            return cell

        case .none:
            return UICollectionViewCell()
        }
    }

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

    private func render(_ state: BasketballMatchDetailViewState) {
        switch state {
        case .idle:
            renderLoadingState(.idle)

        case .loading:
            renderLoadingState(.loading)

        case .loaded(let presentation):
            title = presentation.title
            sections = presentation.sections
            collectionView.reloadData()
            renderLoadingState(.idle)

        case .failed(let message):
            sections = []
            collectionView.reloadData()
            renderLoadingState(.failed(message: message))
        }
    }

    private func sectionViewData(at index: Int) -> BasketballMatchDetailSectionViewData? {
        guard sections.indices.contains(index) else {
            return nil
        }

        return sections[index]
    }
}
