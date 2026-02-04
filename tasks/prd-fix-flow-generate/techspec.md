# Technical Specification: Fix Flow Generate

## Overview

Este documento detalha a implementação técnica para corrigir os 4 problemas principais identificados no PRD.

## Architecture

### Current Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Presentation Layer                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │ WorkoutTab  │  │ HomeView    │  │ ChallengesView          │  │
│  │   View      │  │ Model       │  │                         │  │
│  └──────┬──────┘  └──────┬──────┘  └───────────┬─────────────┘  │
└─────────┼────────────────┼─────────────────────┼────────────────┘
          │                │                     │
┌─────────┼────────────────┼─────────────────────┼────────────────┐
│         │         Domain Layer                 │                 │
│  ┌──────▼──────┐  ┌──────▼──────┐  ┌──────────▼──────────────┐  │
│  │ Blueprint   │  │ Streak      │  │ CheckInUseCase          │  │
│  │ Engine      │  │ Calculation │  │                         │  │
│  └──────┬──────┘  └──────┬──────┘  └───────────┬─────────────┘  │
└─────────┼────────────────┼─────────────────────┼────────────────┘
          │                │                     │
┌─────────┼────────────────┼─────────────────────┼────────────────┐
│         │          Data Layer                  │                 │
│  ┌──────▼──────┐  ┌──────▼──────┐  ┌──────────▼──────────────┐  │
│  │ OpenAI     │  │ SwiftData   │  │ Firebase                │  │
│  │ + Cache    │  │ Repository  │  │ Repository              │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Component Specifications

---

## Component 1: Workout Generation Cache Fix

### Problem Analysis

O sistema atual usa um `variationSeed` baseado em buckets de 15 minutos:

```swift
// Current (problematic)
String(minuteOfHour / 15)  // Buckets: 0, 1, 2, 3
```

Quando o usuário muda o `focus` (grupo muscular) dentro do mesmo bucket, o cache pode retornar um treino incorreto.

### Solution Design

#### 1.1 Modify `WorkoutBlueprint.swift`

**Location:** `FitToday/Domain/Entities/WorkoutBlueprint.swift`

```swift
// BEFORE (lines ~286-305)
var variationSeed: UInt64 {
    var hasher = Hasher()
    hasher.combine(cacheKey)
    let hash = hasher.finalize()
    return UInt64(bitPattern: Int64(hash))
}

// AFTER
var variationSeed: UInt64 {
    var hasher = Hasher()
    hasher.combine(cacheKey)
    hasher.combine(focus.rawValue)  // Explicit focus inclusion
    hasher.combine(Date().timeIntervalSince1970)  // Time uniqueness
    let hash = hasher.finalize()
    return UInt64(bitPattern: Int64(hash))
}
```

#### 1.2 Modify `OpenAIResponseCache.swift`

**Location:** `FitToday/Data/Services/OpenAI/OpenAIResponseCache.swift`

Adicionar método para invalidar cache por focus:

```swift
actor OpenAIResponseCache {
    private var storage: [String: CachedEntry] = [:]
    private var lastFocus: String?  // Track last focus

    func get(for key: String, focus: String) async -> Data? {
        // Invalidate if focus changed
        if let lastFocus = lastFocus, lastFocus != focus {
            await clearForFocusChange()
        }
        lastFocus = focus

        guard let entry = storage[key],
              !entry.isExpired else {
            return nil
        }
        return entry.data
    }

    func clearForFocusChange() async {
        storage.removeAll()
    }
}
```

#### 1.3 Modify `WorkoutPromptAssembler.swift`

**Location:** `FitToday/Data/Services/OpenAI/WorkoutPromptAssembler.swift`

Garantir que o focus é passado para o cache:

```swift
// In the assemble method, pass focus to cache
let cacheKey = generateCacheKey(includingFocus: metadata.focus)
let cachedResponse = await cache.get(for: cacheKey, focus: metadata.focus.rawValue)
```

### Data Flow

