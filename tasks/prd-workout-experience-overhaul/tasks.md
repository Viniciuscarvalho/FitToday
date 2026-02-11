# Tasks: Workout Experience Overhaul

**Feature:** prd-workout-experience-overhaul
**Created:** 2026-02-09
**Status:** Ready for Implementation
**Review Status:** Multi-agent reviewed (Architect, Swift Expert, Code Reviewer)

---

## Task Overview

| Task | Title | Size | Priority | Dependencies |
|------|-------|------|----------|--------------|
| 0.0 | Workout Input Collection Screen | M | P0 | None |
| 1.0 | Workout Variation Validator | S | P0 | None |
| 2.0 | Local Fallback Workout Composer | M | P0 | 1.0 |
| 3.0 | OpenAI Generation Enhancement | L | P0 | 1.0, 2.0 |
| 4.0 | Exercise Media Resolution | S | P1 | None |
| 5.0 | Portuguese Description Service | M | P1 | None |
| 6.0 | Workout Execution ViewModel | L | P1 | None |
| 7.0 | Workout Navigation Flow | M | P1 | 6.0 |
| 8.0 | Workout Execution Views | L | P1 | 6.0, 4.0, 5.0 |
| 9.0 | Live Activity Extension Setup | M | P1 | None |
| 10.0 | Live Activity Manager | M | P1 | 9.0 |
| 11.0 | Live Activity Integration | M | P1 | 6.0, 10.0 |
| 12.0 | Workout Completion Enhancements | S | P2 | 6.0, 11.0 |
| 13.0 | Integration Tests | S | P2 | All above |

---

## Review Notes

**Multi-Agent Review Completed:**
- Architect: Approved with modifications (use @MainActor, not actor; compose with existing stores)
- Swift Expert: Corrections applied (Sendable compliance, existing timer pattern)
- Code Reviewer: Missing tasks added (0.0, 7.0, 13.0)

**Key Changes from Review:**
1. RestTimerStore/WorkoutTimerStore ALREADY EXIST - compose, don't recreate
2. Live Activity Manager uses @MainActor class, not actor
3. Task 3.0 upgraded from M to L (retry complexity)
4. Tasks 4.0 and 5.0 moved earlier (data layer first)

---

## Epic 1: Dynamic Workout Generation

### [0.0] Workout Input Collection Screen (M)

<critical>Read the prd.md and techspec.md files in this folder before implementing.</critical>

#### Objective
Create UI for collecting workout generation inputs before calling OpenAI/fallback (FR-001).

#### Subtasks
- [ ] 0.1 Create `WorkoutInputViewModel` with @Observable
- [ ] 0.2 Create `WorkoutInputView` with muscle group multi-select picker
- [ ] 0.3 Add energy level selection (tired/normal/energized)
- [ ] 0.4 Load available equipment from user profile
- [ ] 0.5 Pass inputs to `DailyCheckIn` model
- [ ] 0.6 Wire to existing workout generation flow
- [ ] 0.7 Write unit tests for input validation

#### Implementation Details
The PRD requires collecting:
- Equipment availability (from UserProfile.availableStructure)
- Muscle groups to target (DailyFocus or custom selection)
- User level (from UserProfile.level)
- Current feeling/energy (energyLevel in DailyCheckIn)

#### Success Criteria
- All inputs are collected before generation
- Inputs are passed to WorkoutPromptAssembler
- UI respects existing design system
- Tests cover input validation logic

#### Relevant Files
- `FitToday/Presentation/Features/Workout/ViewModels/WorkoutInputViewModel.swift` (new)
- `FitToday/Presentation/Features/Workout/Views/WorkoutInputView.swift` (new)
- `FitToday/Domain/Entities/DailyCheckIn.swift` (existing)

#### status: pending

---

### [1.0] Workout Variation Validator (S)

<critical>Read the prd.md and techspec.md files in this folder before implementing.</critical>

#### Objective
Create a validator that ensures generated workouts have at least 60% different exercises from the last 3 workouts.

