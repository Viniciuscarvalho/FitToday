# Implementation Plan: Workout Experience Overhaul

**Feature:** prd-workout-experience-overhaul
**Date:** 2026-02-09
**Status:** Ready for Implementation

---

## Execution Strategy

### Approach
- Follow task order defined in tasks.md (14 tasks across 4 phases)
- Use TodoWrite for granular task tracking
- Update checkpoint after each major task completion
- Compose with existing stores (DO NOT recreate)
- Apply Swift 6.0 patterns consistently

### Quality Gates
- All new code must compile without warnings
- Unit tests required for each ViewModel/UseCase
- Integration tests at phase boundaries
- Manual testing for Live Activity on physical device (deferred to Phase 3)

---

## Phase 1: Core Generation (P0)

### Task 0.0: Workout Input Collection Screen [M]
**Objective**: Create UI for collecting workout generation inputs

**Files to Create**:
- `FitToday/Presentation/Features/Workout/ViewModels/WorkoutInputViewModel.swift`
- `FitToday/Presentation/Features/Workout/Views/WorkoutInputView.swift`
- `FitTodayTests/Presentation/Features/Workout/WorkoutInputViewModelTests.swift`

**Implementation Steps**:
1. Create WorkoutInputViewModel with @MainActor @Observable
2. Add properties: selectedMuscles, energyLevel, availableEquipment (from profile)
3. Create WorkoutInputView with muscle group multi-select picker
4. Add energy level selection (tired/normal/energized)
5. Load equipment from UserProfile.availableStructure
6. Wire to DailyCheckIn model
7. Write unit tests for input validation

**Dependencies**: DailyCheckIn (existing), UserProfile (existing)

**Success Criteria**:
- All inputs collected before generation
- Inputs passed to WorkoutPromptAssembler
- Tests cover validation logic

---

### Task 1.0: Workout Variation Validator [S]
**Objective**: Ensure generated workouts differ by 60% from last 3 workouts

**Files to Create**:
- `FitToday/Domain/UseCases/WorkoutVariationValidator.swift`
- `FitTodayTests/Domain/UseCases/WorkoutVariationValidatorTests.swift`

**Implementation Steps**:
1. Create WorkoutVariationValidator struct in Domain/UseCases/
2. Implement validateDiversity method with 60% threshold
3. Compare exercise names (case-insensitive)
4. Write unit tests: empty workouts, 0%, 60%, 100% overlap, boundary cases

