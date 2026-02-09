# Technical Specification

**Project Name:** Workout Experience Overhaul
**Version:** 1.0
**Date:** 2026-02-09
**Author:** Engineering Team
**Status:** Draft

---

## Overview

### Problem Statement
FitToday has three critical issues affecting user experience: (1) AI-generated workouts are repetitive despite user inputs, (2) workout execution is only demonstrative without functional timers, controls, or Live Activities, and (3) exercises display missing images and inconsistent descriptions (mixed languages).

### Proposed Solution
Enhance the existing OpenAI workout generation pipeline with stronger variation guarantees, implement a fully functional workout execution flow with Live Activities following the Hevy app pattern, and improve Wger exercise data consistency.

### Goals
- 100% workout variation in sequential generations
- Functional Live Activity with pause/play/next controls
- 90%+ exercises with valid images or appropriate placeholders

---

## Scope

### In Scope
- Enhancement of `WorkoutPromptAssembler` for improved variation
- Local fallback workout generation
- Workout execution screen with timers and controls
- Rest timer with haptic/sound feedback
- Live Activity implementation for iOS 17+
- Workout completion screen with rating
- Exercise image/placeholder improvements
- Portuguese language consistency for descriptions

### Out of Scope
- Apple Watch companion app
- Widgets for next workout
- Detailed weight/reps registration (only completion checkbox)
- HealthKit timer synchronization (only completed workout sync)
- macOS support
- UITests (per CLAUDE.md guidelines)

---

## Architecture Overview

### Existing Architecture
The project uses Clean Architecture with three layers:
- **Domain**: Entities, Protocols, UseCases (pure Swift)
- **Data**: Repositories, Services, Mappers (external integrations)
- **Presentation**: Features, Views, ViewModels (SwiftUI + @Observable)

### Key Components Affected

```
FitToday/
├── Domain/
│   ├── Entities/
│   │   ├── WorkoutExecutionModels.swift  [ENHANCE]
│   │   └── LiveActivityModels.swift      [NEW]
│   ├── UseCases/
│   │   ├── WorkoutPlanUseCases.swift     [ENHANCE]
│   │   └── WorkoutExecutionUseCases.swift [NEW]
│   └── Protocols/
│       └── WorkoutHistoryRepository.swift [EXISTS]
│
├── Data/
│   ├── Services/
│   │   ├── OpenAI/
│   │   │   ├── WorkoutPromptAssembler.swift    [ENHANCE]
│   │   │   └── LocalWorkoutPlanComposer.swift  [ENHANCE]
│   │   └── Wger/
│   │       └── WgerExerciseAdapter.swift       [ENHANCE]
│   └── Repositories/
│       └── SwiftDataWorkoutHistoryRepository.swift [EXISTS]
│
├── Presentation/
│   └── Features/
│       └── Workout/
│           ├── Views/
│           │   ├── WorkoutExecutionView.swift       [NEW]
│           │   ├── RestTimerView.swift              [NEW]
│           │   ├── WorkoutCompletionView.swift      [ENHANCE]
│           │   └── ExerciseExecutionCard.swift      [NEW]
│           ├── ViewModels/
│           │   ├── WorkoutExecutionViewModel.swift  [NEW]
│           │   └── RestTimerViewModel.swift         [NEW]
│           └── Components/
│               └── ExerciseMediaView.swift          [NEW]
│
└── LiveActivity/                                    [NEW EXTENSION TARGET]
    ├── WorkoutLiveActivity.swift
    ├── WorkoutActivityAttributes.swift
    └── WorkoutActivityConfiguration.swift
```

---

## Technical Approach

### Epic 1: Dynamic Workout Generation

#### Component: WorkoutPromptAssembler Enhancement

**Current State**: `WorkoutPromptAssembler.swift` already includes:
- 7-day workout history for diversity
- Variation seed (timestamp-based)
- History hash for cache invalidation
- Exercise prohibition list

**Enhancements Required**:
1. Add post-generation validation for 60% minimum exercise difference
2. Implement retry mechanism with modified seed
3. Add explicit "MUST NOT repeat" instruction emphasis

**File**: `FitToday/Data/Services/OpenAI/WorkoutPromptAssembler.swift`

