# Codebase Analysis — prd-bugfix-descriptionExercices

## Issue #16 — CRASH: WorkoutCompletionView environment crash

**Root Cause:** `WorkoutCompletionView` line 16:
```swift
@Environment(WorkoutTimerStore.self) private var workoutTimer
```
When navigated to from `WorkoutExecutionView` (via `router.push(.workoutSummary, on: .home)` in `navigateToCompletion()`), the `WorkoutTimerStore` is never in the environment chain. `WorkoutExecutionView` creates it as `@State private var workoutTimerStore = WorkoutTimerStore()` (local only). SwiftUI crashes with a fatal "Missing environment value for type WorkoutTimerStore" error.

**Navigation path that crashes:**
- WorkoutExecutionView.finishWorkout() → sessionStore.finish() → navigateToCompletion() → router.push(.workoutSummary, on: .home)
- TabRootView.routeDestination constructs WorkoutCompletionView() with no extra environment injection
- WorkoutCompletionView tries to read @Environment(WorkoutTimerStore.self) → crash

**Fix selected:** Add `lastWorkoutElapsedSeconds: Int` + `formattedLastWorkoutTime: String` to WorkoutSessionStore. Before calling `sessionStore.finish()`, call `sessionStore.recordElapsedTime(workoutTimerStore.elapsedSeconds)`. Remove `@Environment(WorkoutTimerStore.self)` from WorkoutCompletionView, use `sessionStore.formattedLastWorkoutTime` instead.

## Issue #15 — FLICK: Rest timer overlay

**Root Cause:** The overlay is inside an inner ZStack with a bare `if` condition. When `showRestTimer` changes, SwiftUI inserts/removes the entire view tree. The `.transition` modifier on `restTimerOverlay` is correct but the `.animation` at the end of the overlay uses `value: showRestTimer` which changes before the transition completes. Result: the animation fires on an already-removed view.

**Current code:**
```swift
ZStack {
    if sessionStore.plan != nil { workoutContent }
    else { emptyStateView }

    // Rest Timer Overlay
    if showRestTimer || restTimerStore.isActive {
        restTimerOverlay
    }
}
```

**Fix:** Move the overlay out of the main ZStack into a `.overlay` modifier on the body, after all other modifiers. Use `withAnimation` around `showRestTimer` mutations.

## Issue #14 — FLICK: Create Workout navigation

**Root Cause:** `CreateWorkoutView` wraps its entire `body` in a `NavigationStack`. This view is presented as a `.sheet`. When UIKit presents a sheet on iOS 16+, the system uses `UISheetPresentationController` which provides its own `UINavigationController`. Having an inner SwiftUI `NavigationStack` causes the navigation bar to be double-layered — on first render, the SwiftUI NavigationStack tries to layout its navigation bar WHILE the UIKit presentation animation is in progress, causing a layout-pass conflict and a visual flick.

**Fix:** Remove the outer `NavigationStack { }` from `CreateWorkoutView.body`. The `.navigationTitle`, `.navigationBarTitleDisplayMode`, and `.toolbar` modifiers propagate up to the UIKit nav controller provided by the sheet.

## Issue (New) — MIXED LANGUAGE: Exercise descriptions

**Root Cause:** `ExerciseTranslationService.containsEnglishPatterns` uses space-padded pattern matching:
```swift
let englishIndicators = [
    " the ", " and ", " with ", " your ", ...
    " keep ", " hold ", " push ", ...
]
```
All indicators require a leading space. When a description starts with a capital word like `"Keep your back straight"`, after `.lowercased()` it becomes `"keep your back straight"`. This string does NOT contain `" keep "` (with leading space) but does contain `"keep "` (without leading space).

The `detectLanguage` NLLanguageRecognizer may still detect English for longer texts, but for short CMS notes like `"Keep your back straight."` (5 words), the recognizer may not be confident enough, falling back to the pattern checks which miss the sentence-initial match.

The translation dictionary `englishToPortugueseDictionary` uses keys WITHOUT leading spaces for verbs (e.g., `"keep ": "mantenha "`), so the translation WILL fire once detection is fixed. Only detection needs fixing.

**Fix:** Add sentence-start variants (without leading space) to `containsEnglishPatterns`.
