//
//  AppLogger.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/22.
//

import OSLog

// MARK: - AppLogCategory

nonisolated enum AppLogCategory: String, CaseIterable, Sendable {

    case app = "App"
    case lifecycle = "Lifecycle"
    case network = "Network"
    case connectivity = "Connectivity"
    case decoding = "Decoding"
    case persistence = "Persistence"
    case keychain = "Keychain"
    case authentication = "Authentication"
    case navigation = "Navigation"
    case ui = "UI"
    case cache = "Cache"
    case performance = "Performance"
    case backgroundTask = "BackgroundTask"
    case notifications = "Notifications"
    case deeplink = "Deeplink"
    case sync = "Sync"
    case media = "Media"
    case analytics = "Analytics"
    case security = "Security"
    case thirdParty = "ThirdParty"
    case domain = "Domain"
    case search = "Search"
    case configuration = "Configuration"

    var logger: Logger {
        Logger(subsystem: AppLogger.subsystem, category: rawValue)
    }
}

// MARK: - AppLogger

nonisolated enum AppLogger {

    // MARK: - Configuration

    static let subsystem = Bundle.main.bundleIdentifier ?? "NFSportApp"

    // MARK: - Core

    static let app = AppLogCategory.app.logger
    static let lifecycle = AppLogCategory.lifecycle.logger
    static let configuration = AppLogCategory.configuration.logger

    // MARK: - Infrastructure

    static let network = AppLogCategory.network.logger
    static let connectivity = AppLogCategory.connectivity.logger
    static let persistence = AppLogCategory.persistence.logger
    static let keychain = AppLogCategory.keychain.logger
    static let cache = AppLogCategory.cache.logger
    static let sync = AppLogCategory.sync.logger
    static let backgroundTask = AppLogCategory.backgroundTask.logger

    // MARK: - Feature

    static let authentication = AppLogCategory.authentication.logger
    static let navigation = AppLogCategory.navigation.logger
    static let ui = AppLogCategory.ui.logger
    static let domain = AppLogCategory.domain.logger
    static let search = AppLogCategory.search.logger
    static let media = AppLogCategory.media.logger
    static let notifications = AppLogCategory.notifications.logger
    static let deeplink = AppLogCategory.deeplink.logger

    // MARK: - Observability

    static let performance = AppLogCategory.performance.logger
    static let analytics = AppLogCategory.analytics.logger
    static let security = AppLogCategory.security.logger

    // MARK: - Integration

    static let decoding = AppLogCategory.decoding.logger
    static let thirdParty = AppLogCategory.thirdParty.logger

    // MARK: - Network Logging

    static func logNetworkRequest(method: String, url: String) {
        network.debug("\(method, privacy: .public) \(url, privacy: .public)")
    }

    static func logNetworkError(_ error: Error, method: String, path: String) {
        network.error(
            "Network request failed | method=\(method, privacy: .public), path=\(path, privacy: .public), error=\(error.localizedDescription, privacy: .public)"
        )
    }

    // MARK: - Decoding Logging

    static func logDecodingError(_ error: Error, method: String, path: String) {
        decoding.error(
            "Network response decoding failed | method=\(method, privacy: .public), path=\(path, privacy: .public), error=\(error.localizedDescription, privacy: .public)"
        )
    }

    // MARK: - UI Logging

    static func logUIError(_ error: Error, message: String, metadata: String) {
        ui.error(
            "\(message, privacy: .public) | \(metadata, privacy: .public), error=\(error.localizedDescription, privacy: .public)"
        )
    }
}
