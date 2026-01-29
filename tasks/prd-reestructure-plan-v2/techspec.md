# Technical Specification - FitToday App Restructure v2

> **Version:** 1.0
> **Date:** January 2026
> **Author:** AI-Generated from PRD
> **Status:** Draft

---

## 1. Overview

This document outlines the technical implementation details for the FitToday app restructure, covering API migration, new workout system, programs catalog, activity tracking, and AI-powered home screen.

---

## 2. Architecture

### 2.1 Current Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Presentation Layer                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Views     │  │  ViewModels │  │    Design System    │  │
│  │  (SwiftUI)  │  │ (@Observable)│  │   (FitTodayColor,  │  │
│  │             │  │             │  │   FitTodayFont...)  │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                       Domain Layer                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Entities  │  │  Use Cases  │  │   Protocols         │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                        Data Layer                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ Repositories│  │   Services  │  │      DTOs           │  │
│  │             │  │(Firebase,API)│  │                     │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 New Components to Add

| Layer | New Components |
|-------|---------------|
| **Presentation** | WorkoutTabView, ActivityTabView, HomeTabView (refactored), CreateWorkoutView, WorkoutExecutionView, ProgramsListView |
| **Domain** | WorkoutTemplate, WorkoutSession, WgerExercise, WorkoutProgram, UnifiedWorkoutSession |
| **Data** | WgerAPIService, ExerciseCacheManager, WorkoutSyncManager, WorkoutTemplateRepository |

---

## 3. Phase 1: Wger API Migration

### 3.1 Service Protocol

```swift
// Domain/Protocols/ExerciseServiceProtocol.swift
protocol ExerciseServiceProtocol: Sendable {
    func fetchExercises(language: String, category: Int?, equipment: [Int]?) async throws -> [Exercise]
    func fetchExerciseDetail(id: Int) async throws -> ExerciseDetail
    func searchExercises(query: String, language: String) async throws -> [Exercise]
}
```

### 3.2 Wger API Service Implementation

```swift
// Data/Services/WgerAPIService.swift
final class WgerAPIService: ExerciseServiceProtocol, Sendable {
    private let baseURL = "https://wger.de/api/v2"
    private let session: URLSession
    private let decoder: JSONDecoder

    // Language codes: 4 = Portuguese, 2 = English

    func fetchExercises(language: String, category: Int?, equipment: [Int]?) async throws -> [Exercise] {
        var components = URLComponents(string: "\(baseURL)/exercise/")!
        var queryItems = [URLQueryItem(name: "language", value: language)]

        if let category { queryItems.append(URLQueryItem(name: "category", value: "\(category)")) }
        if let equipment { equipment.forEach { queryItems.append(URLQueryItem(name: "equipment", value: "\($0)")) }}

        components.queryItems = queryItems
        // Implementation...
    }
}
```

### 3.3 Cache Strategy

```swift
// Data/Services/ExerciseCacheManager.swift
actor ExerciseCacheManager {
    private let fileManager: FileManager
    private let cacheDirectory: URL
    private let maxCacheAge: TimeInterval = 7 * 24 * 60 * 60 // 7 days

    func cacheExercises(_ exercises: [WgerExercise]) async throws
    func getCachedExercises() async throws -> [WgerExercise]?
    func cacheImage(_ data: Data, for exerciseId: Int) async throws
    func clearExpiredCache() async throws
}
```

### 3.4 Category Mapping

| Wger ID | Category | PT-BR Translation |
|---------|----------|-------------------|
| 8 | Arms | Braços |
| 9 | Legs | Pernas |
| 10 | Abs | Abdômen |
| 11 | Chest | Peito |
| 12 | Back | Costas |
| 13 | Shoulders | Ombros |
| 14 | Calves | Panturrilhas |
| 15 | Cardio | Cardio |

---

## 4. Phase 2: Workout System

### 4.1 Core Models

