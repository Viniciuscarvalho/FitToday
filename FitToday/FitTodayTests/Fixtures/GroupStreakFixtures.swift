//
//  GroupStreakFixtures.swift
//  FitTodayTests
//
//  Created by Claude on 27/01/26.
//

import Foundation
@testable import FitToday

// MARK: - MemberWeeklyStatus Fixtures

extension MemberWeeklyStatus {
    static func fixture(
        id: String = "member1",
        displayName: String = "Test Member",
        photoURL: URL? = nil,
        workoutCount: Int = 0,
        lastWorkoutDate: Date? = nil
    ) -> MemberWeeklyStatus {
        MemberWeeklyStatus(
            id: id,
            displayName: displayName,
            photoURL: photoURL,
            workoutCount: workoutCount,
            lastWorkoutDate: lastWorkoutDate
        )
    }

    static var compliant: MemberWeeklyStatus {
        .fixture(id: "compliant", displayName: "Compliant User", workoutCount: 3)
    }

    static var atRisk: MemberWeeklyStatus {
        .fixture(id: "atRisk", displayName: "At Risk User", workoutCount: 2)
    }

    static var notStarted: MemberWeeklyStatus {
        .fixture(id: "notStarted", displayName: "Not Started User", workoutCount: 0)
    }

    static var overAchiever: MemberWeeklyStatus {
        .fixture(id: "over", displayName: "Over Achiever", workoutCount: 5)
    }
}

// MARK: - GroupStreakWeek Fixtures

extension GroupStreakWeek {
    static func fixture(
        id: String = "week1",
        groupId: String = "group1",
        weekStartDate: Date = Date().startOfWeekUTC,
        weekEndDate: Date = Date().endOfWeekUTC,
        memberCompliance: [MemberWeeklyStatus] = [],
        allCompliant: Bool? = nil,
        createdAt: Date = Date()
    ) -> GroupStreakWeek {
        GroupStreakWeek(
            id: id,
            groupId: groupId,
            weekStartDate: weekStartDate,
            weekEndDate: weekEndDate,
            memberCompliance: memberCompliance,
            allCompliant: allCompliant,
            createdAt: createdAt
        )
    }

    static var allCompliant: GroupStreakWeek {
        .fixture(
            memberCompliance: [
                .fixture(id: "1", displayName: "Alice", workoutCount: 3),
                .fixture(id: "2", displayName: "Bob", workoutCount: 4),
                .fixture(id: "3", displayName: "Charlie", workoutCount: 3)
            ],
            allCompliant: true
        )
    }

    static var someAtRisk: GroupStreakWeek {
        .fixture(
            memberCompliance: [
                .fixture(id: "1", displayName: "Alice", workoutCount: 3),
                .fixture(id: "2", displayName: "Bob", workoutCount: 2),
                .fixture(id: "3", displayName: "Charlie", workoutCount: 1)
            ]
        )
    }

    static var allFailed: GroupStreakWeek {
        .fixture(
            memberCompliance: [
                .fixture(id: "1", displayName: "Alice", workoutCount: 1),
                .fixture(id: "2", displayName: "Bob", workoutCount: 0),
                .fixture(id: "3", displayName: "Charlie", workoutCount: 2)
            ],
            allCompliant: false
        )
    }

    static var empty: GroupStreakWeek {
        .fixture(memberCompliance: [])
    }
}

// MARK: - GroupStreakStatus Fixtures

extension GroupStreakStatus {
    static func fixture(
        groupId: String = "group1",
        groupName: String = "Test Group",
        streakDays: Int = 0,
        currentWeek: GroupStreakWeek? = nil,
        lastMilestone: StreakMilestone? = nil,
        pausedUntil: Date? = nil,
        pauseUsedThisMonth: Bool = false,
        streakStartDate: Date? = nil
    ) -> GroupStreakStatus {
        GroupStreakStatus(
            groupId: groupId,
            groupName: groupName,
            streakDays: streakDays,
            currentWeek: currentWeek,
            lastMilestone: lastMilestone,
            pausedUntil: pausedUntil,
            pauseUsedThisMonth: pauseUsedThisMonth,
            streakStartDate: streakStartDate
        )
    }

    static var newStreak: GroupStreakStatus {
        .fixture(streakDays: 0, currentWeek: .someAtRisk)
    }

    static var oneWeekStreak: GroupStreakStatus {
        .fixture(
            streakDays: 7,
            currentWeek: .allCompliant,
            lastMilestone: .oneWeek,
            streakStartDate: Date().addingTimeInterval(-7 * 86400)
        )
    }

    static var twoWeekStreak: GroupStreakStatus {
        .fixture(
            streakDays: 14,
            currentWeek: .allCompliant,
            lastMilestone: .twoWeeks,
            streakStartDate: Date().addingTimeInterval(-14 * 86400)
        )
    }

    static var oneMonthStreak: GroupStreakStatus {
        .fixture(
            streakDays: 30,
            currentWeek: .allCompliant,
            lastMilestone: .oneMonth,
            streakStartDate: Date().addingTimeInterval(-30 * 86400)
        )
    }

    static var pausedStreak: GroupStreakStatus {
        .fixture(
            streakDays: 21,
            pausedUntil: Date().addingTimeInterval(3 * 86400),
            pauseUsedThisMonth: true,
            streakStartDate: Date().addingTimeInterval(-21 * 86400)
        )
    }

