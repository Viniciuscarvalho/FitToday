//
//  LoadProgramWorkoutsUseCase.swift
//  FitToday
//
//  Use case para carregar treinos de um programa com exercícios da API Wger.
//

import Foundation

/// Use case que carrega os treinos de um programa com exercícios da API Wger.
struct LoadProgramWorkoutsUseCase: Sendable {
    private let programRepository: ProgramRepository
    private let workoutRepository: WgerProgramWorkoutRepository

    init(programRepository: ProgramRepository, workoutRepository: WgerProgramWorkoutRepository) {
        self.programRepository = programRepository
        self.workoutRepository = workoutRepository
    }

    /// Carrega todos os treinos de um programa com exercícios da Wger.
    /// - Parameter programId: ID do programa
    /// - Returns: Array de ProgramWorkout com exercícios carregados
    func execute(programId: String) async throws -> [ProgramWorkout] {
        #if DEBUG
        print("[LoadProgramWorkouts] 🔄 Loading workouts for program: \(programId)")
        #endif

        guard let program = try await programRepository.getProgram(id: programId) else {
            throw LoadProgramError.programNotFound(programId)
        }

        #if DEBUG
        print("[LoadProgramWorkouts] ✅ Found program: \(program.name)")
        print("[LoadProgramWorkouts] 📋 Templates: \(program.workoutTemplateIds)")
        #endif

        var workouts: [ProgramWorkout] = []

        for (index, templateId) in program.workoutTemplateIds.enumerated() {
            do {
                // Verificar se existe customização do usuário
                if let customization = try await workoutRepository.loadCustomization(
                    programId: programId,
                    workoutId: templateId
                ) {
                    // Carregar exercícios customizados na ordem salva
                    let exercises = try await workoutRepository.fetchExercisesByIds(customization.exerciseIds)
                    let workout = createWorkout(
                        programId: programId,
                        index: index,
                        templateId: templateId,
                        estimatedMinutes: program.estimatedMinutesPerSession,
                        exercises: exercises,
                        customOrder: customization.order
                    )
                    workouts.append(workout)

                    #if DEBUG
                    print("[LoadProgramWorkouts] 📖 Loaded customized workout: \(workout.title)")
                    #endif
                } else {
                    // Carregar exercícios padrão da API Wger
                    let exercises = try await workoutRepository.loadWorkoutExercises(
                        templateId: templateId,
                        exerciseCount: 8
                    )

                    let workout = createWorkout(
                        programId: programId,
                        index: index,
                        templateId: templateId,
                        estimatedMinutes: program.estimatedMinutesPerSession,
                        exercises: exercises,
                        customOrder: nil
                    )
                    workouts.append(workout)

                    #if DEBUG
                    print("[LoadProgramWorkouts] ✅ Loaded default workout: \(workout.title) with \(exercises.count) exercises")
                    #endif
                }
            } catch {
                #if DEBUG
                print("[LoadProgramWorkouts] ⚠️ Error loading template \(templateId): \(error)")
                #endif

                // Criar workout vazio em caso de erro para não quebrar a UI
                let emptyWorkout = createEmptyWorkout(
                    programId: programId,
                    index: index,
                    templateId: templateId,
                    estimatedMinutes: program.estimatedMinutesPerSession
                )
                workouts.append(emptyWorkout)
            }
        }

        #if DEBUG
        print("[LoadProgramWorkouts] 🏁 Loaded \(workouts.count) workouts total")
        #endif

        return workouts
    }

    // MARK: - Private Helpers

    private func createWorkout(
        programId: String,
        index: Int,
        templateId: String,
        estimatedMinutes: Int,
        exercises: [WgerExercise],
        customOrder: [Int]?
    ) -> ProgramWorkout {
        let templateType = WorkoutTemplateType.from(templateId: templateId)

        var programExercises = exercises.enumerated().map { offset, exercise in
            ProgramExercise(
                id: "\(templateId)_\(exercise.id)",
                wgerExercise: exercise,
                sets: defaultSets(for: templateType),
                repsRange: defaultRepsRange(for: templateType),
                restSeconds: defaultRestSeconds(for: templateType),
                notes: nil,
                order: offset
            )
        }

        // Aplicar ordem customizada se existir
        if let order = customOrder {
            programExercises = programExercises.enumerated().map { offset, exercise in
                var mutableExercise = exercise
                mutableExercise.order = order.indices.contains(offset) ? order[offset] : offset
                return mutableExercise
            }.sorted { $0.order < $1.order }
        }

        return ProgramWorkout(
            id: "\(programId)_workout_\(index)",
            templateId: templateId,
            title: workoutTitle(for: templateType, index: index),
            subtitle: templateType?.muscleGroupsDescription ?? "Treino completo",
            estimatedDurationMinutes: estimatedMinutes,
            exercises: programExercises
        )
    }

    private func createEmptyWorkout(
        programId: String,
        index: Int,
        templateId: String,
        estimatedMinutes: Int
    ) -> ProgramWorkout {
        let templateType = WorkoutTemplateType.from(templateId: templateId)

        return ProgramWorkout(
            id: "\(programId)_workout_\(index)",
            templateId: templateId,
            title: workoutTitle(for: templateType, index: index),
            subtitle: "Erro ao carregar exercícios",
            estimatedDurationMinutes: estimatedMinutes,
            exercises: []
        )
    }

    private func workoutTitle(for templateType: WorkoutTemplateType?, index: Int) -> String {
        guard let type = templateType else {
            return "Treino \(index + 1)"
        }
        return "Treino \(index + 1) - \(type.displayName)"
    }

    // MARK: - Default Values Based on Template Type

    private func defaultSets(for templateType: WorkoutTemplateType?) -> Int {
        switch templateType {
        case .hiit, .conditioning:
            return 3
        case .core:
            return 3
        default:
            return 4
        }
    }

    private func defaultRepsRange(for templateType: WorkoutTemplateType?) -> ClosedRange<Int> {
        switch templateType {
        case .hiit, .conditioning:
            return 15...20
        case .core:
            return 12...15
        case .push, .pull, .upper:
            return 8...12
        case .legs, .lower:
            return 10...15
        default:
            return 8...12
        }
    }

    private func defaultRestSeconds(for templateType: WorkoutTemplateType?) -> Int {
        switch templateType {
        case .hiit, .conditioning:
            return 30
        case .core:
            return 45
        default:
            return 90
        }
    }
}

/// Erros do use case de carregamento de programas.
enum LoadProgramError: LocalizedError {
    case programNotFound(String)
    case workoutsEmpty

    var errorDescription: String? {
        switch self {
        case .programNotFound(let id):
            return "Programa não encontrado: \(id)"
        case .workoutsEmpty:
            return "Nenhum treino encontrado no programa"
        }
    }
}
