# Tasks — Production Bugfix Bundle

## Overview

Four targeted bug fixes for production release. Each task is minimal and isolated.

---

## Task List

| # | Title | Size | Priority | Status |
|---|-------|------|----------|--------|
| 1.0 | Fix WorkoutSessionStore — add lastWorkoutElapsedSeconds | S | CRITICAL | pending |
| 2.0 | Fix WorkoutCompletionView — remove WorkoutTimerStore environment dependency | S | CRITICAL | pending |
| 3.0 | Fix WorkoutExecutionView — store elapsed time before finish and fix rest-timer overlay | M | CRITICAL+HIGH | pending |
| 4.0 | Fix CreateWorkoutView — remove double NavigationStack | S | HIGH | pending |
| 5.0 | Fix ExerciseTranslationService — match English patterns at sentence start | S | HIGH | pending |
| 6.0 | Add/update unit tests for translation fix | S | MEDIUM | pending |

---

## Task Details

### Task 1.0 — WorkoutSessionStore: add lastWorkoutElapsedSeconds (S)

**Objective:** Store elapsed workout time when a session is finished, so WorkoutCompletionView can display it without needing WorkoutTimerStore in its environment.

**File:** `FitToday/FitToday/Presentation/Features/Workout/WorkoutSessionStore.swift`

**Subtasks:**
- [ ] 1.1 Add `private(set) var lastWorkoutElapsedSeconds: Int = 0` property
- [ ] 1.2 Add computed property `var formattedLastWorkoutTime: String` that formats `lastWorkoutElapsedSeconds` as `MM:SS` or `H:MM:SS`
- [ ] 1.3 Reset `lastWorkoutElapsedSeconds` to 0 in `reset()`

**Success Criteria:**
- `WorkoutSessionStore` exposes `lastWorkoutElapsedSeconds` and `formattedLastWorkoutTime`
- `reset()` clears `lastWorkoutElapsedSeconds`

---

### Task 2.0 — WorkoutCompletionView: remove WorkoutTimerStore environment (S)

**Objective:** Remove the unsatisfied `@Environment(WorkoutTimerStore.self)` that causes the crash.

**File:** `FitToday/FitToday/Presentation/Features/Workout/WorkoutCompletionView.swift`

**Subtasks:**
- [ ] 2.1 Remove `@Environment(WorkoutTimerStore.self) private var workoutTimer`
- [ ] 2.2 Replace `workoutTimer.formattedTime` in `workoutSummaryCard` with `sessionStore.formattedLastWorkoutTime`
- [ ] 2.3 Verify `workoutSummaryCard` is only shown when `status == .completed` (already gated)

**Success Criteria:**
- File compiles without `WorkoutTimerStore` import or reference
- `workoutSummaryCard` shows correct time when reached from both WorkoutExecutionView and WorkoutPlanView paths

---

### Task 3.0 — WorkoutExecutionView: elapsed time + rest-timer overlay fix (M)

**Objective:** (a) Store elapsed seconds into sessionStore before calling finish; (b) Fix the rest-timer overlay flick using proper .overlay + accessibilityReduceMotion.

**File:** `FitToday/FitToday/Presentation/Features/Workout/Views/WorkoutExecutionView.swift`

**Subtasks:**
- [ ] 3.1 In `finishWorkout()`, before calling `sessionStore.finish(status:)`, set `sessionStore.lastWorkoutElapsedSeconds = workoutTimerStore.elapsedSeconds`
- [ ] 3.2 Add `@Environment(\.accessibilityReduceMotion) private var reduceMotion` to the view
- [ ] 3.3 Remove the `if showRestTimer || restTimerStore.isActive { restTimerOverlay }` block from the inner ZStack
- [ ] 3.4 Add `.overlay` modifier on the outermost content container for the rest-timer, conditioned on `showRestTimer || restTimerStore.isActive`
- [ ] 3.5 Apply correct transition: `reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.95))` with animation modifier on the overlay container
- [ ] 3.6 Note: `sessionStore.lastWorkoutElapsedSeconds` requires a `@Bindable` or direct mutation — since `WorkoutSessionStore` is `@MainActor @Observable` and `WorkoutExecutionView` accesses it via `@Environment`, call a new `func recordElapsedTime(_ seconds: Int)` on the store

**Success Criteria:**
- `finishWorkout()` sets elapsed time before pushing summary
- Rest-timer overlay appears/disappears without flick
- Reduce Motion respected

---

### Task 4.0 — CreateWorkoutView: remove double NavigationStack (S)

**Objective:** Eliminate the visual flick caused by a NavigationStack inside a sheet.

**File:** `FitToday/FitToday/Presentation/Features/Workout/Views/CreateWorkoutView.swift`

**Subtasks:**
- [ ] 4.1 Remove the outer `NavigationStack { }` wrapper from `body`
- [ ] 4.2 Keep `.navigationTitle`, `.navigationBarTitleDisplayMode(.inline)`, and `.toolbar` modifiers — they work inside a sheet without NavigationStack (the sheet uses UINavigationController under the hood in iOS 16+)
- [ ] 4.3 Verify the toolbar Cancel and Save buttons still appear correctly

**Success Criteria:**
- `CreateWorkoutView.body` does not contain a `NavigationStack`
- Cancel and Save toolbar items remain functional
- Sheet presents without flick

---

### Task 5.0 — ExerciseTranslationService: match sentence-initial patterns (S)

**Objective:** Fix language detection to correctly identify English text that starts at the beginning of a string (no leading space).

**File:** `FitToday/FitToday/Data/Services/Translation/ExerciseTranslationService.swift`

**Subtasks:**
- [ ] 5.1 In `containsEnglishPatterns`, add sentence-start variants: `"keep "`, `"hold "`, `"push "`, `"pull "`, `"lift "`, `"lower "`, `"raise "`, `"extend "`, `"flex "`, `"stand "`, `"sit "`, `"lie "`, `"the "`, `"keep "` (without leading space, so they match at string start after lowercasing)
- [ ] 5.2 In `containsPortuguesePatterns`, similarly add `"mantenha "`, `"segure "`, `"empurre "` etc. (without leading space) to avoid false negatives for short Portuguese instructions
- [ ] 5.3 Keep all existing patterns — this is additive only

**Success Criteria:**
- `"Keep your back straight"` is detected as English
- `"Push through your heels"` is detected as English
- `"Mantenha a postura ereta"` continues to be detected as Portuguese
- No existing detection logic is broken

---

### Task 6.0 — Unit tests for translation fix (S)

**Objective:** Add test cases to `ExerciseTranslationServiceTests.swift` that cover sentence-initial English patterns.

**File:** `FitToday/FitTodayTests/Data/Services/ExerciseTranslationServiceTests.swift`

**Subtasks:**
- [ ] 6.1 Add test `testSentenceInitialEnglishDetected` verifying `"Keep your back straight"` returns a Portuguese string
- [ ] 6.2 Add test `testSentenceInitialEnglishPushDetected` verifying `"Push through your heels"` returns a Portuguese string
- [ ] 6.3 Verify existing tests still pass

**Success Criteria:**
- Two new test cases added
- All existing tests still pass
- Coverage for `containsEnglishPatterns` increases
