//
//  FirebaseModels.swift
//  FitToday
//
//  Created by Claude on 16/01/26.
//

import Foundation
import FirebaseFirestore

// MARK: - User DTOs

struct FBUser: Codable {
    @DocumentID var id: String?
    var displayName: String
    var email: String?
    var photoURL: String?
    var authProvider: String
    var currentGroupId: String?
    var privacySettings: FBPrivacySettings
    @ServerTimestamp var createdAt: Timestamp?
}

struct FBPrivacySettings: Codable {
    var shareWorkoutData: Bool

    init(shareWorkoutData: Bool = true) {
        self.shareWorkoutData = shareWorkoutData
    }
}

// MARK: - Group DTOs

struct FBGroup: Codable {
    @DocumentID var id: String?
    var name: String
    @ServerTimestamp var createdAt: Timestamp?
    var createdBy: String
    var memberCount: Int
    var isActive: Bool
}

struct FBMember: Codable {
    @DocumentID var id: String?
    var displayName: String
    var photoURL: String?
    @ServerTimestamp var joinedAt: Timestamp?
    var role: String
    var isActive: Bool
}

// MARK: - Challenge DTOs

struct FBChallenge: Codable {
    @DocumentID var id: String?
    var groupId: String
    var type: String
    @ServerTimestamp var weekStartDate: Timestamp?
    @ServerTimestamp var weekEndDate: Timestamp?
    var isActive: Bool
    @ServerTimestamp var createdAt: Timestamp?
}

struct FBChallengeEntry: Codable {
    @DocumentID var id: String?
    var displayName: String
    var photoURL: String?
    var value: Int
    var rank: Int
    @ServerTimestamp var lastUpdated: Timestamp?
}

// MARK: - Notification DTOs

struct FBNotification: Codable {
    @DocumentID var id: String?
    var userId: String
    var groupId: String
    var type: String
    var message: String
    var isRead: Bool
    @ServerTimestamp var createdAt: Timestamp?
}

// MARK: - Group Streak DTOs

struct FBGroupStreakWeek: Codable {
    @DocumentID var id: String?
    var groupId: String
    @ServerTimestamp var weekStartDate: Timestamp?
    @ServerTimestamp var weekEndDate: Timestamp?
    var memberCompliance: [String: FBMemberWeeklyStatus]  // keyed by userId
    var allCompliant: Bool?
    @ServerTimestamp var createdAt: Timestamp?

    func toDomain() -> GroupStreakWeek? {
        guard let id = id,
              let weekStartDate = weekStartDate?.dateValue(),
              let weekEndDate = weekEndDate?.dateValue() else {
            return nil
        }

        let members = memberCompliance.map { (userId, status) in
            status.toDomain(userId: userId)
        }

        return GroupStreakWeek(
            id: id,
            groupId: groupId,
            weekStartDate: weekStartDate,
            weekEndDate: weekEndDate,
            memberCompliance: members,
            allCompliant: allCompliant,
            createdAt: createdAt?.dateValue() ?? Date()
        )
    }

    init(from domain: GroupStreakWeek) {
        self.id = domain.id
        self.groupId = domain.groupId
        self.weekStartDate = Timestamp(date: domain.weekStartDate)
        self.weekEndDate = Timestamp(date: domain.weekEndDate)
        self.memberCompliance = Dictionary(
            uniqueKeysWithValues: domain.memberCompliance.map { ($0.id, FBMemberWeeklyStatus(from: $0)) }
        )
        self.allCompliant = domain.allCompliant
        self.createdAt = Timestamp(date: domain.createdAt)
    }

    init(
        id: String? = nil,
        groupId: String,
        weekStartDate: Timestamp?,
        weekEndDate: Timestamp?,
        memberCompliance: [String: FBMemberWeeklyStatus],
        allCompliant: Bool? = nil,
        createdAt: Timestamp? = nil
    ) {
        self.id = id
        self.groupId = groupId
        self.weekStartDate = weekStartDate
        self.weekEndDate = weekEndDate
        self.memberCompliance = memberCompliance
        self.allCompliant = allCompliant
        self.createdAt = createdAt
    }
}

struct FBMemberWeeklyStatus: Codable {
    var displayName: String
    var photoURL: String?
    var workoutCount: Int
    @ServerTimestamp var lastWorkoutDate: Timestamp?

    func toDomain(userId: String) -> MemberWeeklyStatus {
        MemberWeeklyStatus(
            id: userId,
            displayName: displayName,
            photoURL: photoURL.flatMap(URL.init),
            workoutCount: workoutCount,
            lastWorkoutDate: lastWorkoutDate?.dateValue()
        )
    }

