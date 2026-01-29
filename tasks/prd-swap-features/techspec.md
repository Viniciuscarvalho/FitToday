# Technical Specification: Treinos Dinâmicos

## Architecture Overview

This feature follows FitToday's established MVVM + Clean Architecture pattern:

```
Presentation Layer (UI)
    ├── Views/
    │   ├── CustomWorkoutBuilderView
    │   ├── ExercisePickerView
    │   ├── ActiveCustomWorkoutView
    │   └── CustomWorkoutTemplatesView
    └── ViewModels/
        ├── CustomWorkoutBuilderViewModel
        ├── ExercisePickerViewModel
        ├── ActiveCustomWorkoutViewModel
        └── CustomWorkoutTemplatesViewModel

Domain Layer (Business Logic)
    ├── Entities/
    │   ├── CustomWorkoutTemplate
    │   ├── CustomExerciseEntry
    │   └── WorkoutSet
    ├── Protocols/
    │   └── CustomWorkoutRepository
    └── UseCases/
        ├── SaveCustomWorkoutUseCase
        ├── StartCustomWorkoutUseCase
        └── CompleteCustomWorkoutUseCase

Data Layer (Persistence)
    ├── SwiftData/
    │   ├── SDCustomWorkoutTemplate
    │   └── SDCustomExerciseEntry
    └── Repositories/
        └── SwiftDataCustomWorkoutRepository
```

## Data Model Details

### Domain Entities

```swift
// Domain/Entities/CustomWorkoutTemplate.swift
struct CustomWorkoutTemplate: Identifiable, Codable, Sendable {
    let id: UUID
    var name: String
    var exercises: [CustomExerciseEntry]
    var createdAt: Date
    var lastUsedAt: Date?

    var estimatedDurationMinutes: Int {
        // ~2 min per set average
        exercises.reduce(0) { $0 + $1.sets.count * 2 }
    }

    var totalSets: Int {
        exercises.reduce(0) { $0 + $1.sets.count }
    }
}

// Domain/Entities/CustomExerciseEntry.swift
struct CustomExerciseEntry: Identifiable, Codable, Sendable {
    let id: UUID
    var exerciseId: String      // ExerciseDB ID
    var exerciseName: String    // Cached name
    var exerciseGifURL: String? // Cached GIF URL
    var orderIndex: Int
    var sets: [WorkoutSet]
    var notes: String?

    init(from exercise: Exercise, orderIndex: Int) {
        self.id = UUID()
        self.exerciseId = exercise.id
        self.exerciseName = exercise.name
        self.exerciseGifURL = exercise.gifUrl
        self.orderIndex = orderIndex
        self.sets = [WorkoutSet()] // Start with 1 empty set
        self.notes = nil
    }
}

// Domain/Entities/WorkoutSet.swift
struct WorkoutSet: Identifiable, Codable, Sendable {
    let id: UUID
    var targetReps: Int?
    var targetWeight: Double?
    var targetDuration: TimeInterval?
    var actualReps: Int?
    var actualWeight: Double?
    var isCompleted: Bool

    init() {
        self.id = UUID()
        self.targetReps = 10
        self.targetWeight = nil
        self.targetDuration = nil
        self.actualReps = nil
        self.actualWeight = nil
        self.isCompleted = false
    }
}
```

### SwiftData Models

```swift
// Data/SwiftData/SDCustomWorkoutTemplate.swift
@Model
final class SDCustomWorkoutTemplate {
    @Attribute(.unique) var id: UUID
    var name: String
    var exercises: [SDCustomExerciseEntry]
    var createdAt: Date
    var lastUsedAt: Date?

    init(from domain: CustomWorkoutTemplate) {
        self.id = domain.id
        self.name = domain.name
        self.exercises = domain.exercises.map { SDCustomExerciseEntry(from: $0) }
        self.createdAt = domain.createdAt
        self.lastUsedAt = domain.lastUsedAt
    }

    func toDomain() -> CustomWorkoutTemplate {
        CustomWorkoutTemplate(
            id: id,
            name: name,
            exercises: exercises.map { $0.toDomain() },
            createdAt: createdAt,
            lastUsedAt: lastUsedAt
        )
    }
}

@Model
final class SDCustomExerciseEntry {
    var id: UUID
    var exerciseId: String
    var exerciseName: String
    var exerciseGifURL: String?
    var orderIndex: Int
    var setsData: Data // JSON encoded [WorkoutSet]
    var notes: String?

    // ... init and toDomain methods
}
```

