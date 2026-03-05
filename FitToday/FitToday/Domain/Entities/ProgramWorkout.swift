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