```swift
// Domain/Entities/WorkoutTemplate.swift
struct WorkoutTemplate: Identifiable, Codable, Sendable {
    let id: UUID
    var name: String
    var exercises: [WorkoutExercise]
    var notes: String?
    var colorTheme: String
    var iconName: String
    var createdAt: Date
    var updatedAt: Date
    var lastPerformedAt: Date?
    var timesCompleted: Int
    var estimatedDuration: Int
    var isFromProgram: Bool
    var programId: String?
}

// Domain/Entities/WorkoutExercise.swift
struct WorkoutExercise: Identifiable, Codable, Sendable {
    let id: UUID
    let exerciseId: Int
    var exerciseName: String
    var exerciseImageURL: String?
    var targetMuscle: String
    var equipment: String
    var sets: [ExerciseSet]
    var notes: String?
    var restSeconds: Int
    var order: Int
}

// Domain/Entities/ExerciseSet.swift
struct ExerciseSet: Identifiable, Codable, Sendable {
    let id: UUID
    var type: SetType
    var targetReps: Int
    var targetWeight: Double?
    var targetRPE: Int?
    var isCompleted: Bool
    var actualReps: Int?
    var actualWeight: Double?
}

enum SetType: String, Codable, CaseIterable, Sendable {
    case warmup = "Aquecimento"
    case working = "Normal"
    case dropset = "Drop Set"
    case failure = "Falha"
    case superSet = "Super Set"
}
```

### 4.2 Repository Pattern

```swift
// Domain/Protocols/WorkoutTemplateRepository.swift
protocol WorkoutTemplateRepository: Sendable {
    func fetchAll() async throws -> [WorkoutTemplate]
    func fetch(id: UUID) async throws -> WorkoutTemplate?
    func save(_ template: WorkoutTemplate) async throws
    func update(_ template: WorkoutTemplate) async throws
    func delete(id: UUID) async throws
}

// Data/Repositories/FirebaseWorkoutTemplateRepository.swift
final class FirebaseWorkoutTemplateRepository: WorkoutTemplateRepository {
    private let firestore: Firestore
    private let userId: String

    // Implementation with Firestore...
}
```

### 4.3 Views Hierarchy

```
WorkoutTabView
├── SegmentedControl (Meus Treinos | Programas)
├── MyWorkoutsView
│   ├── CreateWorkoutButton
│   ├── WorkoutTemplateCardList
│   └── EmptyStateView
└── ProgramsListView
    ├── ProgramFiltersView
    └── ProgramCardList

CreateWorkoutView
├── NameTextField
├── IconColorPicker
├── ExerciseList (draggable)
├── AddExerciseButton → ExerciseSearchSheet
└── SaveButton

ExerciseSearchSheet
├── SearchBar
├── FilterChips (Muscle, Equipment)
└── ExerciseResultsList

WorkoutExecutionView
├── Header (Timer, Progress)
├── CurrentExerciseCard
├── SetTrackingList
├── CompleteSetButton → RestTimerSheet
└── NavigationButtons (Previous, Next)

WorkoutSummaryView
├── CelebrationAnimation
├── StatsGrid (Duration, Volume, Sets)
├── ExerciseSummaryList
└── ActionButtons (Save, Share)
```

---

## 5. Phase 3: Programs Catalog

### 5.1 Program Models

```swift
// Domain/Entities/WorkoutProgram.swift
struct WorkoutProgram: Identifiable, Codable, Sendable {
    let id: String
    let name: String
    let description: String
    let level: FitnessLevel
    let goal: FitnessGoal
    let equipment: EquipmentType
    let daysPerWeek: Int
    let weeksTotal: Int
    let workoutTemplates: [ProgramWorkout]
    let imageURL: String?
    let isPremium: Bool
}

enum FitnessLevel: String, Codable, CaseIterable, Sendable {
    case beginner = "Iniciante"
    case intermediate = "Intermediário"
    case advanced = "Avançado"
}

enum FitnessGoal: String, Codable, CaseIterable, Sendable {
    case muscleGain = "Ganho de Massa"
    case strength = "Força"
    case weightLoss = "Perda de Peso"
    case endurance = "Resistência"
}

enum EquipmentType: String, Codable, CaseIterable, Sendable {
    case fullGym = "Academia Completa"
    case dumbbellOnly = "Apenas Halteres"
    case bodyweight = "Peso Corporal"
    case homeGym = "Academia em Casa"
}
```

### 5.2 Programs Catalog (26 Programs)

