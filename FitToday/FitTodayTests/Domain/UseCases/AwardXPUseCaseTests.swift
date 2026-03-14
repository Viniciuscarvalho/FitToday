//
//  AwardXPUseCaseTests.swift
//  FitTodayTests
//

import XCTest
@testable import FitToday

@MainActor
final class AwardXPUseCaseTests: XCTestCase {

    private var sut: AwardXPUseCase!
    private var mockRepo: MockXPRepository!

    override func setUp() {
        super.setUp()
        mockRepo = MockXPRepository()
        sut = AwardXPUseCase(xpRepository: mockRepo)
    }

    override func tearDown() {
        sut = nil
        mockRepo = nil
        super.tearDown()
    }

    func test_execute_workoutCompleted_awards100XP() async throws {
        mockRepo.currentXP = UserXP(totalXP: 0)

        let result = try await sut.execute(type: .workoutCompleted, currentStreak: 0)

        XCTAssertEqual(result.xpAwarded, 100)
        XCTAssertEqual(result.previousLevel, 1)
    }

    func test_execute_streak7_awardsBonus200XP() async throws {
        mockRepo.currentXP = UserXP(totalXP: 0)

        let result = try await sut.execute(type: .workoutCompleted, currentStreak: 7)

        XCTAssertEqual(result.xpAwarded, 300) // 100 + 200
    }

    func test_execute_streak30_awardsBonus500XP() async throws {
        mockRepo.currentXP = UserXP(totalXP: 0)

        let result = try await sut.execute(type: .workoutCompleted, currentStreak: 30)

        XCTAssertEqual(result.xpAwarded, 600) // 100 + 500
    }

    func test_execute_challengeCompleted_noStreakBonus() async throws {
        mockRepo.currentXP = UserXP(totalXP: 0)

        let result = try await sut.execute(type: .challengeCompleted, currentStreak: 30)

        XCTAssertEqual(result.xpAwarded, 500) // 500 only, no streak bonus for challenges
    }

    func test_execute_detectsLevelUp() async throws {
        mockRepo.currentXP = UserXP(totalXP: 950) // level 1, 50 XP to level up

        let result = try await sut.execute(type: .workoutCompleted, currentStreak: 0)

        XCTAssertTrue(result.didLevelUp)
        XCTAssertEqual(result.previousLevel, 1)
        XCTAssertEqual(result.newLevel, 2)
    }

    func test_execute_noLevelUp() async throws {
        mockRepo.currentXP = UserXP(totalXP: 0) // level 1, far from level up

        let result = try await sut.execute(type: .workoutCompleted, currentStreak: 0)

        XCTAssertFalse(result.didLevelUp)
        XCTAssertEqual(result.previousLevel, 1)
        XCTAssertEqual(result.newLevel, 1)
    }
}

// MARK: - Mock XP Repository

final class MockXPRepository: XPRepository, @unchecked Sendable {
    var currentXP = UserXP.empty
    var awardedTransactions: [XPTransaction] = []

    func getUserXP() async throws -> UserXP {
        currentXP
    }

    func awardXP(transaction: XPTransaction) async throws -> UserXP {
        awardedTransactions.append(transaction)
        currentXP = UserXP(totalXP: currentXP.totalXP + transaction.amount, lastAwardDate: transaction.date)
        return currentXP
    }

    func syncFromRemote() async throws {}
}
