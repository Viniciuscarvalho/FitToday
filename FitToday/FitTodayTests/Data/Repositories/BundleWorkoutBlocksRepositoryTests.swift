//
//  BundleWorkoutBlocksRepositoryTests.swift
//  FitTodayTests
//
//  Created by AI on 15/01/26.
//

import XCTest
@testable import FitToday

// 💡 Learn: Testes para o repositório de blocos de workout do bundle
// Valida carregamento, cache e enriquecimento opcional
final class BundleWorkoutBlocksRepositoryTests: XCTestCase {

    var sut: BundleWorkoutBlocksRepository!

    override func setUp() async throws {
        // Cria repositório - enrichment agora é feito via Wger API separadamente
        sut = BundleWorkoutBlocksRepository()
    }

    override func tearDown() async throws {
        sut = nil
    }

    // MARK: - Load Blocks Tests

    func testLoadBlocks_returnsNonEmptyArray() async throws {
        // When
        let blocks = try await sut.loadBlocks()

        // Then
        XCTAssertFalse(blocks.isEmpty, "Should load workout blocks from bundle")
    }

    func testLoadBlocks_blockHasValidStructure() async throws {
        // When
        let blocks = try await sut.loadBlocks()

        // Then
        guard let firstBlock = blocks.first else {
            XCTFail("Should have at least one block")
            return
        }

        XCTAssertFalse(firstBlock.id.isEmpty)
        XCTAssertFalse(firstBlock.exercises.isEmpty, "Block should have exercises")
        XCTAssertTrue(firstBlock.suggestedSets.lowerBound > 0)
        XCTAssertTrue(firstBlock.suggestedReps.lowerBound > 0)
        XCTAssertTrue(firstBlock.restInterval > 0)
    }

    func testLoadBlocks_exercisesHaveRequiredFields() async throws {
        // When
        let blocks = try await sut.loadBlocks()

        // Then
        guard let firstBlock = blocks.first,
              let firstExercise = firstBlock.exercises.first else {
            XCTFail("Should have blocks with exercises")
            return
        }

        XCTAssertFalse(firstExercise.id.isEmpty)
        XCTAssertFalse(firstExercise.name.isEmpty)
        XCTAssertFalse(firstExercise.instructions.isEmpty, "Exercise should have instructions")
    }

    // MARK: - Cache Tests

    func testLoadBlocks_usesCacheOnSecondCall() async throws {
        // Given
        let firstLoad = try await sut.loadBlocks()
        let firstCount = firstLoad.count

        // When - Second call should use cache
        let secondLoad = try await sut.loadBlocks()

        // Then
        XCTAssertEqual(secondLoad.count, firstCount)
        // Note: Hard to test cache directly without exposing internals,
        // but we can verify behavior is consistent
    }

    func testClearCache_forcesReload() async throws {
        // Given
        _ = try await sut.loadBlocks()

        // When
        await sut.clearCache()
        let reloaded = try await sut.loadBlocks()

        // Then
        XCTAssertFalse(reloaded.isEmpty, "Should reload blocks after cache clear")
    }

    // MARK: - Load Blocks for Goal Tests

    func testLoadBlocksForGoal_returnsBlocks() async throws {
        // When
        let blocks = try await sut.loadBlocks(
            for: .hypertrophy,
            level: .intermediate,
            structure: .fullGym
        )

        // Then
        XCTAssertFalse(blocks.isEmpty, "Should return blocks for specific goal")
    }

    func testLoadBlocksForGoal_containsBaseBlocks() async throws {
        // Given
        let baseBlocks = try await sut.loadBlocks()

        // When
        let goalBlocks = try await sut.loadBlocks(
            for: .conditioning,
            level: .beginner,
            structure: .basicGym
        )

        // Then
        XCTAssertGreaterThanOrEqual(
            goalBlocks.count,
            baseBlocks.count,
            "Goal-specific blocks should contain at least all base blocks"
        )
    }
}
