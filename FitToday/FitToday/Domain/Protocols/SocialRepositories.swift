//
//  SocialRepositories.swift
//  FitToday
//
//  Created by Claude on 16/01/26.
//

import Foundation

// MARK: - Authentication Repository

protocol AuthenticationRepository: Sendable {
    func currentUser() async throws -> SocialUser?
    func signInWithApple() async throws -> SocialUser
    func signInWithGoogle() async throws -> SocialUser
    func signInWithEmail(_ email: String, password: String) async throws -> SocialUser
    func createAccount(email: String, password: String, displayName: String) async throws -> SocialUser
    func signOut() async throws
    func observeAuthState() -> AsyncStream<SocialUser?>
}

// MARK: - Group Repository

protocol GroupRepository: Sendable {
    func createGroup(name: String, ownerId: String) async throws -> SocialGroup
    func getGroup(_ groupId: String) async throws -> SocialGroup?
    func addMember(groupId: String, userId: String, displayName: String, photoURL: URL?) async throws
    func removeMember(groupId: String, userId: String) async throws
    func leaveGroup(groupId: String, userId: String) async throws
    func deleteGroup(_ groupId: String) async throws
    func getMembers(groupId: String) async throws -> [GroupMember]
}

// MARK: - Leaderboard Repository

protocol LeaderboardRepository: Sendable {
    func getCurrentWeekChallenges(groupId: String) async throws -> [Challenge]
    func observeLeaderboard(groupId: String, type: ChallengeType) -> AsyncStream<LeaderboardSnapshot>
    func incrementCheckIn(challengeId: String, userId: String) async throws
    func updateStreak(challengeId: String, userId: String, streakDays: Int) async throws
    func updateMemberWeeklyStats(groupId: String, userId: String, workoutMinutes: Int) async throws
}

// MARK: - User Repository

protocol UserRepository: Sendable {
    func getUser(_ userId: String) async throws -> SocialUser?
    func updateUser(_ user: SocialUser) async throws
    func updatePrivacySettings(_ userId: String, settings: PrivacySettings) async throws
    func updateCurrentGroup(_ userId: String, groupId: String?) async throws
}

// MARK: - Notification Repository

protocol NotificationRepository: Sendable {
    func getNotifications(userId: String) async throws -> [GroupNotification]
    func observeNotifications(userId: String) -> AsyncStream<[GroupNotification]>
    func markAsRead(_ notificationId: String) async throws
    func createNotification(_ notification: GroupNotification) async throws
}

// MARK: - Check-In Repository

protocol CheckInRepository: Sendable {
    /// Creates a new check-in in Firestore.
    func createCheckIn(_ checkIn: CheckIn) async throws

    /// Fetches check-ins for a group with pagination support.
    func getCheckIns(groupId: String, limit: Int, after: Date?) async throws -> [CheckIn]

    /// Observes check-ins for a group in real-time.
    func observeCheckIns(groupId: String) -> AsyncStream<[CheckIn]>

    /// Uploads a photo to Firebase Storage and returns the download URL.
    func uploadPhoto(imageData: Data, groupId: String, userId: String) async throws -> URL
}
