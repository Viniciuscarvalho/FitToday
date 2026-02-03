# Tech Spec: Migrar Programas para API Wger

## Visão Geral

Migrar o carregamento de exercícios dos programas de treino para usar a API Wger, mantendo os metadados dos programas no JSON seed.

## Arquitetura

### Camadas

```
┌─────────────────────────────────────────────────────────────┐
│                     Presentation Layer                       │
│  ProgramsListView → ProgramDetailView → WorkoutExercisesView │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Domain Layer                            │
│  LoadProgramUseCase    LoadWorkoutExercisesUseCase          │
│  SaveWorkoutCustomizationUseCase                            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                       Data Layer                             │
│  BundleProgramRepository   WgerProgramWorkoutRepository     │
│  WgerAPIService            UserDefaultsStorage              │
└─────────────────────────────────────────────────────────────┘
```

## Novos Componentes

### 1. WorkoutTemplateType (Enum)

```swift
// File: Domain/Entities/WorkoutTemplateType.swift

/// Tipo de template de treino para mapeamento com categorias Wger
enum WorkoutTemplateType: String, CaseIterable, Sendable {
    case push
    case pull
    case legs
    case fullbody
    case core
    case hiit
    case upper
    case lower
    case conditioning

    /// IDs das categorias Wger correspondentes
    var wgerCategoryIds: [Int] {
        switch self {
        case .push:
            return [11, 13, 5]      // Chest, Shoulders, Triceps
        case .pull:
            return [12, 1]          // Back, Biceps
        case .legs:
            return [9, 8, 14]       // Legs, Glutes, Calves
        case .fullbody:
            return [11, 12, 9, 10, 13, 1, 5]
        case .core:
            return [10]             // Abs
        case .hiit, .conditioning:
            return [11, 9, 10]      // Compound focus
        case .upper:
            return [11, 12, 13, 1, 5]
        case .lower:
            return [9, 8, 14]
        }
    }

    /// Extrai o tipo do ID do template
    static func from(templateId: String) -> WorkoutTemplateType? {
        let lowered = templateId.lowercased()
        return allCases.first { lowered.contains($0.rawValue) }
    }
}
```

### 2. ProgramWorkout (Entity)

```swift
// File: Domain/Entities/ProgramWorkout.swift

/// Um treino dentro de um programa com exercícios da Wger
struct ProgramWorkout: Identifiable, Sendable {
    let id: String
    let templateId: String
    let title: String
    let subtitle: String
    let estimatedDurationMinutes: Int
    let exercises: [ProgramExercise]

    struct ProgramExercise: Identifiable, Sendable {
        let id: String
        let wgerExercise: WgerExercise
        let sets: Int
        let repsRange: ClosedRange<Int>
        let restSeconds: Int
        let notes: String?
        var order: Int
    }
}
```

### 3. WgerProgramWorkoutRepository (Protocol + Implementation)

```swift
// File: Domain/Repositories/WgerProgramWorkoutRepository.swift

protocol WgerProgramWorkoutRepository: Sendable {
    /// Carrega exercícios Wger para um template de workout
    func loadWorkoutExercises(
        templateId: String,
        exerciseCount: Int
    ) async throws -> [WgerExercise]

    /// Salva customização do usuário
    func saveCustomization(
        programId: String,
        workoutId: String,
        exerciseIds: [Int],
        order: [Int]
    ) async throws

    /// Carrega customização do usuário
    func loadCustomization(
        programId: String,
        workoutId: String
    ) async throws -> WorkoutCustomization?
}

struct WorkoutCustomization: Codable, Sendable {
    let exerciseIds: [Int]
    let order: [Int]
    let updatedAt: Date
}
```

