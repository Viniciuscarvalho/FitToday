# Analysis: Workout Experience Overhaul

**Feature:** prd-workout-experience-overhaul
**Date:** 2026-02-09
**Status:** Complete

---

## Overview

This feature addresses three critical UX issues in FitToday:
1. Repetitive AI-generated workouts (despite user inputs)
2. Non-functional workout execution (no timers, controls, or Live Activities)
3. Inconsistent exercise data (missing images, mixed language descriptions)

---

## Requirements Summary

### Epic 1: Dynamic Workout Generation (P0)
- Collect workout inputs (equipment, muscles, level, feeling) before generation
- Validate 60% minimum exercise variation from last 3 workouts
- Implement local fallback when OpenAI fails (timeout, rate limit, error)
- Add retry mechanism (max 2 attempts) with new seed on validation failure

### Epic 2: Workout Execution with Live Activities (P1)
- Navigation flow: Programs → Workout Preview → Execution
- Execution screen with exercise details, set tracking, rest timer
- Live Activity for Dynamic Island and Lock Screen
- Pause/resume controls, workout completion with rating
- CRITICAL: Compose with existing stores (WorkoutSessionStore, RestTimerStore, WorkoutTimerStore)

### Epic 3: Exercise Data Improvements (P1)
- Media priority: video > GIF > image > placeholder
- Muscle group-specific placeholders when no media
- Portuguese descriptions via Wger API (language=2)
- Fallback translation for English descriptions
- Sanitize HTML and filter Spanish content

---

## Existing Architecture Analysis

### Key Existing Components (DO NOT RECREATE)

**WorkoutSessionStore** (`/Presentation/Features/Workout/WorkoutSessionStore.swift`):
- @MainActor @Observable pattern
- Manages active workout session lifecycle
- Tracks exercise navigation (currentExerciseIndex, advanceToNextExercise)
- Set completion tracking (toggleSet, completeAllCurrentSets)
- Exercise substitution support
- Progress persistence for crash recovery (WorkoutProgress model)
- Computed properties: currentPrescription, currentExerciseProgress, effectiveCurrentExerciseName
- **Action**: COMPOSE with this store, do not duplicate navigation logic

**RestTimerStore** (`/Presentation/Features/Workout/RestTimerStore.swift`):
- @MainActor @Observable pattern
- Task-based timer (Task.sleep with 100ms precision)
- nonisolated(unsafe) timerTask for deinit cleanup
- Pause/resume/skip functionality
- Haptic feedback on completion (UINotificationFeedbackGenerator)
- Formatted time display, progress percentage
- **Action**: COMPOSE with this store, do not create new timer

**WorkoutTimerStore** (`/Presentation/Features/Workout/WorkoutTimerStore.swift`):
- @MainActor @Observable pattern
- Tracks total workout elapsed time (elapsedSeconds)
- Start/pause/toggle/reset actions
- Accumulates time across pause/resume cycles
- Formatted time display (HH:MM:SS or MM:SS)
- **Action**: COMPOSE with this store for workout duration tracking

**WorkoutPromptAssembler** (`/Data/Services/OpenAI/WorkoutPromptAssembler.swift`):
- Already includes variation seed (timestamp-based)
- 7-day workout history for diversity
- Cache key with historyHash
- Exercise prohibition list from previous workouts
- **Action**: Enhance with post-generation validation and retry mechanism

### Identified Gaps (NEW COMPONENTS NEEDED)

1. **WorkoutInputViewModel** - Collect user inputs before generation
2. **WorkoutVariationValidator** - Validate 60% exercise difference
3. **LocalWorkoutPlanComposer** - Fallback generator when OpenAI fails
4. **WorkoutExecutionViewModel** - Orchestrate execution using existing stores
5. **Live Activity Extension** - ActivityKit integration for Dynamic Island
6. **WorkoutLiveActivityManager** - @MainActor class for activity lifecycle
7. **ExerciseDescriptionService** - Portuguese descriptions with fallback
8. **WgerExerciseAdapter enhancements** - Media priority and placeholders

