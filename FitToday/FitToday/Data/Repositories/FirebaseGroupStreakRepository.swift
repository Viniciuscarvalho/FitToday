//
//  FirebaseGroupStreakRepository.swift
//  FitToday
//
//  Created by Claude on 27/01/26.
//

import Foundation

// MARK: - FirebaseGroupStreakRepository

final class FirebaseGroupStreakRepository: GroupStreakRepository, @unchecked Sendable {
    private let streakService: FirebaseGroupStreakService
    private let groupService: FirebaseGroupService

    init(
        streakService: FirebaseGroupStreakService = FirebaseGroupStreakService(),
        groupService: FirebaseGroupService = FirebaseGroupService()
    ) {
        self.streakService = streakService
        self.groupService = groupService
    }

    // MARK: - Get Streak Status

    func getStreakStatus(groupId: String) async throws -> GroupStreakStatus {
        guard let fbGroup = try await groupService.getGroup(groupId) else {
            throw GroupStreakError.groupNotFound
        }

        let fbStreak = try await streakService.getStreakStatus(groupId: groupId)
        let fbWeek = try await streakService.getCurrentWeek(groupId: groupId)

        let groupName = fbGroup.name

        if let fbStreak {
            return fbStreak.toDomain(
                groupId: groupId,
                groupName: groupName,
                currentWeek: fbWeek?.toDomain()
            )
        }

        // No streak data yet - return default
        return GroupStreakStatus(
            groupId: groupId,
            groupName: groupName,
            streakDays: 0,
            currentWeek: fbWeek?.toDomain(),
            lastMilestone: nil,
            pausedUntil: nil,
            pauseUsedThisMonth: false,
            streakStartDate: nil
        )
    }

    // MARK: - Observe Streak Status

    func observeStreakStatus(groupId: String) -> AsyncStream<GroupStreakStatus> {
        AsyncStream { continuation in
            Task {
                guard let fbGroup = try? await self.groupService.getGroup(groupId) else {
                    continuation.finish()
                    return
                }

                let groupName = fbGroup.name

                for await (fbStreak, fbWeek) in self.streakService.observeStreakStatus(groupId: groupId) {
                    let status: GroupStreakStatus
                    if let fbStreak {
                        status = fbStreak.toDomain(
                            groupId: groupId,
                            groupName: groupName,
                            currentWeek: fbWeek?.toDomain()
                        )
                    } else {
                        status = GroupStreakStatus(
                            groupId: groupId,
                            groupName: groupName,
                            streakDays: 0,
                            currentWeek: fbWeek?.toDomain(),
                            lastMilestone: nil,
                            pausedUntil: nil,
                            pauseUsedThisMonth: false,
                            streakStartDate: nil
                        )
                    }
                    continuation.yield(status)
                }
            }
        }
    }

    // MARK: - Increment Workout Count

    func incrementWorkoutCount(
        groupId: String,
        userId: String,
        displayName: String,
        photoURL: URL?
    ) async throws {
        try await streakService.incrementWorkoutCount(
            groupId: groupId,
            userId: userId,
            displayName: displayName,
            photoURL: photoURL?.absoluteString
        )
    }

    // MARK: - Create Week Record

    func createWeekRecord(groupId: String, members: [GroupMember]) async throws -> GroupStreakWeek {
        let memberTuples = members.map { (id: $0.id, displayName: $0.displayName, photoURL: $0.photoURL?.absoluteString) }
        let fbWeek = try await streakService.createWeekRecord(groupId: groupId, members: memberTuples)

        guard let week = fbWeek.toDomain() else {
            throw GroupStreakError.unknownError(underlying: NSError(
                domain: "GroupStreak",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to create week record"]
            ))
        }

        return week
    }

    // MARK: - Update Streak Days

    func updateStreakDays(groupId: String, days: Int, milestone: StreakMilestone?) async throws {
        try await streakService.updateStreakDays(
            groupId: groupId,
            days: days,
            milestone: milestone?.rawValue
        )
    }

    // MARK: - Reset Streak

    func resetStreak(groupId: String) async throws {
        try await streakService.resetStreak(groupId: groupId)
    }

    // MARK: - Pause Streak

    func pauseStreak(groupId: String, until: Date) async throws {
        try await streakService.pauseStreak(groupId: groupId, until: until)
    }

    // MARK: - Resume Streak

    func resumeStreak(groupId: String) async throws {
        try await streakService.resumeStreak(groupId: groupId)
    }

    // MARK: - Get Week History

    func getWeekHistory(groupId: String, limit: Int) async throws -> [GroupStreakWeek] {
        let fbWeeks = try await streakService.getWeekHistory(groupId: groupId, limit: limit)
        return fbWeeks.compactMap { $0.toDomain() }
    }

    // MARK: - Get Current Week

    func getCurrentWeek(groupId: String) async throws -> GroupStreakWeek? {
        let fbWeek = try await streakService.getCurrentWeek(groupId: groupId)
        return fbWeek?.toDomain()
    }

    // MARK: - Mark Pause Used

    func markPauseUsedThisMonth(groupId: String) async throws {
        try await streakService.markPauseUsedThisMonth(groupId: groupId)
    }

    // MARK: - Reset Monthly Pause Flag

    func resetMonthlyPauseFlag(groupId: String) async throws {
        try await streakService.resetMonthlyPauseFlag(groupId: groupId)
    }
}
