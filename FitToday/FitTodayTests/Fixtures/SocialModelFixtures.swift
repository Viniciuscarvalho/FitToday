//
//  SocialModelFixtures.swift
//  FitTodayTests
//
//  Created by Claude on 18/01/26.
//

import Foundation
@testable import FitToday

// MARK: - SocialUser Fixtures

extension SocialUser {
    static func fixture(
        id: String = "user1",
        displayName: String = "Test User",
        email: String? = "test@example.com",
        photoURL: URL? = nil,
        authProvider: AuthProvider = .apple,
        currentGroupId: String? = nil,
        shareWorkoutData: Bool = true,
        createdAt: Date = Date()
    ) -> SocialUser {
        SocialUser(
            id: id,
            displayName: displayName,
            email: email,
            photoURL: photoURL,
            authProvider: authProvider,
            currentGroupId: currentGroupId,
            privacySettings: PrivacySettings(shareWorkoutData: shareWorkoutData),
            createdAt: createdAt
        )
    }

    static var authenticated: SocialUser {
        .fixture(id: "auth-user", displayName: "Authenticated User", currentGroupId: nil)
    }

    static var authenticatedInGroup: SocialUser {
        .fixture(id: "auth-user", displayName: "User In Group", currentGroupId: "existing-group")
    }

    static var privacyDisabled: SocialUser {
        .fixture(id: "private-user", displayName: "Private User", shareWorkoutData: false)
    }
}

// MARK: - SocialGroup Fixtures

extension SocialGroup {
    static func fixture(
        id: String = "group1",
        name: String = "Test Group",
        createdAt: Date = Date(),
        createdBy: String = "user1",
        memberCount: Int = 1,
        isActive: Bool = true
    ) -> SocialGroup {
        SocialGroup(
            id: id,
            name: name,
            createdAt: createdAt,
            createdBy: createdBy,
            memberCount: memberCount,
            isActive: isActive
        )
    }

    static var empty: SocialGroup {
        .fixture(memberCount: 0)
    }

    static var full: SocialGroup {
        .fixture(memberCount: 10)
    }
}

// MARK: - GroupMember Fixtures

extension GroupMember {
    static func fixture(
        id: String = "member1",
        displayName: String = "Test Member",
        photoURL: URL? = nil,
        joinedAt: Date = Date(),
        role: GroupRole = .member,
        isActive: Bool = true
    ) -> GroupMember {
        GroupMember(
            id: id,
            displayName: displayName,
            photoURL: photoURL,
            joinedAt: joinedAt,
            role: role,
            isActive: isActive
        )
    }

    static var admin: GroupMember {
        .fixture(id: "admin1", displayName: "Admin", role: .admin)
    }

    static var member: GroupMember {
        .fixture(id: "member1", displayName: "Member", role: .member)
    }
}

// MARK: - Challenge Fixtures

extension Challenge {
    static func fixture(
        id: String = "challenge1",
        groupId: String = "group1",
        type: ChallengeType = .checkIns,
        weekStartDate: Date = Calendar.current.startOfWeek(for: Date()),
        weekEndDate: Date = Calendar.current.endOfWeek(for: Date()),
        isActive: Bool = true,
        createdAt: Date = Date()
    ) -> Challenge {
        Challenge(
            id: id,
            groupId: groupId,
            type: type,
            weekStartDate: weekStartDate,
            weekEndDate: weekEndDate,
            isActive: isActive,
            createdAt: createdAt
        )
    }

    static var checkIns: Challenge {
        .fixture(id: "checkins-challenge", type: .checkIns)
    }

    static var streak: Challenge {
        .fixture(id: "streak-challenge", type: .streak)
    }
}

// MARK: - GroupNotification Fixtures

extension GroupNotification {
    static func fixture(
        id: String = "notification1",
        userId: String = "user1",
        groupId: String = "group1",
        type: NotificationType = .newMember,
        message: String = "Test notification",
        isRead: Bool = false,
        createdAt: Date = Date()
    ) -> GroupNotification {
        GroupNotification(
            id: id,
            userId: userId,
            groupId: groupId,
            type: type,
            message: message,
            isRead: isRead,
            createdAt: createdAt
        )
    }
}

// MARK: - Calendar Helpers

private extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        var components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        components.weekday = 2 // Monday
        return self.date(from: components) ?? date
    }

    func endOfWeek(for date: Date) -> Date {
        let start = startOfWeek(for: date)
        return self.date(byAdding: .day, value: 6, to: start) ?? date
    }
}
