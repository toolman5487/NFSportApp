//
//  NetworkRequest.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/22.
//

import Foundation

nonisolated struct NetworkRequest: Sendable {
    let path: String
    let method: HTTPMethod
    let queryItems: [NetworkQueryItem]
    let headers: [String: String]
    let body: Data?
    let contentType: String?
    let timeoutInterval: TimeInterval?

    init(
        path: String,
        method: HTTPMethod,
        queryItems: [NetworkQueryItem] = [],
        headers: [String: String] = [:],
        body: Data? = nil,
        contentType: String? = nil,
        timeoutInterval: TimeInterval? = nil
    ) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.headers = headers
        self.body = body
        self.contentType = contentType
        self.timeoutInterval = timeoutInterval
    }
}
