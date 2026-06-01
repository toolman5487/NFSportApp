//
//  SoccerMatchStatsResultCollectionCell.swift
//  NFSportApp
//
//  Created by Codex on 2026/6/1.
//

import SnapKit
import UIKit

// MARK: - SoccerMatchStatsResultCollectionCell

final class SoccerMatchStatsResultCollectionCell: UICollectionViewCell {

    // MARK: - Constants

    static let reuseIdentifier = "SoccerMatchStatsResultCollectionCell"

    // MARK: - Layout Metrics

    private enum LayoutMetric {
        static let interItemSpacing: CGFloat = 8
        static let estimatedItemHeight: CGFloat = 56
    }

    // MARK: - Properties

    private var contents: [SoccerMatchStatsResultContent] = []
    private var currentCollectionViewHeight: CGFloat = 0

    // MARK: - UI Components

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: makeCollectionViewLayout()
        )
        collectionView.backgroundColor = .clear
        collectionView.isScrollEnabled = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.register(
            SoccerMatchStatsComparisonRowCell.self,
            forCellWithReuseIdentifier: SoccerMatchStatsComparisonRowCell.reuseIdentifier
        )
        collectionView.register(
            SoccerMatchStatsValueRowCell.self,
            forCellWithReuseIdentifier: SoccerMatchStatsValueRowCell.reuseIdentifier
        )
        return collectionView
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        contents = []
        collectionView.reloadData()
    }

    // MARK: - Configuration

    func configure(contents: [SoccerMatchStatsResultContent]) {
        self.contents = contents
        collectionView.reloadData()
        updateCollectionViewHeightIfNeeded(for: collectionView.bounds.width)
    }

    override func preferredLayoutAttributesFitting(
        _ layoutAttributes: UICollectionViewLayoutAttributes
    ) -> UICollectionViewLayoutAttributes {
        let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
        attributes.frame.size.height = updateCollectionViewHeightIfNeeded(
            for: layoutAttributes.frame.width
        )
        return attributes
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateCollectionViewHeightIfNeeded(for: bounds.width)
    }

    // MARK: - Setup

    private func setupView() {
        contentView.backgroundColor = .clear
        contentView.addSubview(collectionView)

        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func makeCollectionViewLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(LayoutMetric.estimatedItemHeight)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = LayoutMetric.interItemSpacing
        return UICollectionViewCompositionalLayout(section: section)
    }

    @discardableResult
    private func updateCollectionViewHeightIfNeeded(for width: CGFloat) -> CGFloat {
        guard width > 0 else {
            return currentCollectionViewHeight
        }

        collectionView.bounds.size.width = width
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.layoutIfNeeded()

        let fittingHeight = collectionView.collectionViewLayout.collectionViewContentSize.height
        guard currentCollectionViewHeight != fittingHeight else {
            return currentCollectionViewHeight
        }

        currentCollectionViewHeight = fittingHeight
        return fittingHeight
    }
}

// MARK: - UICollectionViewDataSource

extension SoccerMatchStatsResultCollectionCell: UICollectionViewDataSource {

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        contents.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard contents.indices.contains(indexPath.item) else {
            return UICollectionViewCell()
        }

        switch contents[indexPath.item] {
        case .comparison(let row):
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: SoccerMatchStatsComparisonRowCell.reuseIdentifier,
                for: indexPath
            ) as? SoccerMatchStatsComparisonRowCell else {
                return UICollectionViewCell()
            }

            cell.configure(with: row)
            return cell

        case .value(let row):
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: SoccerMatchStatsValueRowCell.reuseIdentifier,
                for: indexPath
            ) as? SoccerMatchStatsValueRowCell else {
                return UICollectionViewCell()
            }

            cell.configure(with: row)
            return cell
        }
    }
}
