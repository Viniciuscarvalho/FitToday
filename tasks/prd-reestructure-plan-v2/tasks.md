# Tasks Breakdown - FitToday App Restructure v2

> **Version:** 1.0
> **Generated:** January 2026
> **Total Tasks:** 85 tasks across 5 phases

---

## Phase 1: Wger API Migration (10 tasks)

### Task 1.1: Create Wger Models
**File:** `Domain/Entities/WgerExercise.swift`
**Priority:** High
**Depends on:** None

Create Wger API response models:
- WgerExercise
- WgerExerciseImage
- WgerPaginatedResponse<T>
- WgerCategory
- WgerEquipment

### Task 1.2: Create ExerciseServiceProtocol
**File:** `Domain/Protocols/ExerciseServiceProtocol.swift`
**Priority:** High
**Depends on:** 1.1

Define protocol with:
- fetchExercises(language:category:equipment:)
- fetchExerciseDetail(id:)
- searchExercises(query:language:)

### Task 1.3: Implement WgerAPIService
**File:** `Data/Services/Wger/WgerAPIService.swift`
**Priority:** High
**Depends on:** 1.2

Implement service with:
- Base URL configuration
- Request building with query parameters
- Response decoding
- Error handling

### Task 1.4: Create ExerciseCacheManager
**File:** `Data/Services/Wger/ExerciseCacheManager.swift`
**Priority:** Medium
**Depends on:** 1.1

Implement caching with:
- File-based storage
- 7-day TTL
- Image caching
- Cache invalidation

### Task 1.5: Create Category/Equipment Mapping
**File:** `Domain/Entities/WgerMapping.swift`
**Priority:** Medium
**Depends on:** 1.1

Create enums for:
- WgerCategory → Portuguese translation
- WgerEquipment → Portuguese translation
- Helper extensions

### Task 1.6: Implement Search with Pagination
**File:** `Data/Services/Wger/WgerAPIService.swift`
**Priority:** Medium
**Depends on:** 1.3

Add pagination support:
- Offset-based pagination
- Results limiting
- Next/previous page handling

### Task 1.7: Create Fallback Visual System
**File:** `Presentation/DesignSystem/ExercisePlaceholder.swift`
**Priority:** Low
**Depends on:** 1.5

Create SF Symbol fallbacks:
- Default exercise icon by muscle group
- Loading placeholder view
- Error state placeholder

### Task 1.8: Remove ExerciseDB Dependencies
**Priority:** High
**Depends on:** 1.3, 1.4

Remove:
- ExerciseDB service files
- API key configuration
- Related DTOs

### Task 1.9: Update ViewModels
**Priority:** High
**Depends on:** 1.3, 1.8

Update all ViewModels using exercises:
- LibraryViewModel
- WorkoutExecutionView-related
- ExerciseSearchViewModel

### Task 1.10: Write Unit Tests
**File:** `FitTodayTests/Data/WgerAPIServiceTests.swift`
**Priority:** Medium
**Depends on:** 1.3

Test:
- API response parsing
- Cache operations
- Error handling

---

## Phase 2: Workout System (20 tasks)

### Task 2.1: Create WorkoutTemplate Model
**File:** `Domain/Entities/WorkoutTemplate.swift`
**Priority:** High
**Depends on:** None

Create model with all properties from techspec.

### Task 2.2: Create WorkoutExercise Model
**File:** `Domain/Entities/WorkoutExercise.swift`
**Priority:** High
**Depends on:** 2.1

Create model with exercise details and sets.

### Task 2.3: Create ExerciseSet Model
**File:** `Domain/Entities/ExerciseSet.swift`
**Priority:** High
**Depends on:** 2.2

Create model with SetType enum.

### Task 2.4: Create WorkoutTemplateRepository Protocol
**File:** `Domain/Protocols/WorkoutTemplateRepository.swift`
**Priority:** High
**Depends on:** 2.1

Define CRUD protocol.

### Task 2.5: Implement FirebaseWorkoutTemplateRepository
**File:** `Data/Repositories/FirebaseWorkoutTemplateRepository.swift`
**Priority:** High
**Depends on:** 2.4

Implement Firestore persistence.

### Task 2.6: Create WorkoutTabView
**File:** `Presentation/Features/Workout/WorkoutTabView.swift`
**Priority:** High
**Depends on:** None

Create main workout tab with segmented control.

