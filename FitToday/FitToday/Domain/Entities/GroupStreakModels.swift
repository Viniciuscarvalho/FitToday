//
//  GroupStreakModels.swift
//  FitToday
//
//  Created by Claude on 27/01/26.
//

import Foundation

// MARK: - Compliance Status

/// Represents a member's compliance status for the current week
enum ComplianceStatus: String, Codable, Sendable, CaseIterable {
    case compliant       // Member completed 3+ workouts
    case atRisk          // Member has 1-2 workouts, week not over
    case notStarted      // Member has 0 workouts, week not over
    case failed          // Week ended with < 3 workouts

    var localizedDescription: String {
        switch self {
        case .compliant: return String(localized: "Compliant")
        case .atRisk: return String(localized: "At Risk")
        case .notStarted: return String(localized: "Not Started")
        case .failed: return String(localized: "Failed")
        }
    }

    var emoji: String {
        switch self {
        case .compliant: return "✓"
        case .atRisk: return "⚠️"
        case .notStarted: return "○"
        case .failed: return "✗"
        }
    }
}

// MARK: - Streak Milestone

/// Represents milestone achievements for group streaks
enum StreakMilestone: Int, Codable, Sendable, CaseIterable, Comparable {
    case oneWeek = 7
    case twoWeeks = 14
    case oneMonth = 30
    case twoMonths = 60
    case oneHundredDays = 100

    var localizedDescription: String {
        switch self {
        case .oneWeek: return String(localized: "1 Week")
        case .twoWeeks: return String(localized: "2 Weeks")
        case .oneMonth: return String(localized: "1 Month")
        case .twoMonths: return String(localized: "2 Months")
        case .oneHundredDays: return String(localized: "100 Days")
        }
    }

    var emoji: String {
        switch self {
        case .oneWeek: return "🔥"
        case .twoWeeks: return "💪"
        case .oneMonth: return "⭐"
        case .twoMonths: return "🏆"
        case .oneHundredDays: return "👑"
        }
    }

    var celebrationMessage: String {
        switch self {
        case .oneWeek: return String(localized: "First week conquered!")
        case .twoWeeks: return String(localized: "Two weeks strong!")
        case .oneMonth: return String(localized: "One month of dedication!")
        case .twoMonths: return String(localized: "Two months of excellence!")
        case .oneHundredDays: return String(localized: "100 days legend!")
        }
    }

    static func < (lhs: StreakMilestone, rhs: StreakMilestone) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// Returns the next milestone after the given number of days
    static func next(after days: Int) -> StreakMilestone? {
        allCases.first { $0.rawValue > days }
    }

    /// Returns the most recently achieved milestone for the given number of days
    static func achieved(for days: Int) -> StreakMilestone? {
        allCases.filter { $0.rawValue <= days }.last
    }
}

// MARK: - Member Weekly Status

/// Tracks a single member's workout compliance for a given week
struct MemberWeeklyStatus: Codable, Hashable, Sendable, Identifiable {
    let id: String  // userId
    var displayName: String
    var photoURL: URL?
    var workoutCount: Int
    var lastWorkoutDate: Date?

    /// Minimum workouts required per week for compliance
    static let requiredWorkouts = 3

    /// Whether this member has met the weekly requirement
    var isCompliant: Bool {
        workoutCount >= Self.requiredWorkouts
    }

    /// Current compliance status considering week progress
    func complianceStatus(isWeekOver: Bool) -> ComplianceStatus {
        if isCompliant {
            return .compliant
        } else if isWeekOver {
            return .failed
        } else if workoutCount > 0 {
            return .atRisk
        } else {
            return .notStarted
        }
    }

    /// Number of workouts remaining to achieve compliance
    var workoutsRemaining: Int {
        max(0, Self.requiredWorkouts - workoutCount)
    }

    /// Progress dots representation (●○○ style)
    var progressDots: String {
        let filled = min(workoutCount, Self.requiredWorkouts)
        let empty = Self.requiredWorkouts - filled
        return String(repeating: "●", count: filled) + String(repeating: "○", count: empty)
    }

    init(
        id: String,
        displayName: String,
        photoURL: URL? = nil,
        workoutCount: Int = 0,
        lastWorkoutDate: Date? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.photoURL = photoURL
        self.workoutCount = workoutCount
        self.lastWorkoutDate = lastWorkoutDate
    }
}

// MARK: - Group Streak Week

/// Represents a single week's tracking data for a group streak
struct GroupStreakWeek: Codable, Hashable, Sendable, Identifiable {
    let id: String
    let groupId: String
    let weekStartDate: Date  // Monday 00:00 UTC
    let weekEndDate: Date    // Sunday 23:59 UTC
    var memberCompliance: [MemberWeeklyStatus]
    var allCompliant: Bool?  // nil until week ends, then true/false
    let createdAt: Date

    /// Whether all active members are currently compliant
    var isAllCurrentlyCompliant: Bool {
        memberCompliance.allSatisfy { $0.isCompliant }
    }

