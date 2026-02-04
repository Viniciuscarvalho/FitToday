//
//  FeatureFlagRepository.swift
//  FitToday
//
//  Protocol defining the contract for feature flag access.
//  Abstracts the remote config implementation from domain logic.
//

import Foundation

// MARK: - Feature Flag Repository Protocol

/// Repository protocol for checking feature flag states.
/// Provides a clean abstraction over remote config implementation.
protocol FeatureFlagRepository: Sendable {
    /// Checks if a feature flag is enabled.
    /// - Parameter key: The feature flag key to check.
    /// - Returns: `true` if the feature is enabled, `false` otherwise.
    func isEnabled(_ key: FeatureFlagKey) async -> Bool

    /// Fetches and activates the latest feature flag values from remote config.
    /// Should be called at app launch and periodically.
    /// - Throws: Error if fetch or activation fails.
    func fetchAndActivate() async throws
}