### Task 2.7: Create MyWorkoutsView
**File:** `Presentation/Features/Workout/MyWorkoutsView.swift`
**Priority:** High
**Depends on:** 2.6

Create workout templates list view.

### Task 2.8: Create WorkoutTemplateCard
**File:** `Presentation/Features/Workout/Components/WorkoutTemplateCard.swift`
**Priority:** Medium
**Depends on:** 2.7

Create reusable card component.

### Task 2.9: Create CreateWorkoutView
**File:** `Presentation/Features/Workout/CreateWorkoutView.swift`
**Priority:** High
**Depends on:** 2.7

Create workout creation flow.

### Task 2.10: Create CreateWorkoutViewModel
**File:** `Presentation/Features/Workout/ViewModels/CreateWorkoutViewModel.swift`
**Priority:** High
**Depends on:** 2.9, 2.5

Implement @Observable ViewModel.

### Task 2.11: Create ExerciseSearchSheet
**File:** `Presentation/Features/Workout/Components/ExerciseSearchSheet.swift`
**Priority:** High
**Depends on:** 1.3

Create exercise search modal.

### Task 2.12: Create ExerciseConfigSheet
**File:** `Presentation/Features/Workout/Components/ExerciseConfigSheet.swift`
**Priority:** Medium
**Depends on:** 2.11

Create sets configuration modal.

### Task 2.13: Create WorkoutExecutionView
**File:** `Presentation/Features/Workout/WorkoutExecutionView.swift`
**Priority:** High
**Depends on:** 2.1

Refactor or create new execution view.

### Task 2.14: Create WorkoutExecutionViewModel
**File:** `Presentation/Features/Workout/ViewModels/WorkoutExecutionViewModel.swift`
**Priority:** High
**Depends on:** 2.13

Implement execution state management.

### Task 2.15: Create RestTimerView (Update)
**File:** `Presentation/Features/Workout/Components/RestTimerView.swift`
**Priority:** Medium
**Depends on:** 2.13

Update existing timer view for new flow.

### Task 2.16: Create WorkoutSummaryView
**File:** `Presentation/Features/Workout/WorkoutSummaryView.swift`
**Priority:** Medium
**Depends on:** 2.13

Create post-workout summary screen.

### Task 2.17: Implement Drag & Drop Reordering
**Priority:** Low
**Depends on:** 2.9

Add exercise reordering in create flow.

### Task 2.18: Implement Swipe Actions
**Priority:** Low
**Depends on:** 2.7

Add edit/delete swipe actions.

### Task 2.19: Add Haptic Feedback
**Priority:** Low
**Depends on:** 2.13

Add tactile feedback on interactions.

### Task 2.20: Create Empty State Views
**File:** `Presentation/Features/Workout/Components/WorkoutEmptyState.swift`
**Priority:** Medium
**Depends on:** 2.7

Create empty and error states.

---

## Phase 3: Programs Catalog (12 tasks)

### Task 3.1: Create WorkoutProgram Model
**File:** `Domain/Entities/WorkoutProgram.swift`
**Priority:** High
**Depends on:** None

Create program model with enums.

### Task 3.2: Create FitnessLevel Enum
**File:** `Domain/Entities/FitnessLevel.swift`
**Priority:** High
**Depends on:** 3.1

### Task 3.3: Create FitnessGoal Enum
**File:** `Domain/Entities/FitnessGoal.swift`
**Priority:** High
**Depends on:** 3.1

### Task 3.4: Create EquipmentType Enum
**File:** `Domain/Entities/EquipmentType.swift`
**Priority:** High
**Depends on:** 3.1

### Task 3.5: Create ProgramsCatalog
**File:** `Data/Programs/ProgramsCatalog.swift`
**Priority:** High
**Depends on:** 3.1

Define all 26 programs.

### Task 3.6: Create Program Template Files
**Files:** `Data/Programs/Templates/*.swift`
**Priority:** Medium
**Depends on:** 3.5

Create:
- PPLTemplates.swift
- FullBodyTemplates.swift
- UpperLowerTemplates.swift
- BroSplitTemplates.swift
- StrengthTemplates.swift
- WeightLossTemplates.swift
- HomeGymTemplates.swift
- SpecializedTemplates.swift

### Task 3.7: Create ProgramsListView
**File:** `Presentation/Features/Programs/ProgramsListView.swift`
**Priority:** High
**Depends on:** 3.5

