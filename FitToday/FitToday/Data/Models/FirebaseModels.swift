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
