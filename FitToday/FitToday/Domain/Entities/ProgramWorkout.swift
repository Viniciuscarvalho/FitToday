//
//  ProgramWorkout.swift
//  FitToday
//
//  Entity representing a workout within a program,
//  with exercises loaded from the Firestore catalog.
//

import Foundation

/// Um treino dentro de um programa com exercícios do catálogo.
struct ProgramWorkout: Identifiable, Hashable, Sendable {
    let id: String
    let templateId: String
    let title: String
    let subtitle: String
    let estimatedDurationMinutes: Int
    let exercises: [ProgramExercise]

    var templateType: WorkoutTemplateType? {
        WorkoutTemplateType.from(templateId: templateId)
    }

    var exerciseCount: Int {
        exercises.count
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ProgramWorkout, rhs: ProgramWorkout) -> Bool {
        lhs.id == rhs.id
    }
}

/// Um exercício dentro de um treino de programa.
struct ProgramExercise: Identifiable, Hashable, Sendable {
    let id: String
    let catalogExercise: CatalogExercise
    let sets: Int
    let repsRange: ClosedRange<Int>
    let restSeconds: Int
    let notes: String?
    var order: Int

    var name: String {
        catalogExercise.name
    }

    var exerciseDescription: String? {
        catalogExercise.description
    }

    var setsRepsDescription: String {
        "\(sets)x\(repsRange.lowerBound)-\(repsRange.upperBound)"
    }

    var restDescription: String {
        "\(restSeconds)s"
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ProgramExercise, rhs: ProgramExercise) -> Bool {
        lhs.id == rhs.id
    }
}

/// Customização de um treino salva pelo usuário.
struct WorkoutCustomization: Codable, Sendable {
    let programId: String
    let workoutId: String
    let exerciseIds: [String]
    let order: [Int]
    let updatedAt: Date

    var storageKey: String {
        "workout_customization_\(programId)_\(workoutId)"
    }
}

// MARK: - Conversion to WorkoutPlan

extension ProgramWorkout {
    func toWorkoutPlan() -> WorkoutPlan {
        let exercisePrescriptions = exercises.map { programExercise -> ExercisePrescription in
            let catalog = programExercise.catalogExercise
            let workoutExercise = WorkoutExercise(
                id: catalog.id,
                name: catalog.name,
                mainMuscle: MuscleGroup(rawValue: catalog.category ?? "") ?? .fullBody,
                equipment: Self.mapEquipment(catalog.equipment),
                instructions: Self.extractInstructions(from: catalog),
                media: nil
            )

            return ExercisePrescription(
                exercise: workoutExercise,
                sets: programExercise.sets,
                reps: IntRange(
                    programExercise.repsRange.lowerBound,
                    programExercise.repsRange.upperBound
                ),
                restInterval: TimeInterval(programExercise.restSeconds),
                tip: programExercise.notes
            )
        }

        return WorkoutPlan(
            id: UUID(),
            title: title,
            focus: .fullBody,
            estimatedDurationMinutes: estimatedDurationMinutes,
            intensity: .moderate,
            exercises: exercisePrescriptions,
            createdAt: Date()
        )
    }

    private static func mapEquipment(_ equipmentIds: [Int]) -> EquipmentType {
        guard let first = equipmentIds.first else { return .bodyweight }
        switch first {
        case 1: return .barbell
        case 3: return .dumbbell
        case 8: return .machine
        case 10: return .kettlebell
        case 7: return .bodyweight
        case 9: return .resistanceBand
        case 6: return .pullupBar
        default: return .bodyweight
        }
    }

    private static func extractInstructions(from catalog: CatalogExercise) -> [String] {
        guard let description = catalog.description, !description.isEmpty else {
            return ["Realize o exercício com boa técnica."]
        }
        let lines = description
            .components(separatedBy: CharacterSet.newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        return lines.isEmpty ? ["Realize o exercício com boa técnica."] : lines
    }
}

// MARK: - Factory Methods

extension ProgramWorkout {
    /// Cria um ProgramWorkout a partir de metadados e exercícios do catálogo.
    static func create(
        programId: String,
        index: Int,
        templateId: String,
        estimatedMinutes: Int,
        exercises: [CatalogExercise]
    ) -> ProgramWorkout {
        let templateType = WorkoutTemplateType.from(templateId: templateId)

        let programExercises = exercises.enumerated().map { offset, exercise in
            ProgramExercise(
                id: "\(templateId)_\(exercise.id)",
                catalogExercise: exercise,
                sets: 4,
                repsRange: 8...12,
                restSeconds: 90,
                notes: nil,
                order: offset
            )
        }

        return ProgramWorkout(
            id: "\(programId)_\(index)",
            templateId: templateId,
            title: "Treino \(index + 1) - \(templateType?.displayName ?? "Geral")",
            subtitle: templateType?.muscleGroupsDescription ?? "Treino completo",
            estimatedDurationMinutes: estimatedMinutes,
            exercises: programExercises
        )
    }
}