---

## Technical Constraints

### Swift 6.0 Concurrency Patterns
- Use @MainActor @Observable for ViewModels
- Use `actor` for isolated services (e.g., ExerciseDescriptionService)
- Use @MainActor class (NOT actor) for ActivityKit (Live Activity Manager)
- nonisolated(unsafe) for Task cleanup in deinit
- Sendable compliance for all data models

### Timer Implementation Pattern (FROM EXISTING CODE)
```swift
// Preferred pattern (from RestTimerStore.swift lines 119-127)
private func startTicking() {
    timerTask = Task { [weak self] in
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
            guard !Task.isCancelled else { break }
            await self?.tick()
        }
    }
}
```
- DO NOT use DispatchSourceTimer
- DO use Task.sleep for better concurrency integration
- DO cancel in deinit using nonisolated(unsafe)

### State Derivation Pattern (CRITICAL)
All state in WorkoutExecutionViewModel must be DERIVED from existing stores:
```swift
var currentExerciseIndex: Int { sessionStore.currentExerciseIndex }
var workoutElapsedTime: TimeInterval { TimeInterval(workoutTimer.elapsedSeconds) }
var isResting: Bool { restTimer.isActive }
var isPaused: Bool { !workoutTimer.isRunning }
```
- DO NOT duplicate state
- DO use computed properties
- DO derive from single source of truth (existing stores)

---

## Architectural Decisions

### Decision 1: Compose, Don't Recreate
**Rationale**: The codebase already has robust timer stores with proper concurrency patterns, haptic feedback, and persistence. Creating new implementations would:
- Duplicate logic and increase maintenance burden
- Risk introducing bugs in timer accuracy
- Lose existing crash recovery functionality
- Violate DRY principle

**Implementation**: WorkoutExecutionViewModel will compose with WorkoutSessionStore, RestTimerStore, and WorkoutTimerStore via dependency injection.

### Decision 2: Live Activity Manager as @MainActor Class
**Rationale**: ActivityKit's `Activity<T>` type is MainActor-isolated. Using `actor` would create isolation conflicts and compilation errors.

**Implementation**: WorkoutLiveActivityManager will be a @MainActor final class with async methods.

### Decision 3: Local Fallback Before Network Timeout
**Rationale**: 10-second OpenAI timeout is acceptable, but users should not wait for failure before seeing alternative.

**Implementation**:
- Trigger OpenAI request with 10s timeout
- If timeout or error: invoke local fallback immediately
- If success but validation fails: retry with new seed (max 2 times)
- After retries exhausted: use local fallback
- User notification when fallback is used

### Decision 4: Variation Validation Post-Generation
**Rationale**: Cannot guarantee variation without validating actual response. OpenAI may ignore prompts.

**Implementation**:
- WorkoutVariationValidator compares exercise names (case-insensitive)
- Checks last 3 workouts for overlap
- Requires 60% new exercises
- Used after OpenAI response AND in local fallback

---

## Risk Analysis

### High Risk: Live Activity Permission Denial
**Impact**: Core feature unavailable
**Mitigation**: Graceful degradation to in-app execution only. All timer functionality works without Live Activity.

### Medium Risk: OpenAI Rate Limiting
**Impact**: Users cannot generate personalized workouts
**Mitigation**: Local fallback generator using embedded WorkoutBlock catalog. Quality remains high.

### Medium Risk: Timer Drift in Background
**Impact**: Inaccurate rest timers when app backgrounded
**Mitigation**: Task-based timer pattern (already proven in RestTimerStore) maintains accuracy. Live Activity keeps UI in sync.

### Low Risk: Wger API Downtime
**Impact**: Missing exercise descriptions/images
**Mitigation**: In-memory cache, placeholder images, fallback to cached English descriptions.

