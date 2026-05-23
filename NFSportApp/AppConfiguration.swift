//
//  AppConfiguration.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/23.
//

import Foundation

nonisolated enum AppConfigurationError: Error, Equatable, LocalizedError, Sendable {

    case missingAPISportsAPIKey

    var errorDescription: String? {
        switch self {
        case .missingAPISportsAPIKey:
            return "API-Sports API key is missing. Set APISportsAPIKey in Info.plist or API_SPORTS_API_KEY in the app scheme environment."
        }
    }
}

nonisolated enum AppConfiguration {

    private static let apiSportsAPIKeyInfoKey = "APISportsAPIKey"
    private static let apiSportsAPIKeyEnvironmentKey = "API_SPORTS_API_KEY"
    private static let unresolvedBuildSettingPrefix = "$("

    static func apiSportsDefaultHeaders() throws -> [String: String] {
        [
            "x-apisports-key": try apiSportsAPIKey()
        ]
    }

    private static func apiSportsAPIKey() throws -> String {
        if let apiKey = configuredValue(
            Bundle.main.object(forInfoDictionaryKey: apiSportsAPIKeyInfoKey) as? String
        ) {
            return apiKey
        }

        if let apiKey = configuredValue(ProcessInfo.processInfo.environment[apiSportsAPIKeyEnvironmentKey]) {
            return apiKey
        }

        throw AppConfigurationError.missingAPISportsAPIKey
    }

    private static func configuredValue(_ value: String?) -> String? {
        guard let trimmedValue = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmedValue.isEmpty,
              !trimmedValue.hasPrefix(unresolvedBuildSettingPrefix) else {
            return nil
        }

        return trimmedValue
    }
}

