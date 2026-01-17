//
//  ExerciseNameNormalizerTests.swift
//  FitTodayTests
//
//  Created by AI on 16/01/26.
//

@testable import FitToday
import XCTest

final class ExerciseNameNormalizerTests: XCTestCase {

    var sut: ExerciseNameNormalizer!
    fileprivate var mockExerciseDBService: ExerciseNameNormalizerMockService!

    override func setUp() async throws {
        mockExerciseDBService = ExerciseNameNormalizerMockService()
        sut = ExerciseNameNormalizer(exerciseDBService: mockExerciseDBService)
    }

    // MARK: - Translation Tests

    func testNormalize_portugueseName_translatesBeforeMatching() async throws {
        // Given
        mockExerciseDBService.stubbedExercises = [
            ExerciseDBExercise(
                bodyPart: "chest",
                equipment: "barbell",
                id: "1",
                name: "barbell bench press",
                target: "pectorals",
                secondaryMuscles: nil,
                instructions: nil,
                description: nil,
                difficulty: nil,
                category: nil
            )
        ]

        // When
        let result = try await sut.normalize(
            exerciseName: "Supino reto com barra", // PT
            equipment: "barbell",
            muscleGroup: "pectorals"
        )

        // Then
        XCTAssertEqual(result, "barbell bench press")
    }

    // MARK: - Exact Match Tests

    func testNormalize_exactMatch_returnsExerciseDBName() async throws {
        // Given
        mockExerciseDBService.stubbedExercises = [
            ExerciseDBExercise(
                bodyPart: "legs",
                equipment: "barbell",
                id: "1",
                name: "squat",
                target: "quads",
                secondaryMuscles: nil,
                instructions: nil,
                description: nil,
                difficulty: nil,
                category: nil
            )
        ]

        // When
        let result = try await sut.normalize(
            exerciseName: "squat",
            equipment: "barbell",
            muscleGroup: "quads"
        )

        // Then
        XCTAssertEqual(result, "squat")
    }

    // MARK: - Fuzzy Match Tests

    func testNormalize_similarName_returnsBestMatch() async throws {
        // Given - Nome similar mas não exato
        mockExerciseDBService.stubbedExercises = [
            ExerciseDBExercise(
                bodyPart: "chest",
                equipment: "barbell",
                id: "1",
                name: "barbell bench press",
                target: "pectorals",
                secondaryMuscles: nil,
                instructions: nil,
                description: nil,
                difficulty: nil,
                category: nil
            ),
            ExerciseDBExercise(
                bodyPart: "chest",
                equipment: "dumbbell",
                id: "2",
                name: "dumbbell bench press",
                target: "pectorals",
                secondaryMuscles: nil,
                instructions: nil,
                description: nil,
                difficulty: nil,
                category: nil
            )
        ]

        // When - Nome com pequena variação
        let result = try await sut.normalize(
            exerciseName: "bench press with barbell",
            equipment: "barbell",
            muscleGroup: "pectorals"
        )

        // Then - Deve escolher barbell bench press (melhor score)
        XCTAssertEqual(result, "barbell bench press")
    }

    // MARK: - Equipment Validation Tests

    func testNormalize_equipmentMatch_boostsScore() async throws {
        // Given
        mockExerciseDBService.stubbedExercises = [
            ExerciseDBExercise(
                bodyPart: "chest",
                equipment: "barbell", // Equipamento correto
                id: "1",
                name: "bench press",
                target: "pectorals",
                secondaryMuscles: nil,
                instructions: nil,
                description: nil,
                difficulty: nil,
                category: nil
            ),
            ExerciseDBExercise(
                bodyPart: "chest",
                equipment: "dumbbell", // Equipamento diferente
                id: "2",
                name: "bench press",
                target: "pectorals",
                secondaryMuscles: nil,
                instructions: nil,
                description: nil,
                difficulty: nil,
                category: nil
            )
        ]

        // When
        let result = try await sut.normalize(
            exerciseName: "bench press",
            equipment: "barbell",
            muscleGroup: "pectorals"
        )

        // Then - Deve escolher o com equipamento correto
        XCTAssertEqual(result, "bench press") // ID 1
    }

    // MARK: - Fallback Tests

    func testNormalize_noMatch_returnsOriginalName() async throws {
        // Given - Nenhum exercício encontrado
        mockExerciseDBService.stubbedExercises = []

        // When
        let result = try await sut.normalize(
            exerciseName: "Exercício Personalizado XYZ",
            equipment: nil,
            muscleGroup: nil
        )

        // Then - Retorna nome original
        XCTAssertEqual(result, "Exercício Personalizado XYZ")
    }

