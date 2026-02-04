//
//  FeatureFlag.swift
//  FitToday
//
//  Feature flags for remote configuration of features.
//  Used to control feature rollout and A/B testing.
//

import Foundation

// MARK: - Feature Flag Key

/// Keys for remote feature flags controlled via Firebase Remote Config.
/// Each key corresponds to a boolean flag that can be toggled remotely.
enum FeatureFlagKey: String, CaseIterable, Sendable {
    /// Enables personal trainer integration features.
    /// When enabled, users can connect with personal trainers via CMS.
    case personalTrainerEnabled = "personal_trainer_enabled"

    /// Enables synchronization of workouts from CMS.
    /// When enabled, trainer-assigned workouts sync to the user's app.
    case cmsWorkoutSyncEnabled = "cms_workout_sync_enabled"

    /// Enables chat functionality with personal trainers.
    /// When enabled, users can message their assigned trainer.
    case trainerChatEnabled = "trainer_chat_enabled"

    /// Human-readable display name for the feature flag.
    var displayName: String {
        switch self {
        case .personalTrainerEnabled:
            return "Personal Trainer Integration"
        case .cmsWorkoutSyncEnabled:
            return "CMS Workout Sync"
        case .trainerChatEnabled:
            return "Trainer Chat"
        }
    }

    /// Default value when remote config is unavailable.
    var defaultValue: Bool {
        switch self {
        case .personalTrainerEnabled:
            return false
        case .cmsWorkoutSyncEnabled:
            return false
        case .trainerChatEnabled:
            return false
        }
    }
}
