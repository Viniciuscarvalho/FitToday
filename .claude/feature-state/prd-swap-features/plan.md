# Implementation Plan: Treinos Dinâmicos

## Summary

Implementing custom workout builder feature with 12 tasks across 4 phases.

## Critical Files to Create

### Domain Layer
1. `Domain/Entities/CustomWorkoutTemplate.swift`
2. `Domain/Entities/CustomExerciseEntry.swift`
3. `Domain/Entities/WorkoutSet.swift`
4. `Domain/Protocols/CustomWorkoutRepository.swift`
5. `Domain/UseCases/SaveCustomWorkoutUseCase.swift`
6. `Domain/UseCases/CompleteCustomWorkoutUseCase.swift`

### Data Layer
7. `Data/SwiftData/SDCustomWorkoutTemplate.swift`
8. `Data/Repositories/SwiftDataCustomWorkoutRepository.swift`

### Presentation Layer
9. `Presentation/Features/CustomWorkout/Views/CustomWorkoutBuilderView.swift`
10. `Presentation/Features/CustomWorkout/Views/ExercisePickerView.swift`
11. `Presentation/Features/CustomWorkout/Views/CustomWorkoutTemplatesView.swift`
12. `Presentation/Features/CustomWorkout/Views/ActiveCustomWorkoutView.swift`
13. `Presentation/Features/CustomWorkout/ViewModels/CustomWorkoutBuilderViewModel.swift`
14. `Presentation/Features/CustomWorkout/ViewModels/ExercisePickerViewModel.swift`
15. `Presentation/Features/CustomWorkout/ViewModels/CustomWorkoutTemplatesViewModel.swift`
16. `Presentation/Features/CustomWorkout/ViewModels/ActiveCustomWorkoutViewModel.swift`
17. `Presentation/Features/CustomWorkout/Components/ExerciseRowView.swift`
18. `Presentation/Features/CustomWorkout/Components/SetConfigurationRow.swift`

### Files to Modify
- `Presentation/DI/AppContainer.swift` - Register new dependencies
- `Data/SwiftData/Schema` - Add new models
- `Presentation/Navigation/AppRouter.swift` - Add routes (if needed)
- Main navigation entry point

## Execution Order

1. **Tasks 1-4**: Data foundation (entities, protocols, SwiftData, repository)
2. **Tasks 5-6**: Business logic (use cases)
3. **Tasks 7-8**: ViewModels
4. **Tasks 9-11**: UI Views
5. **Task 12**: Integration

## Risks Identified

1. **ExerciseDB Integration**: Need to verify existing service works for picker
2. **SwiftData Schema**: Adding new models - verify no migration issues
3. **HealthKit Sync**: Reuse existing use case, minimal risk

## Ready to Implement

Starting with Task 1: Create Domain Entities