**Algorithm**:
```swift
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

**Success Criteria**:
- Validator correctly identifies diversity threshold failures
- 80% test coverage minimum

---

### Task 2.0: Local Fallback Workout Composer [M]
**Objective**: Generate workouts locally when OpenAI fails

**Files to Create**:
- `FitToday/Domain/Protocols/LocalWorkoutPlanComposer.swift`
- `FitToday/Data/Services/Workout/LocalWorkoutPlanComposer.swift`
- `FitTodayTests/Data/Services/Workout/LocalWorkoutPlanComposerTests.swift`

**Implementation Steps**:
1. Create LocalWorkoutPlanComposing protocol
2. Implement DefaultLocalWorkoutPlanComposer
3. Use WorkoutBlueprint for structure
4. Select exercises from WorkoutBlock repository filtered by equipment
5. Apply WorkoutVariationValidator for variation
6. Write unit tests with mock blocks

**Protocol**:
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

**Dependencies**: Task 1.0 (WorkoutVariationValidator)

**Success Criteria**:
- Generates valid WorkoutPlan in <2 seconds
- Respects equipment constraints
- Enforces variation from previous workouts
- 70% test coverage

---

### Task 3.0: OpenAI Generation Enhancement [L]
**Objective**: Add post-generation validation and retry mechanism

**Files to Modify**:
- `FitToday/Data/Services/OpenAI/OpenAIWorkoutPlanComposer.swift`
- `FitToday/Data/Services/OpenAI/WorkoutPromptAssembler.swift`
- `FitTodayTests/Data/Services/OpenAI/OpenAIWorkoutPlanComposerTests.swift`

**Implementation Steps**:
1. Add WorkoutVariationValidator call after generation
2. Implement retry mechanism with modified seed (max 2 retries)
3. Integrate local fallback when retries exhausted
4. Add user notification flag for fallback usage
5. Update tests for new flow
6. Add timeout handling (10s max)
7. Test edge cases: network failure, rate limit, invalid response

**Retry Logic**:
```swift
func generateWithValidation(inputs: WorkoutInputs) async throws -> WorkoutPlan {
    let maxRetries = 2
    var attempt = 0

    while attempt < maxRetries {
        do {
            // Call OpenAI with timeout
            let response = try await callOpenAI(inputs, seed: generateSeed())

            // Validate diversity
            if WorkoutVariationValidator.validateDiversity(
                generated: response,
                previousWorkouts: inputs.previousWorkouts
            ) {
                return mapToWorkoutPlan(response)
            }

            // Validation failed, retry with new seed
            attempt += 1
        } catch {
            // Network/timeout error, skip to fallback
            break
        }
    }

    // All retries exhausted or error occurred
    return await localFallback.compose(...)
}
```

**Dependencies**: Task 1.0, Task 2.0

**Success Criteria**:
- Post-generation validation runs automatically
- Failed validation triggers retry
- After 2 retries, local fallback used
- User notified when fallback used
- Tests cover all retry paths

---

## Phase 2A: Data Layer (P1)

### Task 4.0: Exercise Media Resolution [S]
**Objective**: Improve media resolution with priority and placeholders

**Files to Modify**:
- `FitToday/Data/Services/Wger/WgerExerciseAdapter.swift`
- `FitToday/Domain/Entities/WorkoutModels.swift`
- `FitTodayTests/Data/Services/Wger/WgerExerciseAdapterTests.swift`

**Implementation Steps**:
1. Enhance resolveMedia method
2. Implement priority: video > GIF > image > placeholder
3. Create muscle group placeholder images (or reference existing)
4. Update ExerciseMedia model with placeholder support
5. Write tests for media resolution priority

**Media Resolution**:
```swift
extension WgerExerciseAdapter {
    static func resolveMedia(
        from images: [WgerExerciseImage],
        videos: [WgerExerciseVideo]? = nil,
        muscleGroup: MuscleGroup
    ) -> ExerciseMedia {
        if let video = videos?.first {
            return ExerciseMedia(videoURL: video.url, source: "Wger")
        }

        if let mainImage = images.first(where: { $0.isMain }) ?? images.first {
            return ExerciseMedia(imageURL: mainImage.imageURL, source: "Wger")
        }

        return ExerciseMedia(
            imageURL: nil,
            placeholderName: muscleGroup.placeholderImageName,
            source: "Placeholder"
        )
    }
}
```

**Success Criteria**:
- Video prioritized when available
- Placeholder displayed when no media exists
- Placeholder matches muscle group
- Tests verify priority order

---

### Task 5.0: Portuguese Description Service [M]
**Objective**: Ensure Portuguese descriptions with translation fallback

**Files to Create**:
- `FitToday/Domain/Protocols/ExerciseDescriptionServicing.swift`
- `FitToday/Data/Services/Translation/ExerciseDescriptionService.swift`
- `FitTodayTests/Data/Services/Translation/ExerciseDescriptionServiceTests.swift`

**Implementation Steps**:
1. Create ExerciseDescriptionServicing protocol
2. Implement ExerciseDescriptionService actor
3. Fetch Portuguese description from Wger (language=2)
4. Implement fallback to English translation
5. Sanitize HTML and remove Spanish content
6. Add in-memory cache for descriptions
7. Write tests for caching and fallback

**Service Pattern**:
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
        if let cached = cache[exerciseId] {
            return cached
        }

        // 2. Fetch from Wger API (language=2)
        if let ptDescription = try? await wgerAPI.fetchDescription(exerciseId, language: 2) {
            let sanitized = sanitize(ptDescription)
            cache[exerciseId] = sanitized
            return sanitized
        }

        // 3. Translate English fallback
        if let english = fallbackEnglish,
           let translated = await translationService?.translate(english, to: "pt") {
            cache[exerciseId] = translated
            return translated
        }

        return nil
    }

    private func sanitize(_ html: String) -> String {
        // Remove HTML tags, replace entities, filter Spanish
        var text = html
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")

        // Filter Spanish patterns (basic heuristic)
        let spanishPatterns = ["ejercicio", "músculo", "entrenamiento"]
        // If text contains many Spanish words, mark as untrusted

        return text
    }
}
```