| Category | Beginner | Intermediate | Advanced | Total |
|----------|----------|--------------|----------|-------|
| Push Pull Legs | 1 | 1 | 1 | 3 |
| Full Body | 3 | 1 | 0 | 4 |
| Upper Lower | 1 | 2 | 1 | 4 |
| Bro Split | 0 | 1 | 1 | 2 |
| Strength | 1 | 1 | 0 | 2 |
| Weight Loss | 1 | 1 | 1 | 3 |
| Home Gym | 1 | 1 | 0 | 2 |
| Specialized | 2 | 3 | 1 | 6 |
| **Total** | **10** | **11** | **5** | **26** |

---

## 6. Phase 4: Activity & Sync

### 6.1 Unified Workout Session

```swift
// Domain/Entities/UnifiedWorkoutSession.swift
struct UnifiedWorkoutSession: Identifiable, Codable, Sendable {
    let id: String
    let userId: String
    var name: String
    var templateId: String?
    var programId: String?
    var startedAt: Date
    var completedAt: Date?
    var duration: TimeInterval
    var totalVolume: Double
    var totalSets: Int
    var totalReps: Int
    var caloriesBurned: Double?
    var avgHeartRate: Double?
    var exercises: [CompletedExercise]
    var source: WorkoutSource
    var healthKitId: UUID?
    var challengeContributions: [ChallengeContribution]
}

enum WorkoutSource: String, Codable, Sendable {
    case app
    case healthKit = "health_kit"
    case merged
}
```

### 6.2 Sync Manager

```swift
// Data/Services/WorkoutSyncManager.swift
@Observable
final class WorkoutSyncManager {
    private let healthKitService: HealthKitService
    private let firestoreService: FirestoreService
    private let challengeService: ChallengeService

    var syncStatus: SyncStatus = .idle
    var lastSyncDate: Date?

    @MainActor
    func syncWorkouts() async throws {
        syncStatus = .syncing

        // 1. Fetch HealthKit workouts (last 30 days)
        // 2. Fetch Firebase workouts
        // 3. Merge avoiding duplicates
        // 4. Save new/updated workouts
        // 5. Update challenge progress

        syncStatus = .completed
        lastSyncDate = Date()
    }
}

enum SyncStatus: Equatable, Sendable {
    case idle
    case syncing
    case completed
    case failed(String)
}
```

### 6.3 Activity Tab Structure

```
ActivityTabView
├── SegmentedControl (Histórico | Desafios | Stats)
├── WorkoutHistoryView
│   ├── MonthCalendarView (highlighted workout days)
│   ├── WorkoutSessionList
│   └── EmptyStateView
├── ChallengesListView
│   ├── ActiveChallengesSection
│   ├── CompletedChallengesSection
│   └── JoinChallengeButton
└── StatsView
    ├── WeeklyStatsChart
    ├── MonthlyVolumeChart
    └── PersonalRecordsSection
```

---

## 7. Phase 5: AI-Powered Home

### 7.1 AI Workout Generator

```swift
// Domain/UseCases/AIWorkoutGenerator.swift
final class AIWorkoutGenerator: Sendable {
    private let openAIService: OpenAIService
    private let wgerService: WgerAPIService

    struct GenerationInput: Sendable {
        let targetMuscles: [MuscleGroup]
        let fatigueLevel: Int // 1-5
        let availableTime: Int // minutes
        let equipment: EquipmentType
        let fitnessLevel: FitnessLevel
        let recentWorkouts: [UnifiedWorkoutSession]
    }

    func generateWorkout(input: GenerationInput) async throws -> GeneratedWorkout {
        // 1. Fetch available exercises from Wger
        // 2. Build optimized prompt
        // 3. Call OpenAI with JSON response format
        // 4. Parse response into structured workout
    }
}

struct GeneratedWorkout: Sendable {
    let name: String
    let exercises: [WorkoutExercise]
    let estimatedDuration: Int
    let warmupIncluded: Bool
    let focusAreas: [String]
}
```

### 7.2 Muscle Group Mapping