```swift
// File: Data/Repositories/DefaultWgerProgramWorkoutRepository.swift

actor DefaultWgerProgramWorkoutRepository: WgerProgramWorkoutRepository {
    private let wgerService: ExerciseServiceProtocol
    private let storage: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private var exerciseCache: [Int: [WgerExercise]] = [:] // categoryId -> exercises

    init(wgerService: ExerciseServiceProtocol, storage: UserDefaults = .standard) {
        self.wgerService = wgerService
        self.storage = storage
    }

    func loadWorkoutExercises(templateId: String, exerciseCount: Int = 8) async throws -> [WgerExercise] {
        guard let templateType = WorkoutTemplateType.from(templateId: templateId) else {
            throw WgerProgramError.unknownTemplate(templateId)
        }

        var allExercises: [WgerExercise] = []

        for categoryId in templateType.wgerCategoryIds {
            let exercises = try await loadExercisesForCategory(categoryId)
            allExercises.append(contentsOf: exercises)
        }

        // Shuffle e limitar ao count desejado
        return Array(allExercises.shuffled().prefix(exerciseCount))
    }

    private func loadExercisesForCategory(_ categoryId: Int) async throws -> [WgerExercise] {
        if let cached = exerciseCache[categoryId] {
            return cached
        }

        let exercises = try await wgerService.fetchExercises(
            language: .portuguese,
            category: categoryId,
            equipment: nil,
            limit: 50
        )

        exerciseCache[categoryId] = exercises
        return exercises
    }

    func saveCustomization(programId: String, workoutId: String, exerciseIds: [Int], order: [Int]) async throws {
        let key = customizationKey(programId: programId, workoutId: workoutId)
        let customization = WorkoutCustomization(
            exerciseIds: exerciseIds,
            order: order,
            updatedAt: Date()
        )
        let data = try encoder.encode(customization)
        storage.set(data, forKey: key)
    }

    func loadCustomization(programId: String, workoutId: String) async throws -> WorkoutCustomization? {
        let key = customizationKey(programId: programId, workoutId: workoutId)
        guard let data = storage.data(forKey: key) else { return nil }
        return try decoder.decode(WorkoutCustomization.self, from: data)
    }

    private func customizationKey(programId: String, workoutId: String) -> String {
        "workout_customization_\(programId)_\(workoutId)"
    }
}

enum WgerProgramError: LocalizedError {
    case unknownTemplate(String)
    case exercisesNotFound
    case apiError(Error)

    var errorDescription: String? {
        switch self {
        case .unknownTemplate(let id):
            return "Template desconhecido: \(id)"
        case .exercisesNotFound:
            return "Nenhum exercício encontrado"
        case .apiError(let error):
            return "Erro na API: \(error.localizedDescription)"
        }
    }
}
```

### 4. LoadProgramWorkoutsUseCase

