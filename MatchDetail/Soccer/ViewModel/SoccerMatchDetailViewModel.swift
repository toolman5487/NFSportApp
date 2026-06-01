//
//  SoccerMatchDetailViewModel.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/26.
//

import Foundation

// MARK: - State

nonisolated enum SoccerMatchDetailViewState: Equatable, Sendable {

    case idle
    case loading
    case loaded(SoccerMatchDetailPresentation)
    case failed(message: String)
}

// MARK: - SoccerMatchDetailViewModel

@MainActor
final class SoccerMatchDetailViewModel {

    // MARK: - Properties

    private(set) var state: SoccerMatchDetailViewState = .idle {
        didSet {
            onStateChange?(state)
        }
    }

    var onStateChange: ((SoccerMatchDetailViewState) -> Void)?

    var title: String {
        "Match Detail"
    }

    private let fixtureID: Int
    private let detailService: SoccerMatchDetailServicing
    private let presentationBuilder: SoccerMatchDetailPresentationBuilder

    // MARK: - Initialization

    init(
        fixtureID: Int,
        detailService: SoccerMatchDetailServicing,
        presentationBuilder: SoccerMatchDetailPresentationBuilder = SoccerMatchDetailPresentationBuilder()
    ) {
        self.fixtureID = fixtureID
        self.detailService = detailService
        self.presentationBuilder = presentationBuilder
    }

    // MARK: - Actions

    func loadMatchDetail() async {
        state = .loading

        do {
            let detail = try await detailService.fetchMatchDetail(fixtureID: fixtureID)
            state = .loaded(presentationBuilder.makePresentation(from: detail))
        } catch {
            state = .failed(message: error.localizedDescription)
            AppLogger.logUIError(
                error,
                message: "Soccer match detail loading failed",
                metadata: "fixtureID=\(fixtureID)"
            )
        }
    }
}
