//
//  WorkoutSessionStore.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import Foundation
import Combine
import Swinject

@MainActor
final class WorkoutSessionStore: ObservableObject {
    @Published private(set) var session: WorkoutSession?
    @Published private(set) var currentExerciseIndex: Int = 0
    @Published private(set) var skippedExerciseIDs: Set<String> = []
    @Published private(set) var lastCompletionStatus: WorkoutStatus?
    @Published private(set) var isSavingCompletion = false

    private let startUseCase = StartWorkoutSessionUseCase()
    private let completeUseCase: CompleteWorkoutSessionUseCase

    init(resolver: Resolver) {
        guard let historyRepository = resolver.resolve(WorkoutHistoryRepository.self) else {
            fatalError("WorkoutHistoryRepository não registrado no container.")
        }
        self.completeUseCase = CompleteWorkoutSessionUseCase(historyRepository: historyRepository)
    }

    func start(with plan: WorkoutPlan) {
        session = startUseCase.execute(plan: plan)
        currentExerciseIndex = 0
        skippedExerciseIDs = []
        lastCompletionStatus = nil
    }

    func reset() {
        session = nil
        currentExerciseIndex = 0
        skippedExerciseIDs = []
        lastCompletionStatus = nil
        isSavingCompletion = false
    }

    var plan: WorkoutPlan? {
        session?.plan
    }

    var exercises: [ExercisePrescription] {
        session?.plan.exercises ?? []
    }

    var exerciseCount: Int {
        exercises.count
    }

    var currentPrescription: ExercisePrescription? {
        guard exercises.indices.contains(currentExerciseIndex) else { return nil }
        return exercises[currentExerciseIndex]
    }

    func selectExercise(at index: Int) {
        guard exercises.indices.contains(index) else { return }
        currentExerciseIndex = index
    }

    func advanceToNextExercise() -> Bool {
        guard exercises.count > 0 else { return true }
        if currentExerciseIndex < exercises.count - 1 {
            currentExerciseIndex += 1
            return false
        } else {
            return true
        }
    }

    func skipCurrentExercise() -> Bool {
        if let exerciseID = currentPrescription?.exercise.id {
            skippedExerciseIDs.insert(exerciseID)
        }
        return advanceToNextExercise()
    }

    func finish(status: WorkoutStatus) async throws {
        guard let session else { throw DomainError.invalidInput(reason: "Nenhum treino ativo.") }
        guard !isSavingCompletion else { return }
        isSavingCompletion = true
        defer { isSavingCompletion = false }
        try await completeUseCase.execute(session: session, status: status)
        lastCompletionStatus = status
    }
}

