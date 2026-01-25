//
//  MockSocialRepositories.swift
//  FitTodayTests
//
//  Created by Claude on 18/01/26.
//

import Foundation
@testable import FitToday

// MARK: - MockAuthenticationRepository

final class MockAuthenticationRepository: AuthenticationRepository, @unchecked Sendable {
    var currentUserResult: SocialUser?
    var currentUserError: Error?
    var currentUserCalled = false

    var signInWithAppleResult: Result<SocialUser, Error> = .failure(DomainError.notAuthenticated)
    var signInWithGoogleResult: Result<SocialUser, Error> = .failure(DomainError.notAuthenticated)
    var signInWithEmailResult: Result<SocialUser, Error> = .failure(DomainError.notAuthenticated)
    var signOutCalled = false

    func currentUser() async throws -> SocialUser? {
        currentUserCalled = true
        if let error = currentUserError {
            throw error
        }
        return currentUserResult
    }

    func signInWithApple() async throws -> SocialUser {
        try signInWithAppleResult.get()
    }

    func signInWithGoogle() async throws -> SocialUser {
        try signInWithGoogleResult.get()
    }

    func signInWithEmail(_ email: String, password: String) async throws -> SocialUser {
        try signInWithEmailResult.get()
    }

    func createAccount(email: String, password: String, displayName: String) async throws -> SocialUser {
        try signInWithEmailResult.get()
    }

    func signOut() async throws {
        signOutCalled = true
    }

    func observeAuthState() -> AsyncStream<SocialUser?> {
        AsyncStream { continuation in
            continuation.yield(currentUserResult)
            continuation.finish()
        }
    }
}

// MARK: - MockGroupRepository

final class MockGroupRepository: GroupRepository, @unchecked Sendable {
    var createGroupResult: Result<SocialGroup, Error> = .failure(DomainError.networkFailure)
    var createGroupCalled = false
    var capturedGroupName: String?
    var capturedOwnerId: String?

    var getGroupResult: SocialGroup?
    var getMembersResult: [GroupMember] = []
    var addMemberCalled = false
    var removeMemberCalled = false
    var leaveGroupCalled = false
    var deleteGroupCalled = false

    var capturedAddMemberGroupId: String?
    var capturedAddMemberUserId: String?
    var capturedRemoveMemberUserId: String?
    var capturedLeaveGroupId: String?
    var capturedDeleteGroupId: String?

    func createGroup(name: String, ownerId: String) async throws -> SocialGroup {
        createGroupCalled = true
        capturedGroupName = name
        capturedOwnerId = ownerId
        return try createGroupResult.get()
    }

    func getGroup(_ groupId: String) async throws -> SocialGroup? {
        return getGroupResult
    }

    func addMember(groupId: String, userId: String, displayName: String, photoURL: URL?) async throws {
        addMemberCalled = true
        capturedAddMemberGroupId = groupId
        capturedAddMemberUserId = userId
    }

    func removeMember(groupId: String, userId: String) async throws {
        removeMemberCalled = true
        capturedRemoveMemberUserId = userId
    }

    func leaveGroup(groupId: String, userId: String) async throws {
        leaveGroupCalled = true
        capturedLeaveGroupId = groupId
    }

    func deleteGroup(_ groupId: String) async throws {
        deleteGroupCalled = true
        capturedDeleteGroupId = groupId
    }

    func getMembers(groupId: String) async throws -> [GroupMember] {
        return getMembersResult
    }
}

// MARK: - MockUserRepository

final class MockUserRepository: UserRepository, @unchecked Sendable {
    var getUserResult: SocialUser?
    var updateUserCalled = false
    var updatePrivacySettingsCalled = false
    var updateCurrentGroupCalled = false
    var capturedCurrentGroupId: String?

    func getUser(_ userId: String) async throws -> SocialUser? {
        return getUserResult
    }

    func updateUser(_ user: SocialUser) async throws {
        updateUserCalled = true
    }

    func updatePrivacySettings(_ userId: String, settings: PrivacySettings) async throws {
        updatePrivacySettingsCalled = true
    }

    func updateCurrentGroup(_ userId: String, groupId: String?) async throws {
        updateCurrentGroupCalled = true
        capturedCurrentGroupId = groupId
    }
}

// MARK: - MockLeaderboardRepository

final class MockLeaderboardRepository: LeaderboardRepository, @unchecked Sendable {
    var getCurrentWeekChallengesResult: [Challenge] = []
    var incrementCheckInCalled = false
    var updateStreakCalled = false
    var updateMemberWeeklyStatsCalled = false
    var capturedStreakValue: Int?
    var capturedChallengeId: String?
    var capturedWorkoutMinutes: Int?