**Success Criteria**:
- Portuguese descriptions fetched when available
- English descriptions translated as fallback
- No Spanish content in output
- Cache improves performance
- Tests cover all scenarios

---

## Phase 2B: Execution Foundation (P1)

### Task 6.0: Workout Execution ViewModel [L]
**Objective**: Orchestrate execution by composing with existing stores

**Files to Create**:
- `FitToday/Presentation/Features/Workout/ViewModels/WorkoutExecutionViewModel.swift`
- `FitTodayTests/Presentation/Features/Workout/WorkoutExecutionViewModelTests.swift`

**Files to Reference (Existing)**:
- `FitToday/Presentation/Features/Workout/WorkoutSessionStore.swift`
- `FitToday/Presentation/Features/Workout/RestTimerStore.swift`
- `FitToday/Presentation/Features/Workout/WorkoutTimerStore.swift`

**Implementation Steps**:
1. Create WorkoutExecutionViewModel with @MainActor @Observable
2. Inject WorkoutSessionStore, RestTimerStore, WorkoutTimerStore
3. Derive state via computed properties (DO NOT duplicate)
4. Implement exercise navigation via sessionStore delegation
5. Implement set completion tracking via sessionStore
6. Wire rest timer start on set completion
7. Implement pause/resume via workoutTimer
8. Add crash recovery persistence (use existing WorkoutProgress)
9. Add nonisolated(unsafe) for Task cleanup in deinit
10. Write comprehensive unit tests