```swift
// Add to WorkoutPromptAssembler
struct WorkoutVariationValidator: Sendable {
    static func validateDiversity(
        generated: OpenAIWorkoutResponse,
        previousWorkouts: [WorkoutPlan],
        minimumDiversityPercent: Double = 0.6
    ) -> Bool {
        let previousExercises = Set(
            previousWorkouts.prefix(3)
                .flatMap { $0.exercises }
                .map { $0.exercise.name.lowercased() }
        )

        let generatedExercises = generated.phases
            .compactMap { $0.exercises }
            .flatMap { $0 }
            .map { $0.name.lowercased() }

        guard !generatedExercises.isEmpty else { return false }

        let newExercises = generatedExercises.filter { !previousExercises.contains($0) }
        let diversityRatio = Double(newExercises.count) / Double(generatedExercises.count)

        return diversityRatio >= minimumDiversityPercent
    }
}
```

#### Component: Local Fallback Generator

**File**: `FitToday/Data/Services/OpenAI/LocalWorkoutPlanComposer.swift`

**Requirements**:
- Respect same user inputs (equipment, focus, level, energy)
- Use embedded exercise catalog from `WorkoutBlock` repository
- Enforce variation using same prohibition logic
- Return `WorkoutPlan` directly (no network dependency)

```swift
protocol LocalWorkoutPlanComposing: Sendable {
    func compose(
        blueprint: WorkoutBlueprint,
        availableBlocks: [WorkoutBlock],
        previousWorkouts: [WorkoutPlan],
        profile: UserProfile,
        checkIn: DailyCheckIn
    ) async -> WorkoutPlan
}
```

---

### Epic 2: Workout Execution with Live Activities

#### Component: WorkoutExecutionViewModel

**File**: `FitToday/Presentation/Features/Workout/ViewModels/WorkoutExecutionViewModel.swift`

**Responsibilities**:
- Compose with existing stores (WorkoutSessionStore, WorkoutTimerStore, RestTimerStore)
- Manage workout state through delegation to specialized stores
- Coordinate Live Activity updates
- Persist progress for crash recovery

**IMPORTANT**: The codebase already has `RestTimerStore` and `WorkoutTimerStore` that handle timer logic. This ViewModel should COMPOSE with them, not duplicate their functionality.

```swift
@MainActor
@Observable final class WorkoutExecutionViewModel {
    // Dependencies (composed, not owned) - reuse existing stores
    private let sessionStore: WorkoutSessionStore
    private let workoutTimer: WorkoutTimerStore  // Existing in codebase
    private let restTimer: RestTimerStore        // Existing in codebase
    private let liveActivityManager: WorkoutLiveActivityManager

    // For Task cleanup in deinit (Swift 6 pattern)
    private nonisolated(unsafe) var liveActivityTask: Task<Void, Never>?

    // Computed state (derived from stores - single source of truth)
    var currentExerciseIndex: Int { sessionStore.currentExerciseIndex }
    var workoutElapsedTime: TimeInterval { TimeInterval(workoutTimer.elapsedSeconds) }
    var isResting: Bool { restTimer.isActive }
    var isPaused: Bool { !workoutTimer.isRunning }

    init(
        sessionStore: WorkoutSessionStore,
        workoutTimer: WorkoutTimerStore,
        restTimer: RestTimerStore,
        liveActivityManager: WorkoutLiveActivityManager
    ) {
        self.sessionStore = sessionStore
        self.workoutTimer = workoutTimer
        self.restTimer = restTimer
        self.liveActivityManager = liveActivityManager
    }

    deinit {
        liveActivityTask?.cancel()
    }

    // Actions
    func startWorkout(plan: WorkoutPlan) async throws
    func completeSet() -> Bool  // Returns true if exercise complete
    func skipExercise() -> Bool  // Returns true if was last exercise
    func nextExercise() -> Bool  // Returns true if was last exercise
    func togglePause()
    func startRestTimer(duration: TimeInterval)
    func skipRest()
    func finishWorkout() async throws
}
```

#### Component: RestTimerStore (EXISTING)