Create programs grid view.

### Task 3.8: Create ProgramFiltersView
**File:** `Presentation/Features/Programs/ProgramFiltersView.swift`
**Priority:** Medium
**Depends on:** 3.7

Create filter chips component.

### Task 3.9: Create ProgramDetailView
**File:** `Presentation/Features/Programs/ProgramDetailView.swift`
**Priority:** High
**Depends on:** 3.7

Create program detail screen.

### Task 3.10: Create ProgramWorkoutPreviewView
**File:** `Presentation/Features/Programs/ProgramWorkoutPreviewView.swift`
**Priority:** Medium
**Depends on:** 3.9

Create workout preview modal.

### Task 3.11: Implement Start Program Flow
**Priority:** High
**Depends on:** 3.9, 2.5

Convert program to user templates.

### Task 3.12: Create Programs Empty State
**File:** `Presentation/Features/Programs/Components/ProgramsEmptyState.swift`
**Priority:** Low
**Depends on:** 3.7

---

## Phase 4: Activity & Sync (15 tasks)

### Task 4.1: Create UnifiedWorkoutSession Model
**File:** `Domain/Entities/UnifiedWorkoutSession.swift`
**Priority:** High
**Depends on:** None

### Task 4.2: Create WorkoutSource Enum
**File:** `Domain/Entities/WorkoutSource.swift`
**Priority:** High
**Depends on:** 4.1

### Task 4.3: Create ChallengeContribution Model
**File:** `Domain/Entities/ChallengeContribution.swift`
**Priority:** Medium
**Depends on:** 4.1

### Task 4.4: Create WorkoutSyncManager
**File:** `Data/Services/WorkoutSyncManager.swift`
**Priority:** High
**Depends on:** 4.1

### Task 4.5: Create HealthKitService (Update)
**File:** `Data/Services/HealthKit/HealthKitService.swift`
**Priority:** High
**Depends on:** 4.4

Update for workout reading.

### Task 4.6: Implement Merge Logic
**Priority:** High
**Depends on:** 4.4, 4.5

Implement duplicate-free merge.

### Task 4.7: Create ActivityTabView
**File:** `Presentation/Features/Activity/ActivityTabView.swift`
**Priority:** High
**Depends on:** None

Create main activity tab.

### Task 4.8: Create WorkoutHistoryView
**File:** `Presentation/Features/Activity/WorkoutHistoryView.swift`
**Priority:** High
**Depends on:** 4.7

Create history with calendar.

### Task 4.9: Create MonthCalendarView
**File:** `Presentation/Features/Activity/Components/MonthCalendarView.swift`
**Priority:** Medium
**Depends on:** 4.8

Create calendar component.

### Task 4.10: Create WorkoutDetailView
**File:** `Presentation/Features/Activity/WorkoutDetailView.swift`
**Priority:** Medium
**Depends on:** 4.8

Create session detail view.

### Task 4.11: Create ChallengesListView
**File:** `Presentation/Features/Activity/ChallengesListView.swift`
**Priority:** Medium
**Depends on:** 4.7

### Task 4.12: Create ChallengeDetailView
**File:** `Presentation/Features/Activity/ChallengeDetailView.swift`
**Priority:** Medium
**Depends on:** 4.11

### Task 4.13: Create StatsView
**File:** `Presentation/Features/Activity/StatsView.swift`
**Priority:** Low
**Depends on:** 4.7

### Task 4.14: Implement Background Sync
**Priority:** Low
**Depends on:** 4.4

Use BackgroundTasks framework.

### Task 4.15: Create Activity Empty States
**File:** `Presentation/Features/Activity/Components/ActivityEmptyStates.swift`
**Priority:** Low
**Depends on:** 4.7

---

## Phase 5: Home & AI (13 tasks)

### Task 5.1: Create MuscleGroup Enum
**File:** `Domain/Entities/MuscleGroup.swift`
**Priority:** High
**Depends on:** 1.5

### Task 5.2: Create AIWorkoutGenerator
**File:** `Domain/UseCases/AIWorkoutGenerator.swift`
**Priority:** High
**Depends on:** 1.3, 5.1

### Task 5.3: Create GeneratedWorkout Model
**File:** `Domain/Entities/GeneratedWorkout.swift`
**Priority:** High
**Depends on:** 5.2

