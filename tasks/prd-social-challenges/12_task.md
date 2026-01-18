# [12.0] Privacy Controls (M)

## status: completed

<task_context>
<domain>presentation/settings</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>medium</complexity>
<dependencies>user_repository|settings_ui</dependencies>
</task_context>

# Task 12.0: Privacy Controls

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Implement user privacy controls that allow users to opt-out of sharing workout data with their group. This includes creating the UI toggle in settings and syncing the preference to Firestore.

<requirements>
- Add PrivacySettingsView with "Share workout data" toggle
- Integrate into Profile/Settings tab
- Update user.privacySettings in Firestore when toggle changes
- Default value: shareWorkoutData = true (opt-out model)
- SyncWorkoutCompletionUseCase must respect this setting
- Display clear explanation of what data is shared
- Follow SwiftUI @Bindable pattern for toggle state
</requirements>

## Subtasks

- [x] 12.1 Verify PrivacySettings entity exists
  - Exists in SocialModels.swift
  - struct PrivacySettings { var shareWorkoutData: Bool }

- [x] 12.2 Implement UserRepository.updatePrivacySettings
  - Method signature: updatePrivacySettings(userId: String, settings: PrivacySettings) async throws
  - Exists in FirebaseUserRepository.swift

- [x] 12.3 Create PrivacySettingsView
  - `/Presentation/Features/Pro/PrivacySettingsView.swift`
  - Toggle: "Compartilhar treinos com grupos"
  - Explanation text about what data is shared
  - onChange → call UserRepository.updatePrivacySettings

- [x] 12.4 Create PrivacySettingsViewModel
  - `/Presentation/Features/Pro/PrivacySettingsViewModel.swift`
  - @MainActor, @Observable
  - Property: shareWorkoutData (bindable)
  - Methods: loadSettings() and updateSettings() async

- [x] 12.5 Integrate into Settings/Profile screen
  - Added navigation link to PrivacySettingsView via ProfileSettingsSection
  - Added .privacySettings route to AppRoute

- [x] 12.6 Handle toggle state persistence
  - Load shareWorkoutData from Firestore on view appear
  - Update Firestore on toggle change
  - Loading states handled in ViewModel

- [x] 12.7 Update SyncWorkoutCompletionUseCase
  - Already implemented in Task 11.0
  - Verified early-exit when shareWorkoutData = false

- [ ] 12.8 Add privacy disclosure to group creation flow
  - Deferred to future iteration
  - Currently opt-out model with clear explanation in settings

## Implementation Details

Reference **techspec.md** sections:
- "Technical Considerations > Privacy Controls"
- "Data Models > PrivacySettings"

### PrivacySettingsView Implementation
```swift
struct PrivacySettingsView: View {
  @State private var viewModel: PrivacySettingsViewModel

  var body: some View {
    Form {
      Section {
        Toggle("Share workout completions with groups", isOn: $viewModel.shareWorkoutData)
          .onChange(of: viewModel.shareWorkoutData) { _, newValue in
            Task {
              await viewModel.updateSettings()
            }
          }
      } header: {
        Text("Group Data Sharing")
      } footer: {
        Text("Your workout completions (count and dates) are shared with group members for leaderboards. Exercise details and workout plans are never shared.")
          .font(.caption)
      }

      Section {
        Button("Learn More About Privacy") {
          // Open privacy policy or help article
        }
      }
    }
    .navigationTitle("Privacy")
    .task {
      await viewModel.loadSettings()
    }
  }
}
```

### PrivacySettingsViewModel
```swift
@MainActor
@Observable final class PrivacySettingsViewModel {
  var shareWorkoutData: Bool = true
  private(set) var isLoading = false

  private let userRepo: UserRepository
  private let authRepo: AuthenticationRepository
  private let resolver: Resolver

  init(resolver: Resolver) {
    self.resolver = resolver
    self.userRepo = resolver.resolve(UserRepository.self)!
    self.authRepo = resolver.resolve(AuthenticationRepository.self)!
  }

  func loadSettings() async {
    isLoading = true
    defer { isLoading = false }

    do {
      let user = try await authRepo.currentUser()
      shareWorkoutData = user?.privacySettings.shareWorkoutData ?? true
    } catch {
      // Handle error
    }
  }

  func updateSettings() async {
    guard let user = try? await authRepo.currentUser() else { return }

    let newSettings = PrivacySettings(shareWorkoutData: shareWorkoutData)
    try? await userRepo.updatePrivacySettings(userId: user.id, settings: newSettings)
  }
}
```

### UserRepository Method
```swift
// In FirebaseUserRepository.swift
func updatePrivacySettings(userId: String, settings: PrivacySettings) async throws {
  let db = Firestore.firestore()
  try await db.collection("users").document(userId).updateData([
    "privacySettings.shareWorkoutData": settings.shareWorkoutData
  ])
}
```

## Success Criteria

- [x] Privacy settings screen accessible from Profile/Settings tab
- [x] Toggle state loads correctly from Firestore
- [x] Toggle change updates Firestore immediately
- [x] SyncWorkoutCompletionUseCase respects toggle (verified in Task 11.0)
- [x] Explanation text clearly describes what data is shared
- [x] Default value is true (opt-out model for higher feature adoption)
- [ ] Privacy disclosure shown on first group join (deferred)
- [x] No errors when toggle changed while offline (graceful failure)

## Dependencies

**Before starting this task:**
- Task 2.0 (Authentication) must have PrivacySettings entity
- Task 11.0 (Workout Sync) should check privacy settings

**Blocks these tasks:**
- None (privacy controls are independent)

## Notes

- **Opt-Out vs Opt-In**: PRD specifies opt-out (default ON) for higher feature adoption. This is acceptable since data shared is minimal (workout count/dates, not exercise details).
- **GDPR/CCPA**: Ensure compliance by providing clear disclosure and easy opt-out. Privacy policy should document what data is shared.
- **Existing Leaderboard Data**: When user disables sharing, existing leaderboard entries remain (historical data). New workouts won't sync. Consider adding "Remove my data" button (out of scope for MVP).
- **UI Placement**: Ideal location: Settings/Profile → Privacy → Share workout data toggle
- **Offline Updates**: If toggle changed offline, queue for sync when online (Firestore SDK handles this automatically).

## Validation Steps

1. Navigate to Settings/Profile → Privacy
2. Verify toggle shows current state (default: ON)
3. Toggle OFF → verify Firestore updated (check Firebase Console)
4. Complete workout → verify NOT synced to leaderboard
5. Toggle ON again → complete workout → verify synced
6. Toggle OFF while offline → go online → verify update syncs
7. First-time user joins group → verify privacy disclosure shown

## Relevant Files

### Files Created
- `/Presentation/Features/Pro/PrivacySettingsView.swift`
- `/Presentation/Features/Pro/PrivacySettingsViewModel.swift`

### Files Modified
- `/Presentation/Features/Pro/Components/ProfileSettingsSection.swift` - Added privacy settings row
- `/Presentation/Features/Pro/ProfileProView.swift` - Added privacy settings handler
- `/Presentation/Router/AppRouter.swift` - Added .privacySettings route
- `/Presentation/Root/TabRootView.swift` - Added route destination

### Reference Files
- `/Data/Repositories/FirebaseUserRepository.swift` - Has updatePrivacySettings method
- `/Domain/Entities/SocialModels.swift` - PrivacySettings entity
