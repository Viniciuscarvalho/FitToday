//
//  PersonalWorkoutsViewModel.swift
//  FitToday
//
//  ViewModel para lista de treinos do Personal.
//

import Foundation

/// ViewModel para gerenciar a lista de treinos do Personal.
@MainActor
@Observable
final class PersonalWorkoutsViewModel {
    // MARK: - Published State

    private(set) var workouts: [PersonalWorkout] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    // MARK: - Dependencies

    private let repository: PersonalWorkoutRepository
    private let pdfCache: PDFCaching
    private var observationTask: Task<Void, Never>?

    // MARK: - Computed Properties

    /// Número de treinos não visualizados.
    var newWorkoutsCount: Int {
        workouts.filter { $0.isNew }.count
    }

    /// Indica se há treinos novos.
    var hasNewWorkouts: Bool {
        newWorkoutsCount > 0
    }

    /// Indica se a lista está vazia.
    var isEmpty: Bool {
        workouts.isEmpty && !isLoading
    }

    // MARK: - Initialization

    init(repository: PersonalWorkoutRepository, pdfCache: PDFCaching) {
        self.repository = repository
        self.pdfCache = pdfCache
    }

    /// Cancela a observação de treinos.
    func stopObserving() {
        observationTask?.cancel()
        observationTask = nil
    }

    // MARK: - Public Methods

    /// Inicia observação em tempo real dos treinos.
    /// - Parameter userId: ID do usuário
    func startObserving(userId: String) {
        observationTask?.cancel()
        observationTask = Task {
            for await updatedWorkouts in repository.observeWorkouts(for: userId) {
                guard !Task.isCancelled else { return }
                self.workouts = updatedWorkouts
                #if DEBUG
                print("[PersonalWorkoutsVM] Observação: \(updatedWorkouts.count) treinos")
                #endif
            }
        }
    }

    /// Carrega os treinos do usuário.
    /// - Parameter userId: ID do usuário
    func loadWorkouts(userId: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            workouts = try await repository.fetchWorkouts(for: userId)
            #if DEBUG
            print("[PersonalWorkoutsVM] Carregados \(workouts.count) treinos")
            #endif
        } catch {
            errorMessage = "Não foi possível carregar os treinos: \(error.localizedDescription)"
            #if DEBUG
            print("[PersonalWorkoutsVM] Erro: \(error)")
            #endif
        }
    }

    /// Marca um treino como visualizado.
    /// - Parameter workout: O treino a ser marcado
    func markAsViewed(_ workout: PersonalWorkout) async {
        guard workout.isNew else { return }

        do {
            try await repository.markAsViewed(workout.id)

            // Atualizar localmente
            if let index = workouts.firstIndex(where: { $0.id == workout.id }) {
                workouts[index].viewedAt = Date()
            }

            #if DEBUG
            print("[PersonalWorkoutsVM] Treino \(workout.id) marcado como visualizado")
            #endif
        } catch {
            // Falha silenciosa - não é crítico
            #if DEBUG
            print("[PersonalWorkoutsVM] Erro ao marcar como visualizado: \(error)")
            #endif
        }
    }

    /// Obtém a URL local do PDF (do cache ou baixando).
    /// - Parameter workout: O treino
    /// - Returns: URL local do arquivo
    func getPDFURL(for workout: PersonalWorkout) async throws -> URL {
        try await pdfCache.getPDF(for: workout)
    }

    /// Verifica se o PDF está em cache.
    /// - Parameter workout: O treino
    /// - Returns: true se o arquivo está em cache
    func isPDFCached(_ workout: PersonalWorkout) async -> Bool {
        await pdfCache.isCached(workoutId: workout.id, fileType: workout.fileType)
    }

    /// Limpa mensagem de erro.
    func clearError() {
        errorMessage = nil
    }
}
