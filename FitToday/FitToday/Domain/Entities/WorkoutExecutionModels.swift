//
//  WorkoutExecutionModels.swift
//  FitToday
//
//  Modelos para tracking de execução de treino por série.
//

import Foundation

/// Estado de progresso de uma única série
struct SetProgress: Codable, Hashable, Sendable, Identifiable {
    let id: UUID
    let setNumber: Int
    var isCompleted: Bool
    var completedAt: Date?
    
    init(setNumber: Int, isCompleted: Bool = false, completedAt: Date? = nil) {
        self.id = UUID()
        self.setNumber = setNumber
        self.isCompleted = isCompleted
        self.completedAt = completedAt
    }
    
    mutating func complete() {
        isCompleted = true
        completedAt = Date()
    }
    
    mutating func uncomplete() {
        isCompleted = false
        completedAt = nil
    }
}

/// Estado de progresso de um exercício
struct ExerciseProgress: Codable, Hashable, Sendable, Identifiable {
    let id: UUID
    let exerciseId: String
    var sets: [SetProgress]
    var isSkipped: Bool
    
    init(exerciseId: String, totalSets: Int, isSkipped: Bool = false) {
        self.id = UUID()
        self.exerciseId = exerciseId
        self.sets = (1...totalSets).map { SetProgress(setNumber: $0) }
        self.isSkipped = isSkipped
    }
    
    var completedSetsCount: Int {
        sets.filter(\.isCompleted).count
    }
    
    var totalSets: Int {
        sets.count
    }
    
    var isFullyCompleted: Bool {
        sets.allSatisfy(\.isCompleted)
    }
    
    var progressPercentage: Double {
        guard totalSets > 0 else { return 0 }
        return Double(completedSetsCount) / Double(totalSets)
    }
    
    mutating func completeSet(at index: Int) {
        guard sets.indices.contains(index) else { return }
        sets[index].complete()
    }
    
    mutating func uncompleteSet(at index: Int) {
        guard sets.indices.contains(index) else { return }
        sets[index].uncomplete()
    }
    
    mutating func toggleSet(at index: Int) {
        guard sets.indices.contains(index) else { return }
        if sets[index].isCompleted {
            sets[index].uncomplete()
        } else {
            sets[index].complete()
        }
    }
}

/// Estado completo de progresso de um treino
struct WorkoutProgress: Codable, Hashable, Sendable {
    let planId: UUID
    var exercises: [ExerciseProgress]
    var startedAt: Date
    var lastUpdatedAt: Date
    
    init(planId: UUID, exercises: [ExerciseProgress]) {
        self.planId = planId
        self.exercises = exercises
        self.startedAt = Date()
        self.lastUpdatedAt = Date()
    }
    
    /// Inicializa a partir de um WorkoutPlan
    init(from plan: WorkoutPlan) {
        self.planId = plan.id
        self.exercises = plan.exercises.map { prescription in
            ExerciseProgress(exerciseId: prescription.exercise.id, totalSets: prescription.sets)
        }
        self.startedAt = Date()
        self.lastUpdatedAt = Date()
    }
    
    // MARK: - Computed Properties
    
    var completedExercisesCount: Int {
        exercises.filter { $0.isFullyCompleted || $0.isSkipped }.count
    }
    
    var totalExercises: Int {
        exercises.count
    }
    
    var overallProgressPercentage: Double {
        guard totalExercises > 0 else { return 0 }
        let totalSets = exercises.reduce(0) { $0 + $1.totalSets }
        let completedSets = exercises.reduce(0) { $0 + $1.completedSetsCount }
        guard totalSets > 0 else { return 0 }
        return Double(completedSets) / Double(totalSets)
    }
    
    var isFullyCompleted: Bool {
        exercises.allSatisfy { $0.isFullyCompleted || $0.isSkipped }
    }
    
    // MARK: - Mutations
    
    mutating func progress(for exerciseId: String) -> ExerciseProgress? {
        exercises.first { $0.exerciseId == exerciseId }
    }
    
    mutating func toggleSet(exerciseIndex: Int, setIndex: Int) {
        guard exercises.indices.contains(exerciseIndex) else { return }
        exercises[exerciseIndex].toggleSet(at: setIndex)
        lastUpdatedAt = Date()
    }
    
    mutating func skipExercise(at index: Int) {
        guard exercises.indices.contains(index) else { return }
        exercises[index].isSkipped = true
        lastUpdatedAt = Date()
    }
    
    mutating func completeAllSets(exerciseIndex: Int) {
        guard exercises.indices.contains(exerciseIndex) else { return }
        for setIndex in exercises[exerciseIndex].sets.indices {
            exercises[exerciseIndex].sets[setIndex].complete()
        }
        lastUpdatedAt = Date()
    }

    mutating func removeExercise(at index: Int) {
        guard exercises.indices.contains(index) else { return }
        exercises.remove(at: index)
        lastUpdatedAt = Date()
    }
}

// MARK: - Persistence Key

extension WorkoutProgress {
    static let persistenceKey = "active_workout_progress"
}

