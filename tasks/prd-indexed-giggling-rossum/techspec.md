# Technical Specification: CMS Personal Trainer Integration

## 1. Architecture Overview

This feature follows the existing MVVM + Clean Architecture pattern:

```
Presentation (SwiftUI Views, ViewModels)
    |
    v
Domain (Use Cases, Entities, Protocols)
    |
    v
Data (Repositories, Services, DTOs, Mappers)
```

All new services are registered in `AppContainer.swift` using Swinject.

## 2. Firebase Remote Config Integration

### 2.1 New Files

#### Domain Layer

**`Domain/Entities/FeatureFlag.swift`**
```swift
enum FeatureFlagKey: String, CaseIterable {
    case personalTrainerEnabled = "personal_trainer_enabled"
    case cmsWorkoutSyncEnabled = "cms_workout_sync_enabled"
    case trainerChatEnabled = "trainer_chat_enabled"
}
```

**`Domain/Protocols/FeatureFlagRepository.swift`**
```swift
protocol FeatureFlagRepository: Sendable {
    func isEnabled(_ key: FeatureFlagKey) async -> Bool
    func fetchAndActivate() async throws
    func observeChanges() -> AsyncStream<FeatureFlagKey>
}
```

**`Domain/UseCases/FeatureFlagUseCase.swift`**
```swift
protocol FeatureFlagChecking: Sendable {
    func isFeatureEnabled(_ key: FeatureFlagKey) async -> Bool
    func checkFeatureAccess(_ feature: ProFeature, flag: FeatureFlagKey) async -> FeatureAccessResult
}
```

#### Data Layer

**`Data/Services/RemoteConfig/RemoteConfigService.swift`**
```swift
actor RemoteConfigService {
    func fetchAndActivate() async throws
    func getValue(for key: String) -> Bool
    func observeConfigChanges() -> AsyncStream<Void>
}
```

**`Data/Repositories/RemoteConfigFeatureFlagRepository.swift`**
```swift
final class RemoteConfigFeatureFlagRepository: FeatureFlagRepository {
    private let remoteConfigService: RemoteConfigService
    private let cache: UserDefaults
}
```

### 2.2 Modifications

**`FeatureGatingUseCase.swift`**
- Add `checkFeatureFlag(_ key: FeatureFlagKey)` method
- Combine entitlement check + feature flag check
- Return `.requiresPro` if flag disabled OR entitlement missing

**`AppContainer.swift`**
- Register `RemoteConfigService`
- Register `FeatureFlagRepository`
- Update `FeatureGating` registration to inject flag repository

### 2.3 Remote Config Schema (Firebase Console)

```json
{
  "personal_trainer_enabled": {
    "defaultValue": { "value": "false" },
    "description": "Enable Personal Trainer feature"
  },
  "cms_workout_sync_enabled": {
    "defaultValue": { "value": "false" },
    "description": "Enable workout sync from CMS"
  },
  "trainer_chat_enabled": {
    "defaultValue": { "value": "false" },
    "description": "Enable trainer-student chat (future)"
  }
}
```

## 3. Personal Trainer Domain Model

### 3.1 Firestore Schema

#### Collection: `/personalTrainers/{trainerId}`
```typescript
{
  displayName: string,
  email: string,
  photoURL: string | null,
  specializations: string[],
  bio: string | null,
  isActive: boolean,
  maxStudents: number,
  currentStudentCount: number,
  inviteCode: string,  // 6-char unique code
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

#### Collection: `/trainerStudents/{relationshipId}`
```typescript
{
  trainerId: string,
  studentId: string,
  status: "pending" | "active" | "paused" | "cancelled",
  requestedBy: "student" | "trainer",
  requestedAt: Timestamp,
  acceptedAt: Timestamp | null,
  createdAt: Timestamp
}
```

#### Collection: `/trainerWorkouts/{workoutId}`
```typescript
{
  trainerId: string,
  assignedStudents: string[],
  title: string,
  description: string | null,
  focus: string,  // Maps to DailyFocus
  estimatedDurationMinutes: number,
  intensity: "low" | "moderate" | "high",
  phases: WorkoutPhase[],
  schedule: {
    type: "once" | "recurring" | "weekly",
    scheduledDate?: Timestamp,
    dayOfWeek?: number
  },
  isActive: boolean,
  createdAt: Timestamp,
  version: number
}
```

### 3.2 New Files

#### Domain Layer

**`Domain/Entities/PersonalTrainerModels.swift`**
```swift
struct PersonalTrainer: Identifiable, Sendable {
    let id: String
    let displayName: String
    let email: String
    let photoURL: URL?
    let specializations: [String]
    let bio: String?
    let isActive: Bool
    let inviteCode: String
}

struct TrainerStudentRelationship: Identifiable, Sendable {
    let id: String
    let trainerId: String
    let studentId: String
    let status: TrainerConnectionStatus
    let requestedAt: Date
    let acceptedAt: Date?
}