    init(from domain: MemberWeeklyStatus) {
        self.displayName = domain.displayName
        self.photoURL = domain.photoURL?.absoluteString
        self.workoutCount = domain.workoutCount
        self.lastWorkoutDate = domain.lastWorkoutDate.map { Timestamp(date: $0) }
    }

    init(
        displayName: String,
        photoURL: String? = nil,
        workoutCount: Int = 0,
        lastWorkoutDate: Timestamp? = nil
    ) {
        self.displayName = displayName
        self.photoURL = photoURL
        self.workoutCount = workoutCount
        self.lastWorkoutDate = lastWorkoutDate
    }
}

// MARK: - Group Streak Extension

extension FBGroup {
    struct StreakFields: Codable {
        var groupStreakDays: Int
        var lastMilestone: Int?
        @ServerTimestamp var streakStartDate: Timestamp?
        @ServerTimestamp var pausedUntil: Timestamp?
        var pauseUsedThisMonth: Bool
    }
}

struct FBGroupStreak: Codable {
    @DocumentID var id: String?
    var groupStreakDays: Int
    var lastMilestone: Int?
    @ServerTimestamp var streakStartDate: Timestamp?
    @ServerTimestamp var pausedUntil: Timestamp?
    var pauseUsedThisMonth: Bool

    func toDomain(groupId: String, groupName: String, currentWeek: GroupStreakWeek?) -> GroupStreakStatus {
        GroupStreakStatus(
            groupId: groupId,
            groupName: groupName,
            streakDays: groupStreakDays,
            currentWeek: currentWeek,
            lastMilestone: lastMilestone.flatMap { StreakMilestone(rawValue: $0) },
            pausedUntil: pausedUntil?.dateValue(),
            pauseUsedThisMonth: pauseUsedThisMonth,
            streakStartDate: streakStartDate?.dateValue()
        )
    }

    init(from domain: GroupStreakStatus) {
        self.id = domain.groupId
        self.groupStreakDays = domain.streakDays
        self.lastMilestone = domain.lastMilestone?.rawValue
        self.streakStartDate = domain.streakStartDate.map { Timestamp(date: $0) }
        self.pausedUntil = domain.pausedUntil.map { Timestamp(date: $0) }
        self.pauseUsedThisMonth = domain.pauseUsedThisMonth
    }

    init(
        id: String? = nil,
        groupStreakDays: Int = 0,
        lastMilestone: Int? = nil,
        streakStartDate: Timestamp? = nil,
        pausedUntil: Timestamp? = nil,
        pauseUsedThisMonth: Bool = false
    ) {
        self.id = id
        self.groupStreakDays = groupStreakDays
        self.lastMilestone = lastMilestone
        self.streakStartDate = streakStartDate
        self.pausedUntil = pausedUntil
        self.pauseUsedThisMonth = pauseUsedThisMonth
    }
}

// MARK: - Check-In DTOs

struct FBCheckIn: Codable {
    @DocumentID var id: String?
    var groupId: String
    var challengeId: String
    var userId: String
    var displayName: String
    var userPhotoURL: String?
    var checkInPhotoURL: String
    var workoutEntryId: String
    var workoutDurationMinutes: Int
    @ServerTimestamp var createdAt: Timestamp?

    init(from checkIn: CheckIn) {
        self.id = checkIn.id
        self.groupId = checkIn.groupId
        self.challengeId = checkIn.challengeId
        self.userId = checkIn.userId
        self.displayName = checkIn.displayName
        self.userPhotoURL = checkIn.userPhotoURL?.absoluteString
        self.checkInPhotoURL = checkIn.checkInPhotoURL.absoluteString
        self.workoutEntryId = checkIn.workoutEntryId.uuidString
        self.workoutDurationMinutes = checkIn.workoutDurationMinutes
        self.createdAt = Timestamp(date: checkIn.createdAt)
    }

    func toDomain() -> CheckIn? {
        guard let id = id,
              let checkInPhotoURL = URL(string: checkInPhotoURL),
              let workoutEntryId = UUID(uuidString: workoutEntryId) else {
            return nil
        }

        return CheckIn(
            id: id,
            groupId: groupId,
            challengeId: challengeId,
            userId: userId,
            displayName: displayName,
            userPhotoURL: userPhotoURL.flatMap(URL.init),
            checkInPhotoURL: checkInPhotoURL,
            workoutEntryId: workoutEntryId,
            workoutDurationMinutes: workoutDurationMinutes,
            createdAt: createdAt?.dateValue() ?? Date()
        )
    }
}