    func getCurrentWeekChallenges(groupId: String) async throws -> [Challenge] {
        return getCurrentWeekChallengesResult
    }

    func observeLeaderboard(groupId: String, type: ChallengeType) -> AsyncStream<LeaderboardSnapshot> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }

    func incrementCheckIn(challengeId: String, userId: String) async throws {
        incrementCheckInCalled = true
        capturedChallengeId = challengeId
    }

    func updateStreak(challengeId: String, userId: String, streakDays: Int) async throws {
        updateStreakCalled = true
        capturedChallengeId = challengeId
        capturedStreakValue = streakDays
    }

    func updateMemberWeeklyStats(groupId: String, userId: String, workoutMinutes: Int) async throws {
        updateMemberWeeklyStatsCalled = true
        capturedWorkoutMinutes = workoutMinutes
    }
}

// MARK: - MockNotificationRepository

final class MockNotificationRepository: NotificationRepository, @unchecked Sendable {
    var getNotificationsResult: [GroupNotification] = []
    var createNotificationCalled = false
    var markAsReadCalled = false

    func getNotifications(userId: String) async throws -> [GroupNotification] {
        return getNotificationsResult
    }

    func observeNotifications(userId: String) -> AsyncStream<[GroupNotification]> {
        AsyncStream { continuation in
            continuation.yield(getNotificationsResult)
            continuation.finish()
        }
    }

    func markAsRead(_ notificationId: String) async throws {
        markAsReadCalled = true
    }

    func createNotification(_ notification: GroupNotification) async throws {
        createNotificationCalled = true
    }
}

// MARK: - MockCheckInRepository

final class MockCheckInRepository: CheckInRepository, @unchecked Sendable {
    var createCheckInCalled = false
    var uploadPhotoCalled = false
    var capturedCheckIn: CheckIn?
    var capturedPhotoData: Data?
    var capturedGroupId: String?
    var capturedUserId: String?

    var uploadPhotoResult: Result<URL, Error> = .success(URL(string: "https://example.com/photo.jpg")!)
    var createCheckInError: Error?
    var getCheckInsResult: [CheckIn] = []

    func createCheckIn(_ checkIn: CheckIn) async throws {
        createCheckInCalled = true
        capturedCheckIn = checkIn
        if let error = createCheckInError {
            throw error
        }
    }

    func getCheckIns(groupId: String, limit: Int, after: Date?) async throws -> [CheckIn] {
        capturedGroupId = groupId
        return getCheckInsResult
    }

    func observeCheckIns(groupId: String) -> AsyncStream<[CheckIn]> {
        capturedGroupId = groupId
        return AsyncStream { continuation in
            continuation.yield(getCheckInsResult)
            continuation.finish()
        }
    }

    func uploadPhoto(imageData: Data, groupId: String, userId: String) async throws -> URL {
        uploadPhotoCalled = true
        capturedPhotoData = imageData
        capturedGroupId = groupId
        capturedUserId = userId
        return try uploadPhotoResult.get()
    }
}

// MARK: - MockImageCompressor

final class MockImageCompressor: ImageCompressing, @unchecked Sendable {
    var compressCalled = false
    var capturedData: Data?
    var capturedMaxBytes: Int?
    var capturedQuality: CGFloat?

    var compressResult: Result<Data, Error> = .success(Data([0x01, 0x02, 0x03]))

    func compress(data: Data, maxBytes: Int, quality: CGFloat) throws -> Data {
        compressCalled = true
        capturedData = data
        capturedMaxBytes = maxBytes
        capturedQuality = quality
        return try compressResult.get()
    }
}

// MARK: - MockAnalyticsTracking

final class MockAnalyticsTracking: AnalyticsTracking, @unchecked Sendable {
    var trackGroupCreatedCalled = false
    var trackGroupJoinedCalled = false
    var trackWorkoutSyncedCalled = false
    var trackGroupLeftCalled = false
    var setUserInGroupCalled = false
    var setUserRoleCalled = false

    func trackGroupCreated(groupId: String, userId: String) {
        trackGroupCreatedCalled = true
    }

    func trackGroupJoined(groupId: String, userId: String, inviteSource: InviteSource) {
        trackGroupJoinedCalled = true
    }

    func trackWorkoutSynced(userId: String, groupId: String, challengeType: ChallengeType, value: Int) {
        trackWorkoutSyncedCalled = true
    }

    func trackGroupLeft(groupId: String, userId: String, durationDays: Int) {
        trackGroupLeftCalled = true
    }

    func setUserInGroup(_ isInGroup: Bool) {
        setUserInGroupCalled = true
    }

    func setUserRole(_ role: GroupRole?) {
        setUserRoleCalled = true
    }
}