---

## Success Criteria Validation

| Criterion | Validation Method | Target |
|-----------|-------------------|--------|
| 100% workout variation | Integration test with 10 sequential generations | Pass |
| Functional execution screen | Manual testing of all controls | Pass |
| Rest timer accuracy | Unit test with simulated 60s timer | ±1 second |
| Live Activity real-time updates | Manual test on physical device | Pass |
| Live Activity background persistence | Manual test with app backgrounded | Pass |
| 90%+ valid media | Integration test with Wger API | Pass |
| Portuguese descriptions | Unit test with mock API responses | Pass |
| 80% ViewModel coverage | XCTest with code coverage report | Pass |
| 70% UseCase coverage | XCTest with code coverage report | Pass |
| Zero build warnings | Xcode build log | Pass |

---

## Dependencies Mapping

### External APIs
- **OpenAI API v1**: Workout generation (fallback mitigates risk)
- **Wger API v2**: Exercise data (cache mitigates risk)
- **ActivityKit (iOS 17+)**: Live Activities (optional feature)

### Internal Dependencies
| New Component | Depends On (Existing) |
|---------------|----------------------|
| WorkoutExecutionViewModel | WorkoutSessionStore, RestTimerStore, WorkoutTimerStore |
| WorkoutLiveActivityManager | ActivityKit framework |
| LocalWorkoutPlanComposer | WorkoutBlock repository, WorkoutBlueprint |
| ExerciseDescriptionService | WgerAPIService, TranslationService (optional) |
| WgerExerciseAdapter | Existing exercise models |

---

## Testing Strategy

### Unit Tests (80% ViewModels, 70% UseCases)
- **WorkoutVariationValidator**: diversity calculation, edge cases (0%, 60%, 100% overlap)
- **LocalWorkoutPlanComposer**: exercise selection, equipment filtering, variation enforcement
- **WorkoutExecutionViewModel**: state transitions, set completion, exercise navigation
- **WorkoutLiveActivityManager**: start/update/end lifecycle with spy
- **ExerciseDescriptionService**: Portuguese fetch, English fallback, cache hits

### Integration Tests
- Full workout generation with validation and retries
- Workout execution from start to completion (no UITests)
- Live Activity lifecycle with mock ActivityKit
- Crash recovery with persisted progress
- Timer accuracy over 60 seconds

### Test Doubles Pattern
```swift
// For @MainActor classes
@MainActor
final class SpyLiveActivityManager {
    private(set) var startActivityCalled = false
    private(set) var lastUpdateState: WorkoutActivityAttributes.ContentState?

    func startActivity(workoutName: String, totalExercises: Int) async throws -> String {
        startActivityCalled = true
        return "test-activity-id"
    }
}
```

---

## Known Issues & Constraints

### Issue 1: UITests Explicitly Out of Scope
**Per CLAUDE.md**: "DO NOT write UITests during scaffolding phase"
**Mitigation**: Manual testing on physical device for Live Activity, comprehensive unit/integration tests for logic.

### Issue 2: Physical Device Required for Live Activity Testing
**Constraint**: Simulators may not fully support Dynamic Island
**Mitigation**: Test Live Activity manager with spy in unit tests, defer real-device testing to Phase 3.

### Issue 3: SwiftUI Navigation Pattern Migration
**Current State**: May use deprecated NavigationView
**Action**: Use Router Navigation Pattern per CLAUDE.md guidelines.

---

## File Structure Plan

