# Implementation Plan: CMS Personal Trainer Integration

## File Mapping Overview

This plan organizes all files by layer and creation order.

### Legend
- **[CREATE]** - New file to create
- **[MODIFY]** - Existing file to modify
- **[TEST]** - Test file

---

## Phase 1: Feature Flags Infrastructure (Tasks 1-6)

### Task 1: Add FirebaseRemoteConfig Dependency

**Action:** Add package dependency via Xcode

**Steps:**
1. Open `FitToday.xcodeproj` in Xcode
2. Navigate to Project > Package Dependencies
3. Find `firebase-ios-sdk` package
4. Add `FirebaseRemoteConfig` product to FitToday target

**Verification:** `import FirebaseRemoteConfig` compiles

---

### Task 2: Create FeatureFlag Domain Entities

**[CREATE]** `FitToday/FitToday/Domain/Entities/FeatureFlag.swift`

```swift
// FeatureFlagKey enum with raw values matching Firebase keys
// - personalTrainerEnabled = "personal_trainer_enabled"
// - cmsWorkoutSyncEnabled = "cms_workout_sync_enabled"
// - trainerChatEnabled = "trainer_chat_enabled"
```

**Dependencies:** None

---

### Task 3: Create RemoteConfigService Actor

**[CREATE]** `FitToday/FitToday/Data/Services/RemoteConfig/RemoteConfigService.swift`

```swift
// Actor wrapping Firebase Remote Config SDK
// Methods:
// - fetchAndActivate() async throws
// - getValue(for: FeatureFlagKey) -> Bool
// - setMinimumFetchInterval(_ interval: TimeInterval)
```

**Dependencies:** Task 2 (FeatureFlag.swift)

---

### Task 4: Create FeatureFlagRepository Protocol and Implementation

**[CREATE]** `FitToday/FitToday/Domain/Protocols/FeatureFlagRepository.swift`

```swift
// Protocol:
// - isEnabled(_ key: FeatureFlagKey) async -> Bool
// - fetchAndActivate() async throws
```

**[CREATE]** `FitToday/FitToday/Data/Repositories/RemoteConfigFeatureFlagRepository.swift`

```swift
// Implementation using RemoteConfigService
// Caches values in UserDefaults for offline access
```

**Dependencies:** Task 2, Task 3

---

### Task 5: Create FeatureFlagUseCase

**[CREATE]** `FitToday/FitToday/Domain/UseCases/FeatureFlagUseCase.swift`

```swift
// Protocol FeatureFlagChecking:
// - isFeatureEnabled(_ key: FeatureFlagKey) async -> Bool
// - checkFeatureAccess(_ feature: ProFeature, flag: FeatureFlagKey) async -> FeatureAccessResult
```

**Dependencies:** Task 4

---

### Task 6: Integrate Feature Flags in AppContainer

**[MODIFY]** `FitToday/FitToday/Presentation/DI/AppContainer.swift`

**Changes:**
1. Register `RemoteConfigService` (line ~170, after Analytics)
2. Register `FeatureFlagRepository`
3. Update `FeatureGating` registration to optionally inject `FeatureFlagRepository`

**Dependencies:** Tasks 3, 4, 5

---

## Phase 2: Personal Trainer Domain (Tasks 7-11)

### Task 7: Create PersonalTrainerModels Domain Entities

**[CREATE]** `FitToday/FitToday/Domain/Entities/PersonalTrainerModels.swift`

```swift
// Entities:
// - PersonalTrainer: id, displayName, email, photoURL, specializations, bio, isActive, inviteCode
// - TrainerStudentRelationship: id, trainerId, studentId, status, requestedAt, acceptedAt
// - TrainerConnectionStatus: enum (pending, active, paused, cancelled)
```

**Dependencies:** Task 6 complete

---

### Task 8: Create FBPersonalTrainerModels DTOs

**[CREATE]** `FitToday/FitToday/Data/Models/FBPersonalTrainerModels.swift`

```swift
// DTOs (Codable):
// - FBPersonalTrainer: matches Firestore schema
// - FBTrainerStudent: matches Firestore schema
```

**Dependencies:** Task 7

---

### Task 9: Create PersonalTrainerMapper

**[CREATE]** `FitToday/FitToday/Data/Mappers/PersonalTrainerMapper.swift`

```swift
// Mapper struct:
// - toDomain(_ fb: FBPersonalTrainer, id: String) -> PersonalTrainer
// - toRelationship(_ fb: FBTrainerStudent, id: String) -> TrainerStudentRelationship
```

