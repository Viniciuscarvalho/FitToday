# Tasks: Firebase Remote Config Feature Flags

## Task 1: Expand FeatureFlagKey Enum
**File:** `Domain/Entities/FeatureFlag.swift`
**Description:** Add 17 new cases to `FeatureFlagKey` enum with proper rawValue, displayName, and defaultValue.
**Acceptance:** All 20 total cases compile. `allCases` returns 20 items. Defaults: existing features = `true`, unreleased = `false`.

## Task 2: Wire Operational Flags (Maintenance + Force Update)
**File:** `Presentation/Root/TabRootView.swift`
**Description:** Add `FeatureFlagChecking` dependency. On `.task`, check `maintenanceModeEnabled` and `forceUpdateEnabled`. Show overlay views when enabled.
**Acceptance:** Setting `maintenance_mode_enabled = true` in Firebase shows maintenance banner. Setting `force_update_enabled = true` shows full-screen update dialog.

## Task 3: Wire Feature Flags in Key ViewModels
**Files:** HomeViewModel, ChallengesViewModel, GroupsViewModel
**Description:** Inject `FeatureFlagChecking` and add `isXxxEnabled` state properties. Check flags in `onAppear()` or equivalent. Hide/show features conditionally in views.
**Acceptance:** Disabling `challenges_enabled` hides challenges content. Disabling `social_groups_enabled` hides group features. Disabling `ai_workout_generation_enabled` hides AI section.

## Task 4: Generate Firebase Remote Config Key List
**File:** Output a markdown file with all 20 keys, types, and default values ready for Firebase Console setup.
**Description:** Create a reference document listing every Remote Config parameter to configure in Firebase Console.
**Acceptance:** Document contains all 20 keys with their types and default values.

## Task 5: Build Verification
**Description:** Build the project and verify no compilation errors. Verify existing features work with flags at default values (no regression).
**Acceptance:** BUILD SUCCEEDED. App launches normally with all features visible.