```
User selects "Shoulders"
        │
        ▼
┌───────────────────┐
│ BlueprintInput    │ focus = .upper (or specific)
└────────┬──────────┘
         │
         ▼
┌───────────────────┐
│ Check Cache       │ Is focus different from last?
└────────┬──────────┘
         │ YES → Clear cache
         ▼
┌───────────────────┐
│ Generate New      │ With focus-specific exercises
│ Workout           │
└───────────────────┘
```

---

## Component 2: Title Header & Minhas Rotinas

### 2.1 Restore Navigation Title

**Location:** `FitToday/Presentation/Features/Workout/Views/WorkoutTabView.swift`

```swift
struct WorkoutTabView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segment picker
                segmentPicker

                // Content based on selection
                TabView(selection: $selectedSegment) {
                    MyWorkoutsView()
                        .tag(0)
                    ProgramsView()
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("workout.title".localized)  // Ensure this is present
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
```

### 2.2 Create SavedRoutine Model

**New File:** `FitToday/Domain/Entities/SavedRoutine.swift`

```swift
import Foundation

/// Represents a user-saved routine (program saved for quick access)
struct SavedRoutine: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let programId: String
    let name: String
    let goalTag: ProgramGoalTag
    let level: ProgramLevel
    let workoutCount: Int
    let savedAt: Date

    init(from program: Program) {
        self.id = UUID()
        self.programId = program.id
        self.name = program.name
        self.goalTag = program.goalTag
        self.level = program.level
        self.workoutCount = program.workoutTemplateIds.count
        self.savedAt = Date()
    }
}
```

### 2.3 Create SwiftData Model

**New File:** `FitToday/Data/Models/SDSavedRoutine.swift`

```swift
import Foundation
import SwiftData

@Model
final class SDSavedRoutine {
    @Attribute(.unique) var id: UUID
    var programId: String
    var name: String
    var goalTagRaw: String
    var levelRaw: String
    var workoutCount: Int
    var savedAt: Date

    init(from routine: SavedRoutine) {
        self.id = routine.id
        self.programId = routine.programId
        self.name = routine.name
        self.goalTagRaw = routine.goalTag.rawValue
        self.levelRaw = routine.level.rawValue
        self.workoutCount = routine.workoutCount
        self.savedAt = routine.savedAt
    }

    func toDomain() -> SavedRoutine {
        SavedRoutine(
            id: id,
            programId: programId,
            name: name,
            goalTag: ProgramGoalTag(rawValue: goalTagRaw) ?? .strength,
            level: ProgramLevel(rawValue: levelRaw) ?? .beginner,
            workoutCount: workoutCount,
            savedAt: savedAt
        )
    }
}
```

### 2.4 Repository Protocol & Implementation

**New File:** `FitToday/Domain/Protocols/SavedRoutineRepository.swift`

```swift
import Foundation

protocol SavedRoutineRepository: Sendable {
    func listRoutines() async throws -> [SavedRoutine]
    func saveRoutine(_ routine: SavedRoutine) async throws
    func deleteRoutine(_ id: UUID) async throws
    func canSaveMore() async -> Bool  // Max 5 limit
}
```

**New File:** `FitToday/Data/Repositories/SwiftDataSavedRoutineRepository.swift`

```swift
import Foundation
import SwiftData

@MainActor
final class SwiftDataSavedRoutineRepository: SavedRoutineRepository {
    private let modelContainer: ModelContainer
    private let maxRoutines = 5

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func listRoutines() async throws -> [SavedRoutine] {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<SDSavedRoutine>(
            sortBy: [SortDescriptor(\.savedAt, order: .reverse)]
        )
        let results = try context.fetch(descriptor)
        return results.map { $0.toDomain() }
    }

    func saveRoutine(_ routine: SavedRoutine) async throws {
        let context = modelContainer.mainContext

        // Check limit
        let count = try context.fetchCount(FetchDescriptor<SDSavedRoutine>())
        guard count < maxRoutines else {
            throw RoutineError.limitReached
        }

        let sdRoutine = SDSavedRoutine(from: routine)
        context.insert(sdRoutine)
        try context.save()
    }

    func deleteRoutine(_ id: UUID) async throws {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<SDSavedRoutine>(
            predicate: #Predicate { $0.id == id }
        )
        if let routine = try context.fetch(descriptor).first {
            context.delete(routine)
            try context.save()
        }
    }

    func canSaveMore() async -> Bool {
        let context = modelContainer.mainContext
        let count = (try? context.fetchCount(FetchDescriptor<SDSavedRoutine>())) ?? 0
        return count < maxRoutines
    }
}

enum RoutineError: LocalizedError {
    case limitReached

    var errorDescription: String? {
        switch self {
        case .limitReached:
            return "routine.error.limit_reached".localized
        }
    }
}
```