**Dependencies:** Tasks 7, 8

---

### Task 10: Create FirebasePersonalTrainerService

**[CREATE]** `FitToday/FitToday/Data/Services/Firebase/FirebasePersonalTrainerService.swift`

```swift
// Actor with methods:
// - fetchTrainer(id: String) async throws -> FBPersonalTrainer
// - searchTrainers(query: String, limit: Int) async throws -> [(String, FBPersonalTrainer)]
// - findByInviteCode(_ code: String) async throws -> (String, FBPersonalTrainer)?
// - requestConnection(trainerId: String, studentId: String) async throws
// - cancelConnection(relationshipId: String) async throws
// - observeRelationship(studentId: String) -> AsyncStream<(String, FBTrainerStudent)?>
```

**Dependencies:** Task 8

---

### Task 11: Create PersonalTrainerRepository

**[CREATE]** `FitToday/FitToday/Domain/Protocols/PersonalTrainerRepository.swift`

```swift
// Protocols:
// - PersonalTrainerRepository: fetchTrainer, searchTrainers, findByInviteCode
// - TrainerStudentRepository: requestConnection, cancelConnection, observeRelationship
```

**[CREATE]** `FitToday/FitToday/Data/Repositories/FirebasePersonalTrainerRepository.swift`

```swift
// Implementation using FirebasePersonalTrainerService and PersonalTrainerMapper
```

**Dependencies:** Tasks 9, 10

---

## Phase 3: Trainer Workout Sync (Tasks 12-13)

### Task 12: Create TrainerWorkout DTOs and Mapper

**[CREATE]** `FitToday/FitToday/Data/Models/FBTrainerWorkout.swift`

```swift
// DTOs:
// - FBTrainerWorkout: trainerId, assignedStudents, title, description, focus, phases, schedule
// - FBWorkoutPhase: name, items
// - FBWorkoutItem: exerciseId, exerciseName, sets, reps, restSeconds, notes
// - FBWorkoutSchedule: type, scheduledDate, dayOfWeek
```

**[CREATE]** `FitToday/FitToday/Data/Mappers/TrainerWorkoutMapper.swift`

```swift
// CRITICAL MAPPER:
// - toWorkoutPlan(_ fb: FBTrainerWorkout, id: String) -> WorkoutPlan
// - toWorkoutPlanPhase(_ fb: FBWorkoutPhase) -> WorkoutPlanPhase
// - toExercisePrescription(_ fb: FBWorkoutItem) -> ExercisePrescription
// - toDailyFocus(_ focus: String) -> DailyFocus
// - toWorkoutIntensity(_ intensity: String) -> WorkoutIntensity
```

**Dependencies:** Task 11

---

### Task 13: Create FirebaseTrainerWorkoutService and Repository

**[CREATE]** `FitToday/FitToday/Data/Services/Firebase/FirebaseTrainerWorkoutService.swift`

```swift
// Actor with methods:
// - fetchAssignedWorkouts(studentId: String) async throws -> [(String, FBTrainerWorkout)]
// - observeAssignedWorkouts(studentId: String) -> AsyncStream<[(String, FBTrainerWorkout)]>
```

**[CREATE]** `FitToday/FitToday/Domain/Protocols/TrainerWorkoutRepository.swift`

```swift
// Protocol:
// - fetchAssignedWorkouts(studentId: String) async throws -> [WorkoutPlan]
// - observeAssignedWorkouts(studentId: String) -> AsyncStream<[WorkoutPlan]>
```

**[CREATE]** `FitToday/FitToday/Data/Repositories/FirebaseTrainerWorkoutRepository.swift`

```swift
// Implementation using FirebaseTrainerWorkoutService and TrainerWorkoutMapper
```

**Dependencies:** Task 12

---

## Phase 4: Use Cases and UI (Tasks 14-15)

### Task 14: Create Personal Trainer Use Cases

**[CREATE]** `FitToday/FitToday/Domain/UseCases/PersonalTrainerUseCases.swift`

```swift
// Use Cases:
// - DiscoverTrainersUseCase
// - RequestTrainerConnectionUseCase
// - CancelTrainerConnectionUseCase
// - GetCurrentTrainerUseCase
// - FetchAssignedWorkoutsUseCase
// - ObserveTrainerWorkoutsUseCase
```

**Dependencies:** Tasks 11, 13

---

### Task 15: Create PersonalTrainerViewModel and Views

**[CREATE]** `FitToday/FitToday/Presentation/Features/PersonalTrainer/PersonalTrainerViewModel.swift`

