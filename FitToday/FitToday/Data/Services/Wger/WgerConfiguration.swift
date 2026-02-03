//
//  WgerConfiguration.swift
//  FitToday
//
//  Configuration for Wger API service.
//

import Foundation

/// Configuration for Wger API.
struct WgerConfiguration: Sendable {
    /// Base URL for Wger API (v2).
    let baseURL: URL

    /// Default language for API requests.
    let defaultLanguage: WgerLanguageCode

    /// Request timeout in seconds.
    let timeoutInterval: TimeInterval

    /// Maximum results per page.
    let pageLimit: Int

    /// Cache TTL in seconds (7 days default).
    let cacheTTL: TimeInterval

    /// Default configuration for production.
    nonisolated(unsafe) static let `default` = WgerConfiguration(
        baseURL: URL(string: "https://wger.de/api/v2")!,
        defaultLanguage: .portuguese,
        timeoutInterval: 15.0,
        pageLimit: 50,
        cacheTTL: 7 * 24 * 60 * 60 // 7 days
    )

    /// Configuration for testing with shorter cache.
    nonisolated(unsafe) static let testing = WgerConfiguration(
        baseURL: URL(string: "https://wger.de/api/v2")!,
        defaultLanguage: .english,
        timeoutInterval: 5.0,
        pageLimit: 20,
        cacheTTL: 60 // 1 minute for testing
    )

    init(
        baseURL: URL,
        defaultLanguage: WgerLanguageCode = .portuguese,
        timeoutInterval: TimeInterval = 15.0,
        pageLimit: Int = 50,
        cacheTTL: TimeInterval = 7 * 24 * 60 * 60
    ) {
        self.baseURL = baseURL
        self.defaultLanguage = defaultLanguage
        self.timeoutInterval = timeoutInterval
        self.pageLimit = pageLimit
        self.cacheTTL = cacheTTL
    }
}
