# Technical Specification

**Project Name:** FitToday — Production Bugfix Bundle
**Version:** 1.0
**Date:** 2026-02-19
**Author:** Feature-Marker Agent
**Status:** Approved

---

## Overview

### Problem Statement
Four production-blocking issues exist on the `feature/app-store-review-request` branch. Each requires a targeted, minimal fix within the existing SwiftUI / MVVM / @Observable architecture.

### Proposed Solution
Four isolated code changes, each scoped to the minimum set of files required:

1. Remove `WorkoutTimerStore` environment dependency from `WorkoutCompletionView`; pass timer data via `WorkoutSessionStore` or use a local store
2. Replace the raw ZStack conditional for the rest-timer overlay with `.overlay(alignment:)` + `@AccessibilityPreference` for Reduce Motion
3. Remove the inner `NavigationStack` from `CreateWorkoutView` (it is presented inside a `.sheet` which already has navigation provided by the parent or none needed)
4. Apply `ExerciseTranslationService` in the CMS mapper and in `WorkoutExecutionView` for AI-generated instructions

### Goals
- Zero crash on workout finish
- Smooth rest-timer overlay animation
- Smooth create-workout sheet presentation
- All exercise descriptions in pt-BR

---

## Scope

### In Scope
- `WorkoutCompletionView.swift` — remove `@Environment(WorkoutTimerStore.self)` dependency
- `WorkoutExecutionView.swift` — fix rest-timer overlay presentation
- `CreateWorkoutView.swift` — fix NavigationStack double-nesting
- `CMSWorkoutMapper.swift` — apply translation to exercise notes
- `ExerciseTranslationService.swift` — make `ensureLocalizedDescription` properly `async` callable

