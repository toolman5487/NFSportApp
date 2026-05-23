//
//  SportSelectionViewController.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/23.
//

import SnapKit
import UIKit

@MainActor
final class SportSelectionViewController: BaseViewController {

    // MARK: - Layout Metrics

    private enum LayoutMetric {
        static let horizontalInset: CGFloat = 16
        static let sectionSpacing: CGFloat = 24
        static let itemSpacing: CGFloat = 12
        static let itemHeight: CGFloat = 96
    }

    // MARK: - Dependencies

    private let viewModel: SportSelectionViewModel

    // MARK: - UI Components

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: makeCollectionViewLayout()
        )
        collectionView.backgroundColor = .backgroundColor
        collectionView.alwaysBounceVertical = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()

    // MARK: - State

    private var sports: [SportSelectionViewData] = []

    // MARK: - Callbacks

    var onSportSelected: ((SportType) -> Void)?

    // MARK: - Initialization

    init(viewModel: SportSelectionViewModel) {
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

            await viewModel.loadSports()
        }
    }

    // MARK: - Setup

    override func setupNavigation() {
        super.setupNavigation()

        title = "Choose Sport"
        navigationItem.largeTitleDisplayMode = .always
    }

    override func setupView() {
        super.setupView()
        view.backgroundColor = .backgroundColor

        view.addSubview(collectionView)

        collectionView.register(
            SportSelectionCell.self,
            forCellWithReuseIdentifier: SportSelectionCell.reuseIdentifier
        )
    }

    override func setupConstraints() {
        super.setupConstraints()

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    override func bindViewModel() {
        super.bindViewModel()

        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }

        render(viewModel.state)
    }

    // MARK: - Rendering

    private func render(_ state: SportSelectionViewState) {
        switch state {
        case .idle:
            renderLoadingState(.idle)
        case .loading:
            renderLoadingState(.loading)
        case .loaded(let sports):
            renderLoadingState(.idle)
            self.sports = sports
            collectionView.reloadData()
        case .failed(let message):
            renderLoadingState(.failed(message: message))
        }
    }

    // MARK: - Layout

    private func makeCollectionViewLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { _, _ in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .absolute(LayoutMetric.itemHeight)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = LayoutMetric.itemSpacing
            section.contentInsets = NSDirectionalEdgeInsets(
                top: LayoutMetric.sectionSpacing,
                leading: LayoutMetric.horizontalInset,
                bottom: LayoutMetric.sectionSpacing,
                trailing: LayoutMetric.horizontalInset
            )
            return section
        }
    }
}

// MARK: - UICollectionViewDataSource

extension SportSelectionViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        sports.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: SportSelectionCell.reuseIdentifier,
            for: indexPath
        ) as? SportSelectionCell else {
            return UICollectionViewCell()
        }

        cell.configure(with: sports[indexPath.item])
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension SportSelectionViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let sport = sports[indexPath.item].sport
        onSportSelected?(sport)
    }
}

// MARK: - SportSelectionCell

private final class SportSelectionCell: UICollectionViewCell {

    static let reuseIdentifier = "SportSelectionCell"

    private let iconContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondaryBackgroundColor
        view.layer.cornerRadius = 24
        return view
    }()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .primaryLabel
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .primaryLabel
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabelColor
        label.numberOfLines = 2
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let disclosureImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        imageView.tintColor = .secondaryLabelColor
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewData: SportSelectionViewData) {
        titleLabel.text = viewData.title
        subtitleLabel.text = viewData.subtitle
        iconImageView.image = UIImage(systemName: viewData.systemImageName)
    }

    private func setupView() {
        contentView.backgroundColor = .secondaryBackgroundColor
        contentView.layer.cornerRadius = 8
        contentView.layer.masksToBounds = true

        contentView.addSubview(iconContainerView)
        iconContainerView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(disclosureImageView)

        iconContainerView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(48)
        }

        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(28)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(16)
            make.leading.equalTo(iconContainerView.snp.trailing).offset(16)
            make.trailing.lessThanOrEqualTo(disclosureImageView.snp.leading).offset(-16)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalTo(titleLabel)
            make.trailing.equalTo(disclosureImageView.snp.leading).offset(-16)
            make.bottom.lessThanOrEqualToSuperview().inset(16)
        }

        disclosureImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(16)
        }
    }
}