## Repository Protocol

```swift
// Domain/Protocols/CustomWorkoutRepository.swift
protocol CustomWorkoutRepository: Sendable {
    /// Fetches all saved workout templates
    func listTemplates() async throws -> [CustomWorkoutTemplate]

    /// Fetches a single template by ID
    func getTemplate(id: UUID) async throws -> CustomWorkoutTemplate?

    /// Saves or updates a template
    func saveTemplate(_ template: CustomWorkoutTemplate) async throws

    /// Deletes a template
    func deleteTemplate(id: UUID) async throws

    /// Records a completed custom workout session
    func recordCompletion(
        templateId: UUID,
        actualSets: [CustomExerciseEntry],
        duration: Int,
        completedAt: Date
    ) async throws
}
```

## Use Cases

### SaveCustomWorkoutUseCase

```swift
struct SaveCustomWorkoutUseCase: Sendable {
    private let repository: CustomWorkoutRepository

    func execute(template: CustomWorkoutTemplate) async throws {
        // Validation
        guard !template.name.isEmpty else {
            throw CustomWorkoutError.emptyName
        }
        guard !template.exercises.isEmpty else {
            throw CustomWorkoutError.noExercises
        }

        try await repository.saveTemplate(template)
    }
}
```

### CompleteCustomWorkoutUseCase

```swift
struct CompleteCustomWorkoutUseCase: Sendable {
    private let repository: CustomWorkoutRepository
    private let historyRepository: WorkoutHistoryRepository
    private let syncWorkoutUseCase: SyncWorkoutCompletionUseCase?
    private let healthKitUseCase: SyncWorkoutWithHealthKitUseCase?

    func execute(
        template: CustomWorkoutTemplate,
        actualExercises: [CustomExerciseEntry],
        startTime: Date,
        endTime: Date
    ) async throws {
        let durationMinutes = Int(endTime.timeIntervalSince(startTime) / 60)

        // 1. Record completion in custom workout repository
        try await repository.recordCompletion(
            templateId: template.id,
            actualSets: actualExercises,
            duration: durationMinutes,
            completedAt: endTime
        )

        // 2. Create history entry for general tracking
        let historyEntry = WorkoutHistoryEntry(
            id: UUID(),
            date: endTime,
            planId: template.id, // Use template ID as plan ID
            title: template.name,
            focus: .fullBody,
            status: .completed,
            durationMinutes: durationMinutes,
            caloriesBurned: nil,
            source: .manual
        )

        try await historyRepository.saveEntry(historyEntry)

        // 3. Sync to HealthKit
        try await healthKitUseCase?.execute(entry: historyEntry)

        // 4. Sync to challenges (if >= 30 min)
        if durationMinutes >= 30 {
            await syncWorkoutUseCase?.execute(entry: historyEntry)
        }
    }
}
```

## View Models

### CustomWorkoutBuilderViewModel