```swift
// @Observable @MainActor class with:
// - currentTrainer: PersonalTrainer?
// - connectionStatus: TrainerConnectionStatus?
// - assignedWorkouts: [WorkoutPlan]
// - searchResults: [PersonalTrainer]
// - isLoading, error
```

**[CREATE]** `FitToday/FitToday/Presentation/Features/PersonalTrainer/PersonalTrainerView.swift`

```swift
// Main view showing:
// - Current trainer card (if connected)
// - Connection status badge
// - Assigned workouts list
// - Search button
```

**[CREATE]** `FitToday/FitToday/Presentation/Features/PersonalTrainer/TrainerSearchView.swift`

```swift
// Search view with:
// - Text search field
// - Invite code entry
// - Search results list
```

**[CREATE]** `FitToday/FitToday/Presentation/Features/PersonalTrainer/Components/TrainerCard.swift`

```swift
// Reusable card component for trainer display
```

**[CREATE]** `FitToday/FitToday/Presentation/Features/PersonalTrainer/Components/ConnectionRequestSheet.swift`

```swift
// Confirmation sheet for connection request
```

**Dependencies:** Task 14

---

## Modifications to Existing Files

### AppContainer.swift (Final State)

**Location:** `FitToday/FitToday/Presentation/DI/AppContainer.swift`

**Additions after line 170 (after Firebase Analytics):**

```swift
// ========== REMOTE CONFIG (Feature Flags) ==========
let remoteConfigService = RemoteConfigService()
container.register(RemoteConfigService.self) { _ in remoteConfigService }
    .inObjectScope(.container)

container.register(FeatureFlagRepository.self) { resolver in
    RemoteConfigFeatureFlagRepository(
        remoteConfigService: resolver.resolve(RemoteConfigService.self)!
    )
}
.inObjectScope(.container)

// ========== PERSONAL TRAINER ==========
let personalTrainerService = FirebasePersonalTrainerService()
container.register(FirebasePersonalTrainerService.self) { _ in personalTrainerService }
    .inObjectScope(.container)

container.register(PersonalTrainerRepository.self) { resolver in
    FirebasePersonalTrainerRepository(
        service: resolver.resolve(FirebasePersonalTrainerService.self)!
    )
}
.inObjectScope(.container)

container.register(TrainerStudentRepository.self) { resolver in
    FirebasePersonalTrainerRepository(
        service: resolver.resolve(FirebasePersonalTrainerService.self)!
    )
}
.inObjectScope(.container)

// ========== TRAINER WORKOUTS ==========
let trainerWorkoutService = FirebaseTrainerWorkoutService()
container.register(FirebaseTrainerWorkoutService.self) { _ in trainerWorkoutService }
    .inObjectScope(.container)

container.register(TrainerWorkoutRepository.self) { resolver in
    FirebaseTrainerWorkoutRepository(
        service: resolver.resolve(FirebaseTrainerWorkoutService.self)!
    )
}
.inObjectScope(.container)

// ========== PERSONAL TRAINER USE CASES ==========
container.register(DiscoverTrainersUseCase.self) { resolver in
    DiscoverTrainersUseCase(
        repository: resolver.resolve(PersonalTrainerRepository.self)!
    )
}

container.register(RequestTrainerConnectionUseCase.self) { resolver in
    RequestTrainerConnectionUseCase(
        repository: resolver.resolve(TrainerStudentRepository.self)!,
        authRepository: resolver.resolve(AuthenticationRepository.self)!
    )
}

container.register(FetchAssignedWorkoutsUseCase.self) { resolver in
    FetchAssignedWorkoutsUseCase(
        repository: resolver.resolve(TrainerWorkoutRepository.self)!,
        authRepository: resolver.resolve(AuthenticationRepository.self)!
    )
}
```

---

### EntitlementPolicy.swift

**Location:** `FitToday/FitToday/Domain/Entities/EntitlementPolicy.swift`

**Changes:**

1. Add to `ProFeature` enum:
```swift
case personalTrainer = "personal_trainer"
case trainerWorkouts = "trainer_workouts"
```

2. Add display names:
```swift
case .personalTrainer: return "Personal Trainer"
case .trainerWorkouts: return "Trainer Workouts"
```

3. Add to `canAccess` switch:
```swift
case .personalTrainer, .trainerWorkouts:
    return .requiresPro(feature: feature)
```

4. Add to `isProOnly`:
```swift
case .personalTrainer, .trainerWorkouts:
    return true
```

---

### AppRouter.swift

