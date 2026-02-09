# Product Requirements Document (PRD)

**Project Name:** OpenAI Workout Generation Fix
**Document Version:** 1.0.0
**Date:** 2026-02-08
**Author:** AI Agent
**Status:** Draft

---

## Executive Summary

**Problem Statement:**
Users are experiencing two critical issues with the workout system:
1. Exercises in generated workouts cannot be clicked to access details or deleted
2. OpenAI-generated workouts are always identical (lack of variation)

**Proposed Solution:**
1. Fix exercise navigation and add delete functionality to generated workout views
2. Improve workout variation by adjusting cache TTL, temperature settings, and adding explicit randomization seeds

**Business Value:**
- Improved user experience with proper exercise interaction
- Unique workout generation increases engagement and prevents user frustration
- Reduced churn from users feeling workouts are "stuck" or repetitive

**Success Metrics:**
- 100% of exercises in generated workouts are tappable and navigate correctly
- Each workout generation produces unique exercise combinations
- No two consecutive workouts for the same user are identical

---

## Problem Analysis

### Issue 1: Exercise Click/Delete Not Working

**Current State:**
- `PhaseSectionView.swift` has `onTapGesture` for exercise navigation (lines 46-48)
- Navigation is implemented but may be blocked by gesture conflicts
- Delete functionality exists for custom workouts but NOT for generated workouts

**Root Cause Investigation:**
- `contentShape(Rectangle())` is applied but LazyVStack may have gesture issues
- No swipe-to-delete or delete buttons exist in `WorkoutExerciseRow` or `PhaseSectionView`
- Generated workouts (via OpenAI) do not support exercise removal

### Issue 2: OpenAI Always Generates Same Workout

**Current State (from `OpenAIConfiguration.swift` lines 28-36):**
```swift
#if DEBUG
let temperature = 0.7 // Higher for testing variety
let cacheTTL: TimeInterval = 0 // No cache in DEBUG
#else
let temperature = 0.3 // Low = consistent (production)
let cacheTTL: TimeInterval = 900 // 15 minutes cache
#endif
```

**Root Causes:**
1. **Cache TTL**: 15-minute cache in production means same response for repeated calls
2. **Low Temperature (0.3)**: Produces very consistent/predictable outputs
3. **15-minute Variation Buckets**: `WorkoutBlueprint.swift` uses `minuteOfHour / 15` in production, creating only 4 unique seeds per hour
4. **No Explicit Randomization**: Prompts lack random seeds or explicit variation instructions

---

## Functional Requirements

### FR-001: Fix Exercise Tap Navigation [MUST]

**Description:**
Ensure all exercises displayed in `PhaseSectionView` and `WorkoutExerciseRow` are tappable and navigate to the exercise detail preview.

**Acceptance Criteria:**
- Tapping any exercise opens `workoutExercisePreview` route
- Visual feedback (highlight) appears on tap
- No gesture conflicts with parent views

**Files Affected:**
- `PhaseSectionView.swift`
- `WorkoutExerciseRow.swift`

---

### FR-002: Add Delete Capability for Generated Workout Exercises [SHOULD]

**Description:**
Allow users to remove exercises from a generated workout before starting or during planning.

**Acceptance Criteria:**
- Swipe-to-delete gesture works on exercise rows
- Confirmation dialog before deletion
- Workout plan updates immediately after deletion
- Minimum 1 exercise must remain in workout

**Files Affected:**
- `PhaseSectionView.swift`
- `WorkoutPlanView.swift`
- `WorkoutSessionStore.swift`

---

### FR-003: Improve OpenAI Workout Variation [MUST]

**Description:**
Ensure each workout generation produces a unique exercise combination by improving randomization and reducing aggressive caching.

**Acceptance Criteria:**
- No two consecutive workouts are identical for the same user
- Cache invalidation happens on explicit regeneration
- Variation is noticeable to users

**Technical Approach:**
1. Add explicit random seed to OpenAI prompts
2. Reduce cache TTL to 5 minutes or disable on regeneration
3. Increase temperature to 0.5-0.6 in production
4. Use per-second variation instead of 15-minute buckets

