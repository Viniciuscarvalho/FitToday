//
//  ExercisePickerViewModel.swift
//  FitToday
//
//  ViewModel for searching and selecting exercises from Wger API.
//

import Foundation

/// ViewModel for searching and selecting exercises from Wger API.
@Observable
@MainActor
final class ExercisePickerViewModel {
    // MARK: - State

    var searchText: String = "" {
        didSet { debounceSearch() }
    }

    var selectedCategory: WgerCategoryMapping?
    var selectedEquipment: WgerEquipmentMapping?

    var exercises: [WgerExercise] = []
    var isLoading = false
    var error: Error?

    // Categories for filtering (from Wger API)
    var categories: [WgerCategoryMapping] = WgerCategoryMapping.allCases

    // Equipment for filtering (from Wger API)
    var equipmentTypes: [WgerEquipmentMapping] = WgerEquipmentMapping.allCases

    // MARK: - Dependencies

    private let exerciseService: ExerciseServiceProtocol?
    private var searchTask: Task<Void, Never>?
    private let debounceDelay: UInt64 = 300_000_000 // 300ms

    // MARK: - Initialization

    init(exerciseService: ExerciseServiceProtocol?) {
        self.exerciseService = exerciseService
    }

    // MARK: - Actions

    func loadInitialExercises() async {
        guard exercises.isEmpty else { return }
        await search()
    }

    func search() async {
        searchTask?.cancel()
        isLoading = true
        error = nil

        defer { isLoading = false }

        guard let service = exerciseService else {
            error = ExercisePickerError.serviceUnavailable
            return
        }

        do {
            if !searchText.isEmpty {
                // Search by name
                exercises = try await service.searchExercises(
                    query: searchText,
                    language: .portuguese,
                    limit: 50
                )

                // Apply category filter if selected
                if let category = selectedCategory {
                    exercises = exercises.filter { $0.category == category.rawValue }
                }

                // Apply equipment filter if selected
                if let equipment = selectedEquipment {
                    exercises = exercises.filter { $0.equipment.contains(equipment.rawValue) }
                }
            } else {
                // Fetch exercises with optional filters
                let categoryId = selectedCategory?.rawValue
                let equipmentIds = selectedEquipment.map { [$0.rawValue] }

                exercises = try await service.fetchExercises(
                    language: .portuguese,
                    category: categoryId,
                    equipment: equipmentIds,
                    limit: 50
                )
            }
        } catch {
            self.error = error
            exercises = []
        }
    }

    func selectCategory(_ category: WgerCategoryMapping?) {
        if selectedCategory == category {
            selectedCategory = nil
        } else {
            selectedCategory = category
        }
        Task { await search() }
    }

    func selectEquipment(_ equipment: WgerEquipmentMapping?) {
        if selectedEquipment == equipment {
            selectedEquipment = nil
        } else {
            selectedEquipment = equipment
        }
        Task { await search() }
    }

    func clearFilters() {
        searchText = ""
        selectedCategory = nil
        selectedEquipment = nil
        Task { await search() }
    }

    // MARK: - Private

    private func debounceSearch() {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(nanoseconds: debounceDelay)
            guard !Task.isCancelled else { return }
            await search()
        }
    }
}

// MARK: - Errors

enum ExercisePickerError: LocalizedError {
    case serviceUnavailable

    var errorDescription: String? {
        switch self {
        case .serviceUnavailable:
            return String(localized: "Serviço de exercícios não disponível")
        }
    }
}
