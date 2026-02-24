# Tasks: Workout Session UX Fix

## Task 1: Add reps/weight fields to SetProgress model
- Add `actualReps: Int?` and `weight: Double?` to `SetProgress`
- Add `updateReps(_:)` and `updateWeight(_:)` methods
- Add `updateSetReps()` and `updateSetWeight()` to `WorkoutSessionStore`
- Add `updateSetReps()` and `updateSetWeight()` to `WorkoutProgress`

## Task 2: Redesign SetCheckbox with editable reps + weight
- Redesign `SetCheckbox` to include a reps `TextField` and weight `TextField`
- Show prescription reps as placeholder, actual reps as value
- Weight field with "kg" suffix, defaults to "—"
- Maintain the existing checkbox toggle for completion

## Task 3: Add inline execution mode to WorkoutPlanView
- Add `@State private var isExecuting = false` to WorkoutPlanView
- When timer starts AND "Ver exercício" is tapped, set `isExecuting = true`
- In execution mode, each exercise row expands to show set tracking with the new SetCheckbox
- Remove `router.push(.workoutExecution)` from `startFromCurrentExercise()`
- Show current exercise highlighted with progress indicator

## Task 4: Replace blocking rest timer with inline timer
- Create `InlineRestTimerBar` component: compact horizontal bar with mini circular progress, time, +30s, skip
- When a set is completed (not last set), show `InlineRestTimerBar` below that exercise's set list
- Remove the full-screen rest timer overlay from the flow
- Auto-dismiss when timer ends

## Task 5: Fix finish workout flow
- The FloatingTimerBar already has a "Finalizar" button calling `finishSession(as: .completed)` which works
- Ensure `finishSession(as:)` works correctly from the inline execution mode
- After finish, properly navigate to `.workoutSummary`
- Clean up session state (reset timer, clear progress)

## Task 6: Localization
- Extract hardcoded Portuguese strings from modified files
- Add keys to `en.lproj/Localizable.strings`
- Add keys to `pt-BR.lproj/Localizable.strings`