**Files Affected:**
- `OpenAIConfiguration.swift`
- `WorkoutBlueprint.swift`
- `WorkoutPromptAssembler.swift`
- `OpenAIResponseCache.swift`

---

### FR-004: Force Unique Workout on Regeneration [MUST]

**Description:**
When user taps "Regenerate", the new workout must be different from the current one.

**Acceptance Criteria:**
- Regeneration bypasses cache
- A different variation seed is used
- At least 50% of exercises must differ from previous

**Files Affected:**
- `WorkoutPlanView.swift`
- `HybridWorkoutPlanComposer.swift`

---

## Non-Functional Requirements

### NFR-001: Response Time [MUST]

**Description:**
Exercise navigation and deletion must feel instant.

**Acceptance Criteria:**
- Navigation < 100ms
- Deletion animation < 300ms

---

### NFR-002: OpenAI Token Efficiency [SHOULD]

**Description:**
Maintain reasonable token usage while improving variation.

**Acceptance Criteria:**
- Average token usage increase < 10%
- Cache still provides cost savings for identical inputs

---

## User Stories

### STORY-001: Exercise Navigation

```
As a user viewing my generated workout,
I want to tap any exercise to see details,
So that I can understand how to perform it correctly.
```

**Acceptance Criteria:**
- Given I am on the workout plan view, when I tap an exercise, then the exercise detail screen opens
- Given I tap an exercise, when the screen opens, then I see exercise name, description, and demonstration

---

### STORY-002: Remove Exercise from Workout

```
As a user,
I want to remove exercises I don't want from my generated workout,
So that I can customize the plan before starting.
```

**Acceptance Criteria:**
- Given I am on the workout plan view, when I swipe left on an exercise, then I see a delete option
- Given I confirm deletion, when the exercise is removed, then the workout updates immediately

---

### STORY-003: Unique Workout Generation

```
As a user,
I want each AI-generated workout to be different,
So that my training stays varied and engaging.
```

**Acceptance Criteria:**
- Given I generate a workout, when I regenerate, then the exercises are different
- Given I generate a workout tomorrow, when I compare to today, then there is noticeable variety

---

## Technical Approach Summary

### Exercise Navigation Fix
1. Verify `onTapGesture` is not blocked by parent gestures
2. Add `.highPriorityGesture` if needed
3. Ensure `contentShape(Rectangle())` covers full row

### Exercise Delete Implementation
1. Wrap exercise list in `List` for native swipe actions
2. Add `removeExercise(at:)` method to `WorkoutSessionStore`
3. Add confirmation dialog

### Workout Variation Fix
1. **OpenAIConfiguration.swift**: Increase production temperature to 0.5
2. **WorkoutBlueprint.swift**: Use per-minute or per-second seeds instead of 15-min buckets
3. **WorkoutPromptAssembler.swift**: Add explicit random seed to prompts
4. **OpenAIResponseCache.swift**: Add `invalidate()` method for regeneration
5. **WorkoutPlanView.swift**: Call cache invalidation before regeneration

---

## Out of Scope

1. **Exercise reordering** - Future enhancement
2. **Exercise replacement suggestions** - Future enhancement
3. **Custom exercise addition to generated workouts** - Future enhancement
4. **Offline workout variation** - Requires different approach

---

## Files Reference

| File | Purpose |
|------|---------|
| `PhaseSectionView.swift` | Exercise display and tap handling |
| `WorkoutExerciseRow.swift` | Individual exercise row component |
| `WorkoutPlanView.swift` | Main workout plan container |
| `WorkoutSessionStore.swift` | Workout state management |
| `OpenAIConfiguration.swift` | Temperature and cache TTL settings |
| `WorkoutBlueprint.swift` | Variation seed generation |
| `WorkoutPromptAssembler.swift` | Prompt construction and cache keys |
| `OpenAIResponseCache.swift` | Response caching logic |
| `HybridWorkoutPlanComposer.swift` | Workout composition |

---

**Document End**