**NOTE**: `RestTimerStore` already exists at `FitToday/Presentation/Features/Workout/RestTimerStore.swift`. DO NOT create a new RestTimerViewModel. The existing implementation includes:
- @MainActor + @Observable pattern
- Haptic feedback (UINotificationFeedbackGenerator)
- Pause/resume/skip functionality
- Task-based timer with proper cancellation
- nonisolated(unsafe) for timerTask cleanup

**Rest Timer Presets**:
- Light exercises: 60s
- Moderate exercises: 90s
- Heavy/compound exercises: 120s

#### Component: Live Activity Implementation

**Extension Target**: `FitTodayLiveActivity`

**Files**:
```
LiveActivity/
├── WorkoutActivityAttributes.swift
├── WorkoutLiveActivity.swift
└── WorkoutActivityConfiguration.swift
```

**Attributes Model**:
```swift
struct WorkoutActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var currentExerciseName: String
        var currentSet: Int
        var totalSets: Int
        var restTimeRemaining: TimeInterval?
        var workoutElapsedTime: TimeInterval
        var isPaused: Bool
    }

    var workoutName: String
    var totalExercises: Int
}
```

**Live Activity Manager**:

**CRITICAL**: Use `@MainActor` class, NOT `actor`. ActivityKit's `Activity<T>` type is MainActor-bound.

```swift
import ActivityKit

@MainActor
final class WorkoutLiveActivityManager {
    private var currentActivity: Activity<WorkoutActivityAttributes>?

    func startActivity(
        workoutName: String,
        totalExercises: Int
    ) async throws -> String {
        // Check if Live Activities are supported
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            throw WorkoutExecutionError.liveActivityNotSupported
        }

        let attributes = WorkoutActivityAttributes(
            workoutName: workoutName,
            totalExercises: totalExercises
        )

        let initialState = WorkoutActivityAttributes.ContentState(
            currentExerciseName: "",
            currentSet: 0,
            totalSets: 0,
            restTimeRemaining: nil,
            workoutElapsedTime: 0,
            isPaused: false
        )

        do {
            let activity = try Activity<WorkoutActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            currentActivity = activity
            return activity.id
        } catch {
            throw WorkoutExecutionError.liveActivityStartFailed(underlying: error)
        }
    }

    func updateActivity(state: WorkoutActivityAttributes.ContentState) async {
        guard let activity = currentActivity else { return }
        let content = ActivityContent(state: state, staleDate: nil)
        await activity.update(content)
    }

    func endActivity(dismissalPolicy: ActivityUIDismissalPolicy) async {
        guard let activity = currentActivity else { return }
        await activity.end(
            ActivityContent(state: activity.content.state, staleDate: nil),
            dismissalPolicy: dismissalPolicy
        )
        currentActivity = nil
    }
}
```

**Live Activity State Derivation** (in WorkoutExecutionViewModel):
```swift
// Computed property - single source of truth, no duplication
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

**UI Components** (Dynamic Island + Lock Screen):
- Compact: Exercise name + set counter
- Minimal: Timer only
- Expanded: Full controls with pause/play/next

---

### Epic 3: Exercise Data Improvements

#### Component: Exercise Image Resolution

**File**: `FitToday/Data/Services/Wger/WgerExerciseAdapter.swift`

**Enhancements**:
1. Priority order: Video > GIF > Image > Placeholder
2. Muscle group-specific placeholders
3. Local image cache with fallback

```swift
extension WgerExerciseAdapter {
    static func resolveMedia(
        from images: [WgerExerciseImage],
        videos: [WgerExerciseVideo]? = nil,
        muscleGroup: MuscleGroup
    ) -> ExerciseMedia {
        // Priority: video > gif > image > placeholder
        if let video = videos?.first {
            return ExerciseMedia(videoURL: video.url, source: "Wger")
        }

        if let mainImage = images.first(where: { $0.isMain }) ?? images.first {
            return ExerciseMedia(imageURL: mainImage.imageURL, source: "Wger")
        }

        // Fallback to muscle group placeholder
        return ExerciseMedia(
            imageURL: nil,
            placeholderName: muscleGroup.placeholderImageName,
            source: "Placeholder"
        )
    }
}
```

#### Component: Portuguese Description Service

**File**: `FitToday/Data/Services/Translation/ExerciseDescriptionService.swift`

```swift
protocol ExerciseDescriptionServicing: Sendable {
    func getPortugueseDescription(
        for exerciseId: String,
        fallbackEnglish: String?
    ) async -> String?
}

