# Technical Specification

**Project Name:** App Store Review Request
**Version:** 1.0
**Date:** 2026-02-18
**Author:** Claude
**Status:** Approved

---

## Overview

### Problem Statement
FitToday has no mechanism to prompt users for App Store reviews. Without prompting, review volume stays low and tends to be negatively biased.

### Proposed Solution
Create an `AppReviewService` that uses Apple's `SKStoreReviewController.requestReview(in:)` to prompt users at key success moments. Integrate it at the workout completion flow with smart eligibility checks.

### Goals
- Prompt users for App Store review after positive experiences
- Respect Apple's throttling guidelines (max 3/year enforced by OS)
- Add app-level throttling to avoid annoying users
- Keep implementation simple and testable

---

## Scope

### In Scope
- `AppReviewService` with eligibility logic
- `AppStorageKeys` extension for review tracking
- Integration in `WorkoutCompletionView`
- Unit tests for eligibility logic

### Out of Scope
- Custom review UI (Apple mandates using their API)
- Analytics tracking of actual review submissions (Apple provides no callback)
- A/B testing of trigger points

---

## Technical Approach

### Architecture

Follows existing MVVM architecture. The review service lives in `Domain/Services/` as a simple struct with protocol for testability.

```
Domain/Services/
└── AppReviewService.swift       ← Eligibility logic + protocol

Presentation/Support/
└── AppStorageKeys.swift         ← Extended with review keys

Presentation/Features/Workout/
└── WorkoutCompletionView.swift  ← Integration point
```

### Key Technologies
- StoreKit: `SKStoreReviewController.requestReview(in:)` for iOS 16+
- UserDefaults: Persistence for review request tracking via AppStorageKeys

### Components

#### Component 1: AppReviewService

**Purpose:** Centralized review request logic with eligibility checks.

**Interface:**
```swift
protocol AppReviewRequesting {
    func requestReviewIfEligible() async
    func isEligible(completedWorkoutsCount: Int) -> Bool
}

struct AppReviewService: AppReviewRequesting {
    // Eligibility criteria:
    // 1. completedWorkoutsCount >= 3
    // 2. At least 7 days since first app launch
    // 3. At least 30 days since last review request

    func requestReviewIfEligible() async
    func isEligible(completedWorkoutsCount: Int) -> Bool
}
```

**Responsibilities:**
- Check all eligibility criteria
- Call `SKStoreReviewController.requestReview(in:)` via UIKit window scene
- Record request timestamp in UserDefaults

#### Component 2: AppStorageKeys Extension

**Purpose:** Add review-related persistence keys.

```swift
extension AppStorageKeys {
    static let lastReviewRequestDate = "lastReviewRequestDate"
    static let firstLaunchDate = "firstLaunchDate"
}
```

### Data Model

No new entities needed. Review state is stored entirely in UserDefaults:
- `lastReviewRequestDate: Date?` — when last review was requested
- `firstLaunchDate: Date?` — when app was first launched (set once)

Workout count is read from existing `WorkoutHistoryRepository.count()`.

### Integration Point

In `WorkoutCompletionView.swift`, after the user completes rating (or skips it), call `AppReviewService.requestReviewIfEligible()`. This ensures:
- User has seen their completion summary
- User has had the chance to rate the workout
- The positive moment has been absorbed

**Location:** Inside the `.task` modifier or after `hasRated` becomes `true`.

---

## Implementation Considerations

### Design Patterns
- Protocol-based service for testability (`AppReviewRequesting`)
- Value type (struct) since no mutable state beyond UserDefaults

### Error Handling
Review request failures are silently ignored — Apple may suppress the prompt based on internal heuristics. No error UI needed.

### Configuration
- `minimumWorkoutsForReview = 3` — configurable threshold
- `minimumDaysSinceLastRequest = 30` — app-level throttle
- `minimumDaysSinceFirstLaunch = 7` — new user protection

---

## Testing Strategy

### Unit Testing
**Coverage Target:** 90% for eligibility logic

**Focus Areas:**
- `isEligible()` with various combinations of workout count, dates
- Edge cases: first launch, exactly 30 days ago, exactly 3 workouts

### Test Cases:
1. New user (< 7 days) — should NOT be eligible
2. User with < 3 workouts — should NOT be eligible
3. User prompted < 30 days ago — should NOT be eligible
4. Eligible user (3+ workouts, 7+ days, 30+ since last) — SHOULD be eligible
5. First-time eligible (never prompted before) — SHOULD be eligible

---

## Dependencies

### External Dependencies
| Dependency | Version | Purpose |
|------------|---------|---------|
| StoreKit | iOS 16+ | `SKStoreReviewController.requestReview(in:)` |

### Internal Dependencies
- `WorkoutHistoryRepository` — for workout count
- `AppStorageKeys` — for persistence keys
- `WorkoutCompletionView` — integration point

---

## Success Criteria

- [ ] `AppReviewService` created with protocol
- [ ] Eligibility logic implemented with all criteria
- [ ] Integrated in `WorkoutCompletionView` after rating
- [ ] AppStorageKeys extended with review tracking
- [ ] First launch date set on app startup
- [ ] Unit tests for all eligibility scenarios
- [ ] Build succeeds with 0 errors

---

**Document End**
