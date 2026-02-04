//
//  FeatureFlagUseCase.swift
//  FitToday
//
//  Use case for checking feature flags with entitlement integration.
//  Combines remote feature flags with subscription-based access control.
//

import Foundation

// MARK: - Feature Flag Checking Protocol

/// Protocol for checking feature flag states with entitlement integration.
protocol FeatureFlagChecking: Sendable {
    /// Checks if a feature flag is enabled.
    /// - Parameter key: The feature flag key to check.
    /// - Returns: `true` if the feature is enabled, `false` otherwise.
    func isFeatureEnabled(_ key: FeatureFlagKey) async -> Bool

    /// Checks feature access combining feature flag and entitlement.
    /// - Parameters:
    ///   - feature: The Pro feature to check access for.
    ///   - flag: The feature flag that must be enabled.
    /// - Returns: The result of the access check.
    func checkFeatureAccess(_ feature: ProFeature, flag: FeatureFlagKey) async -> FeatureAccessResult

    /// Refreshes feature flags from remote config.
    /// - Throws: Error if refresh fails.
    func refreshFlags() async throws
}

// MARK: - Feature Flag Use Case

/// Use case implementation for feature flag checking.
/// Logic: Check flag first, then delegate to entitlement if enabled.
final class FeatureFlagUseCase: FeatureFlagChecking, @unchecked Sendable {
    // MARK: - Properties

    private let featureFlagRepository: FeatureFlagRepository
    private let featureGating: FeatureGating

    // MARK: - Initialization

    /// Creates a new feature flag use case.
    /// - Parameters:
    ///   - featureFlagRepository: Repository for feature flag access.
    ///   - featureGating: Use case for entitlement-based feature gating.
    init(
        featureFlagRepository: FeatureFlagRepository,
        featureGating: FeatureGating
    ) {
        self.featureFlagRepository = featureFlagRepository
        self.featureGating = featureGating
    }

    // MARK: - FeatureFlagChecking

    func isFeatureEnabled(_ key: FeatureFlagKey) async -> Bool {
        await featureFlagRepository.isEnabled(key)
    }

    func checkFeatureAccess(
        _ feature: ProFeature,
        flag: FeatureFlagKey
    ) async -> FeatureAccessResult {
        // Step 1: Check if feature flag is enabled
        let flagEnabled = await featureFlagRepository.isEnabled(flag)

        guard flagEnabled else {
            // Feature flag is disabled - feature is not available
            return .featureDisabled(reason: "\(flag.displayName) is not available yet.")
        }

        // Step 2: Feature flag is enabled, check entitlement
        return await featureGating.checkAccess(to: feature)
    }

    func refreshFlags() async throws {
        try await featureFlagRepository.fetchAndActivate()
    }
}