#### Subtasks
- [ ] 1.1 Create `WorkoutVariationValidator` struct in Domain/UseCases/
- [ ] 1.2 Implement `validateDiversity` method with 60% threshold
- [ ] 1.3 Add comparison logic for exercise names (case-insensitive)
- [ ] 1.4 Write unit tests for validator with various scenarios

#### Implementation Details
See techspec.md section "Component: WorkoutPromptAssembler Enhancement"

#### Success Criteria
- Validator correctly identifies when diversity threshold is not met
- Tests cover: empty workouts, 100% overlap, 0% overlap, boundary cases
- Minimum 80% test coverage

#### Relevant Files
- `FitToday/Domain/UseCases/WorkoutVariationValidator.swift` (new)
- `FitTodayTests/Domain/UseCases/WorkoutVariationValidatorTests.swift` (new)

#### status: pending

---

### [2.0] Local Fallback Workout Composer (M)

<critical>Read the prd.md and techspec.md files in this folder before implementing.</critical>

#### Objective
Implement a local workout generator that creates workouts when OpenAI fails, respecting user inputs and variation rules.

#### Subtasks
- [ ] 2.1 Create `LocalWorkoutPlanComposer` protocol in Domain/Protocols/
- [ ] 2.2 Implement `DefaultLocalWorkoutPlanComposer` in Data/Services/
- [ ] 2.3 Use `WorkoutBlueprint` to determine workout structure
- [ ] 2.4 Select exercises from `WorkoutBlock` repository filtered by equipment
- [ ] 2.5 Apply variation logic using `WorkoutVariationValidator`
- [ ] 2.6 Write unit tests with mock blocks

#### Implementation Details
See techspec.md section "Component: Local Fallback Generator"

#### Success Criteria
- Generates valid `WorkoutPlan` in under 2 seconds
- Respects equipment constraints from user profile
- Enforces variation from previous workouts
- All tests passing with 70% coverage

#### Relevant Files
- `FitToday/Domain/Protocols/LocalWorkoutPlanComposer.swift` (new)
- `FitToday/Data/Services/Workout/LocalWorkoutPlanComposer.swift` (new)
- `FitTodayTests/Data/Services/Workout/LocalWorkoutPlanComposerTests.swift` (new)

#### Dependencies
- Task 1.0 (Workout Variation Validator)

#### status: pending

---

### [3.0] OpenAI Generation Enhancement (L)

<critical>Read the prd.md and techspec.md files in this folder before implementing.</critical>

#### Objective
Enhance the existing OpenAI workout generation to include post-generation validation and retry mechanism.

#### Subtasks
- [ ] 3.1 Add `WorkoutVariationValidator` call after generation in `OpenAIWorkoutPlanComposer`
- [ ] 3.2 Implement retry mechanism with modified seed (max 2 retries)
- [ ] 3.3 Integrate local fallback when retries exhausted
- [ ] 3.4 Add user notification flag for fallback usage
- [ ] 3.5 Update existing tests to cover new flow
- [ ] 3.6 Add timeout handling (10s max)
- [ ] 3.7 Test edge cases: network failure, rate limit, invalid response

#### Implementation Details
See techspec.md section "Epic 1: Dynamic Workout Generation"

#### Success Criteria
- Post-generation validation runs automatically
- Failed validation triggers retry with new seed
- After 2 retries, local fallback is used
- User is notified when fallback is used
- Tests cover all retry paths

#### Relevant Files
- `FitToday/Data/Services/OpenAI/OpenAIWorkoutPlanComposer.swift`
- `FitToday/Data/Services/OpenAI/WorkoutPromptAssembler.swift`
- `FitTodayTests/Data/Services/OpenAI/OpenAIWorkoutPlanComposerTests.swift`

#### Dependencies
- Task 1.0 (Workout Variation Validator)
- Task 2.0 (Local Fallback Workout Composer)

#### status: pending

---

## Epic 2: Workout Execution with Live Activities

**IMPORTANT**: The codebase already has `RestTimerStore` and `WorkoutTimerStore` that handle timer logic. Tasks in this epic should COMPOSE with them, not recreate them.

### [4.0] Exercise Media Resolution (S)

<critical>Read the prd.md and techspec.md files in this folder before implementing.</critical>

#### Objective
Improve exercise media resolution with proper priority order and placeholders.