```swift
@Observable
@MainActor
final class CustomWorkoutBuilderViewModel {
    var name: String = ""
    var exercises: [CustomExerciseEntry] = []
    var isLoading = false
    var error: Error?
    var showExercisePicker = false

    private let saveUseCase: SaveCustomWorkoutUseCase
    private let exerciseService: ExerciseDBServicing?

    // MARK: - Actions

    func addExercise(_ exercise: Exercise) {
        let entry = CustomExerciseEntry(
            from: exercise,
            orderIndex: exercises.count
        )
        exercises.append(entry)
    }

    func removeExercise(at index: Int) {
        exercises.remove(at: index)
        reorderExercises()
    }

    func moveExercise(from source: IndexSet, to destination: Int) {
        exercises.move(fromOffsets: source, toOffset: destination)
        reorderExercises()
    }

    func addSet(to exerciseIndex: Int) {
        guard exerciseIndex < exercises.count else { return }
        exercises[exerciseIndex].sets.append(WorkoutSet())
    }

    func removeSet(from exerciseIndex: Int, at setIndex: Int) {
        guard exerciseIndex < exercises.count else { return }
        exercises[exerciseIndex].sets.remove(at: setIndex)
    }

    func save() async throws -> CustomWorkoutTemplate {
        let template = CustomWorkoutTemplate(
            id: UUID(),
            name: name,
            exercises: exercises,
            createdAt: Date(),
            lastUsedAt: nil
        )
        try await saveUseCase.execute(template: template)
        return template
    }

    private func reorderExercises() {
        for i in exercises.indices {
            exercises[i].orderIndex = i
        }
    }
}
```

### ExercisePickerViewModel

```swift
@Observable
@MainActor
final class ExercisePickerViewModel {
    var searchText: String = ""
    var selectedBodyPart: BodyPart?
    var selectedEquipment: Equipment?
    var exercises: [Exercise] = []
    var recentExercises: [Exercise] = []
    var isLoading = false

    private let exerciseService: ExerciseDBServicing
    private var searchTask: Task<Void, Never>?

    func search() {
        searchTask?.cancel()
        searchTask = Task {
            isLoading = true
            defer { isLoading = false }

            do {
                if searchText.isEmpty && selectedBodyPart == nil {
                    exercises = try await exerciseService.fetchExercises(limit: 50)
                } else if let bodyPart = selectedBodyPart {
                    exercises = try await exerciseService.fetchExercises(
                        bodyPart: bodyPart.rawValue,
                        limit: 50
                    )
                } else {
                    exercises = try await exerciseService.searchExercises(
                        query: searchText,
                        limit: 50
                    )
                }

                // Filter by equipment if selected
                if let equipment = selectedEquipment {
                    exercises = exercises.filter { $0.equipment == equipment.rawValue }
                }
            } catch {
                // Handle error
            }
        }
    }
}
```

## UI Components

### CustomWorkoutBuilderView

```swift
struct CustomWorkoutBuilderView: View {
    @State private var viewModel: CustomWorkoutBuilderViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Workout Name") {
                    TextField("e.g., Push Day", text: $viewModel.name)
                }

                Section("Exercises") {
                    ForEach(Array(viewModel.exercises.enumerated()), id: \.element.id) { index, exercise in
                        ExerciseRowView(
                            exercise: exercise,
                            onAddSet: { viewModel.addSet(to: index) },
                            onRemoveSet: { setIndex in
                                viewModel.removeSet(from: index, at: setIndex)
                            }
                        )
                    }
                    .onMove { viewModel.moveExercise(from: $0, to: $1) }
                    .onDelete { indexSet in
                        indexSet.forEach { viewModel.removeExercise(at: $0) }
                    }

                    Button("Add Exercise") {
                        viewModel.showExercisePicker = true
                    }
                }
            }
            .navigationTitle("Create Workout")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            try await viewModel.save()
                            dismiss()
                        }
                    }
                    .disabled(viewModel.name.isEmpty || viewModel.exercises.isEmpty)
                }
            }
            .sheet(isPresented: $viewModel.showExercisePicker) {
                ExercisePickerView { exercise in
                    viewModel.addExercise(exercise)
                }
            }
        }
    }
}
```

## DI Registration

