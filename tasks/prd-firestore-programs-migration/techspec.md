# Tech Spec — Migração de Programas: WGER → Catálogo Firestore

**Feature slug:** `prd-firestore-programs-migration`

---

## 1. Arquitetura: Antes vs. Depois

### Antes (quebrado)
```
HomeViewModel
  └── DefaultWgerProgramWorkoutRepository  ← chama API WGER (offline)
        └── WgerExercise                   ← modelo acoplado

ProgramExercise { wgerExercise: WgerExercise }
```

### Depois (target)
```
HomeViewModel
  └── FirestoreProgramExerciseRepository  ← query Firestore
        └── FirestoreExercise             ← novo modelo de domínio

ProgramExercise { exerciseId: String, name: String, primaryMuscles: [String] }
ExerciseImageCache.shared.image(for: exerciseId)  ← já existe (PR #49)
```

---

## 2. Novos Tipos de Domínio

### FirestoreExercise
**`Domain/Entities/FirestoreExercise.swift`**
```swift
struct FirestoreExercise: Identifiable, Hashable, Sendable, Codable {
    let id: String           // "barbell_bench_press"
    let namePt: String       // "Supino Reto com Barra"
    let nameEn: String       // "Barbell Bench Press"
    let category: String     // "chest" | "back" | "quadriceps" etc.
    let equipment: String    // "barbell" | "dumbbell" | "bodyweight" etc.
    let primaryMuscles: [String]
    let isActive: Bool
}

// DTO interno do repositório
private struct FBExercise: Codable {
    @DocumentID var id: String?
    let name: FBExerciseName
    let category: String
    let equipment: String
    let primaryMuscles: [String]
    let isActive: Bool

    struct FBExerciseName: Codable { let pt: String; let en: String }

    func toDomain() -> FirestoreExercise {
        FirestoreExercise(id: id ?? "", namePt: name.pt, nameEn: name.en,
                          category: category, equipment: equipment,
                          primaryMuscles: primaryMuscles, isActive: isActive)
    }
}
```

### ProgramExercise (refactor)
**`Domain/Entities/ProgramWorkout.swift`**
```swift
// ANTES
struct ProgramExercise {
    let wgerExercise: WgerExercise
    var name: String { wgerExercise.name }
}

// DEPOIS
struct ProgramExercise: Identifiable, Hashable, Sendable {
    let id: String
    let exerciseId: String       // ID Firestore
    let name: String             // name.pt
    let primaryMuscles: [String]
    let sets: Int
    let repsRange: ClosedRange<Int>
    let restSeconds: Int
    let notes: String?
    var order: Int
    // Imagens via ExerciseImageCache — não armazenadas aqui
}
```

### WorkoutTemplateType (extensão)
```swift
extension WorkoutTemplateType {
    var firestoreCategories: [String] {
        switch self {
        case .pushBeginner, .pushHypertrophy:   return ["chest", "shoulders", "triceps"]
        case .pullBeginner, .pullHypertrophy:   return ["back", "biceps"]
        case .legsBeginner, .legsHypertrophy:   return ["quadriceps", "hamstrings", "glutes", "calves"]
        case .strengthCompound:                  return ["chest", "back", "quadriceps"]
        case .coreStrength:                      return ["core"]
        case .fullBody:                          return ["chest", "back", "quadriceps", "shoulders"]
        case .upperBody:                         return ["chest", "back", "shoulders", "biceps", "triceps"]
        case .lowerBody:                         return ["quadriceps", "hamstrings", "glutes", "calves"]
        }
    }

    var firestoreEquipment: [String] {
        switch self {
        case _ where rawValue.contains("gym"):  return ["barbell", "dumbbell", "cable", "machine"]
        case _ where rawValue.contains("home"): return ["bodyweight", "dumbbell"]
        default:                                return ["barbell", "dumbbell", "cable", "bodyweight"]
        }
    }
}
```

---

## 3. Protocolo e Repositório

### ProgramExerciseRepository
**`Domain/Protocols/ProgramExerciseRepository.swift`**
```swift
protocol ProgramExerciseRepository: Sendable {
    func loadExercises(forTemplate templateId: String, count: Int) async throws -> [FirestoreExercise]
    func loadExercise(id: String) async throws -> FirestoreExercise?
}
```

