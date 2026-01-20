//
//  UserStatsCalculator.swift
//  FitToday
//
//  Created by Claude on 20/01/26.
//

import Foundation

/// Calculates user workout statistics including streaks, weekly/monthly aggregates.
struct UserStatsCalculator: UserStatsCalculating {
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        var cal = calendar
        cal.firstWeekday = 2 // Monday = 2 (ISO 8601)
        self.calendar = cal
    }

    // MARK: - Streak Calculation

    func calculateCurrentStreak(from history: [WorkoutHistoryEntry]) -> Int {
        // Filter only completed workouts and sort by date descending
        let completed = history
            .filter { $0.status == .completed }
            .sorted { $0.date > $1.date }

        guard let mostRecent = completed.first else { return 0 }

        let today = calendar.startOfDay(for: Date())
        let mostRecentDay = calendar.startOfDay(for: mostRecent.date)

        // Calculate days since last workout
        let daysDiff = calendar.dateComponents([.day], from: mostRecentDay, to: today).day ?? 0

        // If last workout was more than 1 day ago, streak is broken
        if daysDiff > 1 { return 0 }

        // Count consecutive days backwards
        var streak = 1 // Include the most recent day
        var previousDay = mostRecentDay
        var uniqueDays: Set<Date> = [mostRecentDay]

        for entry in completed.dropFirst() {
            let entryDay = calendar.startOfDay(for: entry.date)

            // Skip if already counted this day
            if uniqueDays.contains(entryDay) { continue }

            let diff = calendar.dateComponents([.day], from: entryDay, to: previousDay).day ?? 0

            if diff == 1 {
                // Consecutive day found
                streak += 1
                previousDay = entryDay
                uniqueDays.insert(entryDay)
            } else if diff > 1 {
                // Gap found, stop counting
                break
            }
            // diff == 0 means same day, continue to next entry
        }

        return streak
    }

    // MARK: - Weekly Stats

    func calculateWeeklyStats(from history: [WorkoutHistoryEntry]) -> WeeklyStats {
        let weekStart = Date().startOfWeek
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? Date()

        let weekEntries = history.filter { entry in
            entry.status == .completed &&
            entry.date >= weekStart &&
            entry.date < weekEnd
        }

        let totalMinutes = weekEntries.reduce(0) { sum, entry in
            sum + (entry.durationMinutes ?? entry.workoutPlan?.estimatedDurationMinutes ?? 0)
        }

        let totalCalories = weekEntries.reduce(0) { sum, entry in
            sum + (entry.caloriesBurned ?? 0)
        }

        // Note: userRating is an enum (tooEasy/adequate/tooHard), not numeric
        // For now, we count how many rated as "adequate" (positive feedback)
        let ratings = weekEntries.compactMap { $0.userRating }
        let adequateCount = ratings.filter { $0 == .adequate }.count
        let averageRating: Double? = ratings.isEmpty ? nil : Double(adequateCount) / Double(ratings.count)

        return WeeklyStats(
            weekStartDate: weekStart,
            workoutsCompleted: weekEntries.count,
            totalDurationMinutes: totalMinutes,
            totalCaloriesBurned: totalCalories,
            averageRating: averageRating
        )
    }

    // MARK: - Monthly Stats

    func calculateMonthlyStats(from history: [WorkoutHistoryEntry]) -> MonthlyStats {
        let monthStart = Date().startOfMonth
        let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? Date()

        let monthEntries = history.filter { entry in
            entry.status == .completed &&
            entry.date >= monthStart &&
            entry.date < monthEnd
        }

        let totalMinutes = monthEntries.reduce(0) { sum, entry in
            sum + (entry.durationMinutes ?? entry.workoutPlan?.estimatedDurationMinutes ?? 0)
        }

        let totalCalories = monthEntries.reduce(0) { sum, entry in
            sum + (entry.caloriesBurned ?? 0)
        }

        // Note: userRating is an enum (tooEasy/adequate/tooHard), not numeric
        let ratings = monthEntries.compactMap { $0.userRating }
        let adequateCount = ratings.filter { $0 == .adequate }.count
        let averageRating: Double? = ratings.isEmpty ? nil : Double(adequateCount) / Double(ratings.count)

        return MonthlyStats(
            monthStartDate: monthStart,
            workoutsCompleted: monthEntries.count,
            totalDurationMinutes: totalMinutes,
            totalCaloriesBurned: totalCalories,
            averageRating: averageRating
        )
    }

    // MARK: - Full Stats Computation

    func computeStats(
        from history: [WorkoutHistoryEntry],
        currentStats: UserStats?
    ) -> UserStats {
        let streak = calculateCurrentStreak(from: history)
        let weekly = calculateWeeklyStats(from: history)
        let monthly = calculateMonthlyStats(from: history)

        // Track longest streak
        let previousLongest = currentStats?.longestStreak ?? 0
        let longestStreak = max(streak, previousLongest)

        // Find most recent workout date
        let lastWorkoutDate = history
            .filter { $0.status == .completed }
            .max(by: { $0.date < $1.date })?
            .date

        return UserStats(
            currentStreak: streak,
            longestStreak: longestStreak,
            lastWorkoutDate: lastWorkoutDate,
            weekStartDate: weekly.weekStartDate,
            weekWorkoutsCount: weekly.workoutsCompleted,
            weekTotalMinutes: weekly.totalDurationMinutes,
            weekTotalCalories: weekly.totalCaloriesBurned,
            monthStartDate: monthly.monthStartDate,
            monthWorkoutsCount: monthly.workoutsCompleted,
            monthTotalMinutes: monthly.totalDurationMinutes,
            monthTotalCalories: monthly.totalCaloriesBurned,
            lastUpdatedAt: Date()
        )
    }
}
