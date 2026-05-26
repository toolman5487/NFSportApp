//
//  MainSoccerMatchesViewController.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/26.
//

import SnapKit
import UIKit

// MARK: - MainSoccerMatchesViewController

@MainActor
final class MainSoccerMatchesViewController: MainBaseViewController, TabBarRootViewController, TabBarRootReselectHandling {

    private enum LayoutMetric {
        static let horizontalInset: CGFloat = 16
        static let sectionTopInset: CGFloat = 8
        static let sectionBottomInset: CGFloat = 16
        static let itemSpacing: CGFloat = 8
        static let estimatedDatePickerHeight: CGFloat = 128
        static let estimatedFilterHeight: CGFloat = 60
        static let estimatedGameHeight: CGFloat = 156
    }

    private let viewModel: MainSoccerMatchesViewModel
    private var screenTitle: String
    private var sections: [MainSoccerMatchesContentSectionViewData] = []

    var tabBarItemConfiguration: TabBarItemConfiguration {
        TabBarItemConfiguration(
            title: "Matches",
            systemImageName: "calendar"
        )
    }

    init(viewModel: MainSoccerMatchesViewModel) {
        self.viewModel = viewModel
        self.screenTitle = viewModel.title
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        Task { [weak self] in
            guard let self else {
                return
            }

            await viewModel.loadSchedule()
        }
    }

    override func setupMainNavigation() {
        title = screenTitle
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.leftBarButtonItem = nil
    }

    override func registerReusableViews() {
        collectionView.register(
            MainSoccerMatchesDatePickerCell.self,
            forCellWithReuseIdentifier: MainSoccerMatchesDatePickerCell.reuseIdentifier
        )
        collectionView.register(
            MainSoccerMatchesFilterCell.self,
            forCellWithReuseIdentifier: MainSoccerMatchesFilterCell.reuseIdentifier
        )
        collectionView.register(
            MainSoccerMatchesGameCell.self,
            forCellWithReuseIdentifier: MainSoccerMatchesGameCell.reuseIdentifier
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

    private func render(_ state: MainSoccerMatchesViewState) {
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

    private func applyPresentation(_ presentation: MainSoccerMatchesPresentation) {
        screenTitle = presentation.title
        title = presentation.title
        sections = presentation.sections
        collectionView.reloadData()
    }

    private func sectionViewData(at index: Int) -> MainSoccerMatchesContentSectionViewData? {
        guard sections.indices.contains(index) else {
            return nil
        }

        return sections[index]
    }

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
        makeListSectionLayout(
            itemHeight: .estimated(LayoutMetric.estimatedGameHeight),
            contentInsets: NSDirectionalEdgeInsets(
                top: LayoutMetric.sectionTopInset,
                leading: LayoutMetric.horizontalInset,
                bottom: LayoutMetric.sectionBottomInset,
                trailing: LayoutMetric.horizontalInset
            ),
            interGroupSpacing: LayoutMetric.itemSpacing
        )
    }

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
                withReuseIdentifier: MainSoccerMatchesDatePickerCell.reuseIdentifier,
                for: indexPath
            ) as? MainSoccerMatchesDatePickerCell else {
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
                withReuseIdentifier: MainSoccerMatchesFilterCell.reuseIdentifier,
                for: indexPath
            ) as? MainSoccerMatchesFilterCell else {
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
                    withReuseIdentifier: MainSoccerMatchesGameCell.reuseIdentifier,
                    for: indexPath
                  ) as? MainSoccerMatchesGameCell else {
                return UICollectionViewCell()
            }

            cell.configure(with: groupViewData.items[indexPath.item])
            return cell

        case .none:
            return UICollectionViewCell()
        }
    }
}