### 2.5 Update MyWorkoutsView

**Location:** `FitToday/Presentation/Features/Workout/Views/MyWorkoutsView.swift`

```swift
struct MyWorkoutsView: View {
    @State private var savedRoutines: [SavedRoutine] = []
    @State private var customWorkouts: [CustomWorkoutTemplate] = []
    @Injected private var routineRepository: SavedRoutineRepository

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                // Section: Minhas Rotinas
                if !savedRoutines.isEmpty {
                    savedRoutinesSection
                }

                // Section: Treinos Personalizados
                customWorkoutsSection
            }
            .padding()
        }
        .task {
            await loadData()
        }
    }

    private var savedRoutinesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("workout.my_routines".localized)
                    .font(.headline)
                Spacer()
                Text("\(savedRoutines.count)/5")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(savedRoutines) { routine in
                SavedRoutineCard(routine: routine, onDelete: deleteRoutine)
            }
        }
    }

    private func loadData() async {
        do {
            savedRoutines = try await routineRepository.listRoutines()
        } catch {
            // Handle error
        }
    }

    private func deleteRoutine(_ id: UUID) {
        Task {
            try? await routineRepository.deleteRoutine(id)
            await loadData()
        }
    }
}
```

---

## Component 3: Exercise Description Translation

### 3.1 Create Translation Service

**New File:** `FitToday/Data/Services/Translation/ExerciseTranslationService.swift`

```swift
import Foundation
import NaturalLanguage

actor ExerciseTranslationService {
    private var cache: [String: String] = [:]

    /// Detects language and translates if necessary
    func ensureLocalizedDescription(_ text: String, targetLocale: Locale = .current) async -> String {
        // Check cache first
        let cacheKey = "\(text.hashValue)_\(targetLocale.identifier)"
        if let cached = cache[cacheKey] {
            return cached
        }

        // Detect language
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)

        guard let detectedLanguage = recognizer.dominantLanguage else {
            return text
        }

        let targetLanguageCode = targetLocale.language.languageCode?.identifier ?? "pt"

        // If already in target language, return as-is
        if detectedLanguage.rawValue.hasPrefix(targetLanguageCode) {
            cache[cacheKey] = text
            return text
        }

        // For Spanish or other non-target languages, provide fallback
        if detectedLanguage == .spanish ||
           (detectedLanguage != .english && detectedLanguage != .portuguese) {
            let fallback = getPortugueseFallback(for: text)
            cache[cacheKey] = fallback
            return fallback
        }

        // English is acceptable as fallback
        cache[cacheKey] = text
        return text
    }

    /// Provides generic Portuguese instruction when translation unavailable
    private func getPortugueseFallback(for text: String) -> String {
        // Generic fallback for exercise instructions
        return "Execute o exercício mantendo a postura correta e controlando o movimento."
    }
}
```

### 3.2 Update WgerModels.swift

**Location:** `FitToday/Domain/Entities/WgerModels.swift`

