# Tasks: Treinos Dinâmicos Implementation

## Overview

Total Tasks: 12
Estimated Effort: 4-5 days

## Task List

### Phase 1: Data Layer (Foundation)

- [ ] **Task 1**: Create Domain Entities
  - File: `Domain/Entities/CustomWorkoutTemplate.swift`
  - File: `Domain/Entities/CustomExerciseEntry.swift`
  - File: `Domain/Entities/WorkoutSet.swift`
  - Includes: Codable, Sendable, computed properties

- [ ] **Task 2**: Create Repository Protocol
  - File: `Domain/Protocols/CustomWorkoutRepository.swift`
  - Methods: listTemplates, getTemplate, saveTemplate, deleteTemplate, recordCompletion

- [ ] **Task 3**: Create SwiftData Models
  - File: `Data/SwiftData/SDCustomWorkoutTemplate.swift`
  - Includes: @Model decorators, toDomain/fromDomain mappers
  - Update: Schema in AppContainer

- [ ] **Task 4**: Implement Repository
  - File: `Data/Repositories/SwiftDataCustomWorkoutRepository.swift`
  - Implement all protocol methods
  - Add to DI container

### Phase 2: Use Cases (Business Logic)

- [ ] **Task 5**: Create SaveCustomWorkoutUseCase
  - File: `Domain/UseCases/SaveCustomWorkoutUseCase.swift`
  - Validation: non-empty name, at least 1 exercise
  - Register in DI

- [ ] **Task 6**: Create CompleteCustomWorkoutUseCase
  - File: `Domain/UseCases/CompleteCustomWorkoutUseCase.swift`
  - Integration: HistoryRepository, SyncWorkoutCompletionUseCase, HealthKit
  - Register in DI

### Phase 3: Presentation Layer (UI)

- [ ] **Task 7**: Create CustomWorkoutBuilderViewModel
  - File: `Presentation/Features/CustomWorkout/ViewModels/CustomWorkoutBuilderViewModel.swift`
  - State: name, exercises, loading, error
  - Actions: add/remove/move exercises, add/remove sets, save

- [ ] **Task 8**: Create ExercisePickerViewModel
  - File: `Presentation/Features/CustomWorkout/ViewModels/ExercisePickerViewModel.swift`
  - State: searchText, filters, exercises, loading
  - Actions: search, filter by body part/equipment

- [ ] **Task 9**: Create UI Views
  - File: `Presentation/Features/CustomWorkout/Views/CustomWorkoutBuilderView.swift`
  - File: `Presentation/Features/CustomWorkout/Views/ExercisePickerView.swift`
  - File: `Presentation/Features/CustomWorkout/Components/ExerciseRowView.swift`
  - File: `Presentation/Features/CustomWorkout/Components/SetConfigurationRow.swift`
  - Includes: Drag-to-reorder, sheet presentation

- [ ] **Task 10**: Create Templates List View
  - File: `Presentation/Features/CustomWorkout/Views/CustomWorkoutTemplatesView.swift`
  - File: `Presentation/Features/CustomWorkout/ViewModels/CustomWorkoutTemplatesViewModel.swift`
  - Features: List saved templates, delete, start workout

- [ ] **Task 11**: Create Active Workout View
  - File: `Presentation/Features/CustomWorkout/Views/ActiveCustomWorkoutView.swift`
  - File: `Presentation/Features/CustomWorkout/ViewModels/ActiveCustomWorkoutViewModel.swift`
  - Features: Track sets, mark complete, timer, finish workout

### Phase 4: Integration & Polish

- [ ] **Task 12**: Integration & Navigation
  - Update: MainTabView or HomeView to include entry point
  - Update: AppRouter for navigation
  - Add: Feature flag (if needed)
  - Test: End-to-end flow

## Dependencies

```
Task 1 → Task 2 → Task 3 → Task 4 → Task 5 → Task 6
                                      ↓
Task 7 → Task 8 → Task 9 → Task 10 → Task 11 → Task 12
```

## Acceptance Criteria per Task

### Task 1: Domain Entities
- [ ] All entities compile without errors
- [ ] Entities conform to Codable and Sendable
- [ ] Computed properties work correctly
- [ ] Unit tests pass

### Task 2: Repository Protocol
- [ ] Protocol defined with all required methods
- [ ] Return types are correct
- [ ] Async/throws signatures

### Task 3: SwiftData Models
- [ ] Models registered in Schema
- [ ] toDomain/fromDomain work correctly
- [ ] No migration errors

### Task 4: Repository Implementation
- [ ] All CRUD operations work
- [ ] Registered in DI container
- [ ] Repository tests pass

### Task 5: SaveCustomWorkoutUseCase
- [ ] Validation rejects empty name
- [ ] Validation rejects empty exercises
- [ ] Successful save persists data
- [ ] Unit tests pass

### Task 6: CompleteCustomWorkoutUseCase
- [ ] Creates history entry
- [ ] Syncs to HealthKit
- [ ] Syncs to challenges if >= 30 min
- [ ] Unit tests pass

### Task 7: BuilderViewModel
- [ ] Can add exercises
- [ ] Can remove exercises
- [ ] Can reorder exercises
- [ ] Can add/remove sets
- [ ] Can save template

### Task 8: PickerViewModel
- [ ] Search works
- [ ] Filter by body part works
- [ ] Filter by equipment works
- [ ] Loading state correct

### Task 9: UI Views
- [ ] Builder view renders correctly
- [ ] Picker modal opens/closes
- [ ] Drag-to-reorder works
- [ ] Save button enabled/disabled correctly

### Task 10: Templates List
- [ ] Lists all saved templates
- [ ] Delete works
- [ ] Can start workout from template

### Task 11: Active Workout
- [ ] Timer runs
- [ ] Can mark sets complete
- [ ] Can log actual weight/reps
- [ ] Finish creates history entry

### Task 12: Integration
- [ ] Entry point accessible from main app
- [ ] Navigation works correctly
- [ ] Full flow tested end-to-end
- [ ] Build succeeds
