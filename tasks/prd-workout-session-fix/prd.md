# PRD: Workout Session UX Fix

## Problem Statement

The workout execution flow has multiple UX issues that degrade the user experience:

1. **Duplicate screens**: After viewing the workout plan (WorkoutPlanView), tapping "Iniciar Treino" opens a second screen (WorkoutExecutionView) with the same exercises displayed differently. This creates confusion and a redundant navigation step.
2. **Non-editable reps**: Repetitions are displayed as static text from the plan prescription. Users cannot adjust reps for the actual completed count.
3. **No weight input**: There is no field to log the weight used per set, a fundamental feature for any training app.
4. **Blocking rest timer**: The rest timer appears as a full-screen overlay (Color.black.opacity(0.7) + centered card) that blocks all interaction with the workout content underneath.
5. **Finish button does nothing**: The "Finalizar Treino" action fails to navigate to the completion screen.
6. **Missing localizable strings**: Hardcoded Portuguese strings need to move to Localizable.strings.

## Goals

- Remove the redundant WorkoutExecutionView and consolidate execution into WorkoutPlanView
- Make reps and weight editable per set during execution
- Replace the blocking rest timer overlay with an inline timer attached to the current exercise
- Fix the finish workout navigation flow
- Add all missing strings to Localizable.strings (en + pt-BR)

## Non-Goals

- Redesigning the overall app navigation
- Adding new exercise types or workout generation logic
- Changing the workout plan generation flow

## User Stories

1. As a user, I want a single-screen workout experience where I start and complete my workout without navigating to a duplicate screen.
2. As a user, I want to log the actual reps I completed and the weight I used for each set.
3. As a user, I want the rest timer to appear inline near the exercise I'm doing so I can still see my workout progress.
4. As a user, I want the "Finalizar Treino" button to actually save my workout and show the completion screen.

## Success Metrics

- Zero duplicate screens in the workout execution flow
- Reps and weight fields are editable per set
- Rest timer does not block full-screen interaction
- Finish workout reliably navigates to completion
