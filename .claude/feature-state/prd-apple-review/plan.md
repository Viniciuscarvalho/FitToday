# Implementation Plan: App Store Review Request

## Approach

Use Apple's recommended SwiftUI `@Environment(\.requestReview)` pattern (iOS 16+) instead of the UIKit-based `SKStoreReviewController`. This is the modern, idiomatic approach for SwiftUI apps.

## Key Design Decision

Per Apple's sample code, the best pattern is:
1. Use `@Environment(\.requestReview)` in the SwiftUI view
2. Track `processCompletedCount` via `@AppStorage` (or UserDefaults)
3. Track `lastVersionPromptedForReview` to avoid re-prompting same version
4. Add a 2-second delay before showing the prompt
5. Eligibility logic in a testable service struct

## Task Execution Order

1. **AppStorageKeys** — Add review tracking keys
2. **FitTodayApp** — Set `firstLaunchDate` on first launch
3. **AppReviewService** — Create eligibility service (protocol + implementation)
4. **WorkoutCompletionView** — Integrate review request after rating
5. **Unit Tests** — Test eligibility logic
6. **Build Verify** — Final check

## Files to Create
- `Domain/Services/AppReviewService.swift`
- `FitTodayTests/Domain/Services/AppReviewServiceTests.swift`

## Files to Modify
- `Presentation/Support/AppStorageKeys.swift`
- `FitTodayApp.swift`
- `Presentation/Features/Workout/WorkoutCompletionView.swift`