**State Derivation (CRITICAL)**:
```swift
@MainActor
@Observable final class WorkoutExecutionViewModel {
    // Dependencies (composed, not owned)
    private let sessionStore: WorkoutSessionStore
    private let workoutTimer: WorkoutTimerStore
    private let restTimer: RestTimerStore
    private let liveActivityManager: WorkoutLiveActivityManager

    private nonisolated(unsafe) var liveActivityTask: Task<Void, Never>?

    // DERIVED state (computed properties only)
    var currentExerciseIndex: Int { sessionStore.currentExerciseIndex }
    var currentPrescription: ExercisePrescription? { sessionStore.currentPrescription }
    var currentExerciseProgress: ExerciseProgress? { sessionStore.currentExerciseProgress }
    var workoutElapsedTime: TimeInterval { TimeInterval(workoutTimer.elapsedSeconds) }
    var isResting: Bool { restTimer.isActive }
    var isPaused: Bool { !workoutTimer.isRunning }
    var formattedWorkoutTime: String { workoutTimer.formattedTime }
    var formattedRestTime: String { restTimer.formattedTime }
    var restProgress: Double { restTimer.progressPercentage }

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

    // Actions (delegate to stores)
    func startWorkout(plan: WorkoutPlan) async throws {
        sessionStore.start(with: plan)
        workoutTimer.start()
        try await startLiveActivity(plan: plan)
    }

    func completeSet(at index: Int) {
        sessionStore.toggleCurrentExerciseSet(at: index)

        // Start rest timer if not last set
        if !sessionStore.isCurrentExerciseComplete {
            let restDuration = determineRestDuration()
            restTimer.start(duration: restDuration)
        }

        Task { await updateLiveActivity() }
    }

    func nextExercise() -> Bool {
        let isLast = sessionStore.advanceToNextExercise()
        restTimer.stop()
        Task { await updateLiveActivity() }
        return isLast
    }

    func skipExercise() -> Bool {
        let isLast = sessionStore.skipCurrentExercise()
        restTimer.stop()
        Task { await updateLiveActivity() }
        return isLast
    }

    func togglePause() {
        workoutTimer.toggle()
        if !workoutTimer.isRunning {
            restTimer.pause()
        } else {
            restTimer.resume()
        }
        Task { await updateLiveActivity() }
    }

    func skipRest() {
        restTimer.skip()
    }

    func finishWorkout() async throws {
        workoutTimer.pause()
        try await sessionStore.finish(status: .completed)
        await endLiveActivity()
    }

    // Live Activity integration
    private func startLiveActivity(plan: WorkoutPlan) async throws {
        try await liveActivityManager.startActivity(
            workoutName: plan.title,
            totalExercises: plan.exercises.count
        )
    }

    private func updateLiveActivity() async {
        let state = WorkoutActivityAttributes.ContentState(
            currentExerciseName: sessionStore.effectiveCurrentExerciseName,
            currentSet: sessionStore.currentExerciseProgress?.completedSetsCount ?? 0,
            totalSets: sessionStore.currentExerciseProgress?.totalSets ?? 0,
            restTimeRemaining: restTimer.isActive ? TimeInterval(restTimer.remainingSeconds) : nil,
            workoutElapsedTime: TimeInterval(workoutTimer.elapsedSeconds),
            isPaused: !workoutTimer.isRunning
        )
        await liveActivityManager.updateActivity(state: state)
    }

    private func endLiveActivity() async {
        await liveActivityManager.endActivity(dismissalPolicy: .default)
    }

    private func determineRestDuration() -> TimeInterval {
        // Logic based on exercise type
        // Light: 60s, Moderate: 90s, Heavy: 120s
        return 90 // Default
    }
}
```

**Success Criteria**:
- All state derived from existing stores (no duplication)
- Set completion triggers RestTimerStore
- Exercise navigation uses WorkoutSessionStore
- Pause stops workoutTimer
- Progress uses existing WorkoutProgress persistence
- 80% test coverage

---

### Task 7.0: Workout Navigation Flow [M]
**Objective**: Implement navigation from programs to execution

**Files to Create/Modify**:
- `FitToday/Presentation/Features/Workout/Views/WorkoutPreviewView.swift` (new)
- `FitToday/Presentation/Features/Programs/` (enhance existing)
- `FitToday/Presentation/Navigation/` (enhance existing router)

**Implementation Steps**:
1. Review existing program/workout views
2. Create or enhance ProgramDetailView showing workouts
3. Create WorkoutPreviewView showing exercises before start
4. Add "Start Workout" button navigating to WorkoutExecutionView
5. Implement Router navigation pattern
6. Wire back navigation on workout completion

**Navigation Flow**:
```
Programs → ProgramDetailView → WorkoutPreviewView → WorkoutExecutionView → WorkoutCompletionView
```

**Dependencies**: Task 6.0 (WorkoutExecutionViewModel)

**Success Criteria**:
- User can navigate from program list to execution
- Preview shows exercises before starting
- Start button initiates execution
- Back navigation works correctly

---

### Task 8.0: Workout Execution Views [L]
**Objective**: Create SwiftUI views for workout execution

**Files to Create**:
- `FitToday/Presentation/Features/Workout/Views/WorkoutExecutionView.swift`
- `FitToday/Presentation/Features/Workout/Components/ExerciseExecutionCard.swift`
- `FitToday/Presentation/Features/Workout/Components/ExerciseMediaView.swift`

**Files to Reference (Existing)**:
- `FitToday/Presentation/DesignSystem/RestTimerView.swift`

**Implementation Steps**:
1. Create WorkoutExecutionView main screen
2. Create ExerciseExecutionCard component
3. Use existing RestTimerView or create overlay variant
4. Create ExerciseMediaView for image/video display
5. Implement set completion checkboxes
6. Add skip/next exercise buttons
7. Add pause/play controls
8. Add total workout timer display
9. Wire navigation to completion screen

