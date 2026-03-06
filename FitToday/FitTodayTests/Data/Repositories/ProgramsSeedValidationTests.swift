//
//  ProgramsSeedValidationTests.swift
//  FitTodayTests
//
//  Validates ProgramsSeed.json integrity: all goal_tags and levels are valid enum values.
//

import XCTest
@testable import FitToday

final class ProgramsSeedValidationTests: XCTestCase {

    private struct SeedDTO: Decodable {
        let id: String
        let goalTag: String
        let level: String
    }

    func testAllGoalTagsAreValidEnumValues() throws {
        let data = try loadSeedData()
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let dtos = try decoder.decode([SeedDTO].self, from: data)

        let validGoalTags = Set(ProgramGoalTag.allCases.map(\.rawValue))

        for dto in dtos {
            XCTAssertTrue(
                validGoalTags.contains(dto.goalTag),
                "Program '\(dto.id)' has invalid goal_tag '\(dto.goalTag)'. Valid: \(validGoalTags)"
            )
        }
    }

    func testAllLevelsAreValidEnumValues() throws {
        let data = try loadSeedData()
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let dtos = try decoder.decode([SeedDTO].self, from: data)

        let validLevels = Set(ProgramLevel.allCases.map(\.rawValue))

        for dto in dtos {
            XCTAssertTrue(
                validLevels.contains(dto.level),
                "Program '\(dto.id)' has invalid level '\(dto.level)'. Valid: \(validLevels)"
            )
        }
    }

    func testSeedHasAtLeastTenPrograms() throws {
        let data = try loadSeedData()
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let dtos = try decoder.decode([SeedDTO].self, from: data)

        XCTAssertGreaterThanOrEqual(dtos.count, 10, "Expected at least 10 programs in seed")
    }

    func testGoalTagDistributionIsNotMonolithic() throws {
        let data = try loadSeedData()
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let dtos = try decoder.decode([SeedDTO].self, from: data)

        let grouped = Dictionary(grouping: dtos, by: \.goalTag)

        // No single goal_tag should have more than 60% of programs
        let maxCount = grouped.values.map(\.count).max() ?? 0
        let threshold = Int(Double(dtos.count) * 0.6)

        XCTAssertLessThanOrEqual(
            maxCount,
            threshold,
            "Goal tag distribution is too concentrated. Max \(maxCount) out of \(dtos.count)"
        )
    }

    // MARK: - Helper

    private func loadSeedData() throws -> Data {
        guard let url = Bundle.main.url(forResource: "ProgramsSeed", withExtension: "json") else {
            throw XCTSkip("ProgramsSeed.json not found in test bundle")
        }
        return try Data(contentsOf: url)
    }
}
