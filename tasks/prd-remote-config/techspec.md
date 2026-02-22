# Technical Specification: Firebase Remote Config Feature Flags

## Architecture Overview

The existing architecture is fully layered and requires only expansion, not restructuring:

```
Firebase Remote Config (server)
       ↓
RemoteConfigService (actor)           ← Already exists, auto-configures defaults
       ↓
RemoteConfigFeatureFlagRepository     ← Already exists, UserDefaults cache
       ↓
FeatureFlagUseCase                    ← Already exists, combines with EntitlementPolicy
       ↓
ViewModels (inject FeatureFlagChecking) ← Wire new checks
```

## Changes Required

### 1. Expand FeatureFlagKey Enum

**File:** `Domain/Entities/FeatureFlag.swift`

Add 17 new cases to `FeatureFlagKey`. Each new case needs:
- `rawValue` matching the Firebase Remote Config key
- `displayName` computed property
- `defaultValue` computed property

Existing cases remain unchanged. New defaults: `true` for existing features, `false` for unreleased.

### 2. Wire Flags in ViewModels

For each feature, the relevant ViewModel checks the flag before presenting the feature. The pattern is:

```swift
// In ViewModel
private let featureFlags: FeatureFlagChecking?

var isFeatureAvailable: Bool = true

func onAppear() async {
    isFeatureAvailable = await featureFlags?.isFeatureEnabled(.someFlag) ?? true
}
```

```swift
// In View
if viewModel.isFeatureAvailable {
    FeatureContent()
}
```

**ViewModels to modify:**

| ViewModel | Flag | What to gate |
|---|---|---|
| `HomeViewModel` | `aiWorkoutGenerationEnabled` | AI workout section visibility |
| `ChallengesViewModel` | `challengesEnabled` | Challenges tab content |
| `GroupsViewModel` | `socialGroupsEnabled` | Group features |
| `ActivityStatsViewModel` | `statsChartsEnabled` | Charts section |
| `ProgramsListViewModel` or equivalent | `programsEnabled` | Programs tab content |
| `LibraryViewModel` | `exerciseLibraryEnabled` | Library tab content |
| `ProfileProView` | `paywallEnabled` | Pro upgrade prompts |

**Note:** Not every feature needs ViewModel-level gating. Some features (like HealthKit) are already conditionally available based on device capability. The flags serve as a remote kill-switch.

### 3. Operational Flags

#### Maintenance Mode
- Check `maintenanceModeEnabled` on app launch
- If `true`, show a `MaintenanceBannerView` overlay
- Optionally disable write operations (save workout, check-in, etc.)

#### Force Update
- Check `forceUpdateEnabled` on app launch
- If `true`, show a full-screen non-dismissable view with App Store link
- Implementation: A `.fullScreenCover` on the root view

### 4. Remote Config Defaults (auto-configured)

The existing `RemoteConfigService.configureDefaults()` already iterates `FeatureFlagKey.allCases` and registers defaults. No changes needed to this method — it will automatically pick up new cases.

### 5. UserDefaults Cache (auto-configured)

The existing `RemoteConfigFeatureFlagRepository` already caches all keys after `fetchAndActivate()`. No changes needed.

## Files to Modify

| File | Change |
|---|---|
| `Domain/Entities/FeatureFlag.swift` | Add 17 new cases to enum |
| `Presentation/Features/Home/HomeViewModel.swift` | Add AI flag check |
| `Presentation/Features/Activity/ViewModels/ChallengesViewModel.swift` | Add challenges flag check |
| `Presentation/Features/Groups/ViewModels/GroupsViewModel.swift` | Add groups flag check |
| `Presentation/Features/Activity/ViewModels/ActivityStatsViewModel.swift` | Add stats flag check |
| `Presentation/Root/TabRootView.swift` | Add maintenance/force-update overlays |

## Files NOT to Modify

- `RemoteConfigService.swift` — already handles all cases automatically
- `RemoteConfigFeatureFlagRepository.swift` — already caches all cases
- `FeatureFlagUseCase.swift` — already works with any key
- `AppContainer.swift` — DI already wired for FeatureFlagChecking

## Testing Strategy

1. Unit test: Verify all `FeatureFlagKey.allCases` have valid `rawValue`, `displayName`, and `defaultValue`
2. Unit test: Verify default values match spec (existing features = true, unreleased = false)
3. Manual test: Toggle flags in Firebase Console, verify behavior in debug build

## Risk Assessment

- **Low risk:** Expanding an enum and adding optional checks
- **Zero regression:** All new flags default to `true` for existing features
- **Graceful degradation:** UserDefaults cache ensures offline behavior