```swift
// Update the description method to be more strict
extension WgerExerciseInfo {
    /// Returns description only in Portuguese or English, never Spanish
    func description(for languageId: Int) -> String? {
        // Priority 1: Portuguese (exact match)
        if let ptTranslation = translations.first(where: {
            $0.language == WgerLanguageCode.portuguese.rawValue
        }) {
            if let desc = ptTranslation.description, !desc.isEmpty {
                return desc.strippingHTML
            }
        }

        // Priority 2: English (fallback)
        if let enTranslation = translations.first(where: {
            $0.language == WgerLanguageCode.english.rawValue
        }) {
            if let desc = enTranslation.description, !desc.isEmpty {
                return desc.strippingHTML
            }
        }

        // Priority 3: Return nil to trigger service fallback
        // NEVER return Spanish or other languages
        return nil
    }
}
```

### 3.3 Update WgerAPIService.swift

**Location:** `FitToday/Data/Services/Wger/WgerAPIService.swift`

```swift
final class WgerAPIService {
    private let translationService = ExerciseTranslationService()

    func fetchExercise(id: Int) async throws -> WgerExerciseDetail {
        // ... existing fetch logic ...

        // Get description with strict language filtering
        let rawDescription = info.description(for: WgerLanguageCode.portuguese.rawValue)

        // Apply translation service for any remaining non-Portuguese content
        let localizedDescription: String
        if let raw = rawDescription {
            localizedDescription = await translationService.ensureLocalizedDescription(raw)
        } else {
            localizedDescription = "Execute o exercício mantendo a postura correta e controlando o movimento."
        }

        return WgerExerciseDetail(
            // ... other properties ...
            description: localizedDescription
        )
    }
}
```

---

## Component 4: Streaks Synchronization & Photo Upload

### 4.1 Unify Streak Calculation

**Location:** `FitToday/Domain/UseCases/SyncWorkoutCompletionUseCase.swift`

Create a shared streak calculator:

```swift
/// Unified streak calculator used by both personal and group contexts
struct StreakCalculator: Sendable {
    static let minimumWorkoutMinutes = 30

    /// Calculates streak using consistent timezone (user's local)
    static func calculateStreak(from entries: [WorkoutHistoryEntry]) -> Int {
        let calendar = Calendar.current  // Always use user's local timezone

        let completedDates = entries
            .filter { $0.status == .completed && ($0.durationMinutes ?? 0) >= minimumWorkoutMinutes }
            .map { calendar.startOfDay(for: $0.date) }

        let uniqueDates = Array(Set(completedDates)).sorted(by: >)

        guard let mostRecent = uniqueDates.first else { return 0 }

        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        // Streak is broken if no activity today or yesterday
        guard mostRecent >= yesterday else { return 0 }

        var streak = 1
        var currentDate = mostRecent

        for date in uniqueDates.dropFirst() {
            let expectedPrevious = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            if date == expectedPrevious {
                streak += 1
                currentDate = date
            } else if date == currentDate {
                continue  // Same day, skip
            } else {
                break  // Gap found, streak ends
            }
        }

        return streak
    }
}
```

### 4.2 Update HomeViewModel

**Location:** `FitToday/Presentation/Features/Home/HomeViewModel.swift`

```swift
@Observable
final class HomeViewModel {
    var historyEntries: [WorkoutHistoryEntry] = []

    var streakDays: Int {
        StreakCalculator.calculateStreak(from: historyEntries)
    }

    var activeDays: Int {
        // Active days should equal streak days for consistency
        streakDays
    }
}
```

### 4.3 Fix Photo Upload in CheckInUseCase

**Location:** `FitToday/Domain/UseCases/CheckInUseCase.swift`

