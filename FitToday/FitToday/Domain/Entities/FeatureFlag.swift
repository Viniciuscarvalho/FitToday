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

    // MARK: - AI Features

    /// Enables AI-powered workout generation (OpenAI).
    case aiWorkoutGenerationEnabled = "ai_workout_generation_enabled"

    /// Enables AI exercise substitution during active workout.
    case aiExerciseSubstitutionEnabled = "ai_exercise_substitution_enabled"

    // MARK: - Social Features

    /// Enables group creation, joining, and management.
    case socialGroupsEnabled = "social_groups_enabled"

    /// Enables workout challenges within groups.
    case challengesEnabled = "challenges_enabled"

    /// Enables leaderboard ranking in groups.
    case leaderboardEnabled = "leaderboard_enabled"

    /// Enables photo check-in for challenge validation.
    case checkInEnabled = "check_in_enabled"

    /// Enables group streak tracking and display.
    case groupStreaksEnabled = "group_streaks_enabled"

    // MARK: - Health & Sync

    /// Enables Apple Health read/write integration.
    case healthKitSyncEnabled = "healthkit_sync_enabled"

    /// Enables activity stats with Swift Charts.
    case statsChartsEnabled = "stats_charts_enabled"

    // MARK: - Content

    /// Enables structured training programs.
    case programsEnabled = "programs_enabled"

    /// Enables user-created workout templates.
    case customWorkoutsEnabled = "custom_workouts_enabled"

    /// Enables exercise library/explorer (Wger API).
    case exerciseLibraryEnabled = "exercise_library_enabled"

    // MARK: - Personal Trainer

    /// Enables personal trainer integration features.
    /// When enabled, users can connect with personal trainers via CMS.
    case personalTrainerEnabled = "personal_trainer_enabled"

    /// Enables synchronization of workouts from CMS.
    /// When enabled, trainer-assigned workouts sync to the user's app.
    case cmsWorkoutSyncEnabled = "cms_workout_sync_enabled"

    /// Enables chat functionality with personal trainers.
    /// When enabled, users can message their assigned trainer.
    case trainerChatEnabled = "trainer_chat_enabled"

    // MARK: - Monetization & UX

    /// Enables paywall/Pro upgrade prompts.
    case paywallEnabled = "paywall_enabled"

    /// Enables App Store review request after workout completion.
    case reviewRequestEnabled = "review_request_enabled"

    // MARK: - Operational

    /// Shows maintenance banner and disables write operations.
    case maintenanceModeEnabled = "maintenance_mode_enabled"

    /// Shows non-dismissable update dialog directing to App Store.
    case forceUpdateEnabled = "force_update_enabled"

    // MARK: - Display Name

    /// Human-readable display name for the feature flag.
    var displayName: String {
        switch self {
        // AI
        case .aiWorkoutGenerationEnabled: return "AI Workout Generation"
        case .aiExerciseSubstitutionEnabled: return "AI Exercise Substitution"
        // Social
        case .socialGroupsEnabled: return "Social Groups"
        case .challengesEnabled: return "Challenges"
        case .leaderboardEnabled: return "Leaderboard"
        case .checkInEnabled: return "Check-In"
        case .groupStreaksEnabled: return "Group Streaks"
        // Health
        case .healthKitSyncEnabled: return "Apple Health Sync"
        case .statsChartsEnabled: return "Stats Charts"
        // Content
        case .programsEnabled: return "Training Programs"
        case .customWorkoutsEnabled: return "Custom Workouts"
        case .exerciseLibraryEnabled: return "Exercise Library"
        // Personal Trainer
        case .personalTrainerEnabled: return "Personal Trainer Integration"
        case .cmsWorkoutSyncEnabled: return "CMS Workout Sync"
        case .trainerChatEnabled: return "Trainer Chat"
        // Monetization
        case .paywallEnabled: return "Paywall"
        case .reviewRequestEnabled: return "Review Request"
        // Operational
        case .maintenanceModeEnabled: return "Maintenance Mode"
        case .forceUpdateEnabled: return "Force Update"
        }
    }

    // MARK: - Default Value

    /// Default value when remote config is unavailable.
    /// Existing features default to `true` (no regression).
    /// Unreleased features default to `false`.
    var defaultValue: Bool {
        switch self {
        // Unreleased features — disabled by default
        case .personalTrainerEnabled,
             .cmsWorkoutSyncEnabled,
             .trainerChatEnabled,
             .maintenanceModeEnabled,
             .forceUpdateEnabled:
            return false

        // All existing features — enabled by default
        default:
            return true
        }
    }
}
