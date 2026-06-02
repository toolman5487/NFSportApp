//
//  BaseballMatchStatsResultCollectionCell.swift
//  NFSportApp
//
//  Created by Codex on 2026/6/1.
//

import SnapKit
import UIKit

// MARK: - BaseballMatchStatsResultCollectionCell

final class BaseballMatchStatsResultCollectionCell: UICollectionViewCell {

    // MARK: - Constants

    static let reuseIdentifier = "BaseballMatchStatsResultCollectionCell"

    // MARK: - Layout Metrics

    private enum LayoutMetric {
        static let headerHeight: CGFloat = 24
        static let headerBottomSpacing: CGFloat = 8
        static let interItemSpacing: CGFloat = 8
        static let estimatedItemHeight: CGFloat = 56
    }

    // MARK: - Properties

    private var contents: [BaseballMatchStatsResultContent] = []
    private var currentCollectionViewHeight: CGFloat = 0

    // MARK: - UI Components

    private let leadingTeamLabel = BaseballMatchStatsResultCollectionCell.makeTeamLabel(alignment: .left)
    private let centerTeamLabel = BaseballMatchStatsResultCollectionCell.makeTeamLabel(alignment: .center)
    private let trailingTeamLabel = BaseballMatchStatsResultCollectionCell.makeTeamLabel(alignment: .right)

    private lazy var teamNameStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            leadingTeamLabel,
            centerTeamLabel,
            trailingTeamLabel
        ])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fillEqually
        return stackView
    }()

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
            BaseballMatchStatsComparisonRowCell.self,
            forCellWithReuseIdentifier: BaseballMatchStatsComparisonRowCell.reuseIdentifier
        )
        collectionView.register(
            BaseballMatchStatsValueRowCell.self,
            forCellWithReuseIdentifier: BaseballMatchStatsValueRowCell.reuseIdentifier
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
        configureTeamNames(leading: nil, center: nil, trailing: nil)
        collectionView.reloadData()
    }

    // MARK: - Configuration

    func configure(
        contents: [BaseballMatchStatsResultContent],
        leadingTeamName: String?,
        centerTeamName: String?,
        trailingTeamName: String?
    ) {
        self.contents = contents
        configureTeamNames(
            leading: leadingTeamName,
            center: centerTeamName,
            trailing: trailingTeamName
        )
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
        contentView.addSubview(teamNameStackView)
        contentView.addSubview(collectionView)

        teamNameStackView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(LayoutMetric.headerHeight)
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(teamNameStackView.snp.bottom).offset(LayoutMetric.headerBottomSpacing)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func configureTeamNames(
        leading: String?,
        center: String?,
        trailing: String?
    ) {
        leadingTeamLabel.text = leading
        centerTeamLabel.text = center
        trailingTeamLabel.text = trailing
    }

    private static func makeTeamLabel(alignment: NSTextAlignment) -> UILabel {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .secondaryLabel
        label.textAlignment = alignment
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.82
        return label
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
            + LayoutMetric.headerHeight
            + LayoutMetric.headerBottomSpacing
        guard currentCollectionViewHeight != fittingHeight else {
            return currentCollectionViewHeight
        }

        currentCollectionViewHeight = fittingHeight
        return fittingHeight
    }
}

// MARK: - UICollectionViewDataSource

extension BaseballMatchStatsResultCollectionCell: UICollectionViewDataSource {

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
                withReuseIdentifier: BaseballMatchStatsComparisonRowCell.reuseIdentifier,
                for: indexPath
            ) as? BaseballMatchStatsComparisonRowCell else {
                return UICollectionViewCell()
            }

            cell.configure(with: row)
            return cell

        case .value(let row):
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: BaseballMatchStatsValueRowCell.reuseIdentifier,
                for: indexPath
            ) as? BaseballMatchStatsValueRowCell else {
                return UICollectionViewCell()
            }

            cell.configure(with: row)
            return cell
        }
    }
}
