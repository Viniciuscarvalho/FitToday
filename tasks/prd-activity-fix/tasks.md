# Implementation Tasks

**Feature:** prd-activity-fix
**Date:** 2026-02-19

---

## Task 1: Replace mock data with real WorkoutHistoryRepository in WorkoutHistoryView

**Priority:** CRITICAL
**Estimated Complexity:** Medium
**Files:** `ActivityTabView.swift`

### Description
Replace the `loadWorkouts()` function in `WorkoutHistoryView` that currently loads from `MockWorkoutData.recentSessions` with real data from `WorkoutHistoryRepository`.

### Steps
1. Add `WorkoutHistoryRepository` as a dependency resolved from `Resolver`
2. Replace `@State private var workouts: [UnifiedWorkoutSession]` with `@State private var workouts: [WorkoutHistoryEntry]`
3. Update `loadWorkouts()` to call `repository.listEntries(limit: 20, offset: 0)`
4. Update `workoutDays` computed property to use `WorkoutHistoryEntry.date` instead of `UnifiedWorkoutSession.startedAt`
5. Replace `WorkoutSessionCard` with `HistoryRow` (or adapt card to use `WorkoutHistoryEntry`)
6. Remove `MockWorkoutData` enum entirely
7. Handle errors with try/catch and show error state

### Acceptance Criteria
- [x] No mock data displayed
- [x] Real workouts from SwiftData shown
- [x] Calendar highlights real workout days
- [x] Empty state shown when no workouts
- [x] Loading state during fetch

---

## Task 2: Adapt WorkoutHistoryView cards for WorkoutHistoryEntry model

**Priority:** HIGH
**Estimated Complexity:** Low
**Files:** `ActivityTabView.swift`

### Description
Update the workout list section to display `WorkoutHistoryEntry` data instead of `UnifiedWorkoutSession`. Either reuse `HistoryRow` from `HistoryView.swift` or adapt `WorkoutSessionCard`.

### Steps
1. Replace `ForEach(workouts) { workout in WorkoutSessionCard(session: workout) }` with entry-based rendering
2. Show: title, focus, date, status, duration, calories, source icon, program name
3. Ensure the card design matches the existing Activity tab style

### Acceptance Criteria
- [x] Workout entries display correctly with all available data
- [x] Source indicator shows app vs Apple Health icon
- [x] Duration and calories shown when available

---

## Task 3: Add post-translation quality check to ExerciseTranslationService

**Priority:** HIGH
**Estimated Complexity:** Low
**Files:** `ExerciseTranslationService.swift`

### Description
After the dictionary-based translation, validate that the result doesn't still contain Spanish/English patterns. If it does, return the Portuguese fallback instead of garbled mixed-language text.

### Steps
1. In `ensureLocalizedDescription()`, after calling `translateToPortuguese()`, check the result
2. If `containsSpanishPatterns(translated)` or `containsEnglishPatterns(translated)` returns true, use fallback
3. Cache the fallback result to avoid repeated processing

### Acceptance Criteria
- [x] Translated text with remaining Spanish patterns shows fallback
- [x] Translated text with remaining English patterns shows fallback
- [x] Clean Portuguese translations pass through unchanged
- [x] Existing tests pass

---

## Task 4: Update ExerciseTranslationService tests

**Priority:** MEDIUM
**Estimated Complexity:** Low
**Files:** `ExerciseTranslationServiceTests.swift`

### Description
Add test cases for the new post-translation quality check.

### Steps
1. Add test: Spanish input that translates poorly -> returns fallback
2. Add test: English input that translates poorly -> returns fallback
3. Add test: Clean Portuguese input -> passes through
4. Verify existing tests still pass

### Acceptance Criteria
- [x] New test cases cover post-translation validation
- [x] All existing tests pass
- [x] Edge cases covered (mixed Spanish/English input)

---

## Task 5: Build verification and manual testing

**Priority:** HIGH
**Estimated Complexity:** Low

### Description
Build the project and verify all changes work together.

### Steps
1. Build project with `mcp__xcodebuildmcp__build_sim_name_proj`
2. Run tests with `mcp__xcodebuildmcp__test_sim_name_proj`
3. Verify no Swift 6 concurrency warnings in modified files

### Acceptance Criteria
- [x] Project builds without errors
- [x] All tests pass
- [x] No new warnings