enum TrainerConnectionStatus: String, Sendable {
    case pending
    case active
    case paused
    case cancelled
}
```

**`Domain/Protocols/PersonalTrainerRepository.swift`**
```swift
protocol PersonalTrainerRepository: Sendable {
    func fetchTrainer(id: String) async throws -> PersonalTrainer
    func searchTrainers(query: String) async throws -> [PersonalTrainer]
    func findByInviteCode(_ code: String) async throws -> PersonalTrainer?
}

protocol TrainerStudentRepository: Sendable {
    func requestConnection(trainerId: String, studentId: String) async throws
    func cancelConnection(relationshipId: String) async throws
    func observeRelationship(studentId: String) -> AsyncStream<TrainerStudentRelationship?>
    func getCurrentRelationship(studentId: String) async throws -> TrainerStudentRelationship?
}
```

**`Domain/UseCases/PersonalTrainerUseCases.swift`**
```swift
struct DiscoverTrainersUseCase { }
struct RequestTrainerConnectionUseCase { }
struct CancelTrainerConnectionUseCase { }
struct GetCurrentTrainerUseCase { }
```

#### Data Layer

**`Data/Models/FBPersonalTrainerModels.swift`**
```swift
struct FBPersonalTrainer: Codable {
    let displayName: String
    let email: String
    let photoURL: String?
    let specializations: [String]
    let bio: String?
    let isActive: Bool
    let maxStudents: Int
    let currentStudentCount: Int
    let inviteCode: String
    let createdAt: Date
    let updatedAt: Date
}

struct FBTrainerStudent: Codable {
    let trainerId: String
    let studentId: String
    let status: String
    let requestedBy: String
    let requestedAt: Date
    let acceptedAt: Date?
    let createdAt: Date
}
```

**`Data/Mappers/PersonalTrainerMapper.swift`**
```swift
struct PersonalTrainerMapper {
    static func toDomain(_ fb: FBPersonalTrainer, id: String) -> PersonalTrainer
    static func toRelationship(_ fb: FBTrainerStudent, id: String) -> TrainerStudentRelationship
}
```

**`Data/Services/Firebase/FirebasePersonalTrainerService.swift`**
```swift
actor FirebasePersonalTrainerService {
    func fetchTrainer(id: String) async throws -> FBPersonalTrainer
    func searchTrainers(query: String, limit: Int) async throws -> [(String, FBPersonalTrainer)]
    func findByInviteCode(_ code: String) async throws -> (String, FBPersonalTrainer)?
    func requestConnection(trainerId: String, studentId: String) async throws
    func cancelConnection(relationshipId: String) async throws
    func observeRelationship(studentId: String) -> AsyncStream<(String, FBTrainerStudent)?>
}
```

**`Data/Repositories/FirebasePersonalTrainerRepository.swift`**
```swift
final class FirebasePersonalTrainerRepository: PersonalTrainerRepository, TrainerStudentRepository { }
```

## 4. Trainer Workout Sync

### 4.1 New Files

#### Data Layer

**`Data/Models/FBTrainerWorkout.swift`**
```swift
struct FBTrainerWorkout: Codable {
    let trainerId: String
    let assignedStudents: [String]
    let title: String
    let description: String?
    let focus: String
    let estimatedDurationMinutes: Int
    let intensity: String
    let phases: [FBWorkoutPhase]
    let schedule: FBWorkoutSchedule
    let isActive: Bool
    let createdAt: Date
    let version: Int
}

struct FBWorkoutPhase: Codable {
    let name: String
    let items: [FBWorkoutItem]
}

struct FBWorkoutItem: Codable {
    let exerciseId: String
    let exerciseName: String
    let sets: Int
    let reps: String
    let restSeconds: Int
    let notes: String?
}
```

**`Data/Mappers/TrainerWorkoutMapper.swift`**
```swift
struct TrainerWorkoutMapper {
    /// Critical: Maps FBTrainerWorkout to existing WorkoutPlan format
    static func toWorkoutPlan(_ fb: FBTrainerWorkout, id: String) -> WorkoutPlan
    static func toWorkoutPlanPhase(_ fb: FBWorkoutPhase) -> WorkoutPlanPhase
    static func toExercisePrescription(_ fb: FBWorkoutItem) -> ExercisePrescription
}
```

**`Data/Services/Firebase/FirebaseTrainerWorkoutService.swift`**
```swift
actor FirebaseTrainerWorkoutService {
    func fetchAssignedWorkouts(studentId: String) async throws -> [(String, FBTrainerWorkout)]
    func observeAssignedWorkouts(studentId: String) -> AsyncStream<[(String, FBTrainerWorkout)]>
}
```

**`Data/Repositories/FirebaseTrainerWorkoutRepository.swift`**
```swift
protocol TrainerWorkoutRepository: Sendable {
    func fetchAssignedWorkouts(studentId: String) async throws -> [WorkoutPlan]
    func observeAssignedWorkouts(studentId: String) -> AsyncStream<[WorkoutPlan]>
}

final class FirebaseTrainerWorkoutRepository: TrainerWorkoutRepository { }
```

#### Domain Layer

**`Domain/UseCases/TrainerWorkoutUseCases.swift`**
```swift
struct FetchAssignedWorkoutsUseCase {
    func execute(studentId: String) async throws -> [WorkoutPlan]
}

