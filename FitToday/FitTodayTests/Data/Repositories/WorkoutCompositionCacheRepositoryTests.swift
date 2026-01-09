//
//  WorkoutCompositionCacheRepositoryTests.swift
//  FitTodayTests
//
//  Created by AI on 09/01/26.
//

import XCTest
import SwiftData
@testable import FitToday

@MainActor
final class WorkoutCompositionCacheRepositoryTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var repository: SwiftDataWorkoutCompositionCacheRepository!
    
    override func setUp() {
        super.setUp()
        // Usar container em memória para testes
        let schema = Schema([SDCachedWorkout.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try! ModelContainer(for: schema, configurations: [config])
        repository = SwiftDataWorkoutCompositionCacheRepository(modelContainer: modelContainer)
        SwiftDataWorkoutCompositionCacheRepository.isCacheDisabled = false
    }
    
    override func tearDown() {
        modelContainer = nil
        repository = nil
        SwiftDataWorkoutCompositionCacheRepository.isCacheDisabled = false
        super.tearDown()
    }
    
    // MARK: - Helpers
    
    private func makeTestWorkoutPlan(title: String = "Test Workout") -> WorkoutPlan {
        WorkoutPlan(
            id: UUID(),
            title: title,
            focus: .fullBody,
            estimatedDurationMinutes: 45,
            intensity: .moderate,
            phases: [
                WorkoutPlanPhase(
                    kind: .warmup,
                    title: "Warmup",
                    rpeTarget: 5,
                    items: []
                ),
                WorkoutPlanPhase(
                    kind: .strength,
                    title: "Strength",
                    rpeTarget: 8,
                    items: []
                )
            ]
        )
    }
    
    private func makeCachedEntry(
        hash: String = "test_hash_123",
        workoutPlan: WorkoutPlan? = nil,
        createdAt: Date = Date(),
        ttlSeconds: TimeInterval = SDCachedWorkout.defaultTTLSeconds
    ) -> CachedWorkoutEntry {
        let plan = workoutPlan ?? makeTestWorkoutPlan()
        return CachedWorkoutEntry(
            inputsHash: hash,
            workoutPlan: plan,
            createdAt: createdAt,
            expiresAt: createdAt.addingTimeInterval(ttlSeconds),
            goal: .hypertrophy,
            structure: .fullGym,
            focus: .fullBody,
            blueprintVersion: BlueprintVersion.current.rawValue,
            variationSeed: 12345
        )
    }
    
    // MARK: - Hash Stability Tests
    
    func testBlueprintInputCacheKeyIsStable() {
        let input1 = BlueprintInput(
            goal: .hypertrophy,
            structure: .fullGym,
            level: .intermediate,
            focus: .fullBody,
            sorenessLevel: .light,
            sorenessAreas: [.chest],
            dayOfWeek: 2,
            weekOfYear: 1
        )
        
        let input2 = BlueprintInput(
            goal: .hypertrophy,
            structure: .fullGym,
            level: .intermediate,
            focus: .fullBody,
            sorenessLevel: .light,
            sorenessAreas: [.chest],
            dayOfWeek: 2,
            weekOfYear: 1
        )
        
        XCTAssertEqual(input1.cacheKey, input2.cacheKey, "Same inputs should produce same cache key")
    }
    
    func testBlueprintInputCacheKeyDiffersWithDifferentInputs() {
        let input1 = BlueprintInput(
            goal: .hypertrophy,
            structure: .fullGym,
            level: .intermediate,
            focus: .fullBody,
            sorenessLevel: .light,
            sorenessAreas: [],
            dayOfWeek: 2,
            weekOfYear: 1
        )
        
        let input2 = BlueprintInput(
            goal: .weightLoss, // Different goal
            structure: .fullGym,
            level: .intermediate,
            focus: .fullBody,
            sorenessLevel: .light,
            sorenessAreas: [],
            dayOfWeek: 2,
            weekOfYear: 1
        )
        
        XCTAssertNotEqual(input1.cacheKey, input2.cacheKey, "Different inputs should produce different cache keys")
    }
    
    func testVariationSeedIsDeterministic() {
        let input = BlueprintInput(
            goal: .hypertrophy,
            structure: .fullGym,
            level: .intermediate,
            focus: .fullBody,
            sorenessLevel: .none,
            sorenessAreas: [],
            dayOfWeek: 3,
            weekOfYear: 5
        )
        
        let seed1 = input.variationSeed
        let seed2 = input.variationSeed
        
        XCTAssertEqual(seed1, seed2, "Variation seed should be deterministic")
    }
    
    // MARK: - Cache Hit/Miss Tests
    
    func testCacheMissReturnsNil() async throws {
        let result = try await repository.getCachedWorkout(for: "nonexistent_hash")
        XCTAssertNil(result, "Cache miss should return nil")
    }
    
    func testCacheHitReturnsEntry() async throws {
        let entry = makeCachedEntry(hash: "hit_test_hash")
        try await repository.saveCachedWorkout(entry)
        
        let result = try await repository.getCachedWorkout(for: "hit_test_hash")
        
        XCTAssertNotNil(result, "Cache hit should return entry")
        XCTAssertEqual(result?.inputsHash, "hit_test_hash")
        XCTAssertEqual(result?.workoutPlan.title, entry.workoutPlan.title)
        XCTAssertEqual(result?.goal, .hypertrophy)
        XCTAssertEqual(result?.structure, .fullGym)
    }
    
    func testSaveUpdatesExistingEntry() async throws {
        let entry1 = makeCachedEntry(hash: "update_test", workoutPlan: makeTestWorkoutPlan(title: "Original"))
        try await repository.saveCachedWorkout(entry1)
        
        let entry2 = makeCachedEntry(hash: "update_test", workoutPlan: makeTestWorkoutPlan(title: "Updated"))
        try await repository.saveCachedWorkout(entry2)
        
        let result = try await repository.getCachedWorkout(for: "update_test")
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.workoutPlan.title, "Updated", "Save should update existing entry")
        
        // Verificar que há apenas 1 entry
        let stats = try await repository.getStats()
        XCTAssertEqual(stats.total, 1, "Should have only 1 entry after update")
    }
    
    // MARK: - TTL Tests
    
    func testValidCacheIsNotExpired() async throws {
        let entry = makeCachedEntry(hash: "ttl_valid", createdAt: Date())
        try await repository.saveCachedWorkout(entry)
        
        let result = try await repository.getCachedWorkout(for: "ttl_valid")
        
        XCTAssertNotNil(result, "Valid cache should not be expired")
        XCTAssertFalse(result!.isExpired)
        XCTAssertGreaterThan(result!.timeToLive, 0)
    }
    
    func testExpiredCacheReturnsNil() async throws {
        // Criar entry com TTL negativo (já expirado)
        let pastDate = Date().addingTimeInterval(-48 * 60 * 60) // 48h atrás
        let entry = makeCachedEntry(hash: "ttl_expired", createdAt: pastDate, ttlSeconds: 24 * 60 * 60)
        
        try await repository.saveCachedWorkout(entry)
        
        let result = try await repository.getCachedWorkout(for: "ttl_expired")
        
        XCTAssertNil(result, "Expired cache should return nil")
    }
    
    func testDefaultTTLIs24Hours() {
        XCTAssertEqual(SDCachedWorkout.defaultTTLSeconds, 24 * 60 * 60, "Default TTL should be 24 hours")
    }
    
    // MARK: - Cleanup Tests
    
    func testCleanupRemovesExpiredEntries() async throws {
        // Criar entries válidas e expiradas
        let validEntry = makeCachedEntry(hash: "cleanup_valid", createdAt: Date())
        try await repository.saveCachedWorkout(validEntry)
        
        let expiredDate = Date().addingTimeInterval(-48 * 60 * 60)
        let expiredEntry1 = makeCachedEntry(hash: "cleanup_expired_1", createdAt: expiredDate, ttlSeconds: 24 * 60 * 60)
        let expiredEntry2 = makeCachedEntry(hash: "cleanup_expired_2", createdAt: expiredDate, ttlSeconds: 24 * 60 * 60)
        try await repository.saveCachedWorkout(expiredEntry1)
        try await repository.saveCachedWorkout(expiredEntry2)
        
        let removedCount = try await repository.cleanupExpired()
        
        XCTAssertEqual(removedCount, 2, "Should remove 2 expired entries")
        
        let stats = try await repository.getStats()
        XCTAssertEqual(stats.total, 1, "Should have 1 valid entry remaining")
        XCTAssertEqual(stats.expired, 0, "Should have 0 expired entries")
        XCTAssertEqual(stats.validCount, 1, "Valid count should be 1")
    }
    
    func testCleanupWithNoExpiredReturnsZero() async throws {
        let entry = makeCachedEntry(hash: "no_expired_test")
        try await repository.saveCachedWorkout(entry)
        
        let removedCount = try await repository.cleanupExpired()
        
        XCTAssertEqual(removedCount, 0, "Should return 0 when no expired entries")
    }
    
    // MARK: - Clear All Tests
    
    func testClearAllRemovesEverything() async throws {
        try await repository.saveCachedWorkout(makeCachedEntry(hash: "clear_1"))
        try await repository.saveCachedWorkout(makeCachedEntry(hash: "clear_2"))
        try await repository.saveCachedWorkout(makeCachedEntry(hash: "clear_3"))
        
        try await repository.clearAll()
        
        let stats = try await repository.getStats()
        XCTAssertEqual(stats.total, 0, "Clear all should remove everything")
    }
    
    // MARK: - Stats Tests
    
    func testStatsReturnsCorrectCounts() async throws {
        // Valid entries
        try await repository.saveCachedWorkout(makeCachedEntry(hash: "stats_valid_1"))
        try await repository.saveCachedWorkout(makeCachedEntry(hash: "stats_valid_2"))
        
        // Expired entry
        let expiredDate = Date().addingTimeInterval(-48 * 60 * 60)
        let expiredEntry = makeCachedEntry(hash: "stats_expired", createdAt: expiredDate, ttlSeconds: 24 * 60 * 60)
        try await repository.saveCachedWorkout(expiredEntry)
        
        let stats = try await repository.getStats()
        
        XCTAssertEqual(stats.total, 3, "Total should be 3")
        XCTAssertEqual(stats.expired, 1, "Expired should be 1")
        XCTAssertEqual(stats.validCount, 2, "Valid should be 2")
    }
    
    // MARK: - DEBUG Toggle Tests
    
    func testCacheDisabledToggleReturnsNil() async throws {
        let entry = makeCachedEntry(hash: "toggle_test")
        try await repository.saveCachedWorkout(entry)
        
        // Desabilitar cache
        SwiftDataWorkoutCompositionCacheRepository.isCacheDisabled = true
        
        let result = try await repository.getCachedWorkout(for: "toggle_test")
        
        XCTAssertNil(result, "Should return nil when cache is disabled")
        
        // Reabilitar
        SwiftDataWorkoutCompositionCacheRepository.isCacheDisabled = false
        
        let resultEnabled = try await repository.getCachedWorkout(for: "toggle_test")
        XCTAssertNotNil(resultEnabled, "Should return entry when cache is enabled")
    }
    
    func testCacheDisabledSkipsSave() async throws {
        SwiftDataWorkoutCompositionCacheRepository.isCacheDisabled = true
        
        let entry = makeCachedEntry(hash: "disabled_save_test")
        try await repository.saveCachedWorkout(entry)
        
        SwiftDataWorkoutCompositionCacheRepository.isCacheDisabled = false
        
        let result = try await repository.getCachedWorkout(for: "disabled_save_test")
        XCTAssertNil(result, "Should not save when cache is disabled")
    }
    
    // MARK: - Metadata Tests
    
    func testMetadataIsPreserved() async throws {
        let entry = CachedWorkoutEntry(
            inputsHash: "metadata_test",
            workoutPlan: makeTestWorkoutPlan(),
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(24 * 60 * 60),
            goal: .weightLoss,
            structure: .bodyweight,
            focus: .upper,
            blueprintVersion: "v2.0",
            variationSeed: 99999
        )
        
        try await repository.saveCachedWorkout(entry)
        
        let result = try await repository.getCachedWorkout(for: "metadata_test")
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.goal, .weightLoss)
        XCTAssertEqual(result?.structure, .bodyweight)
        XCTAssertEqual(result?.focus, .upper)
        XCTAssertEqual(result?.blueprintVersion, "v2.0")
        XCTAssertEqual(result?.variationSeed, 99999)
    }
    
    // MARK: - Blueprint Version Compatibility Tests
    
    func testCacheIncludesBlueprintVersion() async throws {
        let entry = makeCachedEntry(hash: "version_test")
        try await repository.saveCachedWorkout(entry)
        
        let result = try await repository.getCachedWorkout(for: "version_test")
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.blueprintVersion, BlueprintVersion.current.rawValue)
    }
}