### Task 5.4: Update OpenAIService
**File:** `Data/Services/OpenAI/OpenAIService.swift`
**Priority:** High
**Depends on:** 5.2

Update prompt for new flow.

### Task 5.5: Create HomeTabView (Refactor)
**File:** `Presentation/Features/Home/HomeTabView.swift`
**Priority:** High
**Depends on:** None

Refactor existing HomeView.

### Task 5.6: Create AIWorkoutInputCard
**File:** `Presentation/Features/Home/Components/AIWorkoutInputCard.swift`
**Priority:** High
**Depends on:** 5.5

### Task 5.7: Create MuscleSelectionGrid
**File:** `Presentation/Features/Home/Components/MuscleSelectionGrid.swift`
**Priority:** High
**Depends on:** 5.6, 5.1

### Task 5.8: Create FatigueSlider
**File:** `Presentation/Features/Home/Components/FatigueSlider.swift`
**Priority:** Medium
**Depends on:** 5.6

### Task 5.9: Create TimeSelectionView
**File:** `Presentation/Features/Home/Components/TimeSelectionView.swift`
**Priority:** Medium
**Depends on:** 5.6

### Task 5.10: Create AIGeneratingView
**File:** `Presentation/Features/Home/Components/AIGeneratingView.swift`
**Priority:** Medium
**Depends on:** 5.6

Loading state view.

### Task 5.11: Create GeneratedWorkoutPreview
**File:** `Presentation/Features/Home/GeneratedWorkoutPreview.swift`
**Priority:** High
**Depends on:** 5.2

### Task 5.12: Create StreakProgressBar
**File:** `Presentation/Features/Home/Components/StreakProgressBar.swift`
**Priority:** Low
**Depends on:** 5.5

### Task 5.13: Create WeeklySummaryCard
**File:** `Presentation/Features/Home/Components/WeeklySummaryCard.swift`
**Priority:** Low
**Depends on:** 5.5

---

## General Tasks (15 tasks)

### Task G.1: Update TabRootView
**File:** `Presentation/Root/TabRootView.swift`
**Priority:** High
**Depends on:** 2.6, 4.7, 5.5

Update tab structure.

### Task G.2: Update AppRouter
**File:** `Presentation/Router/AppRouter.swift`
**Priority:** High
**Depends on:** G.1

Add new routes.

### Task G.3: Update AppContainer (DI)
**File:** `Presentation/DI/AppContainer.swift`
**Priority:** High
**Depends on:** All services

Register new dependencies.

### Task G.4: Configure HealthKit Entitlements
**Priority:** High
**Depends on:** 4.5

Add required capabilities.

### Task G.5: Update Firebase Security Rules
**Priority:** Medium
**Depends on:** 2.5

### Task G.6: Add Localization Strings
**Priority:** Medium
**Depends on:** All UI

Add PT-BR and EN strings.

### Task G.7: Create Design System Screens (Pencil)
**Priority:** High
**Depends on:** None

Design all screens in Pencil MCP.

### Task G.8: Update Unit Tests
**Priority:** Medium
**Depends on:** All domain

### Task G.9: Update Integration Tests
**Priority:** Low
**Depends on:** All services

### Task G.10: Performance Testing
**Priority:** Low
**Depends on:** All UI

### Task G.11: Accessibility Audit
**Priority:** Medium
**Depends on:** All UI

### Task G.12: Dark Mode Verification
**Priority:** Medium
**Depends on:** All UI

### Task G.13: Create Migration Guide
**Priority:** Low
**Depends on:** 1.8

### Task G.14: Update README
**Priority:** Low
**Depends on:** All

### Task G.15: Prepare TestFlight Build
**Priority:** High
**Depends on:** All

---

## Task Dependencies Graph

```
Phase 1 (API) ──────────────────────────────────────────┐
                                                         │
Phase 2 (Workout) ──────┬───────────────────────────────┤
                        │                               │
Phase 3 (Programs) ─────┼───────────────────────────────┤
                        │                               │
Phase 4 (Activity) ─────┼───────────────────────────────┤
                        │                               │
Phase 5 (Home/AI) ──────┴───────────────────────────────┤
                                                         │
General Tasks ◄──────────────────────────────────────────┘
```

---

## Priority Legend

- **High**: Critical path, blocks other tasks
- **Medium**: Important but has alternatives
- **Low**: Nice to have, can be deferred

---

**Last Updated:** January 2026
