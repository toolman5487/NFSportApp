//
//  AppLogger.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/22.
//

import OSLog

// MARK: - LogErrorContext

nonisolated struct LogErrorContext: Sendable {

    let message: String
    let file: String
    let function: String
    let line: Int

    init(
        _ message: String,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        self.message = message
        self.file = file
        self.function = function
        self.line = line
    }
}

// MARK: - AppLogger

nonisolated final class AppLogger: @unchecked Sendable {

    static let shared = AppLogger()

    private let logger = Logger(subsystem: "NFSportApp", category: "Error")

    private init() {}

    func error(
        _ error: Error,
        context: LogErrorContext,
        metadata: [String: String] = [:]
    ) {
        var details = metadata
        details["errorType"] = String(describing: type(of: error))
        details["errorMessage"] = error.localizedDescription

        self.error(
            context.message,
            metadata: details,
            file: context.file,
            function: context.function,
            line: context.line
        )
    }

    func error(
        _ message: String,
        metadata: [String: String] = [:],
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        let detail = formattedMetadata(metadata)

        switch detail.isEmpty {
        case true:
            logger.error("[Error] \(message, privacy: .public) | source=\(file, privacy: .public):\(line) \(function, privacy: .public)")
        case false:
            logger.error("[Error] \(message, privacy: .public) | \(detail, privacy: .public) | source=\(file, privacy: .public):\(line) \(function, privacy: .public)")
        }
    }

    private func formattedMetadata(_ metadata: [String: String]) -> String {
        guard !metadata.isEmpty else {
            return ""
        }

        return metadata
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: ", ")
    }
}
