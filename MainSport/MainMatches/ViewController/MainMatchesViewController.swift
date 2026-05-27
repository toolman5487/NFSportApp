//
//  MainMatchesViewController.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/25.
//

import SnapKit
import UIKit

// MARK: - MainMatchesViewController

@MainActor
final class MainMatchesViewController: MainBaseViewController, TabBarRootViewController, TabBarRootReselectHandling {

    // MARK: - Layout Metrics

    private enum LayoutMetric {
        static let horizontalInset: CGFloat = 16
        static let sectionTopInset: CGFloat = 8
        static let sectionBottomInset: CGFloat = 16
        static let itemSpacing: CGFloat = 8
        static let estimatedDatePickerHeight: CGFloat = 128
        static let estimatedFilterHeight: CGFloat = 60
        static let estimatedGameHeight: CGFloat = 156
    }

    // MARK: - Properties

    private let viewModel: MainMatchesViewModel
    private var screenTitle: String
    private var sections: [MainMatchesContentSectionViewData] = []
    var makeMatchDetailViewController: ((Int) -> UIViewController)?

    var tabBarItemConfiguration: TabBarItemConfiguration {
        TabBarItemConfiguration(
            title: "Matches",
            systemImageName: "calendar"
        )
    }

    // MARK: - Initialization

    init(viewModel: MainMatchesViewModel) {
        self.viewModel = viewModel
        self.screenTitle = viewModel.title
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

            await viewModel.loadSchedule()
        }
    }

    // MARK: - Setup

    override func setupMainNavigation() {
        title = screenTitle
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.leftBarButtonItem = nil
    }

    override func registerReusableViews() {
        collectionView.register(
            MainMatchesDatePickerCell.self,
            forCellWithReuseIdentifier: MainMatchesDatePickerCell.reuseIdentifier
        )
        collectionView.register(
            MainMatchesFilterCell.self,
            forCellWithReuseIdentifier: MainMatchesFilterCell.reuseIdentifier
        )
        collectionView.register(
            MainMatchesGameCell.self,
            forCellWithReuseIdentifier: MainMatchesGameCell.reuseIdentifier
        )
    }

    override func bindViewModel() {
        super.bindViewModel()

        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }

        render(viewModel.state)
    }

    func refreshOnTabReselection() async {
        await viewModel.loadSchedule()
    }

    // MARK: - Rendering

    private func render(_ state: MainMatchesViewState) {
        switch state {
        case .idle:
            renderLoadingState(.idle)

        case .loading:
            renderLoadingState(.loading)

        case .loaded(let presentation):
            renderLoadingState(.idle)
            applyPresentation(presentation)

        case .empty(let presentation, let message):
            applyPresentation(presentation)
            renderLoadingState(.empty(message: message))

        case .failed(let message):
            screenTitle = viewModel.title
            title = screenTitle
            sections = []
            collectionView.reloadData()
            renderLoadingState(.failed(message: message))
        }
    }

    private func applyPresentation(_ presentation: MainMatchesPresentation) {
        screenTitle = presentation.title
        title = presentation.title
        sections = presentation.sections
        collectionView.reloadData()
    }

    // MARK: - Section Access

    private func sectionViewData(at index: Int) -> MainMatchesContentSectionViewData? {
        guard sections.indices.contains(index) else {
            return nil
        }

        return sections[index]
    }

    // MARK: - Layout

    override func makeSectionLayout(
        for sectionIndex: Int,
        environment: NSCollectionLayoutEnvironment
    ) -> NSCollectionLayoutSection {
        switch sectionViewData(at: sectionIndex) {
        case .some(.datePicker):
            return makeDatePickerSectionLayout()

        case .some(.filter):
            return makeFilterSectionLayout()

        case .some(.scheduleGroup), .none:
            return makeScheduleGroupSectionLayout()
        }
    }

    private func makeDatePickerSectionLayout() -> NSCollectionLayoutSection {
        makeListSectionLayout(
            itemHeight: .estimated(LayoutMetric.estimatedDatePickerHeight),
            contentInsets: NSDirectionalEdgeInsets(
                top: LayoutMetric.sectionTopInset,
                leading: LayoutMetric.horizontalInset,
                bottom: 0,
                trailing: LayoutMetric.horizontalInset
            ),
            interGroupSpacing: 0
        )
    }

    private func makeFilterSectionLayout() -> NSCollectionLayoutSection {
        makeListSectionLayout(
            itemHeight: .estimated(LayoutMetric.estimatedFilterHeight),
            contentInsets: NSDirectionalEdgeInsets(
                top: 0,
                leading: LayoutMetric.horizontalInset,
                bottom: LayoutMetric.sectionTopInset,
                trailing: LayoutMetric.horizontalInset
            ),
            interGroupSpacing: 0
        )
    }

    private func makeScheduleGroupSectionLayout() -> NSCollectionLayoutSection {
        let section = makeListSectionLayout(
            itemHeight: .estimated(LayoutMetric.estimatedGameHeight),
            contentInsets: NSDirectionalEdgeInsets(
                top: LayoutMetric.sectionTopInset,
                leading: LayoutMetric.horizontalInset,
                bottom: LayoutMetric.sectionBottomInset,
                trailing: LayoutMetric.horizontalInset
            ),
            interGroupSpacing: LayoutMetric.itemSpacing
        )
        return section
    }

    // MARK: - UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        sections.count
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        switch sectionViewData(at: section) {
        case .some(.datePicker), .some(.filter):
            return 1

        case .some(.scheduleGroup(let groupViewData)):
            return groupViewData.items.count

        case .none:
            return 0
        }
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        switch sectionViewData(at: indexPath.section) {
        case .some(.datePicker(let datePickerViewData)):
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MainMatchesDatePickerCell.reuseIdentifier,
                for: indexPath
            ) as? MainMatchesDatePickerCell else {
                return UICollectionViewCell()
            }

            cell.configure(with: datePickerViewData)
            cell.onDateSelected = { [weak self] date in
                Task {
                    await self?.viewModel.selectDate(date)
                }
            }
            cell.onPreviousPageSelected = { [weak self] in
                Task {
                    await self?.viewModel.selectPreviousDatePage()
                }
            }
            cell.onNextPageSelected = { [weak self] in
                Task {
                    await self?.viewModel.selectNextDatePage()
                }
            }
            return cell

        case .some(.filter(let filterViewData)):
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MainMatchesFilterCell.reuseIdentifier,
                for: indexPath
            ) as? MainMatchesFilterCell else {
                return UICollectionViewCell()
            }

            cell.configure(with: filterViewData)
            cell.onFilterSelected = { [weak self] option in
                self?.viewModel.selectFilterOption(option)
            }
            return cell

        case .some(.scheduleGroup(let groupViewData)):
            guard groupViewData.items.indices.contains(indexPath.item),
                  let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: MainMatchesGameCell.reuseIdentifier,
                    for: indexPath
                  ) as? MainMatchesGameCell else {
                return UICollectionViewCell()
            }

            cell.configure(with: groupViewData.items[indexPath.item])
            return cell

        case .none:
            return UICollectionViewCell()
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        guard case .some(.scheduleGroup(let groupViewData)) = sectionViewData(at: indexPath.section),
              groupViewData.items.indices.contains(indexPath.item),
              let detailViewController = makeMatchDetailViewController?(groupViewData.items[indexPath.item].id) else {
            return
        }

        navigationController?.pushViewController(detailViewController, animated: true)
    }

}