#### Subtasks
- [ ] 4.1 Enhance `WgerExerciseAdapter.resolveMedia` method
- [ ] 4.2 Implement priority: video > GIF > image > placeholder
- [ ] 4.3 Create muscle group placeholder images (or reference existing)
- [ ] 4.4 Update `ExerciseMedia` model with placeholder support
- [ ] 4.5 Write tests for media resolution priority

#### Implementation Details
See techspec.md section "Component: Exercise Image Resolution"

Placeholder naming convention: `placeholder_{muscleGroup}.svg`

#### Success Criteria
- Video is prioritized when available
- Placeholder displayed when no media exists
- Placeholder matches muscle group
- Tests verify priority order

#### Relevant Files
- `FitToday/Data/Services/Wger/WgerExerciseAdapter.swift`
- `FitToday/Domain/Entities/WorkoutModels.swift`
- `FitTodayTests/Data/Services/Wger/WgerExerciseAdapterTests.swift`

#### status: pending

---

### [5.0] Portuguese Description Service (M)

<critical>Read the prd.md and techspec.md files in this folder before implementing.</critical>

#### Objective
Ensure exercise descriptions are consistently in Portuguese, with translation fallback.

#### Subtasks
- [ ] 5.1 Create `ExerciseDescriptionServicing` protocol
- [ ] 5.2 Implement `ExerciseDescriptionService` actor
- [ ] 5.3 Fetch Portuguese description from Wger (language=2)
- [ ] 5.4 Implement fallback to English translation
- [ ] 5.5 Sanitize HTML and remove Spanish content
- [ ] 5.6 Add in-memory cache for descriptions
- [ ] 5.7 Write tests for caching and fallback

#### Implementation Details
See techspec.md section "Component: Portuguese Description Service"

Content sanitization:
- Remove HTML tags
- Replace HTML entities
- Filter Spanish content (detect by common Spanish words/patterns)

#### Success Criteria
- Portuguese descriptions fetched when available
- English descriptions translated as fallback
- No Spanish content in output
- Cache improves performance
- Tests cover all scenarios

#### Relevant Files
- `FitToday/Domain/Protocols/ExerciseDescriptionServicing.swift` (new)
- `FitToday/Data/Services/Translation/ExerciseDescriptionService.swift` (new)
- `FitTodayTests/Data/Services/Translation/ExerciseDescriptionServiceTests.swift` (new)

#### status: pending

---

### [6.0] Workout Execution ViewModel (L)

<critical>Read the prd.md and techspec.md files in this folder before implementing.</critical>

#### Objective
Create the main ViewModel for workout execution that COMPOSES with existing stores (WorkoutSessionStore, RestTimerStore, WorkoutTimerStore).

#### Subtasks
- [ ] 6.1 Create `WorkoutExecutionViewModel` with @MainActor + @Observable
- [ ] 6.2 Compose with existing `WorkoutSessionStore` (DO NOT duplicate)
- [ ] 6.3 Compose with existing `RestTimerStore` (DO NOT create new timer)
- [ ] 6.4 Compose with existing `WorkoutTimerStore` (DO NOT duplicate)
- [ ] 6.5 Implement exercise navigation via sessionStore delegation
- [ ] 6.6 Implement set completion tracking via sessionStore
- [ ] 6.7 Wire rest timer start on set completion
- [ ] 6.8 Implement pause/resume via workoutTimer
- [ ] 6.9 Add crash recovery persistence (use existing WorkoutProgress)
- [ ] 6.10 Add `nonisolated(unsafe)` for Task cleanup in deinit
- [ ] 6.11 Write comprehensive unit tests

#### Implementation Details
See techspec.md section "Component: WorkoutExecutionViewModel"

**CRITICAL**: Derive state from existing stores via computed properties:
```swift
var currentExerciseIndex: Int { sessionStore.currentExerciseIndex }
var workoutElapsedTime: TimeInterval { TimeInterval(workoutTimer.elapsedSeconds) }
var isResting: Bool { restTimer.isActive }
var isPaused: Bool { !workoutTimer.isRunning }
```