    static var brokenStreak: GroupStreakStatus {
        .fixture(
            streakDays: 0,
            currentWeek: .allFailed
        )
    }
}

// MARK: - UpdateGroupStreakResult Fixtures

extension UpdateGroupStreakResult {
    static func fixture(
        groupId: String = "group1",
        userBecameCompliant: Bool = false,
        allMembersCompliant: Bool = false,
        currentWorkoutCount: Int = 1,
        milestone: StreakMilestone? = nil
    ) -> UpdateGroupStreakResult {
        UpdateGroupStreakResult(
            groupId: groupId,
            userBecameCompliant: userBecameCompliant,
            allMembersCompliant: allMembersCompliant,
            currentWorkoutCount: currentWorkoutCount,
            milestone: milestone
        )
    }

    static var firstWorkout: UpdateGroupStreakResult {
        .fixture(currentWorkoutCount: 1)
    }

    static var becameCompliant: UpdateGroupStreakResult {
        .fixture(userBecameCompliant: true, currentWorkoutCount: 3)
    }

    static var allCompliantNow: UpdateGroupStreakResult {
        .fixture(userBecameCompliant: true, allMembersCompliant: true, currentWorkoutCount: 3)
    }

    static var milestoneReached: UpdateGroupStreakResult {
        .fixture(allMembersCompliant: true, currentWorkoutCount: 3, milestone: .oneWeek)
    }
}

// MARK: - Mock Repositories

class MockGroupStreakRepository: GroupStreakRepository {
    var streakStatusToReturn: GroupStreakStatus = .fixture()
    var streakStatusStream: AsyncStream<GroupStreakStatus>?
    var incrementWorkoutCountCalled = false
    var incrementWorkoutCountGroupId: String?
    var incrementWorkoutCountUserId: String?
    var createWeekRecordCalled = false
    var updateStreakDaysCalled = false
    var resetStreakCalled = false
    var pauseStreakCalled = false
    var resumeStreakCalled = false
    var shouldThrowError: GroupStreakError?

    func getStreakStatus(groupId: String) async throws -> GroupStreakStatus {
        if let error = shouldThrowError { throw error }
        return streakStatusToReturn
    }

    func observeStreakStatus(groupId: String) -> AsyncStream<GroupStreakStatus> {
        streakStatusStream ?? AsyncStream { continuation in
            continuation.yield(streakStatusToReturn)
        }
    }

    func incrementWorkoutCount(groupId: String, userId: String, displayName: String, photoURL: URL?) async throws {
        if let error = shouldThrowError { throw error }
        incrementWorkoutCountCalled = true
        incrementWorkoutCountGroupId = groupId
        incrementWorkoutCountUserId = userId
    }

    func createWeekRecord(groupId: String, members: [GroupMember]) async throws -> GroupStreakWeek {
        if let error = shouldThrowError { throw error }
        createWeekRecordCalled = true
        return .fixture(groupId: groupId)
    }

    func updateStreakDays(groupId: String, days: Int, milestone: StreakMilestone?) async throws {
        if let error = shouldThrowError { throw error }
        updateStreakDaysCalled = true
    }

    func resetStreak(groupId: String) async throws {
        if let error = shouldThrowError { throw error }
        resetStreakCalled = true
    }

    func pauseStreak(groupId: String, until: Date) async throws {
        if let error = shouldThrowError { throw error }
        pauseStreakCalled = true
    }

    func resumeStreak(groupId: String) async throws {
        if let error = shouldThrowError { throw error }
        resumeStreakCalled = true
    }

    func getWeekHistory(groupId: String, limit: Int) async throws -> [GroupStreakWeek] {
        if let error = shouldThrowError { throw error }
        return []
    }

    func getCurrentWeek(groupId: String) async throws -> GroupStreakWeek? {
        if let error = shouldThrowError { throw error }
        return streakStatusToReturn.currentWeek
    }

    func markPauseUsedThisMonth(groupId: String) async throws {
        if let error = shouldThrowError { throw error }
    }

    func resetMonthlyPauseFlag(groupId: String) async throws {
        if let error = shouldThrowError { throw error }
    }
}

// MARK: - Mock Use Cases

class MockUpdateGroupStreakUseCase: UpdateGroupStreakUseCaseProtocol {
    var resultToReturn: UpdateGroupStreakResult = .fixture()
    var executeCalled = false
    var executeUserId: String?
    var shouldThrowError: Error?

    func execute(userId: String, displayName: String, photoURL: URL?) async throws -> UpdateGroupStreakResult {
        if let error = shouldThrowError { throw error }
        executeCalled = true
        executeUserId = userId
        return resultToReturn
    }
}

class MockPauseGroupStreakUseCase: PauseGroupStreakUseCaseProtocol {
    var pauseCalled = false
    var pauseGroupId: String?
    var pauseDays: Int?
    var resumeCalled = false
    var resumeGroupId: String?
    var shouldThrowError: GroupStreakError?

    func pause(groupId: String, days: Int) async throws {
        if let error = shouldThrowError { throw error }
        pauseCalled = true
        pauseGroupId = groupId
        pauseDays = days
    }

    func resume(groupId: String) async throws {
        if let error = shouldThrowError { throw error }
        resumeCalled = true
        resumeGroupId = groupId
    }
}
