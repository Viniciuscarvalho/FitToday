# Implementation Tasks: CMS Personal Trainer Integration

## Overview

Total: 15 tasks across 4 sprints
Estimated: 12-16 days

---

## Sprint 1: Feature Flags Infrastructure (Tasks 1-6)

### Task 1: Add FirebaseRemoteConfig Dependency
**File**: `FitToday.xcodeproj` (via Xcode)
**Priority**: P0
**Estimate**: 30 min

**Description**: Add FirebaseRemoteConfig product from firebase-ios-sdk to the Xcode project.

**Steps**:
1. Open Xcode project
2. Navigate to Package Dependencies
3. Find firebase-ios-sdk package
4. Add `FirebaseRemoteConfig` product to FitToday target

**Acceptance Criteria**:
- [ ] `import FirebaseRemoteConfig` compiles without errors
- [ ] App builds successfully

---

### Task 2: Create FeatureFlag Domain Entities
**File**: `Domain/Entities/FeatureFlag.swift`
**Priority**: P0
**Estimate**: 30 min

**Description**: Create the `FeatureFlagKey` enum with all feature flag identifiers.

**Code**:
```swift
enum FeatureFlagKey: String, CaseIterable, Sendable {
    case personalTrainerEnabled = "personal_trainer_enabled"
    case cmsWorkoutSyncEnabled = "cms_workout_sync_enabled"
    case trainerChatEnabled = "trainer_chat_enabled"
}
```

**Acceptance Criteria**:
- [ ] Enum is Sendable
- [ ] Raw values match Firebase Remote Config keys

---

### Task 3: Create RemoteConfigService Actor
**File**: `Data/Services/RemoteConfig/RemoteConfigService.swift`
**Priority**: P0
**Estimate**: 2 hours

**Description**: Create an actor that wraps Firebase Remote Config SDK with async/await.

**Key Methods**:
- `fetchAndActivate() async throws`
- `getValue(for key: FeatureFlagKey) -> Bool`
- `setMinimumFetchInterval(_ interval: TimeInterval)`

**Acceptance Criteria**:
- [ ] Actor provides thread-safe access
- [ ] Handles fetch errors gracefully
- [ ] Configurable fetch interval (default 12 hours, 0 for debug)

---

### Task 4: Create FeatureFlagRepository Protocol and Implementation
**Files**:
- `Domain/Protocols/FeatureFlagRepository.swift`
- `Data/Repositories/RemoteConfigFeatureFlagRepository.swift`
**Priority**: P0
**Estimate**: 1.5 hours

**Description**: Create repository protocol and implementation that uses RemoteConfigService.

**Protocol**:
```swift
protocol FeatureFlagRepository: Sendable {
    func isEnabled(_ key: FeatureFlagKey) async -> Bool
    func fetchAndActivate() async throws
}
```

**Acceptance Criteria**:
- [ ] Protocol is Sendable
- [ ] Implementation caches values locally
- [ ] Fetch on app launch, cache for performance

---

### Task 5: Create FeatureFlagUseCase
**File**: `Domain/UseCases/FeatureFlagUseCase.swift`
**Priority**: P0
**Estimate**: 1 hour

**Description**: Use case that combines feature flags with entitlement checks.

**Key Method**:
```swift
func checkFeatureAccess(_ feature: ProFeature, flag: FeatureFlagKey) async -> FeatureAccessResult
```

**Logic**:
1. Check if feature flag is enabled
2. If disabled, return `.requiresPro` (or new `.featureDisabled` case)
3. If enabled, delegate to existing entitlement check

**Acceptance Criteria**:
- [ ] Returns correct result when flag is off
- [ ] Delegates to entitlement check when flag is on
- [ ] Works with existing FeatureGatingUseCase

---

### Task 6: Integrate Feature Flags in AppContainer
**File**: `Presentation/DI/AppContainer.swift`
**Priority**: P0
**Estimate**: 1 hour

**Description**: Register all feature flag services and update FeatureGating.

**Registrations**:
- `RemoteConfigService`
- `FeatureFlagRepository`
- Update `FeatureGating` to optionally use flag repository

**Acceptance Criteria**:
- [ ] All services resolve correctly
- [ ] Existing FeatureGating behavior unchanged when flags not used
- [ ] Feature flag check available via FeatureGating protocol

---

## Sprint 2: Personal Trainer Domain (Tasks 7-11)

### Task 7: Create PersonalTrainerModels Domain Entities
**File**: `Domain/Entities/PersonalTrainerModels.swift`
**Priority**: P1
**Estimate**: 1 hour

**Description**: Create domain entities for Personal Trainer feature.

**Entities**:
- `PersonalTrainer`: id, displayName, email, photoURL, specializations, bio, isActive, inviteCode
- `TrainerStudentRelationship`: id, trainerId, studentId, status, requestedAt, acceptedAt
- `TrainerConnectionStatus`: enum (pending, active, paused, cancelled)

