# Tasks - App Store Review Request

## Task 1: Extend AppStorageKeys with review tracking keys

**File:** `Presentation/Support/AppStorageKeys.swift`

**Changes:**
- Add `lastReviewRequestDate` key
- Add `firstLaunchDate` key

**Acceptance Criteria:**
- Keys follow existing naming pattern
- No functional changes to existing keys

---

## Task 2: Set firstLaunchDate on app startup

**File:** `FitTodayApp.swift`

**Changes:**
- In the app's `init()` or scene phase handler, check if `firstLaunchDate` is nil in UserDefaults
- If nil, set it to `Date()` — this captures when the app was first launched

**Acceptance Criteria:**
- Only sets the date once (first launch)
- Does not overwrite existing value on subsequent launches

---

## Task 3: Create AppReviewService with protocol and eligibility logic

**File:** `Domain/Services/AppReviewService.swift` (new)

**Changes:**
- Define `AppReviewRequesting` protocol with `requestReviewIfEligible()` and `isEligible(completedWorkoutsCount:)`
- Implement `AppReviewService` struct
- Eligibility criteria:
  1. `completedWorkoutsCount >= 3`
  2. At least 7 days since `firstLaunchDate`
  3. At least 30 days since `lastReviewRequestDate` (or never requested)
- `requestReviewIfEligible()`:
  1. Get workout count from `WorkoutHistoryRepository`
  2. Check `isEligible()`
  3. If eligible, call `SKStoreReviewController.requestReview(in:)` on main actor
  4. Record `lastReviewRequestDate` in UserDefaults

**Acceptance Criteria:**
- Protocol is defined for testability
- All three eligibility criteria checked
- Uses `@MainActor` for UI interaction
- Records request timestamp after showing prompt

---

## Task 4: Integrate review request in WorkoutCompletionView

**File:** `Presentation/Features/Workout/WorkoutCompletionView.swift`

**Changes:**
- After `hasRated` becomes `true` (user rated or skipped), trigger review request
- Resolve `WorkoutHistoryRepository` from resolver (already available in the view)
- Create `AppReviewService` and call `requestReviewIfEligible()`
- Add a 2-second delay after rating to let user absorb the moment

**Acceptance Criteria:**
- Only triggers for `.completed` status (not `.skipped`)
- Does not block user flow
- Delay is non-blocking (uses `Task.sleep`)

---

## Task 5: Write unit tests for AppReviewService eligibility

**File:** `FitTodayTests/Domain/Services/AppReviewServiceTests.swift` (new)

**Test cases:**
1. New user (< 7 days since first launch) → not eligible
2. User with < 3 workouts → not eligible
3. User prompted < 30 days ago → not eligible
4. Eligible user (all criteria met) → eligible
5. First-time eligible (never prompted) → eligible
6. User with exactly 3 workouts, 7+ days, never prompted → eligible
7. Edge case: firstLaunchDate is nil → not eligible

**Acceptance Criteria:**
- All test cases pass
- Tests use mock/stub for UserDefaults (or test-specific suite)
- No StoreKit dependency in tests (only test `isEligible()`)

---

## Task 6: Build verification

**Changes:** None — verify build succeeds.

**Acceptance Criteria:**
- `xcodebuild build` succeeds with 0 errors
- All tests pass