```
FitToday/
├── Domain/
│   ├── Entities/
│   │   └── WorkoutExecutionModels.swift [NEW]
│   ├── UseCases/
│   │   └── WorkoutVariationValidator.swift [NEW]
│   └── Protocols/
│       ├── LocalWorkoutPlanComposer.swift [NEW]
│       └── ExerciseDescriptionServicing.swift [NEW]
│
├── Data/
│   ├── Services/
│   │   ├── OpenAI/
│   │   │   ├── WorkoutPromptAssembler.swift [ENHANCE]
│   │   │   └── LocalWorkoutPlanComposer.swift [NEW]
│   │   ├── Wger/
│   │   │   └── WgerExerciseAdapter.swift [ENHANCE]
│   │   └── Translation/
│   │       └── ExerciseDescriptionService.swift [NEW]
│
├── Presentation/
│   └── Features/
│       └── Workout/
│           ├── ViewModels/
│           │   ├── WorkoutInputViewModel.swift [NEW]
│           │   └── WorkoutExecutionViewModel.swift [NEW]
│           ├── Views/
│           │   ├── WorkoutInputView.swift [NEW]
│           │   ├── WorkoutPreviewView.swift [NEW]
│           │   ├── WorkoutExecutionView.swift [NEW]
│           │   └── WorkoutCompletionView.swift [ENHANCE]
│           ├── Components/
│           │   ├── ExerciseExecutionCard.swift [NEW]
│           │   └── ExerciseMediaView.swift [NEW]
│           └── WorkoutLiveActivityManager.swift [NEW]
│
└── FitTodayLiveActivity/ [NEW EXTENSION TARGET]
    ├── WorkoutActivityAttributes.swift
    ├── WorkoutLiveActivity.swift
    └── FitTodayLiveActivityBundle.swift
```

---

## Complexity Assessment

### High Complexity Tasks (Size: L)
- **Task 3.0**: OpenAI enhancement (retry mechanism, validation, fallback integration)
- **Task 6.0**: WorkoutExecutionViewModel (composition with 3 stores, Live Activity coordination)
- **Task 8.0**: Workout execution views (media display, timer overlays, set tracking UI)

### Medium Complexity Tasks (Size: M)
- **Task 0.0**: Workout input collection (multi-select pickers, profile integration)
- **Task 2.0**: Local fallback composer (exercise selection algorithm, variation enforcement)
- **Task 5.0**: Portuguese description service (API integration, translation fallback, HTML sanitization)
- **Task 7.0**: Navigation flow (Router pattern, preview screens)
- **Task 9.0**: Live Activity extension setup (new target, entitlements, Dynamic Island UI)
- **Task 10.0**: Live Activity manager (ActivityKit lifecycle, permission handling)
- **Task 11.0**: Live Activity integration (state derivation, update frequency optimization)

### Small Complexity Tasks (Size: S)
- **Task 1.0**: Variation validator (algorithm implementation, unit tests)
- **Task 4.0**: Exercise media resolution (priority logic, placeholder mapping)
- **Task 12.0**: Workout completion enhancements (UI updates, rating integration)
- **Task 13.0**: Integration tests (test orchestration)

---

## Implementation Phases

### Phase 1: Core Generation (Tasks 0.0-3.0) - P0
**Goal**: Ensure workouts are always different and never fail to generate
**Deliverables**:
- Workout input collection UI
- Variation validator with 60% threshold
- Local fallback generator
- Enhanced OpenAI composer with retry

### Phase 2A: Data Layer (Tasks 4.0-5.0) - P1
**Goal**: Improve exercise data quality
**Deliverables**:
- Media resolution with placeholders
- Portuguese description service

### Phase 2B: Execution Foundation (Tasks 6.0-8.0) - P1
**Goal**: Functional workout execution
**Deliverables**:
- WorkoutExecutionViewModel composing with existing stores
- Navigation flow from programs to execution
- Execution views with timers and controls

### Phase 3: Live Activity (Tasks 9.0-11.0) - P1
**Goal**: Background workout tracking
**Deliverables**:
- Live Activity extension target
- Live Activity manager
- Integration with execution ViewModel

### Phase 4: Polish (Tasks 12.0-13.0) - P2
**Goal**: Production-ready quality
**Deliverables**:
- Enhanced completion screen
- Comprehensive integration tests

---

**Analysis Complete**