**Acceptance Criteria**:
- [ ] All entities are Sendable
- [ ] All entities are Identifiable
- [ ] Status enum has all states from Firestore schema

---

### Task 8: Create FBPersonalTrainerModels DTOs
**File**: `Data/Models/FBPersonalTrainerModels.swift`
**Priority**: P1
**Estimate**: 1 hour

**Description**: Create Firebase DTOs for decoding Firestore documents.

**DTOs**:
- `FBPersonalTrainer`: Codable struct matching Firestore schema
- `FBTrainerStudent`: Codable struct matching Firestore schema

**Acceptance Criteria**:
- [ ] All DTOs are Codable
- [ ] Field names match Firestore exactly (or use CodingKeys)
- [ ] Date fields use appropriate type

---

### Task 9: Create PersonalTrainerMapper
**File**: `Data/Mappers/PersonalTrainerMapper.swift`
**Priority**: P1
**Estimate**: 1 hour

**Description**: Create mapper to convert Firebase DTOs to domain entities.

**Methods**:
- `toDomain(_ fb: FBPersonalTrainer, id: String) -> PersonalTrainer`
- `toRelationship(_ fb: FBTrainerStudent, id: String) -> TrainerStudentRelationship`

**Acceptance Criteria**:
- [ ] Handles optional fields correctly
- [ ] Maps status string to enum
- [ ] URL parsing for photoURL

---

### Task 10: Create FirebasePersonalTrainerService
**File**: `Data/Services/Firebase/FirebasePersonalTrainerService.swift`
**Priority**: P1
**Estimate**: 3 hours

**Description**: Actor that handles all Firestore operations for personal trainers.

**Methods**:
- `fetchTrainer(id: String) async throws -> FBPersonalTrainer`
- `searchTrainers(query: String, limit: Int) async throws -> [(String, FBPersonalTrainer)]`
- `findByInviteCode(_ code: String) async throws -> (String, FBPersonalTrainer)?`
- `requestConnection(trainerId: String, studentId: String) async throws`
- `cancelConnection(relationshipId: String) async throws`
- `observeRelationship(studentId: String) -> AsyncStream<(String, FBTrainerStudent)?>`

**Acceptance Criteria**:
- [ ] Actor provides thread-safe access
- [ ] Proper Firestore queries (where, limit)
- [ ] Real-time listener for relationship status
- [ ] Proper error handling

---

### Task 11: Create PersonalTrainerRepository
**Files**:
- `Domain/Protocols/PersonalTrainerRepository.swift`
- `Data/Repositories/FirebasePersonalTrainerRepository.swift`
**Priority**: P1
**Estimate**: 2 hours

**Description**: Create repository protocols and implementation.

**Protocols**:
- `PersonalTrainerRepository`: fetchTrainer, searchTrainers, findByInviteCode
- `TrainerStudentRepository`: requestConnection, cancelConnection, observeRelationship, getCurrentRelationship

**Acceptance Criteria**:
- [ ] Protocols are Sendable
- [ ] Implementation uses mapper for conversions
- [ ] Registered in AppContainer

---

## Sprint 3: Trainer Workout Sync (Tasks 12-13)

### Task 12: Create TrainerWorkout DTOs and Mapper
**Files**:
- `Data/Models/FBTrainerWorkout.swift`
- `Data/Mappers/TrainerWorkoutMapper.swift`
**Priority**: P1
**Estimate**: 3 hours

**Description**: Create DTOs for trainer workouts and CRITICAL mapper to WorkoutPlan.

**DTOs**:
- `FBTrainerWorkout`: trainerId, assignedStudents, title, description, focus, phases, schedule
- `FBWorkoutPhase`: name, items
- `FBWorkoutItem`: exerciseId, exerciseName, sets, reps, restSeconds, notes

**Mapper** (Critical):
- `toWorkoutPlan(_ fb: FBTrainerWorkout, id: String) -> WorkoutPlan`
- Must map to existing WorkoutPlan, WorkoutPlanPhase, ExercisePrescription

**Acceptance Criteria**:
- [ ] Workout executes in existing workout player
- [ ] All fields map correctly
- [ ] Focus maps to DailyFocus enum
- [ ] Intensity maps correctly

---

### Task 13: Create FirebaseTrainerWorkoutService and Repository
**Files**:
- `Data/Services/Firebase/FirebaseTrainerWorkoutService.swift`
- `Data/Repositories/FirebaseTrainerWorkoutRepository.swift`
- `Domain/Protocols/TrainerWorkoutRepository.swift`
**Priority**: P1
**Estimate**: 2.5 hours

**Description**: Service and repository for fetching trainer-assigned workouts.

**Service Methods**:
- `fetchAssignedWorkouts(studentId: String) async throws -> [(String, FBTrainerWorkout)]`
- `observeAssignedWorkouts(studentId: String) -> AsyncStream<[(String, FBTrainerWorkout)]>`

