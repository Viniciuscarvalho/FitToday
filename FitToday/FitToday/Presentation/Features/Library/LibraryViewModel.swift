//
//  LibraryViewModel.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import Foundation

// 💡 Learn: @Observable elimina a necessidade de Combine publishers
@MainActor
@Observable final class LibraryViewModel: ErrorPresenting {
    private(set) var allWorkouts: [LibraryWorkout] = []
    private(set) var filteredWorkouts: [LibraryWorkout] = []
    var filter: LibraryFilter = .empty {
        didSet {
            // 💡 Learn: Com @Observable, use didSet em vez de Combine sink
            applyFilter(filter)
        }
    }
    private(set) var isLoading = false
    var errorMessage: ErrorMessage? // ErrorPresenting protocol

    private let repository: LibraryWorkoutsRepository

    init(repository: LibraryWorkoutsRepository) {
        self.repository = repository
    }

    func loadWorkouts() {
        guard allWorkouts.isEmpty else { return }
        isLoading = true
        Task {
            do {
                let workouts = try await repository.loadWorkouts()
                allWorkouts = workouts
                applyFilter(filter)
            } catch {
                handleError(error) // ErrorPresenting protocol
            }
            isLoading = false
        }
    }

    private func applyFilter(_ filter: LibraryFilter) {
        var result = allWorkouts
        if let goal = filter.goal {
            result = result.filter { $0.goal == goal }
        }
        if let structure = filter.structure {
            result = result.filter { $0.structure == structure }
        }
        filteredWorkouts = result
    }

    func clearFilter() {
        filter = .empty
    }

    // MARK: - Filter Options

    var availableGoals: [FitnessGoal] {
        Array(Set(allWorkouts.map(\.goal))).sorted { $0.displayName < $1.displayName }
    }

    var availableStructures: [TrainingStructure] {
        Array(Set(allWorkouts.map(\.structure))).sorted { $0.displayName < $1.displayName }
    }
}

// MARK: - Display Helpers

extension FitnessGoal {
    var displayName: String {
        switch self {
        case .hypertrophy: return "Hipertrofia"
        case .conditioning: return "Condicionamento"
        case .endurance: return "Resistência"
        case .weightLoss: return "Perda de Peso"
        case .performance: return "Performance"
        }
    }
}

extension TrainingStructure {
    var displayName: String {
        switch self {
        case .fullGym: return "Academia Completa"
        case .basicGym: return "Academia Básica"
        case .homeDumbbells: return "Casa (Halteres)"
        case .bodyweight: return "Peso Corporal"
        }
    }
}

extension WorkoutIntensity {
    var displayName: String {
        switch self {
        case .low: return "Leve"
        case .moderate: return "Moderado"
        case .high: return "Intenso"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "green"
        case .moderate: return "orange"
        case .high: return "red"
        }
    }
}

