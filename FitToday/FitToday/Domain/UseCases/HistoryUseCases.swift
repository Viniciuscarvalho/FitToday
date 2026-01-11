//
//  HistoryUseCases.swift
//  FitToday
//
//  Created by AI on 03/01/26.
//

import Foundation

struct ListWorkoutHistoryUseCase {
    private let repository: WorkoutHistoryRepository

    init(repository: WorkoutHistoryRepository) {
        self.repository = repository
    }

    func execute() async throws -> [WorkoutHistoryEntry] {
        try await repository.listEntries().sorted { $0.date > $1.date }
    }
}