**Location:** `FitToday/FitToday/Presentation/Router/AppRouter.swift`

**Changes:**

1. Add to `AppRoute` enum:
```swift
case personalTrainer  // Main personal trainer view
case trainerSearch  // Search for trainers
case trainerWorkouts  // List of trainer-assigned workouts
case trainerWorkoutDetail(WorkoutPlan)  // Detail view for trainer workout
```

2. Add to `DeepLink.Destination`:
```swift
case trainerInvite(code: String)
```

3. Add to `DeepLink.init(url:)`:
```swift
// Handle trainer invite: fittoday://trainer/invite/{code}
if host == "trainer", path.hasPrefix("/invite/") {
    let code = String(path.dropFirst("/invite/".count))
    destination = .trainerInvite(code: code)
    return
}
```

4. Add to `handle(deeplink:)`:
```swift
case .trainerInvite(let code):
    select(tab: .profile)
    push(.personalTrainer, on: .profile)
```

---

## File Creation Order (Dependency-Respecting)

### Sprint 1: Feature Flags
1. `Domain/Entities/FeatureFlag.swift`
2. `Data/Services/RemoteConfig/RemoteConfigService.swift`
3. `Domain/Protocols/FeatureFlagRepository.swift`
4. `Data/Repositories/RemoteConfigFeatureFlagRepository.swift`
5. `Domain/UseCases/FeatureFlagUseCase.swift`
6. **[MODIFY]** `Presentation/DI/AppContainer.swift` (add feature flag registrations)

### Sprint 2: Personal Trainer Domain
7. `Domain/Entities/PersonalTrainerModels.swift`
8. `Data/Models/FBPersonalTrainerModels.swift`
9. `Data/Mappers/PersonalTrainerMapper.swift`
10. `Data/Services/Firebase/FirebasePersonalTrainerService.swift`
11. `Domain/Protocols/PersonalTrainerRepository.swift`
12. `Data/Repositories/FirebasePersonalTrainerRepository.swift`
13. **[MODIFY]** `Presentation/DI/AppContainer.swift` (add trainer registrations)

### Sprint 3: Workout Sync
14. `Data/Models/FBTrainerWorkout.swift`
15. `Data/Mappers/TrainerWorkoutMapper.swift`
16. `Data/Services/Firebase/FirebaseTrainerWorkoutService.swift`
17. `Domain/Protocols/TrainerWorkoutRepository.swift`
18. `Data/Repositories/FirebaseTrainerWorkoutRepository.swift`
19. **[MODIFY]** `Presentation/DI/AppContainer.swift` (add workout registrations)

### Sprint 4: Use Cases and UI
20. `Domain/UseCases/PersonalTrainerUseCases.swift`
21. `Presentation/Features/PersonalTrainer/PersonalTrainerViewModel.swift`
22. `Presentation/Features/PersonalTrainer/Components/TrainerCard.swift`
23. `Presentation/Features/PersonalTrainer/Components/ConnectionRequestSheet.swift`
24. `Presentation/Features/PersonalTrainer/PersonalTrainerView.swift`
25. `Presentation/Features/PersonalTrainer/TrainerSearchView.swift`
26. **[MODIFY]** `Domain/Entities/EntitlementPolicy.swift`
27. **[MODIFY]** `Presentation/Router/AppRouter.swift`
28. **[MODIFY]** `Presentation/DI/AppContainer.swift` (add use case registrations)

---

## Test Files

### Unit Tests
- `FitTodayTests/Data/Mappers/TrainerWorkoutMapperTests.swift` (CRITICAL)
- `FitTodayTests/Data/Mappers/PersonalTrainerMapperTests.swift`
- `FitTodayTests/Domain/UseCases/FeatureFlagUseCaseTests.swift`
- `FitTodayTests/Data/Services/RemoteConfigServiceTests.swift`

### Fixtures
- `FitTodayTests/Fixtures/FBTrainerWorkoutFixtures.swift`
- `FitTodayTests/Fixtures/FBPersonalTrainerFixtures.swift`

---

## Verification Checklist

After each sprint:

- [ ] Code compiles without warnings
- [ ] Unit tests pass
- [ ] `import` statements are correct
- [ ] Services registered in AppContainer resolve correctly
- [ ] Swift 6 concurrency rules followed (actors, Sendable)
- [ ] No force unwraps without justification

---

## Rollback Plan

If issues arise:
1. Feature flags can be disabled via Firebase Console
2. Each sprint is independent - can deploy Sprint 1 without Sprint 2-4
3. UI routes can be hidden without removing backend code
