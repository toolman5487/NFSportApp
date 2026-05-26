//
//  MainSoccerSearchViewController.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/26.
//

import Combine
import SnapKit
import UIKit

// MARK: - MainSoccerSearchViewController

@MainActor
final class MainSoccerSearchViewController: MainBaseViewController, TabBarRootViewController, TabBarRootReselectHandling {

    // MARK: - Layout Metrics

    private enum LayoutMetric {
        static let horizontalInset: CGFloat = 16
        static let sectionTopInset: CGFloat = 12
        static let sectionBottomInset: CGFloat = 16
        static let itemSpacing: CGFloat = 8
        static let estimatedTeamHeight: CGFloat = 84
    }

    // MARK: - Properties

    private let viewModel: MainSoccerSearchViewModel
    private var teams: [MainSoccerSearchTeamViewData] = []
    private var cancellables = Set<AnyCancellable>()

    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = "Search teams"
        return searchController
    }()

    private let stateView = ContentStateView()

    var tabBarItemConfiguration: TabBarItemConfiguration {
        TabBarItemConfiguration(
            title: "Search",
            systemImageName: "magnifyingglass"
        )
    }

    // MARK: - Initialization

    init(viewModel: MainSoccerSearchViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    override func setupMainNavigation() {
        title = viewModel.title
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.leftBarButtonItem = nil
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    override func registerReusableViews() {
        collectionView.register(
            MainSoccerSearchTeamCell.self,
            forCellWithReuseIdentifier: MainSoccerSearchTeamCell.reuseIdentifier
        )
    }

    override func configureCollectionView() {
        collectionView.keyboardDismissMode = .onDrag
    }

    override func setupContentView() {
        collectionView.backgroundView = stateView
    }

    override func bindViewModel() {
        super.bindViewModel()

        render(viewModel.state)

        viewModel.$state
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                Task { @MainActor in
                    self?.render(state)
                }
            }
            .store(in: &cancellables)
    }

    func refreshOnTabReselection() async {
        await viewModel.refreshCurrentQuery()
    }

    // MARK: - Rendering

    private func render(_ state: MainSoccerSearchViewState) {
        switch state {
        case .idle:
            teams = []
            collectionView.reloadData()
            stateView.render(
                .message(
                    style: .information,
                    systemImageName: "magnifyingglass",
                    title: "Search teams",
                    subtitle: "Enter at least 3 characters."
                )
            )

        case .waitingForInput(let query, let minimumCharacterCount):
            teams = []
            collectionView.reloadData()
            stateView.render(
                .message(
                    style: .information,
                    systemImageName: "text.magnifyingglass",
                    title: "Keep typing",
                    subtitle: "\(minimumCharacterCount - query.count) more characters needed."
                )
            )

        case .loading(let query):
            teams = []
            collectionView.reloadData()
            stateView.render(.loading(title: "Searching", subtitle: query))

        case .loaded(let presentation):
            teams = presentation.teams
            stateView.render(.hidden)
            collectionView.reloadData()

        case .empty(let query):
            teams = []
            collectionView.reloadData()
            stateView.render(
                .message(
                    style: .information,
                    systemImageName: "magnifyingglass",
                    title: "No teams found",
                    subtitle: query
                )
            )

        case .failed(_, let message):
            teams = []
            collectionView.reloadData()
            stateView.render(
                .message(
                    style: .error,
                    systemImageName: nil,
                    title: "Unable to search",
                    subtitle: message
                )
            )
        }
    }

    // MARK: - Layout

    override func makeSectionLayout(
        for sectionIndex: Int,
        environment: NSCollectionLayoutEnvironment
    ) -> NSCollectionLayoutSection {
        makeListSectionLayout(
            itemHeight: .estimated(LayoutMetric.estimatedTeamHeight),
            contentInsets: NSDirectionalEdgeInsets(
                top: LayoutMetric.sectionTopInset,
                leading: LayoutMetric.horizontalInset,
                bottom: LayoutMetric.sectionBottomInset,
                trailing: LayoutMetric.horizontalInset
            ),
            interGroupSpacing: LayoutMetric.itemSpacing
        )
    }

    // MARK: - UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        teams.isEmpty ? 0 : 1
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        teams.count
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard teams.indices.contains(indexPath.item),
              let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MainSoccerSearchTeamCell.reuseIdentifier,
                for: indexPath
              ) as? MainSoccerSearchTeamCell else {
            return UICollectionViewCell()
        }

        cell.configure(with: teams[indexPath.item])
        return cell
    }
}

// MARK: - UISearchResultsUpdating

extension MainSoccerSearchViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        viewModel.updateSearchText(searchController.searchBar.text ?? "")
    }
}

// MARK: - UISearchBarDelegate

extension MainSoccerSearchViewController: UISearchBarDelegate {

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
