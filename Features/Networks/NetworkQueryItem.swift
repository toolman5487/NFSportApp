//
//  NetworkQueryItem.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/22.
//

import Foundation

nonisolated struct NetworkQueryItem: Equatable, Sendable {
    let name: String
    let value: String?

    init(name: String, value: String?) {
        self.name = name
        self.value = value
    }

    var urlQueryItem: URLQueryItem {
        URLQueryItem(name: name, value: value)
    }
}