### Out of Scope
- `WorkoutSessionStore.swift` — no changes
- `AppRouter.swift` — no changes
- `TabRootView.swift` — no changes (WorkoutTimerStore injection already present in WorkoutPlanView's subtree)

---

## Requirements

### Functional Requirements

#### FR-001: Fix WorkoutCompletionView crash [MUST]

**Root Cause Analysis:**
`WorkoutCompletionView` line 16:
```swift
@Environment(WorkoutTimerStore.self) private var workoutTimer
```
This reads an `@Observable` object from the SwiftUI environment. The environment chain for the path `WorkoutExecutionView → navigateToCompletion() → router.push(.workoutSummary, on: .home)` is:
```
TabRootView
  └── NavigationStack (home tab)
       ├── HomeView
       └── WorkoutExecutionView  ← @State var workoutTimerStore (NOT injected into env)
            └── WorkoutCompletionView  ← @Environment(WorkoutTimerStore.self) CRASH
```
The `WorkoutTimerStore` local to `WorkoutExecutionView` is never passed down via `.environment()`.

**Fix:**
Make `WorkoutCompletionView` independent of `WorkoutTimerStore`. The view only uses `workoutTimer.formattedTime` in the `workoutSummaryCard`. Replace the environment dependency with a stored formatted time string passed as a parameter, or read it from the `WorkoutSessionStore` which already records session start time.

The cleanest minimal fix: add an optional `elapsedTimeFormatted: String?` parameter to `WorkoutCompletionView` and remove `@Environment(WorkoutTimerStore.self)`. The callers that have the timer available (WorkoutPlanView) pass the formatted string. The callers that don't (WorkoutExecutionView, WorkoutExerciseDetailView) pass `nil` or compute the time from `session.startedAt`.

Alternative (also acceptable): Inject the `workoutTimerStore` into the environment in `WorkoutExecutionView`'s navigation destination. Since `WorkoutExecutionView` creates its own `@State private var workoutTimerStore`, it can inject it with `.environment(workoutTimerStore)` on the destination view. But this requires modifying `TabRootView` which is out of scope.

**Selected Fix:** Pass `elapsedTimeFormatted: String?` as an initializer parameter to `WorkoutCompletionView`. Existing callers that have a timer use the formatted string; callers that don't pass `nil` (the card is hidden when `nil`). The `@Environment(WorkoutTimerStore.self)` line is removed.

Wait — simpler: `WorkoutCompletionView` is constructed inside `TabRootView.routeDestination(for:)` with no parameters. Changing the initializer requires changing `TabRootView`. Better option: **make the `workoutTimer` optional** with a default value using `@Environment` optional resolution, or store the elapsed time in `WorkoutSessionStore` during `finish()`.

**Cleanest approach that requires only one file change:**
In `WorkoutSessionStore.finish(status:)`, record `elapsedSeconds: Int` before resetting. Add `var lastWorkoutElapsedSeconds: Int = 0` to `WorkoutSessionStore`. In `WorkoutExecutionView.finishWorkout()`, after calling `sessionStore.finish`, the elapsed seconds are already stored. In `WorkoutCompletionView`, read `sessionStore.lastWorkoutElapsedSeconds` instead of `workoutTimer.formattedTime` and remove `@Environment(WorkoutTimerStore.self)`.

**Files changed:** `WorkoutSessionStore.swift`, `WorkoutExecutionView.swift`, `WorkoutCompletionView.swift`

**Acceptance Criteria:**
- Tapping "Finalizar Treino" in WorkoutExecutionView navigates to WorkoutCompletionView
- Workout time shown in summary card uses the elapsed time from WorkoutSessionStore
- WorkoutPlanView path continues to work (it sets `sessionStore.lastWorkoutElapsedSeconds` before pushing `.workoutSummary`)

---

#### FR-002: Fix rest-timer overlay flick [MUST]

**Root Cause Analysis:**
In `WorkoutExecutionView.workoutContent`, the rest timer overlay is rendered via:
```swift
ZStack {
    if showRestTimer || restTimerStore.isActive {
        restTimerOverlay
    }
}
```
This bare `if` inside a `ZStack` causes SwiftUI to destroy/recreate the view tree on each toggle. The `.transition` and `.animation` modifiers are on `restTimerOverlay` but the animation value is `showRestTimer` — yet the view is removed from the hierarchy entirely when `showRestTimer = false`, so the removal animation runs on a disappearing view without the view being visible.

Additionally, the ZStack sits inside `workoutContent`'s outer ZStack, so the overlay isn't truly fullscreen — it's constrained to the safe-area layout of the scroll view.

**Fix:**
Replace the bare `if` + ZStack approach with `.overlay` modifier on the root view. Add `@Environment(\.accessibilityReduceMotion)` support. The rest timer overlay becomes a `fullScreenCover` or an `.overlay` on the entire view.

Selected approach: use `.overlay` on the outermost ZStack of `body`, controlling visibility via `showRestTimer || restTimerStore.isActive`. Wrap `restTimerOverlay` in a conditional `Group` with stable identity via `.id` or use the `if let` pattern, and apply the animation on the container rather than the leaf view. Use `@Environment(\.accessibilityReduceMotion) var reduceMotion` to switch between `.opacity` and `.scale + opacity`.

**Files changed:** `WorkoutExecutionView.swift`

---

#### FR-003: Fix create-workout navigation flick [MUST]

**Root Cause Analysis:**
`CreateWorkoutView` wraps its content in:
```swift
var body: some View {
    NavigationStack {
        ScrollView { ... }
        .navigationTitle(...)
        .toolbar { ... }
    }
}
```
When this view is presented as a `.sheet`, the `NavigationStack` is freshly initialized on presentation. Because the sheet's internal `NavigationStack` has no path binding and uses `.navigationBarTitleDisplayMode(.inline)`, SwiftUI has to compute the navigation bar on first render, causing a layout flick.

**Fix:** Remove the inner `NavigationStack` from `CreateWorkoutView` since the sheet provides its own navigation chrome via `UINavigationController`. Keep the `.navigationTitle` and `.toolbar` modifiers which work correctly inside a sheet without a wrapping `NavigationStack`. This is the standard SwiftUI pattern for sheets with navigation chrome.

**Files changed:** `CreateWorkoutView.swift`

---

#### FR-004: Normalize exercise descriptions to pt-BR [MUST]

**Root Cause Analysis:**
Three code paths produce exercise instructions:

1. **Wger / program workouts**: `WgerExerciseAdapter` + `ExerciseTranslationService` already in path — handled.
2. **CMS personal-trainer workouts**: `CMSWorkoutMapper.toWorkoutPlan(from:)` sets `instructions: item.notes.map { [$0] } ?? []`. The `notes` field is written by the trainer in English and is never passed through `ExerciseTranslationService`.
3. **AI-generated workouts**: OpenAI composer returns `ExercisePrescription` objects whose `exercise.instructions` may be in English if the OpenAI prompt response contains English text.

**Fix for CMS path:**
In `CMSWorkoutMapper.toWorkoutPlan(from:)`, wrap notes with a synchronous translation call. Since `CMSWorkoutMapper` is an `enum` (static functions, not async), add a static helper that calls `ExerciseTranslationService` synchronously via `Task { await translationService... }` — but that is not viable in a sync context.

Better: Make the translation happen at display time in `WorkoutExecutionView.loadExerciseDescription`, which already calls `translationService.ensureLocalizedDescription`. The fix is already there — but `ExerciseTranslationService.ensureLocalizedDescription` is declared without `async` while being called with `await`. The actor isolation means the call hops to the actor but returns `String` synchronously within the actor. This is valid Swift 6 but the `await` is a no-op hop — it still works.

The actual problem for CMS workouts: when a CMS exercise has `notes = "Keep your back straight and push through your heels"`, this text flows into `exercise.instructions`, then `WorkoutExecutionView.loadExerciseDescription` calls:
```swift
let instructions = exercise.instructions.joined(separator: "\n")
let localized = await translationService.ensureLocalizedDescription(instructions)
```
This path IS going through the translation service. The issue is that the `ExerciseTranslationService.containsEnglishPatterns` check uses whole-word boundaries with spaces (e.g., `" keep "`) but the text may start with a capital `"Keep"` (no leading space). The pattern `" keep "` won't match `"Keep your..."` because there is no leading space.

**Fix:** Update `containsEnglishPatterns` and `containsPortuguesePatterns` in `ExerciseTranslationService` to also check for patterns at the start of string (without leading space), or convert to lowercase before matching (already done via `text.lowercased()` in the method). The issue is with `" keep "` — the lowercased text is `"keep your..."` which does NOT contain `" keep "` (note leading space). Change the patterns array to include both `" keep "` AND `"keep "` (no leading space) to match sentence starts.

Additionally, the `englishToPortugueseDictionary` keys like `"keep "` (no leading space) and `"hold "` etc. will already match in `translateToPortuguese` since it uses `replacingOccurrences` case-insensitively. So the translation will fire once detection is fixed.

**Files changed:** `ExerciseTranslationService.swift`

---

## Technical Approach

### Architecture Overview
All fixes operate within the existing MVVM + @Observable architecture. No new types are introduced. No protocols change.

### Key Technologies
- SwiftUI @Observable: Used in WorkoutSessionStore, RestTimerStore, WorkoutTimerStore
- SwiftUI Environment: The crash fix removes an unsatisfied environment dependency
- NaturalLanguage framework: Used by ExerciseTranslationService for language detection

### Components

#### Component 1: WorkoutSessionStore
**Purpose:** Central state holder for an active workout session.
**Change:** Add `var lastWorkoutElapsedSeconds: Int` to store elapsed time at session completion.

#### Component 2: WorkoutExecutionView
**Purpose:** Exercise-by-exercise workout execution screen.
**Changes:**
- Before calling `sessionStore.finish()`, store `workoutTimerStore.elapsedSeconds` into `sessionStore.lastWorkoutElapsedSeconds`
- Fix rest-timer overlay flick using `.overlay` modifier + accessibilityReduceMotion

#### Component 3: WorkoutCompletionView
**Purpose:** Workout summary screen shown after finish.
**Change:** Remove `@Environment(WorkoutTimerStore.self) private var workoutTimer`. Replace `workoutTimer.formattedTime` with `sessionStore.formattedLastWorkoutTime` (computed property on WorkoutSessionStore).

#### Component 4: CreateWorkoutView
**Purpose:** Sheet for creating custom workout templates.
**Change:** Remove wrapping `NavigationStack { }` from `body`.

#### Component 5: ExerciseTranslationService
**Purpose:** Actor that detects language and translates exercise descriptions.
**Change:** Update `containsEnglishPatterns` to also match patterns at sentence start (no leading space requirement).

---

## Data Model

No new persistent data. `lastWorkoutElapsedSeconds: Int` is an in-memory property on `WorkoutSessionStore` (not persisted to UserDefaults).

---

## Implementation Considerations

### Error Handling
No new error paths introduced. All fixes are within existing error-handling patterns.

### Concurrency
All store mutations remain on `@MainActor`. `ExerciseTranslationService` remains an `actor`. No concurrency model changes.

---

## Testing Strategy

### Unit Testing
- `WorkoutExecutionTests.swift` (existing) — verify no crash scenario can be reproduced
- `ExerciseTranslationServiceTests.swift` (existing) — add test cases for sentence-initial English patterns

### Coverage Target: 70%+ for modified components

---

## Success Criteria

- [ ] App does not crash when tapping "Finalizar Treino" in WorkoutExecutionView
- [ ] Rest timer overlay shows and hides without visual flick
- [ ] Create Workout sheet opens without flick
- [ ] Exercise instructions in English are translated to pt-BR in display
- [ ] All existing tests pass
- [ ] No Swift 6 concurrency warnings introduced
