//
//  FirestoreExerciseService.swift
//  FitToday
//
//  Fetches exercises from the Firestore catalog collection.
//  Primary exercise data source for the app.
//

import Foundation
import FirebaseFirestore

/// Firestore-backed exercise service.
actor FirestoreExerciseService: ExerciseServiceProtocol {
    private let db = Firestore.firestore()
    private let collectionName = "exercises"

    /// In-memory cache: [exerciseId: CatalogExercise]
    private var cache: [String: CatalogExercise] = [:]

    // MARK: - ExerciseServiceProtocol

    func fetchExercises(
        language: ExerciseLanguageCode,
        category: String?,
        equipment: [Int]?,
        limit: Int
    ) async throws -> [CatalogExercise] {
        var query: Query = db.collection(collectionName)

        if let category {
            query = query.whereField("category", isEqualTo: category)
        }

        if let equipment, let firstEquipment = equipment.first {
            query = query.whereField("equipment", arrayContains: firstEquipment)
        }

        query = query.limit(to: limit)

        let snapshot = try await query.getDocuments()
        let exercises = snapshot.documents.compactMap { doc -> CatalogExercise? in
            let exercise = parseCatalogExercise(from: doc, language: language)
            if let exercise { cache[exercise.id] = exercise }
            return exercise
        }

        #if DEBUG
        print("[FirestoreExerciseService] Fetched \(exercises.count) exercises (category: \(category ?? "all"))")
        #endif

        return exercises
    }

    func fetchExercise(id: String) async throws -> CatalogExercise? {
        if let cached = cache[id] {
            return cached
        }

        let doc = try await db.collection(collectionName).document(id).getDocument()

        guard doc.exists else { return nil }

        let exercise = parseCatalogExercise(from: doc, language: .portuguese)
        if let exercise { cache[exercise.id] = exercise }
        return exercise
    }

    func searchExercises(
        query: String,
        language: ExerciseLanguageCode,
        limit: Int
    ) async throws -> [CatalogExercise] {
        // Firestore doesn't support full-text search natively.
        // Use prefix matching on the name field.
        let normalizedQuery = query.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)

        let snapshot = try await db.collection(collectionName)
            .order(by: "name")
            .start(at: [normalizedQuery])
            .end(at: [normalizedQuery + "\u{f8ff}"])
            .limit(to: limit)
            .getDocuments()

        let exercises = snapshot.documents.compactMap { doc -> CatalogExercise? in
            let exercise = parseCatalogExercise(from: doc, language: language)
            if let exercise { cache[exercise.id] = exercise }
            return exercise
        }

        #if DEBUG
        print("[FirestoreExerciseService] Search '\(query)' → \(exercises.count) results")
        #endif

        return exercises
    }

    // MARK: - Parsing

    private func parseCatalogExercise(from doc: DocumentSnapshot, language: ExerciseLanguageCode) -> CatalogExercise? {
        guard let data = doc.data() else { return nil }

        let name = resolveExerciseName(from: data, documentId: doc.documentID, language: language)
        let description = resolveExerciseDescription(from: data, language: language)

        #if DEBUG
        if data["name"] == nil && data["name_\(language.code)"] == nil {
            print("[FirestoreExerciseService] ⚠️ No name field found for \(doc.documentID). Keys: \(data.keys.sorted())")
        }
        #endif

        return CatalogExercise(
            id: doc.documentID,
            name: name,
            description: description,
            category: data["category"] as? String,
            muscles: data["muscles"] as? [Int] ?? [],
            musclesSecondary: data["musclesSecondary"] as? [Int] ?? [],
            equipment: data["equipment"] as? [Int] ?? []
        )
    }

    /// Resolves the exercise name trying language-specific fields first, then generic name,
    /// then falls back to a human-readable form of the document ID.
    private func resolveExerciseName(from data: [String: Any], documentId: String, language: ExerciseLanguageCode) -> String {
        // Try language-specific name (e.g., "name_pt", "name_en")
        if let localizedName = data["name_\(language.code)"] as? String, !localizedName.isEmpty {
            return localizedName
        }
        // Try generic "name" field
        if let name = data["name"] as? String, !name.isEmpty {
            return name
        }
        // Fallback: convert document ID to readable name (e.g., "barbell_bench_press" → "Barbell Bench Press")
        return documentId
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }

    /// Resolves the exercise description trying language-specific fields first.
    private func resolveExerciseDescription(from data: [String: Any], language: ExerciseLanguageCode) -> String? {
        if let localized = data["description_\(language.code)"] as? String, !localized.isEmpty {
            return localized
        }
        return data["description"] as? String
    }

    // MARK: - Cache

    func clearCache() {
        cache.removeAll()
    }
}
