//
//  RemoteConfigService.swift
//  FitToday
//
//  Service that wraps Firebase Remote Config for feature flag management.
//  Uses actor isolation for thread-safe access to remote config values.
//

import Foundation
import FirebaseRemoteConfig

// MARK: - Remote Config Service Protocol

/// Protocol for remote configuration service.
protocol RemoteConfigServicing: Sendable {
    /// Fetches and activates remote config values from Firebase.
    /// - Throws: Error if fetch or activation fails.
    func fetchAndActivate() async throws

    /// Gets the boolean value for a feature flag key.
    /// - Parameter key: The feature flag key to retrieve.
    /// - Returns: The boolean value for the key, or the default value if not set.
    func getValue(for key: FeatureFlagKey) async -> Bool

    /// Sets the minimum fetch interval for remote config.
    /// - Parameter interval: The minimum interval between fetches.
    func setMinimumFetchInterval(_ interval: TimeInterval) async
}

// MARK: - Remote Config Service

/// Actor that wraps Firebase Remote Config for thread-safe feature flag access.
/// Manages fetching, caching, and retrieving remote configuration values.
actor RemoteConfigService: RemoteConfigServicing {
    // MARK: - Properties

    private let remoteConfig: RemoteConfig
    private var lastFetchTime: Date?
    private var isConfigured = false

    /// Default fetch interval: 12 hours for production.
    static let defaultFetchInterval: TimeInterval = 12 * 60 * 60

    /// Debug fetch interval: 0 seconds for immediate updates.
    static let debugFetchInterval: TimeInterval = 0

    // MARK: - Initialization

    init(remoteConfig: RemoteConfig = RemoteConfig.remoteConfig()) {
        self.remoteConfig = remoteConfig
        configureDefaults()
    }

    // MARK: - Configuration

    /// Configures default values for all feature flags.
    private func configureDefaults() {
        guard !isConfigured else { return }

        // Build default values dictionary
        var defaults: [String: NSObject] = [:]
        for key in FeatureFlagKey.allCases {
            defaults[key.rawValue] = NSNumber(value: key.defaultValue)
        }

        remoteConfig.setDefaults(defaults)

        // Configure settings
        let settings = RemoteConfigSettings()
        #if DEBUG
        settings.minimumFetchInterval = Self.debugFetchInterval
        #else
        settings.minimumFetchInterval = Self.defaultFetchInterval
        #endif

        remoteConfig.configSettings = settings
        isConfigured = true
    }

    // MARK: - Public Methods

    func fetchAndActivate() async throws {
        do {
            let status = try await remoteConfig.fetchAndActivate()

            switch status {
            case .successFetchedFromRemote:
                lastFetchTime = Date()
                #if DEBUG
                print("[RemoteConfig] Successfully fetched from remote")
                #endif

            case .successUsingPreFetchedData:
                #if DEBUG
                print("[RemoteConfig] Using pre-fetched data")
                #endif

            case .error:
                #if DEBUG
                print("[RemoteConfig] Fetch returned error status")
                #endif

            @unknown default:
                #if DEBUG
                print("[RemoteConfig] Unknown fetch status")
                #endif
            }
        } catch {
            #if DEBUG
            print("[RemoteConfig] Fetch failed: \(error.localizedDescription)")
            #endif
            throw RemoteConfigError.fetchFailed(underlying: error)
        }
    }

    func getValue(for key: FeatureFlagKey) async -> Bool {
        let configValue = remoteConfig.configValue(forKey: key.rawValue)

        // If no value is set remotely, use default
        if configValue.source == .static {
            return key.defaultValue
        }

        return configValue.boolValue
    }

    func setMinimumFetchInterval(_ interval: TimeInterval) async {
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = interval
        remoteConfig.configSettings = settings
    }

    // MARK: - Debug Helpers

    #if DEBUG
    /// Returns the source of a config value (for debugging).
    func getValueSource(for key: FeatureFlagKey) async -> RemoteConfigSource {
        remoteConfig.configValue(forKey: key.rawValue).source
    }

    /// Returns all current config values (for debugging).
    func getAllValues() async -> [String: Bool] {
        var values: [String: Bool] = [:]
        for key in FeatureFlagKey.allCases {
            values[key.rawValue] = await getValue(for: key)
        }
        return values
    }
    #endif
}

// MARK: - Remote Config Error

/// Errors that can occur during remote config operations.
enum RemoteConfigError: LocalizedError {
    case fetchFailed(underlying: Error)
    case activationFailed(underlying: Error)
    case notConfigured

    var errorDescription: String? {
        switch self {
        case .fetchFailed(let error):
            return "Failed to fetch remote config: \(error.localizedDescription)"
        case .activationFailed(let error):
            return "Failed to activate remote config: \(error.localizedDescription)"
        case .notConfigured:
            return "Remote config service is not configured"
        }
    }
}