actor ExerciseDescriptionService: ExerciseDescriptionServicing {
    private let wgerAPI: WgerAPIService
    private let translationService: TranslationServiceProtocol?
    private var cache: [String: String] = [:]

    func getPortugueseDescription(
        for exerciseId: String,
        fallbackEnglish: String?
    ) async -> String? {
        // 1. Check cache
        // 2. Fetch from Wger API (language=2 for Portuguese)
        // 3. If unavailable, translate English description
        // 4. Sanitize HTML, remove Spanish content
        // 5. Cache result
    }
}
```

---

## Data Models

### WorkoutExecutionProgress

```swift
struct WorkoutExecutionProgress: Codable, Sendable {
    let workoutId: UUID
    let startedAt: Date
    var currentExerciseIndex: Int
    var currentSetIndex: Int
    var completedSets: [CompletedSetRecord]
    var elapsedTime: TimeInterval
    var lastUpdated: Date

    struct CompletedSetRecord: Codable, Sendable {
        let exerciseIndex: Int
        let setIndex: Int
        let completedAt: Date
    }
}
```

### ExerciseMedia Enhancement

```swift
struct ExerciseMedia: Codable, Sendable, Hashable {
    let imageURL: URL?
    let gifURL: URL?
    let videoURL: URL?
    let placeholderName: String?
    let source: String

    var hasValidMedia: Bool {
        videoURL != nil || gifURL != nil || imageURL != nil
    }

    var displayURL: URL? {
        videoURL ?? gifURL ?? imageURL
    }
}
```

---

## Implementation Considerations

### Design Patterns
- **MVVM**: ViewModels use `@Observable` for state management
- **Repository Pattern**: Data access abstracted through protocols
- **Use Cases**: Business logic encapsulated in domain layer
- **Dependency Injection**: Swinject for service resolution

### Error Handling

```swift
enum WorkoutExecutionError: LocalizedError {
    case sessionNotStarted
    case noExercisesAvailable
    case liveActivityNotSupported
    case liveActivityStartFailed(underlying: Error)
    case timerError(message: String)

    var errorDescription: String? {
        switch self {
        case .sessionNotStarted:
            return "Nenhuma sessão de treino ativa"
        case .noExercisesAvailable:
            return "Nenhum exercício disponível no treino"
        case .liveActivityNotSupported:
            return "Live Activity não suportado neste dispositivo"
        case .liveActivityStartFailed(let error):
            return "Falha ao iniciar Live Activity: \(error.localizedDescription)"
        case .timerError(let message):
            return "Erro no timer: \(message)"
        }
    }
}
```

### Background Timer Handling

**NOTE**: Use existing Task-based timer pattern from RestTimerStore/WorkoutTimerStore. DO NOT use DispatchSourceTimer.

```swift
// Existing pattern from RestTimerStore.swift (lines 119-127)
// This is the preferred approach for Swift 6 concurrency
private func startTicking() {
    timerTask = Task { [weak self] in
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms for precision
            guard !Task.isCancelled else { break }
            await self?.tick()
        }
    }
}
```

**Why Task.sleep over DispatchSourceTimer**:
1. Better Swift 6 concurrency integration
2. Automatic cancellation with Task lifecycle
3. Simpler to test and mock
4. Already proven working in the codebase
5. No need for GCD interop

---

## Testing Strategy

### Unit Testing
**Coverage Target**: 80% for ViewModels, 70% for UseCases

**Focus Areas**:
- `WorkoutVariationValidator` diversity calculation
- `LocalWorkoutPlanComposer` exercise selection
- `WorkoutExecutionViewModel` state transitions
- `RestTimerViewModel` timer accuracy
- `WorkoutLiveActivityManager` state updates

### Integration Testing

**Scenarios**:
1. Full workout generation flow with variation validation
2. Workout execution from start to completion
3. Rest timer with haptic/sound feedback
4. Live Activity lifecycle (start, update, end)
5. Crash recovery and session restoration

### Test Doubles

**NOTE**: For @MainActor classes, test doubles should also be @MainActor classes.

```swift
// Mock for OpenAI responses
@MainActor
final class MockOpenAIClient: OpenAIClientProtocol {
    var stubbedResponse: OpenAIWorkoutResponse?
    var shouldFail = false
}