**UI Requirements**:
- Exercise name prominently displayed
- Media (video > GIF > image) with loading indicator
- Series counter (e.g., "Set 2/4")
- Rest timer countdown when active
- Bottom controls: pause, skip, next

**Dependencies**: Task 6.0, Task 4.0, Task 5.0

**Success Criteria**:
- All UI elements display correctly
- Controls trigger appropriate ViewModel actions
- Smooth transitions between exercises
- Rest timer overlay appears/dismisses correctly
- Matches design guidelines in CLAUDE.md

---

## Phase 3: Live Activity (P1)

### Task 9.0: Live Activity Extension Setup [M]
**Objective**: Set up Widget Extension target for Live Activities

**Files to Create**:
- `FitTodayLiveActivity/WorkoutActivityAttributes.swift`
- `FitTodayLiveActivity/WorkoutLiveActivity.swift`
- `FitTodayLiveActivity/FitTodayLiveActivityBundle.swift`
- Project configuration: entitlements, Info.plist

**Implementation Steps**:
1. Create new Widget Extension target "FitTodayLiveActivity"
2. Configure ActivityKit entitlements
3. Create WorkoutActivityAttributes model (with Sendable ContentState)
4. Create basic WorkoutLiveActivity widget
5. Configure Info.plist for Live Activity support
6. Add target to project scheme
7. Implement Dynamic Island UI (compact, minimal, expanded)

**ActivityAttributes Model**:
```swift
import ActivityKit

struct WorkoutActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable, Sendable {
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

**Success Criteria**:
- Widget Extension compiles successfully
- Live Activity can be started from main app
- Basic UI displays in Lock Screen
- Dynamic Island shows compact/expanded views
- No build warnings

---

### Task 10.0: Live Activity Manager [M]
**Objective**: Create manager for Live Activity lifecycle

**Files to Create**:
- `FitToday/Presentation/Features/Workout/WorkoutLiveActivityManager.swift`
- `FitTodayTests/Presentation/Features/Workout/WorkoutLiveActivityManagerTests.swift`

**Implementation Steps**:
1. Create WorkoutLiveActivityManager @MainActor class (NOT actor)
2. Implement startActivity method with permission check
3. Implement updateActivity method
4. Implement endActivity method with dismissal policies
5. Handle permission checks and error cases
6. Write unit tests with spy manager

**Manager Implementation**:
```swift
import ActivityKit

@MainActor
final class WorkoutLiveActivityManager {
    private var currentActivity: Activity<WorkoutActivityAttributes>?

