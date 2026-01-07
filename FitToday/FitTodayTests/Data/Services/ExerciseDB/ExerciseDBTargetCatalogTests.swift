//
//  ExerciseDBTargetCatalogTests.swift
//  FitTodayTests
//
//  Created by AI on 05/01/26.
//

import XCTest
@testable import FitToday

final class ExerciseDBTargetCatalogTests: XCTestCase {
    var sut: ExerciseDBTargetCatalog!
    var mockService: MockExerciseDBService!
    var mockUserDefaults: UserDefaults!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Cria UserDefaults separado para testes
        mockUserDefaults = UserDefaults(suiteName: "test.exercisedb.catalog")!
        mockUserDefaults.removePersistentDomain(forName: "test.exercisedb.catalog")
        
        mockService = MockExerciseDBService()
        sut = ExerciseDBTargetCatalog(
            service: mockService,
            userDefaults: mockUserDefaults,
            ttl: 60 // 60 segundos para facilitar testes
        )
    }
    
    override func tearDown() async throws {
        await sut.clearCache()
        mockUserDefaults.removePersistentDomain(forName: "test.exercisedb.catalog")
        sut = nil
        mockService = nil
        mockUserDefaults = nil
        try await super.tearDown()
    }
    
    // MARK: - Load Targets Tests
    
    func testLoadTargets_FirstTime_FetchesFromService() async throws {
        // Given
        let expectedTargets = ["biceps", "triceps", "chest", "back"]
        mockService.stubbedTargetList = expectedTargets
        
        // When
        let targets = try await sut.loadTargets()
        
        // Then
        XCTAssertEqual(targets.count, 4)
        XCTAssertTrue(mockService.fetchTargetListCalled)
        XCTAssertEqual(targets, expectedTargets)
    }
    
    func testLoadTargets_SecondTime_UsesCacheInMemory() async throws {
        // Given
        mockService.stubbedTargetList = ["biceps", "triceps"]
        
        // When
        _ = try await sut.loadTargets()
        mockService.fetchTargetListCalled = false // Reset
        let cachedTargets = try await sut.loadTargets()
        
        // Then
        XCTAssertFalse(mockService.fetchTargetListCalled, "Deve usar cache em memória")
        XCTAssertEqual(cachedTargets.count, 2)
    }
    
    func testLoadTargets_ForceRefresh_FetchesAgainFromService() async throws {
        // Given
        mockService.stubbedTargetList = ["biceps"]
        _ = try await sut.loadTargets()
        
        // When
        mockService.stubbedTargetList = ["biceps", "triceps", "chest"]
        mockService.fetchTargetListCalled = false
        let refreshedTargets = try await sut.loadTargets(forceRefresh: true)
        
        // Then
        XCTAssertTrue(mockService.fetchTargetListCalled, "Deve buscar da API")
        XCTAssertEqual(refreshedTargets.count, 3)
    }
    
    func testLoadTargets_AfterCacheClear_FetchesAgain() async throws {
        // Given
        mockService.stubbedTargetList = ["biceps"]
        _ = try await sut.loadTargets()
        
        // When
        await sut.clearCache()
        mockService.fetchTargetListCalled = false
        _ = try await sut.loadTargets()
        
        // Then
        XCTAssertTrue(mockService.fetchTargetListCalled, "Deve buscar após clear")
    }
    
    // MARK: - Is Valid Target Tests
    
    func testIsValidTarget_ValidTarget_ReturnsTrue() async throws {
        // Given
        mockService.stubbedTargetList = ["biceps", "triceps", "chest"]
        _ = try await sut.loadTargets()
        
        // When
        let isValid = await sut.isValidTarget("biceps")
        
        // Then
        XCTAssertTrue(isValid)
    }
    
    func testIsValidTarget_InvalidTarget_ReturnsFalse() async throws {
        // Given
        mockService.stubbedTargetList = ["biceps", "triceps"]
        _ = try await sut.loadTargets()
        
        // When
        let isValid = await sut.isValidTarget("quads")
        
        // Then
        XCTAssertFalse(isValid)
    }
    
    func testIsValidTarget_CaseInsensitive_ReturnsTrue() async throws {
        // Given
        mockService.stubbedTargetList = ["biceps", "Triceps", "CHEST"]
        _ = try await sut.loadTargets()
        
        // When
        let bicepsValid = await sut.isValidTarget("BiCePs")
        let tricepsValid = await sut.isValidTarget("triceps")
        let chestValid = await sut.isValidTarget("chest")
        
        // Then
        XCTAssertTrue(bicepsValid)
        XCTAssertTrue(tricepsValid)
        XCTAssertTrue(chestValid)
    }
    
    func testIsValidTarget_WithWhitespace_TrimsAndValidates() async throws {
        // Given
        mockService.stubbedTargetList = ["biceps"]
        _ = try await sut.loadTargets()
        
        // When
        let isValid = await sut.isValidTarget("  biceps  ")
        
        // Then
        XCTAssertTrue(isValid)
    }
    
    // MARK: - Persistence Tests
    
    func testLoadTargets_PersistsToUserDefaults() async throws {
        // Given
        mockService.stubbedTargetList = ["biceps", "triceps"]
        
        // When
        _ = try await sut.loadTargets()
        
        // Then
        let data = mockUserDefaults.data(forKey: "exercisedb_target_list_v1")
        XCTAssertNotNil(data, "Deve persistir no UserDefaults")
        
        let decoded = try? JSONDecoder().decode([String].self, from: data!)
        XCTAssertEqual(decoded, ["biceps", "triceps"])
    }
    
    func testLoadTargets_LoadsFromPersistedCache() async throws {
        // Given - Persistir manualmente
        let targets = ["chest", "back"]
        let data = try JSONEncoder().encode(targets)
        mockUserDefaults.set(data, forKey: "exercisedb_target_list_v1")
        mockUserDefaults.set(Date().timeIntervalSince1970, forKey: "exercisedb_target_list_timestamp_v1")
        
        // When
        let loaded = try await sut.loadTargets()
        
        // Then
        XCTAssertEqual(loaded, targets)
        XCTAssertFalse(mockService.fetchTargetListCalled, "Não deve buscar da API se cache é válido")
    }
}

// MARK: - Mock Service

class MockExerciseDBService: ExerciseDBServicing {
    var stubbedTargetList: [String] = []
    var stubbedExercises: [ExerciseDBExercise] = []
    var fetchTargetListCalled = false
    var fetchExercisesCalled = false
    
    func fetchTargetList() async throws -> [String] {
        fetchTargetListCalled = true
        return stubbedTargetList
    }
    
    func fetchExercises(target: String, limit: Int) async throws -> [ExerciseDBExercise] {
        fetchExercisesCalled = true
        return stubbedExercises
    }
    
    func fetchExercise(byId id: String) async throws -> ExerciseDBExercise? {
        return nil
    }
    
    func searchExercises(query: String, limit: Int) async throws -> [ExerciseDBExercise] {
        return []
    }
    
    func fetchImageURL(exerciseId: String, resolution: ExerciseImageResolution) async throws -> URL? {
        return nil
    }

    func fetchImageData(
        exerciseId: String,
        resolution: ExerciseImageResolution
    ) async throws -> (data: Data, mimeType: String)? {
        return nil
    }
}

