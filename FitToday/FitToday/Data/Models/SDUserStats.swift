//
//  SDUserStats.swift
//  FitToday
//
//  Created by Claude on 18/01/26.
//

import Foundation
import SwiftData

/// SwiftData model for aggregated user statistics.
/// Uses singleton pattern with id = "current" to ensure only one stats record.
@Model
final class SDUserStats {
    /// Singleton identifier - always "current"
    @Attribute(.unique) var id: String

    // MARK: - Streak Data

    /// Current consecutive workout days
    var currentStreak: Int

    /// Longest streak ever achieved
    var longestStreak: Int

    /// Date of last completed workout (for streak calculation)
    var lastWorkoutDate: Date?

    // MARK: - Weekly Aggregates

    /// Start date of the current week (Monday)
    var weekStartDate: Date

    /// Number of workouts completed this week
    var weekWorkoutsCount: Int

    /// Total workout minutes this week
    var weekTotalMinutes: Int

    /// Total calories burned this week
    var weekTotalCalories: Int

    // MARK: - Monthly Aggregates

    /// Start date of the current month
    var monthStartDate: Date

    /// Number of workouts completed this month
    var monthWorkoutsCount: Int

    /// Total workout minutes this month
    var monthTotalMinutes: Int

    /// Total calories burned this month
    var monthTotalCalories: Int

    // MARK: - Metadata

    /// Timestamp of last stats update (for cache validation)
    var lastUpdatedAt: Date

    // MARK: - Initialization

    init(
        id: String = "current",
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        lastWorkoutDate: Date? = nil,
        weekStartDate: Date = Date().startOfWeek,
        weekWorkoutsCount: Int = 0,
        weekTotalMinutes: Int = 0,
        weekTotalCalories: Int = 0,
        monthStartDate: Date = Date().startOfMonth,
        monthWorkoutsCount: Int = 0,
        monthTotalMinutes: Int = 0,
        monthTotalCalories: Int = 0,
        lastUpdatedAt: Date = Date()
    ) {
        self.id = id
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastWorkoutDate = lastWorkoutDate
        self.weekStartDate = weekStartDate
        self.weekWorkoutsCount = weekWorkoutsCount
        self.weekTotalMinutes = weekTotalMinutes
        self.weekTotalCalories = weekTotalCalories
        self.monthStartDate = monthStartDate
        self.monthWorkoutsCount = monthWorkoutsCount
        self.monthTotalMinutes = monthTotalMinutes
        self.monthTotalCalories = monthTotalCalories
        self.lastUpdatedAt = lastUpdatedAt
    }
}