#### Success Criteria
- All state derived from existing stores (no duplication)
- Set completion triggers existing RestTimerStore
- Exercise navigation uses existing WorkoutSessionStore
- Pause stops workoutTimer (existing)
- Progress uses existing WorkoutProgress persistence
- Tests achieve 80% coverage

#### Relevant Files
- `FitToday/Presentation/Features/Workout/ViewModels/WorkoutExecutionViewModel.swift` (new)
- `FitToday/Presentation/Features/Workout/WorkoutSessionStore.swift` (existing - compose)
- `FitToday/Presentation/Features/Workout/RestTimerStore.swift` (existing - compose)
- `FitToday/Presentation/Features/Workout/WorkoutTimerStore.swift` (existing - compose)
- `FitTodayTests/Presentation/Features/Workout/WorkoutExecutionViewModelTests.swift` (new)

#### status: pending

---

### [7.0] Workout Navigation Flow (M)

<critical>Read the prd.md and techspec.md files in this folder before implementing.</critical>

#### Objective
Implement navigation from program selection to workout execution (FR-005).

#### Subtasks
- [ ] 7.1 Review existing program/workout views
- [ ] 7.2 Create or enhance `ProgramDetailView` showing workouts
- [ ] 7.3 Create `WorkoutPreviewView` showing exercises before start
- [ ] 7.4 Add "Start Workout" button that navigates to WorkoutExecutionView
- [ ] 7.5 Implement Router navigation pattern
- [ ] 7.6 Wire back navigation on workout completion

#### Implementation Details
Navigation flow per PRD FR-005:
Programs → Select Program → View Workouts → Select Workout → View Exercises → Start → Execute

#### Success Criteria
- User can navigate from program list to workout execution
- Preview shows exercises before starting
- Start button initiates workout execution
- Back navigation works correctly

#### Relevant Files
- `FitToday/Presentation/Features/Programs/` (existing - enhance)
- `FitToday/Presentation/Features/Workout/Views/WorkoutPreviewView.swift` (new)
- `FitToday/Presentation/Navigation/` (existing router)

#### Dependencies
- Task 6.0 (needs WorkoutExecutionViewModel entry point)

#### status: pending

---

### [8.0] Workout Execution Views (L)

<critical>Read the prd.md and techspec.md files in this folder before implementing.</critical>

#### Objective
Create the SwiftUI views for workout execution: main execution screen, rest timer overlay, exercise cards.

#### Subtasks
- [ ] 8.1 Create `WorkoutExecutionView` main screen
- [ ] 8.2 Create `ExerciseExecutionCard` component
- [ ] 8.3 Use existing `RestTimerView` or create overlay variant
- [ ] 8.4 Create `ExerciseMediaView` for image/video display
- [ ] 8.5 Implement set completion checkboxes
- [ ] 8.6 Add skip/next exercise buttons
- [ ] 8.7 Add pause/play controls
- [ ] 8.8 Add total workout timer display
- [ ] 8.9 Wire navigation to workout completion screen

#### Implementation Details
See techspec.md section "Epic 2: Workout Execution with Live Activities"

UI Requirements:
- Exercise name prominently displayed
- Media (video > GIF > image) with loading indicator
- Series counter (e.g., "Set 2/4")
- Rest timer countdown when active
- Bottom controls: pause, skip, next

#### Success Criteria
- All UI elements display correctly
- Controls trigger appropriate ViewModel actions
- Smooth transitions between exercises
- Rest timer overlay appears/dismisses correctly
- Matches design guidelines in CLAUDE.md

#### Relevant Files
- `FitToday/Presentation/Features/Workout/Views/WorkoutExecutionView.swift` (new)
- `FitToday/Presentation/Features/Workout/Components/ExerciseExecutionCard.swift` (new)
- `FitToday/Presentation/Features/Workout/Components/ExerciseMediaView.swift` (new)
- `FitToday/Presentation/DesignSystem/RestTimerView.swift` (existing)

#### Dependencies
- Task 6.0 (Workout Execution ViewModel)
- Task 4.0 (Exercise Media Resolution)
- Task 5.0 (Portuguese Description Service)

#### status: pending

---

## Epic 3: Live Activity

### [9.0] Live Activity Extension Setup (M)

