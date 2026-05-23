//
//  SportSelectionViewModel.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/23.
//

import Foundation

// MARK: - State

nonisolated enum SportSelectionViewState: Sendable, Equatable {

    case idle
    case loading
    case loaded([SportSelectionViewData])
    case failed(String)
}

// MARK: - SportSelectionViewModel

@MainActor
final class SportSelectionViewModel {

    // MARK: - Properties

    private(set) var state: SportSelectionViewState = .idle {
        didSet {
            onStateChange?(state)
        }
    }

    var onStateChange: ((SportSelectionViewState) -> Void)?

    private let sportCatalogService: SportCatalogServicing

    // MARK: - Initialization

    init(sportCatalogService: SportCatalogServicing) {
        self.sportCatalogService = sportCatalogService
    }

    // MARK: - Public Methods

    func loadSports() async {
        state = .loading

        do {
            let sports = try await sportCatalogService.fetchSports()
            let viewData = sports.map { sport in
                SportSelectionViewData(
                    sport: sport,
                    title: sport.title,
                    subtitle: sport.subtitle,
                    systemImageName: sport.systemImageName
                )
            }

            state = viewData.isEmpty
                ? .failed("No sports available.")
                : .loaded(viewData)
        } catch {
            state = .failed(error.localizedDescription)
            AppLogger.logUIError(
                error,
                message: "Sport catalog loading failed",
                metadata: "source=local-catalog"
            )
        }
    }
}
