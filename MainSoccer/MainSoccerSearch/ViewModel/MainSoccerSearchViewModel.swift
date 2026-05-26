//
//  MainSoccerSearchViewModel.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/26.
//

import Combine
import Foundation

// MARK: - State

nonisolated enum MainSoccerSearchViewState: Equatable, Sendable {

    case idle
    case waitingForInput(query: String, minimumCharacterCount: Int)
    case loading(query: String)
    case loaded(MainSoccerSearchPresentation)
    case empty(query: String)
    case failed(query: String, message: String)
}

// MARK: - MainSoccerSearchViewModel

@MainActor
final class MainSoccerSearchViewModel {

    // MARK: - Constants

    private enum Constant {
        static let minimumCharacterCount = 3
        static let debounceDelayMilliseconds = 350
    }

    // MARK: - Properties

    @Published private(set) var state: MainSoccerSearchViewState = .idle

    var title: String {
        "Search"
    }

    private let selectedSport: SportType
    private let searchService: MainSoccerSearchServicing
    @Published private var searchText = ""
    private var cancellables = Set<AnyCancellable>()
    private var searchTask: Task<Void, Never>?
    private var currentQuery = ""

    // MARK: - Initialization

    init(
        selectedSport: SportType,
        searchService: MainSoccerSearchServicing
    ) {
        self.selectedSport = selectedSport
        self.searchService = searchService
        bindSearchText()
    }

    deinit {
        searchTask?.cancel()
    }

    // MARK: - Public Methods

    func updateSearchText(_ text: String) {
        searchText = text
    }

    func refreshCurrentQuery() async {
        let query = currentQuery

        guard query.count >= Constant.minimumCharacterCount else {
            return
        }

        searchTask?.cancel()
        await searchTeams(matching: query)
    }

    // MARK: - Binding

    private func bindSearchText() {
        $searchText
            .map { Self.normalizedSearchText(from: $0) }
            .removeDuplicates()
            .sink { [weak self] query in
                Task { @MainActor in
                    self?.handleNormalizedSearchTextChange(query)
                }
            }
            .store(in: &cancellables)

        $searchText
            .map { Self.normalizedSearchText(from: $0) }
            .removeDuplicates()
            .filter { $0.count >= Constant.minimumCharacterCount }
            .debounce(
                for: .milliseconds(Constant.debounceDelayMilliseconds),
                scheduler: DispatchQueue.main
            )
            .sink { [weak self] query in
                Task { @MainActor in
                    self?.startSearchTask(matching: query)
                }
            }
            .store(in: &cancellables)
    }

    private func handleNormalizedSearchTextChange(_ query: String) {
        currentQuery = query
        searchTask?.cancel()

        guard !query.isEmpty else {
            state = .idle
            return
        }

        guard query.count >= Constant.minimumCharacterCount else {
            state = .waitingForInput(
                query: query,
                minimumCharacterCount: Constant.minimumCharacterCount
            )
            return
        }
    }

    private func startSearchTask(matching query: String) {
        searchTask?.cancel()
        searchTask = Task { [weak self] in
            await self?.searchTeams(matching: query)
        }
    }

    // MARK: - Private Methods

    private func searchTeams(matching query: String) async {
        state = .loading(query: query)

        do {
            let teams = try await searchService.searchTeams(matching: query)
            guard !Task.isCancelled else {
                return
            }

            let presentation = makePresentation(
                from: teams,
                query: query
            )

            switch presentation.teams.isEmpty {
            case true:
                state = .empty(query: query)

            case false:
                state = .loaded(presentation)
            }
        } catch {
            guard !Task.isCancelled else {
                return
            }

            state = .failed(
                query: query,
                message: error.localizedDescription
            )
            AppLogger.logUIError(
                error,
                message: "Main soccer search loading failed",
                metadata: "sport=\(selectedSport.id), query=\(query)"
            )
        }
    }

    private func makePresentation(
        from teams: [MainSoccerSearchTeam],
        query: String
    ) -> MainSoccerSearchPresentation {
        MainSoccerSearchPresentation(
            query: query,
            teams: teams.map(makeTeamViewData)
        )
    }

    private func makeTeamViewData(from team: MainSoccerSearchTeam) -> MainSoccerSearchTeamViewData {
        MainSoccerSearchTeamViewData(
            id: team.id,
            name: team.name,
            subtitle: makeSubtitle(from: team),
            logoURL: team.logoURL,
            fallbackSystemImageName: "soccerball"
        )
    }

    private func makeSubtitle(from team: MainSoccerSearchTeam) -> String {
        let values = [
            team.city,
            team.countryName,
            team.code
        ].compactMap { value -> String? in
            guard let value,
                  !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return nil
            }

            return value
        }

        return values.isEmpty ? "Team" : values.joined(separator: " / ")
    }

    private nonisolated static func normalizedSearchText(from text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
