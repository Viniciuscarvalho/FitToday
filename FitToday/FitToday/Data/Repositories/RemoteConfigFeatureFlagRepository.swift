//
//  RemoteConfigFeatureFlagRepository.swift
//  FitToday
//
//  Implementation of FeatureFlagRepository using Firebase Remote Config.
//  Includes UserDefaults caching for offline support.
//

import Foundation

// MARK: - Remote Config Feature Flag Repository

/// Implementation of FeatureFlagRepository that uses Firebase Remote Config
/// with UserDefaults caching for offline access.
final class RemoteConfigFeatureFlagRepository: FeatureFlagRepository, @unchecked Sendable {
    // MARK: - Properties

    private let remoteConfigService: RemoteConfigServicing
    private let userDefaults: UserDefaults
    private let cacheKeyPrefix = "feature_flag_cache_"

    // MARK: - Initialization

    /// Creates a new feature flag repository.
    /// - Parameters:
    ///   - remoteConfigService: The remote config service to use for fetching values.
    ///   - userDefaults: UserDefaults instance for caching (defaults to standard).
    init(
        remoteConfigService: RemoteConfigServicing,
        userDefaults: UserDefaults = .standard
    ) {
        self.remoteConfigService = remoteConfigService
        self.userDefaults = userDefaults
    }

    // MARK: - FeatureFlagRepository

    func isEnabled(_ key: FeatureFlagKey) async -> Bool {
        // Get value from remote config service
        let remoteValue = await remoteConfigService.getValue(for: key)

        // Cache the value for offline access
        cacheValue(remoteValue, for: key)

        return remoteValue
    }

    func fetchAndActivate() async throws {
        try await remoteConfigService.fetchAndActivate()

        // After successful fetch, update cache for all keys
        for key in FeatureFlagKey.allCases {
            let value = await remoteConfigService.getValue(for: key)
            cacheValue(value, for: key)
        }
    }

    // MARK: - Caching

    /// Caches a feature flag value to UserDefaults.
    /// - Parameters:
    ///   - value: The boolean value to cache.
    ///   - key: The feature flag key.
    private func cacheValue(_ value: Bool, for key: FeatureFlagKey) {
        let cacheKey = cacheKeyPrefix + key.rawValue
        userDefaults.set(value, forKey: cacheKey)
    }

    /// Retrieves a cached feature flag value from UserDefaults.
    /// - Parameter key: The feature flag key.
    /// - Returns: The cached value, or the default value if not cached.
    func getCachedValue(for key: FeatureFlagKey) -> Bool {
        let cacheKey = cacheKeyPrefix + key.rawValue

        // Check if value exists in cache
        if userDefaults.object(forKey: cacheKey) != nil {
            return userDefaults.bool(forKey: cacheKey)
        }

        // Return default value if not cached
        return key.defaultValue
    }

    /// Clears all cached feature flag values.
    func clearCache() {
        for key in FeatureFlagKey.allCases {
            let cacheKey = cacheKeyPrefix + key.rawValue
            userDefaults.removeObject(forKey: cacheKey)
        }
    }
}