```swift
@MainActor
final class CheckInUseCase {
    private let checkInRepository: CheckInRepository
    private let storageService: FirebaseStorageService
    private let imageCompressor: ImageCompressor

    func execute(
        workoutEntry: WorkoutHistoryEntry,
        photoData: Data,
        isConnected: Bool
    ) async throws -> CheckIn {
        // 1. Validate network
        guard isConnected else {
            throw CheckInError.networkUnavailable
        }

        // 2. Validate user
        guard let user = try await authRepository.currentUser(),
              let groupId = user.currentGroupId else {
            throw CheckInError.notInGroup
        }

        // 3. Validate workout duration
        let duration = workoutEntry.durationMinutes ?? 0
        guard duration >= CheckIn.minimumWorkoutMinutes else {
            throw CheckInError.workoutTooShort(minutes: duration)
        }

        // 4. Compress image with retry
        let compressed = try await compressWithRetry(photoData)

        // 5. Upload photo with detailed error handling
        let photoURL: URL
        do {
            photoURL = try await uploadWithRetry(
                imageData: compressed,
                groupId: groupId,
                userId: user.id
            )
        } catch {
            throw CheckInError.uploadFailed(underlying: error)
        }

        // 6. Get active challenge
        let challenges = try await leaderboardRepository.getCurrentWeekChallenges(groupId: groupId)
        guard let challenge = challenges.first(where: { $0.type == .checkIns }) else {
            throw CheckInError.noActiveChallenge
        }

        // 7. Create and save check-in
        let checkIn = CheckIn(
            id: UUID().uuidString,
            groupId: groupId,
            challengeId: challenge.id,
            userId: user.id,
            displayName: user.displayName,
            userPhotoURL: user.photoURL,
            checkInPhotoURL: photoURL,
            workoutEntryId: workoutEntry.id,
            workoutDurationMinutes: duration,
            createdAt: Date()
        )

        try await checkInRepository.createCheckIn(checkIn)

        // 8. Increment counter
        try await leaderboardRepository.incrementCheckIn(
            challengeId: challenge.id,
            userId: user.id,
            displayName: user.displayName,
            photoURL: user.photoURL
        )

        return checkIn
    }

    private func compressWithRetry(_ data: Data, attempts: Int = 3) async throws -> Data {
        var lastError: Error?

        for attempt in 1...attempts {
            do {
                let quality = max(0.3, 0.7 - (Double(attempt - 1) * 0.2))
                return try imageCompressor.compress(
                    data: data,
                    maxBytes: 500_000,
                    quality: quality
                )
            } catch {
                lastError = error
            }
        }

        throw lastError ?? CheckInError.compressionFailed
    }

    private func uploadWithRetry(
        imageData: Data,
        groupId: String,
        userId: String,
        attempts: Int = 3
    ) async throws -> URL {
        var lastError: Error?

        for attempt in 1...attempts {
            do {
                let timestamp = Int(Date().timeIntervalSince1970)
                let path = "checkIns/\(groupId)/\(userId)/\(timestamp).jpg"
                return try await storageService.uploadImage(data: imageData, path: path)
            } catch {
                lastError = error
                // Wait before retry
                try? await Task.sleep(nanoseconds: UInt64(attempt * 500_000_000))
            }
        }

        throw lastError ?? CheckInError.uploadFailed(underlying: NSError(domain: "CheckIn", code: -1))
    }
}

enum CheckInError: LocalizedError {
    case networkUnavailable
    case notInGroup
    case workoutTooShort(minutes: Int)
    case compressionFailed
    case uploadFailed(underlying: Error)
    case noActiveChallenge

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "checkin.error.network".localized
        case .notInGroup:
            return "checkin.error.not_in_group".localized
        case .workoutTooShort(let minutes):
            return String(format: "checkin.error.too_short".localized, minutes)
        case .compressionFailed:
            return "checkin.error.compression".localized
        case .uploadFailed:
            return "checkin.error.upload".localized
        case .noActiveChallenge:
            return "checkin.error.no_challenge".localized
        }
    }
}
```

### 4.4 Update CheckInSheet UI

**Location:** `FitToday/Presentation/Features/Activity/Views/CheckInSheet.swift`