```swift
// In AppContainer.swift

// Custom Workout Repository
container.register(CustomWorkoutRepository.self) { resolver in
    SwiftDataCustomWorkoutRepository(
        modelContainer: resolver.resolve(ModelContainer.self)!
    )
}.inObjectScope(.container)

// Save Custom Workout Use Case
container.register(SaveCustomWorkoutUseCase.self) { resolver in
    SaveCustomWorkoutUseCase(
        repository: resolver.resolve(CustomWorkoutRepository.self)!
    )
}.inObjectScope(.container)

// Complete Custom Workout Use Case
container.register(CompleteCustomWorkoutUseCase.self) { resolver in
    CompleteCustomWorkoutUseCase(
        repository: resolver.resolve(CustomWorkoutRepository.self)!,
        historyRepository: resolver.resolve(WorkoutHistoryRepository.self)!,
        syncWorkoutUseCase: resolver.resolve(SyncWorkoutCompletionUseCase.self),
        healthKitUseCase: resolver.resolve(SyncWorkoutWithHealthKitUseCase.self)
    )
}.inObjectScope(.container)
```

## GIF Optimization

Use existing `ImageCacheService` with fallback:

```swift
struct ExerciseGifView: View {
    let gifURL: String?
    @State private var loadState: LoadState = .loading

    enum LoadState {
        case loading
        case loaded(UIImage)
        case failed
    }

    var body: some View {
        Group {
            switch loadState {
            case .loading:
                ProgressView()
            case .loaded(let image):
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            case .failed:
                Image(systemName: "figure.run")
                    .foregroundColor(.secondary)
            }
        }
        .task {
            await loadGif()
        }
    }

    private func loadGif() async {
        guard let urlString = gifURL,
              let url = URL(string: urlString) else {
            loadState = .failed
            return
        }

        // Try cache first
        if let cached = await ImageCacheService.shared.image(for: url) {
            loadState = .loaded(cached)
            return
        }

        // Fetch and cache
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                await ImageCacheService.shared.store(image, for: url)
                loadState = .loaded(image)
            } else {
                loadState = .failed
            }
        } catch {
            loadState = .failed
        }
    }
}
```

## Testing Strategy

### Unit Tests

1. `CustomWorkoutTemplateTests` - Entity validation
2. `SaveCustomWorkoutUseCaseTests` - Business rules
3. `CompleteCustomWorkoutUseCaseTests` - Integration with history
4. `CustomWorkoutBuilderViewModelTests` - State management

### Integration Tests

1. Repository CRUD operations
2. Challenge sync after completion
3. HealthKit export

## Migration Plan

No migration needed - new SwiftData models are additive:

```swift
// Update Schema in AppContainer
let schema = Schema([
    SDUserProfile.self,
    SDWorkoutHistoryEntry.self,
    SDProEntitlementSnapshot.self,
    SDCachedWorkout.self,
    SDUserStats.self,
    SDCustomWorkoutTemplate.self,  // NEW
    SDCustomExerciseEntry.self     // NEW
])
```

## File Structure

```
FitToday/
├── Domain/
│   ├── Entities/
│   │   ├── CustomWorkoutTemplate.swift
│   │   ├── CustomExerciseEntry.swift
│   │   └── WorkoutSet.swift
│   ├── Protocols/
│   │   └── CustomWorkoutRepository.swift
│   └── UseCases/
│       ├── SaveCustomWorkoutUseCase.swift
│       └── CompleteCustomWorkoutUseCase.swift
├── Data/
│   └── SwiftData/
│       ├── SDCustomWorkoutTemplate.swift
│       └── SwiftDataCustomWorkoutRepository.swift
└── Presentation/
    └── Features/
        └── CustomWorkout/
            ├── Views/
            │   ├── CustomWorkoutBuilderView.swift
            │   ├── ExercisePickerView.swift
            │   ├── ActiveCustomWorkoutView.swift
            │   └── CustomWorkoutTemplatesView.swift
            ├── ViewModels/
            │   ├── CustomWorkoutBuilderViewModel.swift
            │   ├── ExercisePickerViewModel.swift
            │   ├── ActiveCustomWorkoutViewModel.swift
            │   └── CustomWorkoutTemplatesViewModel.swift
            └── Components/
                ├── ExerciseRowView.swift
                ├── SetConfigurationRow.swift
                └── ExerciseGifView.swift
```