```swift
// Domain/Entities/MuscleGroup.swift
enum MuscleGroup: String, CaseIterable, Codable, Sendable {
    case chest = "Peito"
    case back = "Costas"
    case shoulders = "Ombros"
    case biceps = "Bíceps"
    case triceps = "Tríceps"
    case legs = "Pernas"
    case core = "Abdômen"
    case glutes = "Glúteos"

    var wgerCategoryId: Int {
        switch self {
        case .chest: return 11
        case .back: return 12
        case .shoulders: return 13
        case .biceps, .triceps: return 8
        case .legs, .glutes: return 9
        case .core: return 10
        }
    }

    var icon: String {
        switch self {
        case .chest: return "figure.strengthtraining.traditional"
        case .back: return "figure.rowing"
        case .shoulders: return "figure.arms.open"
        case .biceps, .triceps: return "figure.boxing"
        case .legs, .glutes: return "figure.run"
        case .core: return "figure.core.training"
        }
    }
}
```

### 7.3 Home Tab Structure

```
HomeTabView
├── GreetingSection
├── AIWorkoutInputCard
│   ├── MuscleSelectionGrid
│   ├── FatigueSlider
│   ├── TimeSelectionChips
│   └── GenerateButton
├── ContinueWorkoutCard (if in progress)
├── StreakProgressBar
└── WeeklySummaryCard
```

---

## 8. TabBar Restructure

### 8.1 New Structure

```swift
// Presentation/Root/TabRootView.swift
enum AppTab: String, CaseIterable {
    case home
    case workout
    case quickStart // Center button
    case activity
    case profile

    var title: String {
        switch self {
        case .home: return "Home"
        case .workout: return "Workout"
        case .quickStart: return ""
        case .activity: return "Activity"
        case .profile: return "Profile"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .workout: return "dumbbell.fill"
        case .quickStart: return "plus.circle.fill"
        case .activity: return "chart.bar.fill"
        case .profile: return "person.fill"
        }
    }
}
```

---

## 9. Firebase Structure

```
firestore/
├── users/{userId}/
│   ├── profile/data
│   ├── workoutTemplates/{templateId}
│   ├── workoutSessions/{sessionId}
│   ├── challenges/{challengeId}/
│   │   ├── data
│   │   └── progress
│   ├── stats/weekly/{weekId}
│   └── settings/preferences
├── programs/{programId} (read-only)
├── exerciseCache/{language}/exercises
└── publicChallenges/{challengeId}
```

---

## 10. Dependencies

### 10.1 External Dependencies

| Dependency | Purpose | Version |
|------------|---------|---------|
| Firebase | Auth, Firestore | Latest |
| HealthKit | Health data sync | iOS 17+ |
| OpenAI API | Workout generation | v1 |
| Wger API | Exercise database | v2 |

### 10.2 Internal Dependencies

```
WgerAPIService ← ExerciseCacheManager
WorkoutSyncManager ← HealthKitService, FirestoreService, ChallengeService
AIWorkoutGenerator ← OpenAIService, WgerAPIService
WorkoutExecutionView ← WorkoutSessionStore, RestTimerStore
```

---

## 11. Testing Strategy

### 11.1 Unit Tests

- [ ] WgerAPIService: API parsing, caching
- [ ] WorkoutTemplate: CRUD operations
- [ ] ExerciseCacheManager: Cache expiration, storage
- [ ] AIWorkoutGenerator: Prompt building, response parsing
- [ ] WorkoutSyncManager: Merge logic, duplicate detection

### 11.2 Integration Tests

- [ ] Wger API integration
- [ ] HealthKit sync flow
- [ ] Firebase CRUD operations

### 11.3 UI Tests

- [ ] Workout creation flow
- [ ] Workout execution flow
- [ ] AI generation flow

---

## 12. Localization

All user-facing strings must support:
- Portuguese (PT-BR) - Primary
- English (EN) - Secondary

Use `LocalizedStringKey` for all text content.

---

## 13. Performance Considerations

1. **Exercise Cache**: 7-day TTL, lazy image loading
2. **Pagination**: Max 50 items per API request
3. **Background Sync**: Use BackgroundTasks framework
4. **Image Caching**: Use `CachedAsyncImage` component
5. **List Performance**: Use `LazyVStack` for long lists

---

**Last Updated:** January 2026
**Document Version:** 1.0
