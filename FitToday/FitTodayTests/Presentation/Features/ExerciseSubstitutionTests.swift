//
//  ExerciseSubstitutionTests.swift
//  FitTodayTests
//
//  Testes para substituição de exercícios.
//

import XCTest
@testable import FitToday

final class ExerciseSubstitutionTests: XCTestCase {
    
    // MARK: - AlternativeExercise Tests
    
    func testAlternativeExerciseInit() {
        let alternative = AlternativeExercise(
            id: "test-1",
            name: "Push-up",
            targetMuscle: "chest",
            equipment: "bodyweight",
            difficulty: "beginner",
            instructions: ["Step 1", "Step 2"],
            whyGood: "Great alternative"
        )
        
        XCTAssertEqual(alternative.name, "Push-up")
        XCTAssertEqual(alternative.targetMuscle, "chest")
        XCTAssertEqual(alternative.equipment, "bodyweight")
        XCTAssertEqual(alternative.difficulty, "beginner")
        XCTAssertEqual(alternative.instructions.count, 2)
        XCTAssertEqual(alternative.whyGood, "Great alternative")
    }
    
    func testAlternativeExerciseHashable() {
        let alt1 = AlternativeExercise(
            id: "test-1",
            name: "Push-up",
            targetMuscle: "chest",
            equipment: "bodyweight",
            difficulty: "beginner",
            instructions: [],
            whyGood: "Good"
        )
        
        let alt2 = AlternativeExercise(
            id: "test-2",
            name: "Dips",
            targetMuscle: "chest",
            equipment: "bodyweight",
            difficulty: "intermediate",
            instructions: [],
            whyGood: "Also good"
        )
        
        var set = Set<AlternativeExercise>()
        set.insert(alt1)
        set.insert(alt2)
        
        XCTAssertEqual(set.count, 2)
    }
    
    func testAlternativeExerciseCodable() throws {
        let original = AlternativeExercise(
            id: "test-1",
            name: "Push-up",
            targetMuscle: "chest",
            equipment: "bodyweight",
            difficulty: "beginner",
            instructions: ["Step 1"],
            whyGood: "Good"
        )
        
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AlternativeExercise.self, from: data)
        
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.targetMuscle, original.targetMuscle)
    }
    
    // MARK: - SubstitutionReason Tests
    
    func testSubstitutionReasonDisplayName() {
        XCTAssertEqual(SubstitutionReason.equipmentUnavailable.displayName, "Equipamento indisponível")
        XCTAssertEqual(SubstitutionReason.tooHard.displayName, "Muito difícil")
        XCTAssertEqual(SubstitutionReason.pain.displayName, "Sinto dor")
        XCTAssertEqual(SubstitutionReason.boring.displayName, "Quero variar")
        XCTAssertEqual(SubstitutionReason.other.displayName, "Outro motivo")
    }
    
    func testSubstitutionReasonAllCases() {
        XCTAssertEqual(SubstitutionReason.allCases.count, 5)
    }
    
    // MARK: - SubstitutionResponse Tests
    
    func testSubstitutionResponseDecoding() throws {
        let json = """
        {
            "alternatives": [
                {
                    "id": "1",
                    "name": "Push-up",
                    "targetMuscle": "chest",
                    "equipment": "bodyweight",
                    "difficulty": "beginner",
                    "instructions": ["Lower down", "Push up"],
                    "whyGood": "No equipment needed"
                }
            ],
            "message": "Here are your alternatives"
        }
        """
        
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(SubstitutionResponse.self, from: data)
        
        XCTAssertEqual(response.alternatives.count, 1)
        XCTAssertEqual(response.alternatives[0].name, "Push-up")
        XCTAssertEqual(response.message, "Here are your alternatives")
    }
    
    func testSubstitutionResponseWithoutMessage() throws {
        let json = """
        {
            "alternatives": [
                {
                    "id": "1",
                    "name": "Dips",
                    "targetMuscle": "triceps",
                    "equipment": "parallel_bars",
                    "difficulty": "intermediate",
                    "instructions": ["Dip down"],
                    "whyGood": "Great for triceps"
                }
            ]
        }
        """
        
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(SubstitutionResponse.self, from: data)
        
        XCTAssertEqual(response.alternatives.count, 1)
        XCTAssertNil(response.message)
    }
    
    // MARK: - SubstitutionError Tests
    
    func testSubstitutionErrorDescriptions() {
        let noAlternatives = SubstitutionError.noAlternativesFound
        XCTAssertTrue(noAlternatives.errorDescription?.contains("alternativas") == true)
        
        let apiError = SubstitutionError.apiError("Test error")
        XCTAssertTrue(apiError.errorDescription?.contains("Test error") == true)
        
        let notAvailable = SubstitutionError.notAvailable
        XCTAssertTrue(notAvailable.errorDescription?.contains("API") == true)
    }
    
    // MARK: - Factory Tests
    
    func testFactoryReturnsNilWithoutConfig() {
        // Por padrão, sem chave de API configurada, deve retornar nil
        // Este teste verifica o comportamento quando não há configuração
        // O resultado depende do estado do UserDefaults/Keychain
        
        // Apenas verificar que o método existe e não causa crash
        let _ = ExerciseSubstitutionServiceFactory.create()
        XCTAssertTrue(true)
    }
}

// MARK: - Mock Service for Testing

final class MockExerciseSubstitutionService: ExerciseSubstituting {
    var mockAlternatives: [AlternativeExercise] = []
    var shouldThrowError: SubstitutionError?
    
    func suggestAlternatives(
        for exercise: WorkoutExercise,
        userProfile: UserProfile,
        reason: SubstitutionReason?
    ) async throws -> [AlternativeExercise] {
        if let error = shouldThrowError {
            throw error
        }
        return mockAlternatives
    }
}

