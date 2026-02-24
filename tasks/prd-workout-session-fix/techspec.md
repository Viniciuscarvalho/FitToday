# Tech Spec: Workout Session UX Fix

## Architecture Overview

The current flow is: WorkoutPlanView → (push .workoutExecution) → WorkoutExecutionView → (push .workoutSummary).

The target flow is: WorkoutPlanView (with inline execution) → (push .workoutSummary).

### Key Files

**Models to modify:**
- `Domain/Entities/WorkoutExecutionModels.swift` — Add `actualReps: Int?` and `weight: Double?` to `SetProgress`

**Views to modify:**
- `Presentation/DesignSystem/SetTrackingView.swift` — Redesign `SetCheckbox` to include editable reps + weight fields
- `Presentation/Features/Workout/WorkoutPlanView.swift` — Add inline execution mode with set tracking per exercise
- `Presentation/Features/Workout/Components/WorkoutExerciseRow.swift` — Show set tracking when in execution mode

**Views to delete (or stop using):**
- `Presentation/Features/Workout/Views/WorkoutExecutionView.swift` — Remove from navigation flow (keep file but don't route to it)

**Store to modify:**
- `Presentation/Features/Workout/WorkoutSessionStore.swift` — Add methods for updating reps/weight per set

**Router:**
- `Presentation/Router/AppRouter.swift` — Remove `.workoutExecution` push from the flow

## Detailed Design

### 1. Remove Duplicate Screen

- In `WorkoutPlanView.startFromCurrentExercise()`, instead of `router.push(.workoutExecution)`, toggle an `isExecuting` state that reveals inline set tracking
- When `isExecuting == true` && `timerStore.hasStarted`, each exercise row expands to show set checkboxes with reps/weight inputs
- The bottom FloatingTimerBar already exists — add a "Finalizar" button to it

### 2. Editable Reps & Weight per Set

- Add `actualReps: Int?` and `weight: Double?` to `SetProgress`
- Redesign `SetCheckbox` to show:
  - Set number
  - Reps field (TextField, numeric, pre-filled from prescription)
  - Weight field (TextField, numeric, defaulting to empty "— kg")
  - Completion checkbox
- Add `updateSetReps(exerciseIndex:setIndex:reps:)` and `updateSetWeight(exerciseIndex:setIndex:weight:)` to `WorkoutSessionStore`

### 3. Inline Rest Timer

- Replace the full-screen overlay in `WorkoutExecutionView` with a compact inline bar below the exercise's set list
- The inline timer shows: circular progress ring (small, ~40pt), time remaining, "+30s" button, "Skip" button
- Timer bar sits between the completed set and the next set row
- Does NOT block scrolling or interaction with other parts of the screen

### 4. Fix Finish Workout

- The current `finishWorkout()` in WorkoutExecutionView calls `sessionStore.finish()` then `navigateToCompletion()`. The issue is likely the async Task — the navigation happens inside a Task which may have timing issues with the router.
- Move the finish logic into WorkoutPlanView's FloatingTimerBar "Finalizar" action, using the same pattern as `finishSession(as:)` which already works in WorkoutPlanView.

### 5. Localization

- Extract all hardcoded Portuguese strings from the affected files
- Add corresponding entries to both `en.lproj/Localizable.strings` and `pt-BR.lproj/Localizable.strings`
