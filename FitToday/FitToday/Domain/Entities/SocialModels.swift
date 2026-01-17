//
//  SocialModels.swift
//  FitToday
//
//  Created by Claude on 16/01/26.
//

import Foundation

// MARK: - User Models

struct SocialUser: Codable, Hashable, Sendable, Identifiable {
    let id: String // Firebase UID
    var displayName: String
    var email: String?
    var photoURL: URL?
    var authProvider: AuthProvider
    var currentGroupId: String?
    var privacySettings: PrivacySettings
    let createdAt: Date
}

enum AuthProvider: String, Codable, Sendable {
    case apple
    case google
    case email
}

struct PrivacySettings: Codable, Hashable, Sendable {
    var shareWorkoutData: Bool

    init(shareWorkoutData: Bool = true) {
        self.shareWorkoutData = shareWorkoutData
    }
}

// MARK: - Group Models

struct SocialGroup: Codable, Hashable, Sendable, Identifiable {
    let id: String
    var name: String
    let createdAt: Date
    let createdBy: String // userId
    var memberCount: Int
    var isActive: Bool
}

struct GroupMember: Codable, Hashable, Sendable, Identifiable {
    let id: String // userId
    var displayName: String
    var photoURL: URL?
    let joinedAt: Date
    var role: GroupRole
    var isActive: Bool
}

enum GroupRole: String, Codable, Sendable {
    case admin
    case member
}

// MARK: - Challenge Models

struct Challenge: Codable, Hashable, Sendable, Identifiable {
    let id: String
    let groupId: String
    var type: ChallengeType
    let weekStartDate: Date // Monday 00:00 UTC
    let weekEndDate: Date   // Sunday 23:59 UTC
    var isActive: Bool
    let createdAt: Date
}

enum ChallengeType: String, Codable, CaseIterable, Sendable {
    case checkIns = "check-ins"
    case streak = "streak"
}

// MARK: - Leaderboard Models

struct LeaderboardEntry: Codable, Hashable, Sendable, Identifiable {
    let id: String // userId
    var displayName: String
    var photoURL: URL?
    var value: Int // check-ins count or streak days
    var rank: Int  // 1-indexed
    let lastUpdated: Date
}

struct LeaderboardSnapshot: Sendable {
    let challenge: Challenge
    let entries: [LeaderboardEntry] // Sorted by rank ASC
    let currentUserEntry: LeaderboardEntry?
}

// MARK: - Notification Models

struct GroupNotification: Codable, Hashable, Sendable, Identifiable {
    let id: String
    let userId: String // Recipient
    let groupId: String
    var type: NotificationType
    var message: String
    var isRead: Bool
    let createdAt: Date
}

enum NotificationType: String, Codable, Sendable {
    case newMember = "new_member"
    case rankChange = "rank_change"
    case weekEnded = "week_ended"
}

// MARK: - Auth Errors

enum AuthError: Error, LocalizedError {
    case invalidCredential
    case userNotFound
    case networkError(underlying: Error)
    case unknownError(underlying: Error)
    case signInCancelled
    case appleSignInFailed(reason: String)
    case googleSignInFailed(reason: String)
    case emailSignInFailed(reason: String)

    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "Invalid credentials provided"
        case .userNotFound:
            return "User not found"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unknownError(let error):
            return "Unknown error: \(error.localizedDescription)"
        case .signInCancelled:
            return "Sign in was cancelled"
        case .appleSignInFailed(let reason):
            return "Apple Sign-In failed: \(reason)"
        case .googleSignInFailed(let reason):
            return "Google Sign-In failed: \(reason)"
        case .emailSignInFailed(let reason):
            return "Email Sign-In failed: \(reason)"
        }
    }
}