    /// Count of compliant members
    var compliantMemberCount: Int {
        memberCompliance.filter { $0.isCompliant }.count
    }

    /// Count of at-risk members (have started but not yet compliant)
    var atRiskMemberCount: Int {
        memberCompliance.filter { $0.workoutCount > 0 && !$0.isCompliant }.count
    }

    /// Total workouts completed by the group this week
    var totalGroupWorkouts: Int {
        memberCompliance.reduce(0) { $0 + $1.workoutCount }
    }

    /// Whether the week has ended
    var isWeekOver: Bool {
        Date() > weekEndDate
    }

    init(
        id: String,
        groupId: String,
        weekStartDate: Date,
        weekEndDate: Date,
        memberCompliance: [MemberWeeklyStatus],
        allCompliant: Bool? = nil,
        createdAt: Date = Date()
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

// MARK: - Group Streak Status

/// Complete status of a group's streak including current week
struct GroupStreakStatus: Codable, Hashable, Sendable {
    let groupId: String
    let groupName: String
    var streakDays: Int
    var currentWeek: GroupStreakWeek?
    var lastMilestone: StreakMilestone?
    var pausedUntil: Date?
    var pauseUsedThisMonth: Bool
    let streakStartDate: Date?

    /// Whether the streak is currently paused
    var isPaused: Bool {
        guard let pausedUntil else { return false }
        return Date() < pausedUntil
    }

    /// The next milestone to achieve
    var nextMilestone: StreakMilestone? {
        StreakMilestone.next(after: streakDays)
    }

    /// Days remaining until next milestone
    var daysToNextMilestone: Int? {
        guard let next = nextMilestone else { return nil }
        return next.rawValue - streakDays
    }

    /// Whether a milestone was just achieved (used for celebration overlay)
    var justAchievedMilestone: StreakMilestone? {
        guard let achieved = StreakMilestone.achieved(for: streakDays) else { return nil }
        // Consider "just achieved" if we're within the first day of the milestone
        if achieved.rawValue == streakDays {
            return achieved
        }
        return nil
    }

    /// Progress percentage towards next milestone
    var progressToNextMilestone: Double {
        guard let next = nextMilestone else { return 1.0 }
        let previous = StreakMilestone.allCases.last { $0 < next }?.rawValue ?? 0
        let range = next.rawValue - previous
        let progress = streakDays - previous
        return Double(progress) / Double(range)
    }

    /// Whether the group has an active streak
    var hasActiveStreak: Bool {
        streakDays > 0
    }

    /// Members sorted by workout count (descending)
    var membersSortedByWorkouts: [MemberWeeklyStatus] {
        currentWeek?.memberCompliance.sorted { $0.workoutCount > $1.workoutCount } ?? []
    }

    /// Top performers (top 3 by workout count)
    var topPerformers: [MemberWeeklyStatus] {
        Array(membersSortedByWorkouts.prefix(3))
    }

    init(
        groupId: String,
        groupName: String,
        streakDays: Int = 0,
        currentWeek: GroupStreakWeek? = nil,
        lastMilestone: StreakMilestone? = nil,
        pausedUntil: Date? = nil,
        pauseUsedThisMonth: Bool = false,
        streakStartDate: Date? = nil
    ) {
        self.groupId = groupId
        self.groupName = groupName
        self.streakDays = streakDays
        self.currentWeek = currentWeek
        self.lastMilestone = lastMilestone
        self.pausedUntil = pausedUntil
        self.pauseUsedThisMonth = pauseUsedThisMonth
        self.streakStartDate = streakStartDate
    }
}

// MARK: - Group Streak Error

enum GroupStreakError: Error, LocalizedError, Sendable {
    case groupNotFound
    case weekNotFound
    case notGroupAdmin
    case pauseAlreadyUsedThisMonth
    case pauseDurationTooLong(maxDays: Int)
    case streakNotActive
    case memberNotFound
    case networkError(underlying: Error)
    case unknownError(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .groupNotFound:
            return String(localized: "Group not found")
        case .weekNotFound:
            return String(localized: "Week record not found")
        case .notGroupAdmin:
            return String(localized: "Only group admins can perform this action")
        case .pauseAlreadyUsedThisMonth:
            return String(localized: "Pause has already been used this month")
        case .pauseDurationTooLong(let maxDays):
            return String(localized: "Pause duration cannot exceed \(maxDays) days")
        case .streakNotActive:
            return String(localized: "No active streak to pause")
        case .memberNotFound:
            return String(localized: "Member not found in group")
        case .networkError(let error):
            return String(localized: "Network error: \(error.localizedDescription)")
        case .unknownError(let error):
            return String(localized: "Unknown error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Date Helpers

extension Date {
    /// Returns the start of the current week (Monday 00:00 UTC)
    var startOfWeekUTC: Date {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }

    /// Returns the end of the current week (Sunday 23:59:59 UTC)
    var endOfWeekUTC: Date {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let startOfWeek = self.startOfWeekUTC
        return calendar.date(byAdding: .day, value: 6, to: startOfWeek)?
            .addingTimeInterval(86399) ?? self
    }
}
