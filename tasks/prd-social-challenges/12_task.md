# [12.0] Privacy Controls (M)

## status: pending

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

- [ ] 12.1 Verify PrivacySettings entity exists
  - Should already exist from Task 2.0 in SocialModels.swift
  - struct PrivacySettings { var shareWorkoutData: Bool }

- [ ] 12.2 Implement UserRepository.updatePrivacySettings
  - Method signature: updatePrivacySettings(userId: String, settings: PrivacySettings) async throws
  - Update /users/{userId}.privacySettings in Firestore

- [ ] 12.3 Create PrivacySettingsView
  - `/Presentation/Features/Profile/PrivacySettingsView.swift`
  - Toggle: "Share workout completions with groups"
  - Explanation text: "Your workout completions (count and dates) are shared with group members for leaderboards. Exercise details and workout plans are never shared."
  - onChange → call UserRepository.updatePrivacySettings

- [ ] 12.4 Create PrivacySettingsViewModel (optional)
  - @MainActor, @Observable
  - Property: shareWorkoutData (bindable)
  - Method: updateSettings() async

- [ ] 12.5 Integrate into Settings/Profile screen
  - Add navigation link to PrivacySettingsView
  - Section: "Privacy" or "Groups & Privacy"

- [ ] 12.6 Handle toggle state persistence
  - Load shareWorkoutData from Firestore on view appear
  - Update Firestore on toggle change
  - Show loading indicator during update

- [ ] 12.7 Update SyncWorkoutCompletionUseCase
  - Already implemented in Task 11.0
  - Verify early-exit when shareWorkoutData = false

- [ ] 12.8 Add privacy disclosure to group creation flow
  - Show alert or info sheet on first group creation
  - "By joining groups, your workout completions will be visible to group members. You can change this in Settings > Privacy."
  - One-time disclosure (track with UserDefaults flag)

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

- [ ] Privacy settings screen accessible from Profile/Settings tab
- [ ] Toggle state loads correctly from Firestore
- [ ] Toggle change updates Firestore immediately
- [ ] SyncWorkoutCompletionUseCase respects toggle (verified in Task 11.0)
- [ ] Explanation text clearly describes what data is shared
- [ ] Default value is true (opt-out model for higher feature adoption)
- [ ] Privacy disclosure shown on first group join
- [ ] No errors when toggle changed while offline (graceful failure)

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

### Files to Create
- `/Presentation/Features/Profile/PrivacySettingsView.swift`
- `/Presentation/Features/Profile/PrivacySettingsViewModel.swift` (optional, can use simple view)

### Files to Modify
- `/Data/Repositories/FirebaseUserRepository.swift` - Add updatePrivacySettings method
- `/Presentation/Features/Profile/ProfileView.swift` or Settings screen - Add navigation link

### Reference Files
- `/Presentation/Features/Profile/` - Existing profile/settings screens for integration
- PrivacySettings entity in `/Domain/Entities/SocialModels.swift`