    func testNormalize_lowScore_returnsOriginalName() async throws {
        // Given - Match com score baixo (<80%)
        mockExerciseDBService.stubbedExercises = [
            ExerciseDBExercise(
                bodyPart: "arms",
                equipment: "dumbbell",
                id: "1",
                name: "completely different exercise",
                target: "biceps",
                secondaryMuscles: nil,
                instructions: nil,
                description: nil,
                difficulty: nil,
                category: nil
            )
        ]

        // When
        let result = try await sut.normalize(
            exerciseName: "supino reto",
            equipment: "barbell",
            muscleGroup: "pectorals"
        )

        // Then - Score muito baixo, retorna original
        XCTAssertEqual(result, "supino reto")
    }

    // MARK: - Cache Tests

    func testNormalize_cachedResult_doesNotCallServiceTwice() async throws {
        // Given
        mockExerciseDBService.stubbedExercises = [
            ExerciseDBExercise(
                bodyPart: "legs",
                equipment: "barbell",
                id: "1",
                name: "squat",
                target: "quads",
                secondaryMuscles: nil,
                instructions: nil,
                description: nil,
                difficulty: nil,
                category: nil
            )
        ]

        // When - Primeira chamada
        _ = try await sut.normalize(
            exerciseName: "squat",
            equipment: "barbell",
            muscleGroup: "quads"
        )

        let firstCallCount = mockExerciseDBService.fetchExercisesCallCount

        // Segunda chamada (deveria usar cache)
        _ = try await sut.normalize(
            exerciseName: "squat",
            equipment: "barbell",
            muscleGroup: "quads"
        )

        // Then
        XCTAssertEqual(
            mockExerciseDBService.fetchExercisesCallCount,
            firstCallCount,
            "Não deveria chamar o serviço novamente (cache hit)"
        )
    }

    // MARK: - Performance Tests

    func testNormalize_largeDataset_completesUnder500ms() async throws {
        // Given - 50 exercícios para testar performance
        mockExerciseDBService.stubbedExercises = (0..<50).map { i in
            ExerciseDBExercise(
                bodyPart: "body",
                equipment: "equipment",
                id: "\(i)",
                name: "exercise \(i)",
                target: "muscle",
                secondaryMuscles: nil,
                instructions: nil,
                description: nil,
                difficulty: nil,
                category: nil
            )
        }

        // When
        let startTime = Date()
        _ = try await sut.normalize(
            exerciseName: "exercise 25",
            equipment: "equipment",
            muscleGroup: "muscle"
        )
        let duration = Date().timeIntervalSince(startTime)

        // Then - Deve completar em menos de 500ms
        XCTAssertLessThan(duration, 0.5)
    }

    // MARK: - Additional Edge Case Tests

    func testNormalize_nilEquipmentAndMuscleGroup_usesSearchQuery() async throws {
        // Given
        mockExerciseDBService.stubbedExercises = [
            ExerciseDBExercise(
                bodyPart: "chest",
                equipment: "bodyweight",
                id: "1",
                name: "push up",
                target: "pectorals",
                secondaryMuscles: nil,
                instructions: nil,
                description: nil,
                difficulty: nil,
                category: nil
            )
        ]

        // When - Sem equipamento nem grupo muscular
        let result = try await sut.normalize(
            exerciseName: "push up",
            equipment: nil,
            muscleGroup: nil
        )

        // Then
        XCTAssertEqual(result, "push up")
        XCTAssertTrue(mockExerciseDBService.searchExercisesCalled, "Deveria usar searchExercises quando não há target")
    }
}

// MARK: - Mock

fileprivate final class ExerciseNameNormalizerMockService: ExerciseDBServicing, @unchecked Sendable {
    var stubbedExercises: [ExerciseDBExercise] = []
    var fetchExercisesCallCount = 0
    var searchExercisesCalled = false

    func searchExercises(query: String, limit: Int) async throws -> [ExerciseDBExercise] {
        searchExercisesCalled = true
        fetchExercisesCallCount += 1
        return stubbedExercises
    }

    func fetchExercises(target: String, limit: Int) async throws -> [ExerciseDBExercise] {
        fetchExercisesCallCount += 1
        return stubbedExercises
    }

    func fetchExercise(byId id: String) async throws -> ExerciseDBExercise? {
        stubbedExercises.first { $0.id == id }
    }

    func fetchTargetList() async throws -> [String] {
        []
    }

    func fetchImageURL(exerciseId: String, resolution: ExerciseImageResolution) async throws -> URL? {
        nil
    }

    func fetchImageData(
        exerciseId: String,
        resolution: ExerciseImageResolution
    ) async throws -> (data: Data, mimeType: String)? {
        nil
    }
}
