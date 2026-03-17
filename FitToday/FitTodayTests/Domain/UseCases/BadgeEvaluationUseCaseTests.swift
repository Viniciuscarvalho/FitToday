//
//  BadgeEvaluationUseCaseTests.swift
//  FitTodayTests
//

import XCTest
@testable import FitToday

final class BadgeEvaluationUseCaseTests: XCTestCase {

    private var mockBadgeRepo: MockBadgeRepository!
    private var mockHistoryRepo: StubWorkoutHistoryRepository!
    private var mockFeatureFlags: StubFeatureFlags!
    private var sut: BadgeEvaluationUseCase!

    override func setUp() {
        super.setUp()
        mockBadgeRepo = MockBadgeRepository()
        mockHistoryRepo = StubWorkoutHistoryRepository()
        mockFeatureFlags = StubFeatureFlags(enabled: true)
        sut = BadgeEvaluationUseCase(
            badgeRepository: mockBadgeRepo,
            historyRepository: mockHistoryRepo,
            featureFlags: mockFeatureFlags
        )
    }

    // MARK: - Feature Flag

    func test_evaluate_returnEmpty_whenFeatureFlagDisabled() async throws {
        mockFeatureFlags.enabled = false
        mockHistoryRepo.entries = [makeEntry()]
        let result = try await sut.evaluate(userId: "user1")
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - First Workout

    func test_evaluate_unlocksFirstWorkout_whenOneCompleted() async throws {
        mockHistoryRepo.entries = [makeEntry()]
        let result = try await sut.evaluate(userId: "user1")
        XCTAssertTrue(result.contains { $0.type == .firstWorkout })
    }

    func test_evaluate_noUnlock_whenNoEntries() async throws {
        mockHistoryRepo.entries = []
        let result = try await sut.evaluate(userId: "user1")
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Already Unlocked

    func test_evaluate_doesNotDuplicate_alreadyUnlockedBadge() async throws {
        mockBadgeRepo.badges = [Badge.unlocked(type: .firstWorkout)]
        mockHistoryRepo.entries = [makeEntry()]
        let result = try await sut.evaluate(userId: "user1")
        XCTAssertFalse(result.contains { $0.type == .firstWorkout })
    }

    // MARK: - Streak Badges

    func test_evaluate_unlocksStreak7_with7ConsecutiveDays() async throws {
        mockHistoryRepo.entries = makeConsecutiveEntries(days: 7)
        let result = try await sut.evaluate(userId: "user1")
        XCTAssertTrue(result.contains { $0.type == .streak7 })
    }

    func test_evaluate_doesNotUnlockStreak7_with6Days() async throws {
        mockHistoryRepo.entries = makeConsecutiveEntries(days: 6)
        let result = try await sut.evaluate(userId: "user1")
        XCTAssertFalse(result.contains { $0.type == .streak7 })
    }

    // MARK: - Workout Count Badges

    func test_evaluate_unlocksWorkouts50() async throws {
        mockHistoryRepo.entries = (0..<50).map { makeEntry(daysAgo: $0) }
        let result = try await sut.evaluate(userId: "user1")
        XCTAssertTrue(result.contains { $0.type == .workouts50 })
    }

    // MARK: - Early Bird

    func test_evaluate_unlocksEarlyBird_with5EarlyWorkouts() async throws {
        let calendar = Calendar.current
        mockHistoryRepo.entries = (0..<5).map { i in
            let date = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: Date())!
                .addingTimeInterval(TimeInterval(-i * 86400))
            return makeEntry(date: date)
        }
        let result = try await sut.evaluate(userId: "user1")
        XCTAssertTrue(result.contains { $0.type == .earlyBird })
    }

    // MARK: - Multiple Unlocks

    func test_evaluate_canUnlockMultipleBadges() async throws {
        mockHistoryRepo.entries = makeConsecutiveEntries(days: 7)
        let result = try await sut.evaluate(userId: "user1")
        XCTAssertTrue(result.count >= 2) // firstWorkout + streak7
        XCTAssertTrue(result.contains { $0.type == .firstWorkout })
        XCTAssertTrue(result.contains { $0.type == .streak7 })
    }

    // MARK: - Criteria Direct Tests

    func test_isCriteriaMet_weekWarrior_with7WorkoutsInOneWeek() {
        let calendar = Calendar.current
        let monday = calendar.nextDate(
            after: Date(),
            matching: DateComponents(weekday: 2),
            matchingPolicy: .nextTime,
            direction: .backward
        )!
        let entries = (0..<7).map { i in
            makeEntry(date: calendar.date(byAdding: .day, value: i, to: monday)!)
        }
        XCTAssertTrue(sut.isCriteriaMet(.weekWarrior, entries: entries))
    }

    func test_isCriteriaMet_monthlyConsistency_with4Weeks() {
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .weekOfYear, value: -3, to: Date())!
        let entries = (0..<4).map { week in
            makeEntry(date: calendar.date(byAdding: .weekOfYear, value: week, to: start)!)
        }
        XCTAssertTrue(sut.isCriteriaMet(.monthlyConsistency, entries: entries))
    }

    // MARK: - getAllBadges

    func test_getAllBadges_returns9Badges() async throws {
        let result = try await sut.getAllBadges(userId: "user1")
        XCTAssertEqual(result.count, 9)
    }

    func test_getAllBadges_returnsEmpty_whenFlagDisabled() async throws {
        mockFeatureFlags.enabled = false
        let result = try await sut.getAllBadges(userId: "user1")
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Helpers

    private func makeEntry(daysAgo: Int = 0, date: Date? = nil) -> WorkoutHistoryEntry {
        WorkoutHistoryEntry(
            date: date ?? Date().addingTimeInterval(TimeInterval(-daysAgo * 86400)),
            planId: UUID(),
            title: "Test",
            focus: .fullBody,
            status: .completed
        )
    }

    private func makeConsecutiveEntries(days: Int) -> [WorkoutHistoryEntry] {
        let calendar = Calendar.current
        return (0..<days).map { i in
            let date = calendar.date(byAdding: .day, value: -i, to: calendar.startOfDay(for: Date()))!
            return makeEntry(date: date)
        }
    }
}

// MARK: - Test Doubles

private final class StubWorkoutHistoryRepository: WorkoutHistoryRepository, @unchecked Sendable {
    var entries: [WorkoutHistoryEntry] = []

    func listEntries() async throws -> [WorkoutHistoryEntry] { entries }
    func listEntries(limit: Int, offset: Int) async throws -> [WorkoutHistoryEntry] {
        Array(entries.prefix(limit))
    }
    func count() async throws -> Int { entries.count }
    func saveEntry(_ entry: WorkoutHistoryEntry) async throws {}
    func listAppEntriesWithPlan(limit: Int) async throws -> [WorkoutHistoryEntry] { [] }
}

private final class StubFeatureFlags: FeatureFlagChecking, @unchecked Sendable {
    var enabled: Bool

    init(enabled: Bool) { self.enabled = enabled }

    func isFeatureEnabled(_ key: FeatureFlagKey) async -> Bool { enabled }

    func checkFeatureAccess(_ feature: ProFeature, flag: FeatureFlagKey) async -> FeatureAccessResult {
        .featureDisabled(reason: "stub")
    }

    func refreshFlags() async throws {}
}
