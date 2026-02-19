# Implementation Plan — prd-bugfix-descriptionExercices

## Order of Execution

1. WorkoutSessionStore.swift — add lastWorkoutElapsedSeconds + recordElapsedTime + formattedLastWorkoutTime
2. WorkoutCompletionView.swift — remove WorkoutTimerStore env dependency
3. WorkoutExecutionView.swift — call recordElapsedTime before finish + fix rest-timer overlay
4. CreateWorkoutView.swift — remove NavigationStack wrapper
5. ExerciseTranslationService.swift — fix sentence-initial English detection
6. ExerciseTranslationServiceTests.swift — add two new test cases

## File Mapping

| File | Change | Risk |
|------|--------|------|
| WorkoutSessionStore.swift | Add 3 properties/methods | Low |
| WorkoutCompletionView.swift | Remove 1 env var, update 1 reference | Low |
| WorkoutExecutionView.swift | Add 1 call + refactor overlay (15-20 lines) | Medium |
| CreateWorkoutView.swift | Remove 2 lines (NavigationStack open/close) | Low |
| ExerciseTranslationService.swift | Add ~8 string patterns | Low |
| ExerciseTranslationServiceTests.swift | Add 2 test methods | Low |

## Dependency Order
- Task 1 (SessionStore) must complete before Task 2 (CompletionView) and Task 3 (ExecutionView)
- Tasks 4, 5, 6 are independent
