//
//  MainBaseViewController.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/22.
//

import SnapKit
import UIKit

@MainActor
class MainBaseViewController: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    // MARK: - Layout Metrics

    private enum LayoutMetric {
        static let sectionInset: CGFloat = 16
        static let interGroupSpacing: CGFloat = 12
        static let estimatedItemHeight: CGFloat = 56
    }

    // MARK: - Properties

    private(set) lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: makeCollectionViewLayout()
        )
        collectionView.backgroundColor = .backgroundColor
        collectionView.alwaysBounceVertical = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.contentInsetAdjustmentBehavior = .automatic
        collectionView.keyboardDismissMode = .onDrag
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()

    // MARK: - Override Points

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

    func registerReusableViews() {}

    func configureCollectionView() {}

    func setupContentView() {}

    func setupContentConstraints() {}

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

    func reloadCollectionViewLayout(animated: Bool = false) {
        collectionView.setCollectionViewLayout(makeCollectionViewLayout(), animated: animated)
    }
}

// MARK: - UICollectionViewDataSource

extension MainBaseViewController {

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
