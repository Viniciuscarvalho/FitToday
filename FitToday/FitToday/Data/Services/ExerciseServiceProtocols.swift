//
//  ExerciseServiceProtocols.swift
//  FitToday
//
//  Protocols for exercise catalog service, name normalization, and media resolution.
//

import Foundation

// MARK: - Exercise Service Protocol

/// Protocol for fetching exercises from the catalog (Firestore).
protocol ExerciseServiceProtocol: Sendable {
    func fetchExercises(language: ExerciseLanguageCode, category: String?, equipment: [Int]?, limit: Int) async throws -> [CatalogExercise]
    func fetchExercise(id: String) async throws -> CatalogExercise?
    func searchExercises(query: String, language: ExerciseLanguageCode, limit: Int) async throws -> [CatalogExercise]
}


