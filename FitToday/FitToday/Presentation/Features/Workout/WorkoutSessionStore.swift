//
//  WorkoutSessionStore.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import Foundation
// Combine removido - usando @Observable
import Swinject
import UIKit

// 💡 Learn: @Observable oferece melhor performance para state management
@MainActor
@Observable final class WorkoutSessionStore {
    // MARK: - Published State
    
    private(set) var session: WorkoutSession?
    private(set) var currentExerciseIndex: Int = 0
    private(set) var skippedExerciseIDs: Set<String> = []
    private(set) var lastCompletionStatus: WorkoutStatus?
    private(set) var isSavingCompletion = false
    private(set) var progress: WorkoutProgress?
    
    /// Mapa de substituições: ID do exercício original → Alternativa escolhida
    private(set) var substitutions: [String: AlternativeExercise] = [:]
    
    // 💡 Learn: Estado de erro para indicar falha de DI
    private(set) var dependencyError: String?

    // MARK: - Private

    private let startUseCase = StartWorkoutSessionUseCase()
    private let completeUseCase: CompleteWorkoutSessionUseCase?
    private let syncWorkoutUseCase: SyncWorkoutCompletionUseCase?
    private let persistenceKey = WorkoutProgress.persistenceKey
    private let substitutionsKey = "active_workout_substitutions"

    init(resolver: Resolver) {
        // 💡 Learn: Tratamento gracioso de erro em vez de fatalError
        if let historyRepository = resolver.resolve(WorkoutHistoryRepository.self) {
            // HealthKit sync use case - optional
            let healthKitSyncUseCase = resolver.resolve(SyncWorkoutWithHealthKitUseCase.self)
            // User stats update use case - optional
            let updateStatsUseCase = resolver.resolve(UpdateUserStatsUseCase.self)

            self.completeUseCase = CompleteWorkoutSessionUseCase(
                historyRepository: historyRepository,
                healthKitSyncUseCase: healthKitSyncUseCase,
                updateStatsUseCase: updateStatsUseCase
            )
        } else {
            self.completeUseCase = nil
            self.dependencyError = "Repositório de histórico não configurado"
        }

        // Social sync use case - optional (may not be configured)
        self.syncWorkoutUseCase = resolver.resolve(SyncWorkoutCompletionUseCase.self)

        // Tentar restaurar sessão ativa ao iniciar
        restoreSessionIfNeeded()
        restoreSubstitutions()
    }
    
    // MARK: - Session Lifecycle

    func start(with plan: WorkoutPlan) {
        session = startUseCase.execute(plan: plan)
        currentExerciseIndex = 0
        skippedExerciseIDs = []
        lastCompletionStatus = nil
        
        // Inicializar tracking de progresso
        progress = WorkoutProgress(from: plan)
        persistProgress()
    }

    func reset() {
        session = nil
        currentExerciseIndex = 0
        skippedExerciseIDs = []
        lastCompletionStatus = nil
        isSavingCompletion = false
        progress = nil
        
        clearPersistedProgress()
    }
    
    // MARK: - Computed Properties

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
    
    /// Progresso do exercício atual
    var currentExerciseProgress: ExerciseProgress? {
        guard let progress, exercises.indices.contains(currentExerciseIndex) else { return nil }
        return progress.exercises[currentExerciseIndex]
    }
    
    /// Progresso geral do treino (0.0 - 1.0)
    var overallProgress: Double {
        progress?.overallProgressPercentage ?? 0
    }
    
    /// Contagem de exercícios completos
    var completedExercisesCount: Int {
        progress?.completedExercisesCount ?? 0
    }
    
    // MARK: - Navigation

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
        
        // Marcar como pulado no progress
        progress?.skipExercise(at: currentExerciseIndex)
        persistProgress()
        