<critical>Read the prd.md and techspec.md files in this folder before implementing.</critical>

#### Objective
Set up the Widget Extension target for Live Activities.

**NOTE**: Requires physical device or iOS 17+ simulator for testing.

#### Subtasks
- [ ] 9.1 Create new Widget Extension target "FitTodayLiveActivity"
- [ ] 9.2 Configure ActivityKit entitlements
- [ ] 9.3 Create `WorkoutActivityAttributes` model (with Sendable ContentState)
- [ ] 9.4 Create basic `WorkoutLiveActivity` widget
- [ ] 9.5 Configure Info.plist for Live Activity support
- [ ] 9.6 Add target to project scheme
- [ ] 9.7 Implement Dynamic Island UI (compact, minimal, expanded)

#### Implementation Details
See techspec.md section "Component: Live Activity Implementation"

Required capabilities:
- Push Notifications (for Live Activity updates)
- ActivityKit entitlement

#### Success Criteria
- Widget Extension compiles successfully
- Live Activity can be started from main app
- Basic UI displays in Lock Screen
- Dynamic Island shows compact/expanded views
- No build warnings

#### Relevant Files
- `FitTodayLiveActivity/WorkoutActivityAttributes.swift` (new)
- `FitTodayLiveActivity/WorkoutLiveActivity.swift` (new)
- `FitTodayLiveActivity/FitTodayLiveActivityBundle.swift` (new)

#### status: pending

---

### [10.0] Live Activity Manager (M)

<critical>Read the prd.md and techspec.md files in this folder before implementing.</critical>

#### Objective
Create the manager that handles Live Activity lifecycle from the main app.

**CRITICAL**: Use `@MainActor` class, NOT `actor`. ActivityKit is MainActor-bound.

#### Subtasks
- [ ] 10.1 Create `WorkoutLiveActivityManager` @MainActor class in Presentation/Features/Workout/
- [ ] 10.2 Implement `startActivity` method with permission check
- [ ] 10.3 Implement `updateActivity` method
- [ ] 10.4 Implement `endActivity` method with dismissal policies
- [ ] 10.5 Handle permission checks and error cases
- [ ] 10.6 Write unit tests with spy manager

#### Implementation Details
See techspec.md section "Live Activity Manager"

**Important**: Do NOT use `actor` - ActivityKit APIs are MainActor-isolated.

#### Success Criteria
- Manager starts/updates/ends activities correctly
- Handles permission denied gracefully
- @MainActor isolated (not actor)
- Tests cover all lifecycle states

#### Relevant Files
- `FitToday/Presentation/Features/Workout/WorkoutLiveActivityManager.swift` (new)
- `FitTodayTests/Presentation/Features/Workout/WorkoutLiveActivityManagerTests.swift` (new)

#### Dependencies
- Task 9.0 (Live Activity Extension Setup)

#### status: pending

---

### [11.0] Live Activity Integration (M)

<critical>Read the prd.md and techspec.md files in this folder before implementing.</critical>

#### Objective
Integrate Live Activity updates into the workout execution flow.

#### Subtasks
- [ ] 11.1 Inject `WorkoutLiveActivityManager` into `WorkoutExecutionViewModel`
- [ ] 11.2 Start Live Activity when workout begins
- [ ] 11.3 Update Live Activity on exercise change
- [ ] 11.4 Update Live Activity on set completion
- [ ] 11.5 Update Live Activity on rest timer tick (debounced)
- [ ] 11.6 Update Live Activity on pause/resume
- [ ] 11.7 End Live Activity when workout completes
- [ ] 11.8 Derive state from stores (single source of truth)

#### Implementation Details
Update frequency:
- Exercise change: immediate
- Set completion: immediate
- Rest timer: every second
- Workout timer: every 5 seconds (battery optimization)

**Use computed property for state derivation:**
```swift
private var liveActivityState: WorkoutActivityAttributes.ContentState {
    WorkoutActivityAttributes.ContentState(
        currentExerciseName: sessionStore.effectiveCurrentExerciseName,
        currentSet: sessionStore.currentExerciseProgress?.completedSetsCount ?? 0,
        totalSets: sessionStore.currentExerciseProgress?.totalSets ?? 0,
        restTimeRemaining: restTimer.isActive ? TimeInterval(restTimer.remainingSeconds) : nil,
        workoutElapsedTime: TimeInterval(workoutTimer.elapsedSeconds),
        isPaused: !workoutTimer.isRunning
    )
}
```