struct ObserveTrainerWorkoutsUseCase {
    func execute(studentId: String) -> AsyncStream<[WorkoutPlan]>
}
```

## 5. Presentation Layer

### 5.1 New Files

**`Presentation/Features/PersonalTrainer/PersonalTrainerViewModel.swift`**
```swift
@Observable
@MainActor
final class PersonalTrainerViewModel {
    var currentTrainer: PersonalTrainer?
    var connectionStatus: TrainerConnectionStatus?
    var assignedWorkouts: [WorkoutPlan] = []
    var isLoading = false
    var error: Error?

    // Use cases injected via init
    func loadCurrentTrainer() async
    func requestConnection(trainerId: String) async
    func disconnect() async
    func loadAssignedWorkouts() async
}
```

**`Presentation/Features/PersonalTrainer/PersonalTrainerView.swift`**
```swift
struct PersonalTrainerView: View {
    @Bindable var viewModel: PersonalTrainerViewModel
    // Shows: current trainer card, connection status, assigned workouts list
}
```

**`Presentation/Features/PersonalTrainer/TrainerSearchView.swift`**
```swift
struct TrainerSearchView: View {
    // Search by name or invite code
    // Show trainer cards with "Request Connection" button
}
```

**`Presentation/Features/PersonalTrainer/Components/TrainerCard.swift`**
```swift
struct TrainerCard: View {
    let trainer: PersonalTrainer
    let connectionStatus: TrainerConnectionStatus?
    let onConnect: () -> Void
}
```

**`Presentation/Features/PersonalTrainer/Components/ConnectionRequestSheet.swift`**
```swift
struct ConnectionRequestSheet: View {
    let trainer: PersonalTrainer
    let onConfirm: () -> Void
    let onCancel: () -> Void
}
```

### 5.2 Modifications

**`EntitlementPolicy.swift`**
```swift
enum ProFeature {
    // existing...
    case personalTrainer
    case trainerWorkouts
}
```

**`AppRouter.swift`**
```swift
enum Route {
    // existing...
    case personalTrainer
    case trainerSearch
    case trainerWorkouts
}
```

## 6. Dependency Registration

### AppContainer.swift Additions

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

// Update FeatureGating to include flag checking
container.register(FeatureGating.self) { resolver in
    FeatureGatingUseCase(
        entitlementRepository: resolver.resolve(EntitlementRepository.self)!,
        usageTracker: resolver.resolve(AIUsageTracking.self),
        featureFlagRepository: resolver.resolve(FeatureFlagRepository.self)
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

// ========== USE CASES ==========

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

## 7. Package Dependencies

### Package.swift / Xcode Project

Add to Firebase dependencies:
```swift
.product(name: "FirebaseRemoteConfig", package: "firebase-ios-sdk")
```

## 8. Security Rules (Firestore)

```javascript
// personalTrainers - public read, trainer write
match /personalTrainers/{trainerId} {
  allow read: if request.auth != null;
  allow write: if request.auth.uid == trainerId;
}

// trainerStudents - participants can read, student can create, trainer can update
match /trainerStudents/{relationId} {
  allow read: if request.auth != null &&
    (resource.data.trainerId == request.auth.uid ||
     resource.data.studentId == request.auth.uid);
  allow create: if request.auth != null &&
    request.resource.data.studentId == request.auth.uid;
  allow update: if request.auth != null &&
    resource.data.trainerId == request.auth.uid;
}

// trainerWorkouts - assigned students can read
match /trainerWorkouts/{workoutId} {
  allow read: if request.auth != null &&
    request.auth.uid in resource.data.assignedStudents;
  allow write: if request.auth != null &&
    resource.data.trainerId == request.auth.uid;
}
```

## 9. Error Handling

```swift
enum PersonalTrainerError: LocalizedError {
    case trainerNotFound
    case connectionAlreadyExists
    case notConnected
    case workoutSyncFailed
    case featureDisabled

    var errorDescription: String? {
        switch self {
        case .trainerNotFound:
            return "Personal trainer not found"
        case .connectionAlreadyExists:
            return "You already have a pending or active connection"
        case .notConnected:
            return "You are not connected to a trainer"
        case .workoutSyncFailed:
            return "Failed to sync trainer workouts"
        case .featureDisabled:
            return "This feature is not available"
        }
    }
}
```

## 10. Testing Strategy

### Unit Tests
- `RemoteConfigServiceTests`: Mock Firebase responses
- `FeatureFlagUseCaseTests`: Combination of flags + entitlements
- `PersonalTrainerMapperTests`: Validate all conversions
- `TrainerWorkoutMapperTests`: Critical - ensure WorkoutPlan compatibility

### Integration Tests
- Feature flag toggle in Firebase Console reflects in app
- Complete connection flow (request -> accept -> active)
- Workout sync end-to-end

## 11. Migration Notes

1. Users upgrading will have `personalTrainerId: null` by default
2. Feature flags default to `false` - no impact on existing users
3. No SwiftData schema changes required (uses Firestore only)
