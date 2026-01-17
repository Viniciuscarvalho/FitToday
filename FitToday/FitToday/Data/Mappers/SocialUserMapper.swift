//
//  SocialUserMapper.swift
//  FitToday
//
//  Created by Claude on 16/01/26.
//

import Foundation
import FirebaseFirestore

// MARK: - FBUser to Domain

extension FBUser {
    func toDomain() -> SocialUser {
        SocialUser(
            id: id ?? "",
            displayName: displayName,
            email: email,
            photoURL: photoURL.flatMap { URL(string: $0) },
            authProvider: AuthProvider(rawValue: authProvider) ?? .email,
            currentGroupId: currentGroupId,
            privacySettings: PrivacySettings(shareWorkoutData: privacySettings.shareWorkoutData),
            createdAt: createdAt?.dateValue() ?? Date()
        )
    }
}

// MARK: - SocialUser to Firestore

extension SocialUser {
    func toFirestore() -> FBUser {
        FBUser(
            id: id,
            displayName: displayName,
            email: email,
            photoURL: photoURL?.absoluteString,
            authProvider: authProvider.rawValue,
            currentGroupId: currentGroupId,
            privacySettings: FBPrivacySettings(shareWorkoutData: privacySettings.shareWorkoutData),
            createdAt: Timestamp(date: createdAt)
        )
    }

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "displayName": displayName,
            "authProvider": authProvider.rawValue,
            "privacySettings": [
                "shareWorkoutData": privacySettings.shareWorkoutData
            ],
            "createdAt": Timestamp(date: createdAt)
        ]

        if let email = email {
            dict["email"] = email
        }

        if let photoURL = photoURL {
            dict["photoURL"] = photoURL.absoluteString
        }

        if let currentGroupId = currentGroupId {
            dict["currentGroupId"] = currentGroupId
        }

        return dict
    }
}

// MARK: - Group Mappers

extension FBGroup {
    func toDomain() -> SocialGroup {
        SocialGroup(
            id: id ?? "",
            name: name,
            createdAt: createdAt?.dateValue() ?? Date(),
            createdBy: createdBy,
            memberCount: memberCount,
            isActive: isActive
        )
    }
}

extension SocialGroup {
    func toFirestore() -> FBGroup {
        FBGroup(
            id: id,
            name: name,
            createdAt: Timestamp(date: createdAt),
            createdBy: createdBy,
            memberCount: memberCount,
            isActive: isActive
        )
    }
}

// MARK: - Member Mappers

extension FBMember {
    func toDomain() -> GroupMember {
        GroupMember(
            id: id ?? "",
            displayName: displayName,
            photoURL: photoURL.flatMap { URL(string: $0) },
            joinedAt: joinedAt?.dateValue() ?? Date(),
            role: GroupRole(rawValue: role) ?? .member,
            isActive: isActive
        )
    }
}

extension GroupMember {
    func toFirestore() -> FBMember {
        FBMember(
            id: id,
            displayName: displayName,
            photoURL: photoURL?.absoluteString,
            joinedAt: Timestamp(date: joinedAt),
            role: role.rawValue,
            isActive: isActive
        )
    }
}

// MARK: - Challenge Mappers

extension FBChallenge {
    func toDomain() -> Challenge {
        Challenge(
            id: id ?? "",
            groupId: groupId,
            type: ChallengeType(rawValue: type) ?? .checkIns,
            weekStartDate: weekStartDate?.dateValue() ?? Date(),
            weekEndDate: weekEndDate?.dateValue() ?? Date(),
            isActive: isActive,
            createdAt: createdAt?.dateValue() ?? Date()
        )
    }
}

extension Challenge {
    func toFirestore() -> FBChallenge {
        FBChallenge(
            id: id,
            groupId: groupId,
            type: type.rawValue,
            weekStartDate: Timestamp(date: weekStartDate),
            weekEndDate: Timestamp(date: weekEndDate),
            isActive: isActive,
            createdAt: Timestamp(date: createdAt)
        )
    }
}

// MARK: - Leaderboard Entry Mappers

extension FBChallengeEntry {
    func toDomain() -> LeaderboardEntry {
        LeaderboardEntry(
            id: id ?? "",
            displayName: displayName,
            photoURL: photoURL.flatMap { URL(string: $0) },
            value: value,
            rank: rank,
            lastUpdated: lastUpdated?.dateValue() ?? Date()
        )
    }
}

extension LeaderboardEntry {
    func toFirestore() -> FBChallengeEntry {
        FBChallengeEntry(
            id: id,
            displayName: displayName,
            photoURL: photoURL?.absoluteString,
            value: value,
            rank: rank,
            lastUpdated: Timestamp(date: lastUpdated)
        )
    }
}

// MARK: - Notification Mappers

extension FBNotification {
    func toDomain() -> GroupNotification {
        GroupNotification(
            id: id ?? "",
            userId: userId,
            groupId: groupId,
            type: NotificationType(rawValue: type) ?? .newMember,
            message: message,
            isRead: isRead,
            createdAt: createdAt?.dateValue() ?? Date()
        )
    }
}

extension GroupNotification {
    func toFirestore() -> FBNotification {
        FBNotification(
            id: id,
            userId: userId,
            groupId: groupId,
            type: type.rawValue,
            message: message,
            isRead: isRead,
            createdAt: Timestamp(date: createdAt)
        )
    }
}