#### Success Criteria
- Live Activity shows current exercise and set
- Rest timer countdown visible on Lock Screen
- Pause state reflected in Live Activity
- Activity ends when workout completes
- Works correctly when app is in background

#### Relevant Files
- `FitToday/Presentation/Features/Workout/ViewModels/WorkoutExecutionViewModel.swift`
- `FitTodayLiveActivity/WorkoutLiveActivity.swift`

#### Dependencies
- Task 6.0 (Workout Execution ViewModel)
- Task 10.0 (Live Activity Manager)

#### status: pending

---

## Epic 4: Polish

### [12.0] Workout Completion Enhancements (S)

<critical>Read the prd.md and techspec.md files in this folder before implementing.</critical>

#### Objective
Enhance the workout completion screen with summary statistics and rating.

#### Subtasks
- [ ] 12.1 Update `WorkoutCompletionView` with total time display
- [ ] 12.2 Add completed exercises count
- [ ] 12.3 Integrate 1-5 star rating (existing `WorkoutRatingView`)
- [ ] 12.4 Save completed workout to history
- [ ] 12.5 End Live Activity on completion
- [ ] 12.6 Clear session state after save

#### Implementation Details
Completion screen should display:
- Total workout time
- Exercises completed / total
- Star rating input
- Save button

#### Success Criteria
- All statistics display correctly
- Rating is saved with workout
- Live Activity dismissed
- Session properly cleared
- Navigation returns to appropriate screen

#### Relevant Files
- `FitToday/Presentation/Features/Workout/Views/WorkoutCompletionView.swift`
- `FitToday/Presentation/Features/Workout/Components/WorkoutRatingView.swift`

#### Dependencies
- Task 6.0 (Workout Execution ViewModel)
- Task 11.0 (Live Activity Integration)

#### status: pending

---

### [13.0] Integration Tests (S)

<critical>Read the prd.md and techspec.md files in this folder before implementing.</critical>

#### Objective
Write integration tests covering full flows across layers.

#### Subtasks
- [ ] 13.1 Test full workout generation with validation and fallback
- [ ] 13.2 Test workout execution start-to-finish flow
- [ ] 13.3 Test Live Activity lifecycle with spy manager
- [ ] 13.4 Test crash recovery scenario
- [ ] 13.5 Test timer accuracy over 60 seconds

#### Implementation Details
Integration tests should verify:
- End-to-end data flow
- Component interactions
- Error handling across boundaries

#### Success Criteria
- All integration scenarios pass
- Timer accuracy verified (±1 second)
- Recovery from interruption works
- Live Activity state sync verified

#### Relevant Files
- `FitTodayTests/Integration/WorkoutGenerationIntegrationTests.swift` (new)
- `FitTodayTests/Integration/WorkoutExecutionIntegrationTests.swift` (new)

#### Dependencies
- All implementation tasks complete

#### status: pending

---

## Execution Order

### Phase 1: Core Generation (P0)
1. Task 0.0 - Workout Input Collection
2. Task 1.0 - Workout Variation Validator
3. Task 2.0 - Local Fallback Workout Composer
4. Task 3.0 - OpenAI Generation Enhancement

### Phase 2A: Data Layer (P1)
5. Task 4.0 - Exercise Media Resolution
6. Task 5.0 - Portuguese Description Service

### Phase 2B: Execution Foundation (P1)
7. Task 6.0 - Workout Execution ViewModel
8. Task 7.0 - Workout Navigation Flow
9. Task 8.0 - Workout Execution Views

### Phase 3: Live Activity (P1)
10. Task 9.0 - Live Activity Extension Setup
11. Task 10.0 - Live Activity Manager
12. Task 11.0 - Live Activity Integration

### Phase 4: Polish (P2)
13. Task 12.0 - Workout Completion Enhancements
14. Task 13.0 - Integration Tests

---

**Document End**
