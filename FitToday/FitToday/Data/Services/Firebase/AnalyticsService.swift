//
//  AnalyticsService.swift
//  FitToday
//
//  Created by Claude on 17/01/26.
//

import Foundation

// NOTE: Add FirebaseAnalytics to your SPM dependencies:
// Package: https://github.com/firebase/firebase-ios-sdk.git
// Product: FirebaseAnalytics
#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif

// MARK: - AnalyticsService Protocol

/// Protocol for tracking analytics events. Allows for testing and alternative implementations.
protocol AnalyticsTracking: Sendable {
    func trackGroupCreated(groupId: String, userId: String)
    func trackGroupJoined(groupId: String, userId: String, inviteSource: InviteSource)
    func trackWorkoutSynced(userId: String, groupId: String, challengeType: ChallengeType, value: Int)
    func trackGroupLeft(groupId: String, userId: String, durationDays: Int)
    func setUserInGroup(_ isInGroup: Bool)
    func setUserRole(_ role: GroupRole?)
}

// MARK: - InviteSource

enum InviteSource: String, Sendable {
    case link
    case qr
}

// MARK: - FirebaseAnalyticsService

/// Firebase Analytics implementation for tracking user events.
final class FirebaseAnalyticsService: AnalyticsTracking, @unchecked Sendable {

    // MARK: - Event Names

    private enum EventName {
        static let groupCreated = "group_created"
        static let groupJoined = "group_joined"
        static let workoutSynced = "workout_synced"
        static let groupLeft = "group_left"
    }

    // MARK: - Parameter Keys

    private enum ParameterKey {
        static let groupId = "group_id"
        static let userId = "user_id"
        static let inviteSource = "invite_source"
        static let challengeType = "challenge_type"
        static let value = "value"
        static let durationDays = "duration_days"
        static let timestamp = "timestamp"
    }

    // MARK: - User Property Keys

    private enum UserPropertyKey {
        static let isInGroup = "is_in_group"
        static let groupRole = "group_role"
    }

    // MARK: - Event Tracking

    func trackGroupCreated(groupId: String, userId: String) {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent(EventName.groupCreated, parameters: [
            ParameterKey.groupId: groupId,
            ParameterKey.userId: userId,
            ParameterKey.timestamp: Date().timeIntervalSince1970
        ])
        #endif

        #if DEBUG
        print("[Analytics] Event: \(EventName.groupCreated) - groupId: \(groupId)")
        #endif
    }

    func trackGroupJoined(groupId: String, userId: String, inviteSource: InviteSource) {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent(EventName.groupJoined, parameters: [
            ParameterKey.groupId: groupId,
            ParameterKey.userId: userId,
            ParameterKey.inviteSource: inviteSource.rawValue,
            ParameterKey.timestamp: Date().timeIntervalSince1970
        ])
        #endif

        #if DEBUG
        print("[Analytics] Event: \(EventName.groupJoined) - groupId: \(groupId), source: \(inviteSource.rawValue)")
        #endif
    }

    func trackWorkoutSynced(userId: String, groupId: String, challengeType: ChallengeType, value: Int) {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent(EventName.workoutSynced, parameters: [
            ParameterKey.userId: userId,
            ParameterKey.groupId: groupId,
            ParameterKey.challengeType: challengeType.rawValue,
            ParameterKey.value: value,
            ParameterKey.timestamp: Date().timeIntervalSince1970
        ])
        #endif

        #if DEBUG
        print("[Analytics] Event: \(EventName.workoutSynced) - type: \(challengeType.rawValue), value: \(value)")
        #endif
    }

    func trackGroupLeft(groupId: String, userId: String, durationDays: Int) {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent(EventName.groupLeft, parameters: [
            ParameterKey.groupId: groupId,
            ParameterKey.userId: userId,
            ParameterKey.durationDays: durationDays,
            ParameterKey.timestamp: Date().timeIntervalSince1970
        ])
        #endif

        #if DEBUG
        print("[Analytics] Event: \(EventName.groupLeft) - groupId: \(groupId), duration: \(durationDays) days")
        #endif
    }

    // MARK: - User Properties

    func setUserInGroup(_ isInGroup: Bool) {
        #if canImport(FirebaseAnalytics)
        Analytics.setUserProperty(isInGroup ? "true" : "false", forName: UserPropertyKey.isInGroup)
        #endif

        #if DEBUG
        print("[Analytics] User Property: \(UserPropertyKey.isInGroup) = \(isInGroup)")
        #endif
    }

    func setUserRole(_ role: GroupRole?) {
        let roleValue: String
        switch role {
        case .admin:
            roleValue = "admin"
        case .member:
            roleValue = "member"
        case nil:
            roleValue = "none"
        }

        #if canImport(FirebaseAnalytics)
        Analytics.setUserProperty(roleValue, forName: UserPropertyKey.groupRole)
        #endif

        #if DEBUG
        print("[Analytics] User Property: \(UserPropertyKey.groupRole) = \(roleValue)")
        #endif
    }
}

// MARK: - Mock Analytics Service (for Testing)

#if DEBUG
final class MockAnalyticsService: AnalyticsTracking, @unchecked Sendable {
    var trackedEvents: [(name: String, parameters: [String: Any])] = []
    var userProperties: [String: String] = [:]

    func trackGroupCreated(groupId: String, userId: String) {
        trackedEvents.append((name: "group_created", parameters: ["group_id": groupId, "user_id": userId]))
    }

    func trackGroupJoined(groupId: String, userId: String, inviteSource: InviteSource) {
        trackedEvents.append((name: "group_joined", parameters: ["group_id": groupId, "user_id": userId, "invite_source": inviteSource.rawValue]))
    }

    func trackWorkoutSynced(userId: String, groupId: String, challengeType: ChallengeType, value: Int) {
        trackedEvents.append((name: "workout_synced", parameters: ["user_id": userId, "group_id": groupId, "challenge_type": challengeType.rawValue, "value": value]))
    }

    func trackGroupLeft(groupId: String, userId: String, durationDays: Int) {
        trackedEvents.append((name: "group_left", parameters: ["group_id": groupId, "user_id": userId, "duration_days": durationDays]))
    }

    func setUserInGroup(_ isInGroup: Bool) {
        userProperties["is_in_group"] = isInGroup ? "true" : "false"
    }

    func setUserRole(_ role: GroupRole?) {
        userProperties["group_role"] = role?.rawValue ?? "none"
    }
}
#endif