**Repository Protocol**:
```swift
protocol TrainerWorkoutRepository: Sendable {
    func fetchAssignedWorkouts(studentId: String) async throws -> [WorkoutPlan]
    func observeAssignedWorkouts(studentId: String) -> AsyncStream<[WorkoutPlan]>
}
```

**Acceptance Criteria**:
- [ ] Returns only active workouts
- [ ] Filters by assignedStudents array-contains
- [ ] Real-time updates via AsyncStream
- [ ] Maps to WorkoutPlan via mapper

---

## Sprint 4: Use Cases and UI (Tasks 14-15)

### Task 14: Create Personal Trainer Use Cases
**File**: `Domain/UseCases/PersonalTrainerUseCases.swift`
**Priority**: P1
**Estimate**: 2 hours

**Description**: Create use cases for personal trainer features.

**Use Cases**:
- `DiscoverTrainersUseCase`: Search trainers by name or invite code
- `RequestTrainerConnectionUseCase`: Send connection request
- `CancelTrainerConnectionUseCase`: Cancel pending or active connection
- `GetCurrentTrainerUseCase`: Get current trainer and relationship status
- `FetchAssignedWorkoutsUseCase`: Get trainer-assigned workouts
- `ObserveTrainerWorkoutsUseCase`: Stream of workout updates

**Acceptance Criteria**:
- [ ] All use cases validate feature flag first
- [ ] Proper error handling
- [ ] Registered in AppContainer

---

### Task 15: Create PersonalTrainerViewModel and Views
**Files**:
- `Presentation/Features/PersonalTrainer/PersonalTrainerViewModel.swift`
- `Presentation/Features/PersonalTrainer/PersonalTrainerView.swift`
- `Presentation/Features/PersonalTrainer/TrainerSearchView.swift`
- `Presentation/Features/PersonalTrainer/Components/TrainerCard.swift`
- `Presentation/Features/PersonalTrainer/Components/ConnectionRequestSheet.swift`
**Priority**: P1
**Estimate**: 6 hours

**Description**: Create ViewModel and SwiftUI views for personal trainer feature.

**ViewModel State**:
- `currentTrainer: PersonalTrainer?`
- `connectionStatus: TrainerConnectionStatus?`
- `assignedWorkouts: [WorkoutPlan]`
- `searchResults: [PersonalTrainer]`
- `isLoading: Bool`
- `error: Error?`

**Views**:
- `PersonalTrainerView`: Main view showing current trainer and workouts
- `TrainerSearchView`: Search by name or code
- `TrainerCard`: Card component for trainer display
- `ConnectionRequestSheet`: Confirmation sheet for connection request

**Acceptance Criteria**:
- [ ] ViewModel uses @Observable
- [ ] Views use @Bindable for ViewModel binding
- [ ] Loading states shown
- [ ] Errors displayed appropriately
- [ ] Navigation integrated with AppRouter

---

## Post-Implementation Tasks

### Task 16 (Optional): Update EntitlementPolicy
**File**: `Domain/Entities/EntitlementPolicy.swift`
**Priority**: P2

Add new ProFeature cases:
- `personalTrainer`
- `trainerWorkouts`

### Task 17 (Optional): Add Routes to AppRouter
**File**: `Presentation/Navigation/AppRouter.swift`
**Priority**: P2

Add new routes:
- `personalTrainer`
- `trainerSearch`
- `trainerWorkouts`

### Task 18 (Optional): Add Notifications
**Files**: Various
**Priority**: P2

- `trainerRequest` notification type
- `trainerAccepted` notification type
- `newTrainerWorkout` notification type

---

## Task Dependencies

```
Task 1 (RemoteConfig dep)
    |
    v
Task 2 (FeatureFlag enum)
    |
    v
Task 3 (RemoteConfigService)
    |
    v
Task 4 (FeatureFlagRepository)
    |
    v
Task 5 (FeatureFlagUseCase)
    |
    v
Task 6 (AppContainer integration)
    |
    +---------+---------+
    |                   |
    v                   v
Task 7              Task 12
(Domain models)     (Workout DTOs)
    |                   |
    v                   v
Task 8              Task 13
(Firebase DTOs)     (Workout service)
    |                   |
    v                   |
Task 9                  |
(Mapper)                |
    |                   |
    v                   |
Task 10                 |
(Service)               |
    |                   |
    v                   |
Task 11 <---------------+
(Repository)
    |
    v
Task 14
(Use Cases)
    |
    v
Task 15
(ViewModel + UI)
```

---

## Definition of Done

For each task:
1. Code compiles without warnings
2. Unit tests written (where applicable)
3. Code follows project conventions (MVVM, Clean Architecture)
4. Swift 6 concurrency rules followed
5. Registered in AppContainer (services/repositories)
6. Documentation comments added
