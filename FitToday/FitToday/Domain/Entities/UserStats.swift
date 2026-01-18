//
//  UserStats.swift
//  FitToday
//
//  Created by Claude on 18/01/26.
//

import Foundation

/// Domain entity representing aggregated user statistics for the stats dashboard.
struct UserStats: Codable, Sendable, Equatable {
    // MARK: - Streak Data

    /// Current consecutive workout days
    let currentStreak: Int

    /// Longest streak ever achieved
    let longestStreak: Int

    /// Date of last completed workout
    let lastWorkoutDate: Date?

    // MARK: - Weekly Aggregates

    /// Start date of the current week (Monday)
    let weekStartDate: Date

    /// Number of workouts completed this week
    let weekWorkoutsCount: Int

    /// Total workout minutes this week
    let weekTotalMinutes: Int

    /// Total calories burned this week
    let weekTotalCalories: Int

    // MARK: - Monthly Aggregates

    /// Start date of the current month
    let monthStartDate: Date

    /// Number of workouts completed this month
    let monthWorkoutsCount: Int

    /// Total workout minutes this month
    let monthTotalMinutes: Int

    /// Total calories burned this month
    let monthTotalCalories: Int

    // MARK: - Metadata

    /// Timestamp of last stats update
    let lastUpdatedAt: Date

    // MARK: - Computed Properties

    /// Average workout duration this week (in minutes)
    var weekAverageDuration: Int {
        guard weekWorkoutsCount > 0 else { return 0 }
        return weekTotalMinutes / weekWorkoutsCount
    }

    /// Average workout duration this month (in minutes)
    var monthAverageDuration: Int {
        guard monthWorkoutsCount > 0 else { return 0 }
        return monthTotalMinutes / monthWorkoutsCount
    }

    /// Average calories per workout this week
    var weekAverageCalories: Int {
        guard weekWorkoutsCount > 0 else { return 0 }
        return weekTotalCalories / weekWorkoutsCount
    }

    /// Average calories per workout this month
    var monthAverageCalories: Int {
        guard monthWorkoutsCount > 0 else { return 0 }
        return monthTotalCalories / monthWorkoutsCount
    }

    // MARK: - Factory

    /// Creates a default empty UserStats instance
    static var empty: UserStats {
        UserStats(
            currentStreak: 0,
            longestStreak: 0,
            lastWorkoutDate: nil,
            weekStartDate: Date().startOfWeek,
            weekWorkoutsCount: 0,
            weekTotalMinutes: 0,
            weekTotalCalories: 0,
            monthStartDate: Date().startOfMonth,
            monthWorkoutsCount: 0,
            monthTotalMinutes: 0,
            monthTotalCalories: 0,
            lastUpdatedAt: Date()
        )
    }
}