// Spy for Live Activity (matches @MainActor pattern)
@MainActor
final class SpyLiveActivityManager {
    private(set) var startActivityCalled = false
    private(set) var lastUpdateState: WorkoutActivityAttributes.ContentState?
    private(set) var endActivityCalled = false
    private(set) var startActivityCallCount = 0
    var startActivityError: Error?

    func startActivity(workoutName: String, totalExercises: Int) async throws -> String {
        startActivityCalled = true
        startActivityCallCount += 1
        if let error = startActivityError {
            throw error
        }
        return "test-activity-id"
    }

    func updateActivity(state: WorkoutActivityAttributes.ContentState) async {
        lastUpdateState = state
    }

    func endActivity(dismissalPolicy: ActivityUIDismissalPolicy) async {
        endActivityCalled = true
    }
}

// Stub for RestTimerStore (existing pattern)
@MainActor
final class StubRestTimerStore: RestTimerStore {
    override func start(duration: TimeInterval) {
        // Override for testing
    }
    func simulateTick(remaining: Int) {
        // Direct state manipulation for tests
    }
    func simulateComplete() {
        // Trigger completion
    }
}
```

---

## Dependencies

### External Dependencies
| Dependency | Version | Purpose | Risk |
|------------|---------|---------|------|
| OpenAI API | v1 | Workout generation | Medium - fallback mitigates |
| Wger API | v2 | Exercise data | Low - cache mitigates |
| ActivityKit | iOS 17+ | Live Activities | Low - built-in |
| AVFoundation | Built-in | Timer sounds | None |

### Internal Dependencies
- `WorkoutSessionStore` - Existing session management
- `WorkoutPromptAssembler` - Existing prompt building
- `WgerExerciseAdapter` - Existing exercise conversion
- `TranslationService` - Existing translation (optional)

---

## Assumptions and Constraints

### Assumptions
1. Users grant Live Activity permission when prompted
2. OpenAI API maintains current response format
3. Wger API continues providing Portuguese content (language=2)
4. iOS 17+ deployment target is acceptable

### Constraints
1. Swift 6.0 strict concurrency required
2. SwiftUI only (no UIKit unless necessary)
3. MVVM with @Observable pattern
4. No UITests during scaffolding (per CLAUDE.md)
5. Minimum 70% code coverage for business logic

---

## Risks and Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| OpenAI rate limiting | High | Medium | Local fallback generator |
| Live Activity permission denied | Medium | Low | Graceful degradation to in-app only |
| Wger API downtime | Medium | Low | Local exercise cache |
| Timer drift in background | Medium | Medium | DispatchSourceTimer with high priority |
| Cache key collisions | Low | Low | SHA256 hashing with multiple factors |

---

## Success Criteria

- [ ] 100% sequential workout variation (tested with 10 consecutive generations)
- [ ] Workout execution screen functional with all controls
- [ ] Rest timer accurate to ±1 second
- [ ] Live Activity updates in real-time on Lock Screen
- [ ] Live Activity persists when app goes to background
- [ ] 90%+ exercises display valid media or appropriate placeholder
- [ ] All descriptions in Portuguese (no Spanish/English mix)
- [ ] 80% unit test coverage on ViewModels
- [ ] 70% unit test coverage on UseCases
- [ ] Build succeeds with zero warnings
- [ ] All tests passing

---

## Glossary

| Term | Definition |
|------|------------|
| Live Activity | iOS 16.1+ feature for real-time Lock Screen/Dynamic Island updates |
| Dynamic Island | Interactive pill-shaped area at top of Face ID iPhones |
| WorkoutBlueprint | Deterministic template for workout structure |
| WorkoutBlock | Collection of exercises grouped by movement pattern |
| Variation Seed | Timestamp-based seed for deterministic randomization |
| DOMS | Delayed Onset Muscle Soreness - muscle soreness after exercise |

---

**Document End**