```swift
// File: Domain/UseCases/LoadProgramWorkoutsUseCase.swift

struct LoadProgramWorkoutsUseCase: Sendable {
    private let programRepository: ProgramRepository
    private let workoutRepository: WgerProgramWorkoutRepository

    init(programRepository: ProgramRepository, workoutRepository: WgerProgramWorkoutRepository) {
        self.programRepository = programRepository
        self.workoutRepository = workoutRepository
    }

    func execute(programId: String) async throws -> [ProgramWorkout] {
        guard let program = try await programRepository.getProgram(id: programId) else {
            throw LoadProgramError.programNotFound
        }

        var workouts: [ProgramWorkout] = []

        for (index, templateId) in program.workoutTemplateIds.enumerated() {
            let exercises = try await workoutRepository.loadWorkoutExercises(
                templateId: templateId,
                exerciseCount: 8
            )

            let programExercises = exercises.enumerated().map { offset, exercise in
                ProgramWorkout.ProgramExercise(
                    id: "\(templateId)_\(exercise.id)",
                    wgerExercise: exercise,
                    sets: 4,
                    repsRange: 8...12,
                    restSeconds: 90,
                    notes: nil,
                    order: offset
                )
            }

            let workout = ProgramWorkout(
                id: "\(programId)_\(index)",
                templateId: templateId,
                title: workoutTitle(for: templateId, index: index),
                subtitle: workoutSubtitle(for: templateId),
                estimatedDurationMinutes: program.estimatedMinutesPerSession,
                exercises: programExercises
            )

            workouts.append(workout)
        }

        return workouts
    }

    private func workoutTitle(for templateId: String, index: Int) -> String {
        let type = WorkoutTemplateType.from(templateId: templateId)
        switch type {
        case .push: return "Treino \(index + 1) - Push"
        case .pull: return "Treino \(index + 1) - Pull"
        case .legs: return "Treino \(index + 1) - Legs"
        case .fullbody: return "Treino \(index + 1) - Full Body"
        case .core: return "Treino \(index + 1) - Core"
        case .upper: return "Treino \(index + 1) - Superior"
        case .lower: return "Treino \(index + 1) - Inferior"
        default: return "Treino \(index + 1)"
        }
    }

    private func workoutSubtitle(for templateId: String) -> String {
        let type = WorkoutTemplateType.from(templateId: templateId)
        switch type {
        case .push: return "Peito, Ombros e Tríceps"
        case .pull: return "Costas e Bíceps"
        case .legs: return "Quadríceps, Glúteos e Panturrilha"
        case .fullbody: return "Corpo Inteiro"
        case .core: return "Abdômen e Core"
        case .upper: return "Parte Superior"
        case .lower: return "Parte Inferior"
        default: return "Treino Completo"
        }
    }
}

enum LoadProgramError: LocalizedError {
    case programNotFound

    var errorDescription: String? {
        switch self {
        case .programNotFound:
            return "Programa não encontrado"
        }
    }
}
```

### 5. ProgramDetailViewModel (Atualizado)

```swift
// File: Presentation/Features/Programs/ViewModels/ProgramDetailViewModel.swift

@MainActor
@Observable
final class ProgramDetailViewModel {
    private(set) var program: Program?
    private(set) var workouts: [ProgramWorkout] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let programId: String
    private let loadProgramWorkoutsUseCase: LoadProgramWorkoutsUseCase
    private let programRepository: ProgramRepository

    init(
        programId: String,
        loadProgramWorkoutsUseCase: LoadProgramWorkoutsUseCase,
        programRepository: ProgramRepository
    ) {
        self.programId = programId
        self.loadProgramWorkoutsUseCase = loadProgramWorkoutsUseCase
        self.programRepository = programRepository
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            program = try await programRepository.getProgram(id: programId)
            workouts = try await loadProgramWorkoutsUseCase.execute(programId: programId)

            #if DEBUG
            print("[ProgramDetail] Loaded \(workouts.count) workouts with Wger exercises")
            for workout in workouts {
                print("[ProgramDetail] - \(workout.title): \(workout.exercises.count) exercises")
            }
            #endif
        } catch {
            errorMessage = error.localizedDescription
            #if DEBUG
            print("[ProgramDetail] Error: \(error)")
            #endif
        }
    }
}
```

### 6. ProgramWorkoutDetailView (Nova)

```swift
// File: Presentation/Features/Programs/Views/ProgramWorkoutDetailView.swift

struct ProgramWorkoutDetailView: View {
    let workout: ProgramWorkout
    let resolver: Resolver

    @State private var exercises: [ProgramWorkout.ProgramExercise]
    @State private var isEditMode = false

    init(workout: ProgramWorkout, resolver: Resolver) {
        self.workout = workout
        self.resolver = resolver
        _exercises = State(initialValue: workout.exercises)
    }

    var body: some View {
        List {
            ForEach(exercises) { exercise in
                ExerciseRowView(exercise: exercise)
            }
            .onMove { from, to in
                exercises.move(fromOffsets: from, toOffset: to)
            }
            .onDelete { indexSet in
                exercises.remove(atOffsets: indexSet)
            }
        }
        .navigationTitle(workout.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                EditButton()
            }
        }
    }
}

struct ExerciseRowView: View {
    let exercise: ProgramWorkout.ProgramExercise

    var body: some View {
        HStack(spacing: FitTodaySpacing.md) {
            // Exercise image from Wger
            AsyncImage(url: exercise.wgerExercise.images.first?.image.flatMap(URL.init)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 24))
                    .foregroundStyle(FitTodayColor.textTertiary)
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.wgerExercise.name)
                    .font(FitTodayFont.ui(size: 15, weight: .semiBold))
                    .foregroundStyle(FitTodayColor.textPrimary)

                Text("\(exercise.sets) séries × \(exercise.repsRange.lowerBound)-\(exercise.repsRange.upperBound) reps")
                    .font(FitTodayFont.ui(size: 13, weight: .medium))
                    .foregroundStyle(FitTodayColor.textSecondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}
```

