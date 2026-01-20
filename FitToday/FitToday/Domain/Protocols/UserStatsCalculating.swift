//
//  UserStatsCalculating.swift
//  FitToday
//
//  Created by Claude on 20/01/26.
//

import Foundation

/// Protocol for calculating user workout statistics.
protocol UserStatsCalculating: Sendable {
    /// Calculates the current workout streak (consecutive days).
    /// - Parameter history: Array of workout history entries, sorted by date descending.
    /// - Returns: The number of consecutive workout days (0 if streak is broken).
    func calculateCurrentStreak(from history: [WorkoutHistoryEntry]) -> Int

    /// Calculates weekly statistics for the current week.
    /// - Parameter history: Array of workout history entries.
    /// - Returns: Aggregated stats for the current week (Monday-Sunday).
    func calculateWeeklyStats(from history: [WorkoutHistoryEntry]) -> WeeklyStats

    /// Calculates monthly statistics for the current month.
    /// - Parameter history: Array of workout history entries.
    /// - Returns: Aggregated stats for the current month.
    func calculateMonthlyStats(from history: [WorkoutHistoryEntry]) -> MonthlyStats

    /// Computes a full UserStats snapshot from history.
    /// - Parameters:
    ///   - history: Array of workout history entries.
    ///   - currentStats: Optional current stats (for longest streak tracking).
    /// - Returns: Updated UserStats with all computed values.
    func computeStats(
        from history: [WorkoutHistoryEntry],
        currentStats: UserStats?
    ) -> UserStats
}

// MARK: - WeeklyStats

/// Aggregated statistics for a single week.
struct WeeklyStats: Codable, Sendable, Equatable {
    /// Start date of the week (Monday 00:00)
    let weekStartDate: Date

    /// Number of completed workouts this week
    let workoutsCompleted: Int

    /// Total workout duration in minutes
    let totalDurationMinutes: Int

    /// Total calories burned (from HealthKit or estimates)
    let totalCaloriesBurned: Int

    /// Average workout rating (nil if no ratings)
    let averageRating: Double?

    /// Factory for empty stats
    static func empty(weekStart: Date = Date().startOfWeek) -> WeeklyStats {
        WeeklyStats(
            weekStartDate: weekStart,
            workoutsCompleted: 0,
            totalDurationMinutes: 0,
            totalCaloriesBurned: 0,
            averageRating: nil
        )
    }
}

// MARK: - MonthlyStats

/// Aggregated statistics for a single month.
struct MonthlyStats: Codable, Sendable, Equatable {
    /// Start date of the month (1st at 00:00)
    let monthStartDate: Date

    /// Number of completed workouts this month
    let workoutsCompleted: Int

    /// Total workout duration in minutes
    let totalDurationMinutes: Int

    /// Total calories burned (from HealthKit or estimates)
    let totalCaloriesBurned: Int

    /// Average workout rating (nil if no ratings)
    let averageRating: Double?

    /// Factory for empty stats
    static func empty(monthStart: Date = Date().startOfMonth) -> MonthlyStats {
        MonthlyStats(
            monthStartDate: monthStart,
            workoutsCompleted: 0,
            totalDurationMinutes: 0,
            totalCaloriesBurned: 0,
            averageRating: nil
        )
    }
}