        return advanceToNextExercise()
    }
    
    // MARK: - Set Tracking
    
    /// Alterna o estado de uma série específica
    func toggleSet(exerciseIndex: Int, setIndex: Int) {
        progress?.toggleSet(exerciseIndex: exerciseIndex, setIndex: setIndex)
        persistProgress()
        
        // Haptic feedback
        triggerSetCompletionHaptic()
    }
    
    /// Alterna o estado de uma série do exercício atual
    func toggleCurrentExerciseSet(at setIndex: Int) {
        toggleSet(exerciseIndex: currentExerciseIndex, setIndex: setIndex)
    }
    
    /// Marca todas as séries do exercício atual como concluídas
    func completeAllCurrentSets() {
        progress?.completeAllSets(exerciseIndex: currentExerciseIndex)
        persistProgress()
        triggerSetCompletionHaptic()
    }
    
    /// Verifica se o exercício atual está completo
    var isCurrentExerciseComplete: Bool {
        guard let currentExerciseProgress else { return false }
        return currentExerciseProgress.isFullyCompleted
    }
    
    // MARK: - Exercise Substitution
    
    /// Aplica uma substituição para o exercício atual
    func substituteCurrentExercise(with alternative: AlternativeExercise) {
        guard let currentPrescription else { return }
        let originalId = currentPrescription.exercise.id
        substitutions[originalId] = alternative
        persistSubstitutions()
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    /// Retorna a alternativa para um exercício, se existir
    func substitution(for exerciseId: String) -> AlternativeExercise? {
        substitutions[exerciseId]
    }
    
    /// Verifica se o exercício atual tem substituição
    var currentExerciseHasSubstitution: Bool {
        guard let currentPrescription else { return false }
        return substitutions[currentPrescription.exercise.id] != nil
    }
    
    /// Retorna o exercício atual (original ou substituído)
    var effectiveCurrentExerciseName: String {
        guard let currentPrescription else { return "" }
        if let sub = substitutions[currentPrescription.exercise.id] {
            return sub.name
        }
        return currentPrescription.exercise.name
    }
    
    /// Remove substituição do exercício atual
    func removeCurrentSubstitution() {
        guard let currentPrescription else { return }
        substitutions.removeValue(forKey: currentPrescription.exercise.id)
        persistSubstitutions()
    }
    
    private func persistSubstitutions() {
        do {
            let data = try JSONEncoder().encode(substitutions)
            UserDefaults.standard.set(data, forKey: substitutionsKey)
        } catch {
            print("Failed to persist substitutions: \(error)")
        }
    }
    
    private func restoreSubstitutions() {
        guard let data = UserDefaults.standard.data(forKey: substitutionsKey),
              let saved = try? JSONDecoder().decode([String: AlternativeExercise].self, from: data) else {
            return
        }
        self.substitutions = saved
    }
    
    private func clearSubstitutions() {
        substitutions = [:]
        UserDefaults.standard.removeObject(forKey: substitutionsKey)
    }
    
    // MARK: - Exercise Removal

    /// Removes an exercise from the current workout plan at the specified phase and item index.
    /// - Parameters:
    ///   - phaseIndex: The index of the phase containing the exercise
    ///   - itemIndex: The index of the item within the phase
    /// - Returns: true if exercise was removed, false if operation was blocked
    @discardableResult
    func removeExercise(fromPhase phaseIndex: Int, at itemIndex: Int) -> Bool {
        guard var currentSession = session else { return false }
        guard phaseIndex < currentSession.plan.phases.count else { return false }
        guard itemIndex < currentSession.plan.phases[phaseIndex].items.count else { return false }

        // Ensure at least 1 exercise remains in the entire workout
        let totalExercises = currentSession.plan.phases.reduce(0) { total, phase in
            total + phase.items.filter { if case .exercise = $0 { return true }; return false }.count
        }
        guard totalExercises > 1 else { return false }

        // Remove the item
        currentSession.plan.phases[phaseIndex].items.remove(at: itemIndex)

        // Remove empty phases
        currentSession.plan.phases.removeAll { $0.items.isEmpty }

        // Update session
        session = currentSession

        // Update progress if needed
        if var currentProgress = progress {
            currentProgress.removeExercise(at: currentProgress.exercises.count > itemIndex ? itemIndex : currentProgress.exercises.count - 1)
            progress = currentProgress
            persistProgress()
        }

        // Adjust current exercise index if needed
        if currentExerciseIndex >= exercises.count {
            currentExerciseIndex = max(0, exercises.count - 1)
        }

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)

        return true
    }

    // MARK: - Finish Session

    func finish(status: WorkoutStatus) async throws {
        guard let session else { throw DomainError.invalidInput(reason: "Nenhum treino ativo.") }
        guard !isSavingCompletion else { return }
        // 💡 Learn: Verificar dependência opcional antes de usar
        guard let useCase = completeUseCase else {
            throw DomainError.repositoryFailure(reason: "Serviço de histórico não configurado")
        }
        isSavingCompletion = true
        defer { isSavingCompletion = false }
        try await useCase.execute(session: session, status: status)
        lastCompletionStatus = status

        // Sync to Firebase leaderboard in background (don't block UI)
        if status == .completed, let syncUseCase = syncWorkoutUseCase {
            // Compute workout duration from session start
            let completedAt = Date()
            let durationSeconds = completedAt.timeIntervalSince(session.startedAt)
            let durationMinutes = Int(durationSeconds / 60)

            let entry = WorkoutHistoryEntry(
                planId: session.plan.id,
                title: session.plan.title,
                focus: session.plan.focus,
                status: status,
                durationMinutes: durationMinutes
            )
            Task.detached {
                await syncUseCase.execute(entry: entry)
            }
        }

        // Limpar persistência após conclusão
        clearPersistedProgress()
    }
    
    // MARK: - Persistence
    
    private func persistProgress() {
        guard let progress else { return }
        do {
            let data = try JSONEncoder().encode(progress)
            UserDefaults.standard.set(data, forKey: persistenceKey)
        } catch {
            print("Failed to persist workout progress: \(error)")
        }
    }
    
    private func clearPersistedProgress() {
        UserDefaults.standard.removeObject(forKey: persistenceKey)
        clearSubstitutions()
    }
    
    private func restoreSessionIfNeeded() {
        guard let data = UserDefaults.standard.data(forKey: persistenceKey),
              let savedProgress = try? JSONDecoder().decode(WorkoutProgress.self, from: data) else {
            return
        }
        
        // Apenas restaurar se foi salvo recentemente (últimas 24h)
        let hoursAgo = Date().timeIntervalSince(savedProgress.lastUpdatedAt) / 3600
        guard hoursAgo < 24 else {
            clearPersistedProgress()
            return
        }
        
        // Restaurar o progresso (a sessão/plan precisa ser restaurada separadamente)
        self.progress = savedProgress
    }
    
    /// Restaura sessão completa de um plano (chamado quando o app reabre)
    func restoreSession(from plan: WorkoutPlan) {
        // Se o progress persistido pertence a este plano, restaurar
        if let progress, progress.planId == plan.id {
            session = startUseCase.execute(plan: plan)
            // Encontrar o primeiro exercício não completo
            if let firstIncomplete = self.progress?.exercises.firstIndex(where: { !$0.isFullyCompleted && !$0.isSkipped }) {
                currentExerciseIndex = firstIncomplete
            }
        } else {
            // Novo treino
            start(with: plan)
        }
    }
    
    // MARK: - Haptics
    
    private func triggerSetCompletionHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

