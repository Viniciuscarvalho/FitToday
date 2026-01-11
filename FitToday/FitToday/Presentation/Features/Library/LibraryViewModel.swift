//
//  LibraryViewModel.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import Foundation
import Combine

@MainActor
final class LibraryViewModel: ObservableObject, ErrorPresenting {
    @Published private(set) var allWorkouts: [LibraryWorkout] = []
    @Published private(set) var filteredWorkouts: [LibraryWorkout] = []
    @Published var filter: LibraryFilter = .empty
    @Published private(set) var isLoading = false
    @Published var errorMessage: ErrorMessage? // ErrorPresenting protocol

    private let repository: LibraryWorkoutsRepository
    private var cancellables = Set<AnyCancellable>()

    init(repository: LibraryWorkoutsRepository) {
        self.repository = repository
        setupFilterBinding()
    }

    private func setupFilterBinding() {
        $filter
            .sink { [weak self] newFilter in
                self?.applyFilter(newFilter)
            }
            .store(in: &cancellables)
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

