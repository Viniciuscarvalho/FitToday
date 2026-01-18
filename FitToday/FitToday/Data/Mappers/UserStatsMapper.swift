//
//  UserStatsMapper.swift
//  FitToday
//
//  Created by Claude on 18/01/26.
//

import Foundation

/// Maps between SDUserStats (SwiftData model) and UserStats (domain entity)
struct UserStatsMapper {
    /// Converts SwiftData model to domain entity
    static func toDomain(_ model: SDUserStats) -> UserStats {
        UserStats(
            currentStreak: model.currentStreak,
            longestStreak: model.longestStreak,
            lastWorkoutDate: model.lastWorkoutDate,
            weekStartDate: model.weekStartDate,
            weekWorkoutsCount: model.weekWorkoutsCount,
            weekTotalMinutes: model.weekTotalMinutes,
            weekTotalCalories: model.weekTotalCalories,
            monthStartDate: model.monthStartDate,
            monthWorkoutsCount: model.monthWorkoutsCount,
            monthTotalMinutes: model.monthTotalMinutes,
            monthTotalCalories: model.monthTotalCalories,
            lastUpdatedAt: model.lastUpdatedAt
        )
    }

    /// Converts domain entity to SwiftData model
    static func toModel(_ stats: UserStats) -> SDUserStats {
        SDUserStats(
            id: "current",
            currentStreak: stats.currentStreak,
            longestStreak: stats.longestStreak,
            lastWorkoutDate: stats.lastWorkoutDate,
            weekStartDate: stats.weekStartDate,
            weekWorkoutsCount: stats.weekWorkoutsCount,
            weekTotalMinutes: stats.weekTotalMinutes,
            weekTotalCalories: stats.weekTotalCalories,
            monthStartDate: stats.monthStartDate,
            monthWorkoutsCount: stats.monthWorkoutsCount,
            monthTotalMinutes: stats.monthTotalMinutes,
            monthTotalCalories: stats.monthTotalCalories,
            lastUpdatedAt: stats.lastUpdatedAt
        )
    }

    /// Updates an existing SwiftData model with values from a domain entity
    static func updateModel(_ model: SDUserStats, with stats: UserStats) {
        model.currentStreak = stats.currentStreak
        model.longestStreak = stats.longestStreak
        model.lastWorkoutDate = stats.lastWorkoutDate
        model.weekStartDate = stats.weekStartDate
        model.weekWorkoutsCount = stats.weekWorkoutsCount
        model.weekTotalMinutes = stats.weekTotalMinutes
        model.weekTotalCalories = stats.weekTotalCalories
        model.monthStartDate = stats.monthStartDate
        model.monthWorkoutsCount = stats.monthWorkoutsCount
        model.monthTotalMinutes = stats.monthTotalMinutes
        model.monthTotalCalories = stats.monthTotalCalories
        model.lastUpdatedAt = stats.lastUpdatedAt
    }
}