### FirestoreProgramExerciseRepository
**`Data/Repositories/FirestoreProgramExerciseRepository.swift`**
```swift
actor FirestoreProgramExerciseRepository: ProgramExerciseRepository {
    private let db = Firestore.firestore()
    private var cache: [String: [FirestoreExercise]] = [:]

    func loadExercises(forTemplate templateId: String, count: Int = 8) async throws -> [FirestoreExercise] {
        if let cached = cache[templateId] { return cached }

        guard let templateType = WorkoutTemplateType.from(templateId: templateId) else {
            return try await loadFallback(count: count)
        }

        var result: [FirestoreExercise] = []
        let seen = NSMutableSet()

        for category in templateType.firestoreCategories {
            let snap = try await db.collection("exercises")
                .whereField("category", isEqualTo: category)
                .whereField("isActive", isEqualTo: true)
                .limit(to: count * 2)
                .getDocuments()

            let exercises = snap.documents
                .compactMap { try? $0.data(as: FBExercise.self) }
                .map { $0.toDomain() }
                .filter { templateType.firestoreEquipment.contains($0.equipment) && !seen.contains($0.id) }

            exercises.forEach { seen.add($0.id) }
            result.append(contentsOf: exercises)
            if result.count >= count { break }
        }

        let final = Array(result.prefix(count))
        cache[templateId] = final
        return final
    }

    func loadExercise(id: String) async throws -> FirestoreExercise? {
        let doc = try await db.collection("exercises").document(id).getDocument()
        return (try? doc.data(as: FBExercise.self))?.toDomain()
    }

    private func loadFallback(count: Int) async throws -> [FirestoreExercise] {
        let snap = try await db.collection("exercises")
            .whereField("category", isEqualTo: "full_body")
            .whereField("isActive", isEqualTo: true)
            .limit(to: count)
            .getDocuments()
        return snap.documents.compactMap { (try? $0.data(as: FBExercise.self))?.toDomain() }
    }
}
```

---

## 4. Factory Method Atualizado

```swift
extension ProgramWorkout {
    static func create(programId: String, index: Int, templateId: String,
                       estimatedMinutes: Int, exercises: [FirestoreExercise]) -> ProgramWorkout {
        let programExercises = exercises.enumerated().map { offset, ex in
            ProgramExercise(id: "\(templateId)_\(ex.id)", exerciseId: ex.id,
                            name: ex.namePt, primaryMuscles: ex.primaryMuscles,
                            sets: 4, repsRange: 8...12, restSeconds: 90, notes: nil, order: offset)
        }
        return ProgramWorkout(id: "\(programId)_\(index)", templateId: templateId,
                              title: "Treino \(index + 1)",
                              estimatedDurationMinutes: estimatedMinutes,
                              exercises: programExercises)
    }
}
```

---

## 5. Views Afetadas

```swift
// ANTES (3 views)
ExerciseHeroImage(media: exercise.wgerExercise.mainImageURL)

// DEPOIS
ExerciseAnimatedView(exerciseId: exercise.exerciseId)
    .frame(height: 200)

// Prefetch no carregamento do treino
.task {
    let ids = workout.exercises.map(\.exerciseId)
    await ExerciseImageCache.shared.prefetchWorkoutImages(exerciseIds: ids)
}
```

---

## 6. DI — AppContainer

```swift
// Remover
container.register(WgerProgramWorkoutRepository.self) { ... }

// Adicionar
container.register(ProgramExerciseRepository.self) { _ in
    FirestoreProgramExerciseRepository()
}
```

---

## 7. Índices Firestore Necessários

```
exercises: category ASC + isActive ASC
exercises: equipment ASC + isActive ASC
```

## 8. Security Rules

```js
match /exercises/{exerciseId} {
  allow read: if true;   // catálogo público
  allow write: if false; // só Admin SDK
}
```

---

## 9. Plano de Migração (sem breaking changes)

1. Criar `FirestoreExercise` + `ProgramExerciseRepository` (Tasks 1.1–1.2)
2. Adicionar `firestoreCategories` em `WorkoutTemplateType` (Task 1.3)
3. Implementar repositório + testes (Tasks 2.1–2.2)
4. Adicionar `exerciseId` em `ProgramExercise` como campo novo — manter `wgerExercise?` (Task 3.1)
5. Nova sobrecarga `ProgramWorkout.create([FirestoreExercise])` (Task 3.2)
6. Migrar views para `ExerciseAnimatedView` (Task 4.1)
7. Atualizar ViewModel para usar novo repositório (Task 4.2)
8. Atualizar DI, remover campos legados, remover arquivos WGER (Tasks 5.1–5.3)
9. Validação final (Task 6)