## Registro de Dependências

```swift
// AppContainer.swift - adicionar

// WgerProgramWorkoutRepository
let wgerProgramRepo = DefaultWgerProgramWorkoutRepository(wgerService: wgerService)
container.register(WgerProgramWorkoutRepository.self) { _ in wgerProgramRepo }
    .inObjectScope(.container)

// LoadProgramWorkoutsUseCase
container.register(LoadProgramWorkoutsUseCase.self) { r in
    LoadProgramWorkoutsUseCase(
        programRepository: r.resolve(ProgramRepository.self)!,
        workoutRepository: r.resolve(WgerProgramWorkoutRepository.self)!
    )
}
```

## Wger Category IDs Reference

| ID | Category |
|----|----------|
| 1  | Biceps |
| 5  | Triceps |
| 8  | Glutes |
| 9  | Legs |
| 10 | Abs |
| 11 | Chest |
| 12 | Back |
| 13 | Shoulders |
| 14 | Calves |

## Fluxo de Dados

```
User taps Program
       │
       ▼
ProgramDetailView.task()
       │
       ▼
ProgramDetailViewModel.load()
       │
       ├──► programRepository.getProgram(id)
       │           │
       │           ▼
       │    Program (from JSON seed)
       │
       └──► loadProgramWorkoutsUseCase.execute(programId)
                   │
                   ▼
            For each templateId in program.workoutTemplateIds:
                   │
                   ▼
            workoutRepository.loadWorkoutExercises(templateId)
                   │
                   ▼
            WorkoutTemplateType.from(templateId) → wgerCategoryIds
                   │
                   ▼
            wgerService.fetchExercises(category: categoryId)
                   │
                   ▼
            [WgerExercise] → [ProgramWorkout]
```

## Testes

### Unit Tests

```swift
// LoadProgramWorkoutsUseCaseTests.swift

@Test func loadWorkoutsForPushPullLegs() async throws {
    // Given
    let mockProgramRepo = MockProgramRepository()
    let mockWorkoutRepo = MockWgerProgramWorkoutRepository()

    let program = Program(
        id: "ppl_beginner",
        workoutTemplateIds: ["lib_push_beginner_gym", "lib_pull_beginner_gym", "lib_legs_beginner_gym"]
    )
    mockProgramRepo.programs = [program]

    let useCase = LoadProgramWorkoutsUseCase(
        programRepository: mockProgramRepo,
        workoutRepository: mockWorkoutRepo
    )

    // When
    let workouts = try await useCase.execute(programId: "ppl_beginner")

    // Then
    #expect(workouts.count == 3)
    #expect(workouts[0].title.contains("Push"))
    #expect(workouts[1].title.contains("Pull"))
    #expect(workouts[2].title.contains("Legs"))
}
```

## Migração

### Passo 1: Adicionar novos arquivos
- WorkoutTemplateType.swift
- ProgramWorkout.swift
- WgerProgramWorkoutRepository.swift
- DefaultWgerProgramWorkoutRepository.swift
- LoadProgramWorkoutsUseCase.swift

### Passo 2: Atualizar existentes
- ProgramDetailViewModel.swift
- ProgramDetailView.swift
- AppContainer.swift

### Passo 3: Remover obsoletos
- Remover `LibraryWorkoutsRepository` do ProgramDetailView
- Remover referências ao `LibraryWorkoutsSeed.json` para programas