```swift
struct CheckInSheet: View {
    @State private var selectedImage: UIImage?
    @State private var isUploading = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Photo selection area
                photoSelectionArea

                // Error display
                if let error = errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                // Submit button
                Button(action: submitCheckIn) {
                    if isUploading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("checkin.submit".localized)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedImage == nil || isUploading)
            }
            .padding()
            .navigationTitle("checkin.title".localized)
            .alert("checkin.success.title".localized, isPresented: $showSuccessAlert) {
                Button("OK") { dismiss() }
            } message: {
                Text("checkin.success.message".localized)
            }
        }
    }

    private func submitCheckIn() {
        guard let image = selectedImage,
              let data = image.jpegData(compressionQuality: 0.8) else {
            errorMessage = "checkin.error.no_image".localized
            return
        }

        isUploading = true
        errorMessage = nil

        Task {
            do {
                let useCase = resolver.resolve(CheckInUseCase.self)!
                let entry = try await getRecentWorkout()
                _ = try await useCase.execute(
                    workoutEntry: entry,
                    photoData: data,
                    isConnected: NetworkMonitor.shared.isConnected
                )
                showSuccessAlert = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isUploading = false
        }
    }
}
```

---

## Localization Updates

**Add to `Localizable.strings` (pt-BR):**

```
// Routines
"workout.my_routines" = "Minhas Rotinas";
"routine.save" = "Salvar como Rotina";
"routine.error.limit_reached" = "Você atingiu o limite de 5 rotinas salvas.";
"routine.delete.confirm" = "Remover esta rotina?";

// Check-in errors
"checkin.error.network" = "Sem conexão com a internet.";
"checkin.error.not_in_group" = "Você precisa estar em um grupo para fazer check-in.";
"checkin.error.too_short" = "Treino deve ter pelo menos 30 minutos. Atual: %d min.";
"checkin.error.compression" = "Erro ao processar a imagem.";
"checkin.error.upload" = "Erro ao enviar a foto. Tente novamente.";
"checkin.error.no_challenge" = "Nenhum desafio ativo esta semana.";
"checkin.error.no_image" = "Selecione uma foto para continuar.";
"checkin.success.title" = "Check-in Realizado!";
"checkin.success.message" = "Seu treino foi registrado com sucesso.";
"checkin.title" = "Fazer Check-in";
"checkin.submit" = "Enviar Check-in";
```

**Add to `Localizable.strings` (en):**

```
// Routines
"workout.my_routines" = "My Routines";
"routine.save" = "Save as Routine";
"routine.error.limit_reached" = "You've reached the limit of 5 saved routines.";
"routine.delete.confirm" = "Remove this routine?";

// Check-in errors
"checkin.error.network" = "No internet connection.";
"checkin.error.not_in_group" = "You need to be in a group to check in.";
"checkin.error.too_short" = "Workout must be at least 30 minutes. Current: %d min.";
"checkin.error.compression" = "Error processing image.";
"checkin.error.upload" = "Error uploading photo. Please try again.";
"checkin.error.no_challenge" = "No active challenge this week.";
"checkin.error.no_image" = "Select a photo to continue.";
"checkin.success.title" = "Check-in Complete!";
"checkin.success.message" = "Your workout has been recorded.";
"checkin.title" = "Check In";
"checkin.submit" = "Submit Check-in";
```

---

## Testing Strategy

### Unit Tests

1. **StreakCalculator Tests**
   - Empty entries returns 0
   - Single day returns 1
   - Consecutive days counted correctly
   - Gap breaks streak
   - Same-day duplicates handled
   - Timezone edge cases

2. **SavedRoutineRepository Tests**
   - Save routine success
   - Delete routine success
   - Limit of 5 enforced
   - List sorted by date

3. **ExerciseTranslationService Tests**
   - Portuguese passthrough
   - English passthrough
   - Spanish filtered
   - Unknown language fallback

### Integration Tests

1. **Workout Generation**
   - Different focus generates different workouts
   - Cache invalidates on focus change

2. **Photo Upload**
   - Successful upload flow
   - Retry on failure
   - Compression works

---

## Migration Notes

- No database migrations required for existing users
- New SwiftData model `SDSavedRoutine` will be auto-created
- Existing workout history preserved
- Cache will be cleared on app update (expected behavior)

## Performance Considerations

- Translation service uses in-memory cache
- Streak calculation is O(n) where n = workout history
- Photo compression is async and non-blocking
- Firebase uploads have 3 retry attempts with exponential backoff