    func startActivity(
        workoutName: String,
        totalExercises: Int
    ) async throws -> String {
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

**Dependencies**: Task 9.0

**Success Criteria**:
- Manager starts/updates/ends activities correctly
- Handles permission denied gracefully
- @MainActor isolated (not actor)
- Tests cover all lifecycle states

---

### Task 11.0: Live Activity Integration [M]
**Objective**: Integrate Live Activity updates into execution flow

**Files to Modify**:
- `FitToday/Presentation/Features/Workout/ViewModels/WorkoutExecutionViewModel.swift`
- `FitTodayLiveActivity/WorkoutLiveActivity.swift`

**Implementation Steps**:
1. Inject WorkoutLiveActivityManager into WorkoutExecutionViewModel
2. Start Live Activity when workout begins
3. Update Live Activity on exercise change
4. Update Live Activity on set completion
5. Update Live Activity on rest timer tick (debounced)
6. Update Live Activity on pause/resume
7. End Live Activity when workout completes
8. Derive state from stores (single source of truth)

**Update Frequency**:
- Exercise change: immediate
- Set completion: immediate
- Rest timer: every second
- Workout timer: every 5 seconds (battery optimization)

**Dependencies**: Task 6.0, Task 10.0

**Success Criteria**:
- Live Activity shows current exercise and set
- Rest timer countdown visible on Lock Screen
- Pause state reflected in Live Activity
- Activity ends when workout completes
- Works correctly when app in background

---

## Phase 4: Polish (P2)

### Task 12.0: Workout Completion Enhancements [S]
**Objective**: Enhance completion screen with statistics

**Files to Modify**:
- `FitToday/Presentation/Features/Workout/Views/WorkoutCompletionView.swift`
- `FitToday/Presentation/Features/Workout/Components/WorkoutRatingView.swift` (existing)

**Implementation Steps**:
1. Update WorkoutCompletionView with total time display
2. Add completed exercises count
3. Integrate 1-5 star rating (existing WorkoutRatingView)
4. Save completed workout to history
5. End Live Activity on completion
6. Clear session state after save

**Completion Display**:
- Total workout time
- Exercises completed / total
- Star rating input
- Save button

**Dependencies**: Task 6.0, Task 11.0

**Success Criteria**:
- All statistics display correctly
- Rating saved with workout
- Live Activity dismissed
- Session properly cleared
- Navigation returns to appropriate screen

---

### Task 13.0: Integration Tests [S]
**Objective**: Write integration tests covering full flows

**Files to Create**:
- `FitTodayTests/Integration/WorkoutGenerationIntegrationTests.swift`
- `FitTodayTests/Integration/WorkoutExecutionIntegrationTests.swift`

**Implementation Steps**:
1. Test full workout generation with validation and fallback
2. Test workout execution start-to-finish flow
3. Test Live Activity lifecycle with spy manager
4. Test crash recovery scenario
5. Test timer accuracy over 60 seconds

**Integration Scenarios**:
- End-to-end data flow
- Component interactions
- Error handling across boundaries

**Dependencies**: All implementation tasks complete

**Success Criteria**:
- All integration scenarios pass
- Timer accuracy verified (±1 second)
- Recovery from interruption works
- Live Activity state sync verified

---

## Checkpoint Strategy

### Checkpoint After Each Major Task
Update `.claude/feature-state/prd-workout-experience-overhaul/checkpoint.json`:
```json
{
  "feature": "prd-workout-experience-overhaul",
  "phase": "implementation",
  "currentTask": "3.0",
  "completedTasks": ["0.0", "1.0", "2.0"],
  "timestamp": "2026-02-09T15:30:00Z",
  "status": "in-progress"
}
```

### Progress Tracking
Use TodoWrite to maintain task list with status:
- pending → in_progress → completed
- Update after each subtask completion
- One task in_progress at a time

---

## Risk Mitigation During Implementation

### Risk: Live Activity Not Testable on Simulator
**Mitigation**:
- Use spy manager in unit tests
- Defer physical device testing to Phase 3
- Test all manager methods in isolation

### Risk: Timer Accuracy in Background
**Mitigation**:
- Follow existing Task.sleep pattern from RestTimerStore
- Write timer accuracy integration test
- Validate with 60-second test

### Risk: OpenAI API Rate Limiting During Testing
**Mitigation**:
- Use mock OpenAI client in tests
- Test with stubbed responses
- Validate local fallback thoroughly

---

## Quality Checklist

### Before Marking Task Complete
- [ ] Code compiles without warnings
- [ ] Unit tests written and passing
- [ ] Coverage meets targets (80% VM, 70% UC)
- [ ] Swift 6.0 concurrency warnings resolved
- [ ] @MainActor/@Observable patterns applied correctly
- [ ] No force unwrapping without justification
- [ ] CLAUDE.md guidelines followed
- [ ] Checkpoint updated
- [ ] TodoWrite status updated

---

## Next Steps

1. Update TodoWrite with all 14 tasks
2. Begin Task 0.0 (Workout Input Collection Screen)
3. Follow implementation steps sequentially
4. Update checkpoint after each task
5. Proceed to Phase 3 (Tests & Validation) after all tasks complete

---

**Implementation Plan Complete**
