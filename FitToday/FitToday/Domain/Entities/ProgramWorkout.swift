//
//  ProgramWorkout.swift
//  FitToday
//
//  Entity que representa um treino dentro de um programa,
//  com exercícios carregados da API Wger.
//

import Foundation

/// Um treino dentro de um programa com exercícios da Wger.
struct ProgramWorkout: Identifiable, Hashable, Sendable {
    let id: String
    let templateId: String
    let title: String
    let subtitle: String
    let estimatedDurationMinutes: Int
    let exercises: [ProgramExercise]

    /// Tipo do template de treino inferido do templateId.
    var templateType: WorkoutTemplateType? {
        WorkoutTemplateType.from(templateId: templateId)
    }

    /// Número total de exercícios.
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
    let wgerExercise: WgerExercise
    let sets: Int
    let repsRange: ClosedRange<Int>
    let restSeconds: Int
    let notes: String?
    var order: Int

    /// Nome do exercício para exibição.
    var name: String {
        wgerExercise.name
    }

    /// URL da imagem principal do exercício, se disponível.
    var imageURL: URL? {
        guard let urlString = wgerExercise.mainImageURL else { return nil }
        return URL(string: urlString)
    }

    /// URLs de todas as imagens do exercício.
    var allImageURLs: [URL] {
        wgerExercise.imageURLs.compactMap { URL(string: $0) }
    }

    /// Descrição do exercício (instruções).
    var exerciseDescription: String? {
        wgerExercise.description
    }

    /// Descrição formatada de sets/reps (ex: "4x8-12").
    var setsRepsDescription: String {
        "\(sets)x\(repsRange.lowerBound)-\(repsRange.upperBound)"
    }

    /// Descrição formatada do descanso (ex: "90s").
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
    let exerciseIds: [Int]
    let order: [Int]
    let updatedAt: Date

    /// Chave para persistência no UserDefaults.
    var storageKey: String {
        "workout_customization_\(programId)_\(workoutId)"
    }
}

// MARK: - Factory Methods

extension ProgramWorkout {
    /// Cria um ProgramWorkout a partir de metadados e exercícios Wger.
    static func create(
        programId: String,
        index: Int,
        templateId: String,
        estimatedMinutes: Int,
        exercises: [WgerExercise]
    ) -> ProgramWorkout {
        let templateType = WorkoutTemplateType.from(templateId: templateId)

        let programExercises = exercises.enumerated().map { offset, exercise in
            ProgramExercise(
                id: "\(templateId)_\(exercise.id)",
                wgerExercise: exercise,
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
