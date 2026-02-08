# Implementation Tasks

**Feature:** OpenAI Workout Generation Fix
**Date:** 2026-02-08
**Total Tasks:** 8

---

## Task 1: Fix Exercise Navigation in PhaseSectionView

**Priority:** MUST
**Estimated Effort:** Small
**Status:** Pending

**Description:**
Replace `onTapGesture` with `Button` wrapper for proper gesture handling and accessibility.

**Files to Modify:**
- `FitToday/Presentation/Features/Workout/Components/PhaseSectionView.swift`

**Implementation Steps:**
1. Wrap `WorkoutExerciseRow` in a `Button` with `.buttonStyle(.plain)`
2. Move navigation action to button's action
3. Remove `onTapGesture` and `contentShape`
4. Verify tap works throughout the entire row

**Acceptance Criteria:**
- [ ] Tapping any part of the exercise row navigates to exercise detail
- [ ] Visual feedback on tap (opacity change or highlight)
- [ ] Accessibility support maintained

---

## Task 2: Add removeExercise Method to WorkoutSessionStore

**Priority:** SHOULD
**Estimated Effort:** Small
**Status:** Pending

**Description:**
Add method to remove exercises from the current workout plan.

**Files to Modify:**
- `FitToday/Presentation/Stores/WorkoutSessionStore.swift`

**Implementation Steps:**
1. Add `removeExercise(from phaseIndex: Int, at exerciseIndex: Int)` method
2. Validate indices and ensure at least 1 exercise remains
3. Update the `plan` property with the modified phases
4. Remove empty phases after deletion

**Acceptance Criteria:**
- [ ] Exercise removal updates the plan correctly
- [ ] Empty phases are removed
- [ ] Cannot remove the last exercise

---

## Task 3: Add Swipe-to-Delete in PhaseSectionView

**Priority:** SHOULD
**Estimated Effort:** Medium
**Status:** Pending

**Description:**
Add swipe-to-delete gesture for exercises in generated workouts.

**Files to Modify:**
- `FitToday/Presentation/Features/Workout/Components/PhaseSectionView.swift`

**Implementation Steps:**
1. Consider restructuring to use `List` for native swipe support OR use custom swipe gesture
2. Add `.swipeActions` modifier to exercise rows
3. Add confirmation dialog before deletion
4. Call `WorkoutSessionStore.removeExercise()` on confirmation

**Acceptance Criteria:**
- [ ] Swipe left reveals delete button
- [ ] Confirmation dialog appears before deletion
- [ ] Exercise removed with animation after confirmation
- [ ] Workout total updates correctly

---

## Task 4: Increase OpenAI Temperature for Production

**Priority:** MUST
**Estimated Effort:** Small
**Status:** Pending

**Description:**
Increase temperature from 0.3 to 0.55 for more varied workout generation.

**Files to Modify:**
- `FitToday/Data/Services/OpenAI/OpenAIConfiguration.swift`

**Implementation Steps:**
1. Change production temperature from 0.3 to 0.55
2. Add comment explaining the balance between variety and coherence

**Acceptance Criteria:**
- [ ] Temperature is 0.55 in production builds
- [ ] DEBUG mode still uses 0.7

---

## Task 5: Reduce Cache TTL

**Priority:** MUST
**Estimated Effort:** Small
**Status:** Pending

**Description:**
Reduce cache TTL from 15 minutes to 5 minutes for more frequent variation.

**Files to Modify:**
- `FitToday/Data/Services/OpenAI/OpenAIConfiguration.swift`

**Implementation Steps:**
1. Change production cacheTTL from 900 to 300 seconds
2. Update comment to reflect new 5-minute TTL

**Acceptance Criteria:**
- [ ] Cache TTL is 300 seconds (5 minutes) in production
- [ ] DEBUG mode still has TTL = 0

---

## Task 6: Improve Variation Seed Logic

**Priority:** MUST
**Estimated Effort:** Medium
**Status:** Pending

**Description:**
Change from 15-minute buckets to per-minute variation for more unique workouts.

**Files to Modify:**
- `FitToday/Domain/Entities/WorkoutBlueprint.swift`

**Implementation Steps:**
1. Modify `cacheKey` to use `minuteOfHour` directly in production (not divided by 15)
2. Consider adding `forceNewVariation: Bool` property to `BlueprintInput`
3. When `forceNewVariation` is true, append a UUID component to cache key

**Acceptance Criteria:**
- [ ] Cache key changes every minute (not every 15 minutes)
- [ ] Force regeneration creates a unique cache key
- [ ] Variation seed reflects the new logic

---

## Task 7: Add Cache Invalidation for Regeneration

**Priority:** MUST
**Estimated Effort:** Medium
**Status:** Pending

**Description:**
Add ability to invalidate cache when user explicitly regenerates workout.

**Files to Modify:**
- `FitToday/Data/Services/OpenAI/OpenAIResponseCache.swift`
- `FitToday/Data/Services/OpenAI/HybridWorkoutPlanComposer.swift`
- `FitToday/Presentation/Features/Workout/WorkoutPlanView.swift`

**Implementation Steps:**
1. Add `invalidateAll()` method to `OpenAIResponseCache`
2. Expose `invalidateCache()` method in `HybridWorkoutPlanComposer`
3. Call `invalidateCache()` in `regenerateWorkoutPlan()` before generating new plan
4. Pass `forceNewVariation: true` when regenerating

**Acceptance Criteria:**
- [ ] Regeneration button clears relevant cache
- [ ] New workout is always different from previous
- [ ] Cache still works for normal generation (not regeneration)

---

## Task 8: Write Unit Tests

**Priority:** MUST
**Estimated Effort:** Medium
**Status:** Pending

**Description:**
Add unit tests for new functionality.

**Files to Create/Modify:**
- `FitTodayTests/Presentation/Stores/WorkoutSessionStoreTests.swift`
- `FitTodayTests/Domain/Entities/WorkoutBlueprintTests.swift`

**Test Cases:**
1. `test_removeExercise_updatesWorkoutPlan()`
2. `test_removeExercise_preventsEmptyWorkout()`
3. `test_removeExercise_removesEmptyPhases()`
4. `test_variationSeed_changesEachMinute()`
5. `test_forceNewVariation_createsUniqueCacheKey()`
6. `test_cacheInvalidation_clearsAllEntries()`

**Acceptance Criteria:**
- [ ] All tests pass
- [ ] 80%+ coverage for modified files
- [ ] No regression in existing tests

---

## Implementation Order

1. **Task 4 + Task 5**: Quick config changes for OpenAI variation
2. **Task 6**: Variation seed improvement
3. **Task 7**: Cache invalidation for regeneration
4. **Task 1**: Fix exercise navigation
5. **Task 2**: Add removeExercise method
6. **Task 3**: Add swipe-to-delete UI
7. **Task 8**: Write unit tests

---

## Dependencies

- Task 3 depends on Task 2
- Task 7 depends on Task 6
- Task 8 depends on Tasks 1-7

---

**End of Tasks**
