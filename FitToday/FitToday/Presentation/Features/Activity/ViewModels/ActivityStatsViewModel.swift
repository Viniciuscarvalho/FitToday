//
//  ActivityStatsViewModel.swift
//  FitToday
//
//  ViewModel for the Activity Stats tab with chart-ready data.
//

import Foundation
import Swinject

// MARK: - Chart Data Models

struct DailyChartEntry: Identifiable, Sendable {
    let id = UUID()
    let date: Date
    let workouts: Int
    let minutes: Int
    let calories: Int

    var dayLabel: String {
        date.formatted(.dateTime.weekday(.abbreviated))
    }
}

struct WeeklyChartEntry: Identifiable, Sendable {
    let id = UUID()
    let weekStart: Date
    let workouts: Int
    let minutes: Int
    let calories: Int

    var weekLabel: String {
        // BUG 4 FIX: use abbreviated date (e.g. "3 Jan") instead of weekOfMonth
        // which produces repeated "Sem 1" for cross-month ranges.
        weekStart.formatted(.dateTime.day().month(.abbreviated))
    }
}

// MARK: - ViewModel

@MainActor
@Observable
final class ActivityStatsViewModel {
    // MARK: - State

    private(set) var stats: UserStats?
    private(set) var dailyEntries: [DailyChartEntry] = []
    private(set) var weeklyEntries: [WeeklyChartEntry] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    // MARK: - Dependencies

    private let historyRepository: WorkoutHistoryRepository?
    private let syncService: HealthKitHistorySyncService?

    // MARK: - Init

    init(resolver: Resolver) {
        self.historyRepository = resolver.resolve(WorkoutHistoryRepository.self)
        self.syncService = resolver.resolve(HealthKitHistorySyncService.self)
    }

    // MARK: - Load

    func loadStats() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // BUG 5 FIX: single sync call — importExternalWorkouts already covers
            // external sources; syncLastDays was a redundant duplicate.
            try? await syncService?.importExternalWorkouts(days: 30)

            let entries = try await historyRepository?.listEntries() ?? []
            let completed = entries.filter { $0.status == .completed }

            stats = buildStats(from: completed)
            dailyEntries = buildDailyEntries(from: completed)
            weeklyEntries = buildWeeklyEntries(from: completed)
        } catch {
            errorMessage = error.localizedDescription
            #if DEBUG
            print("[ActivityStatsViewModel] Error: \(error)")
            #endif
        }
    }

    // MARK: - Stats from History

    private func buildStats(from entries: [WorkoutHistoryEntry]) -> UserStats {
        let calendar = Calendar.current
        let today = Date()
        let weekStart = today.startOfWeek
        let monthStart = today.startOfMonth

        let weekEntries = entries.filter { $0.date >= weekStart }
        let monthEntries = entries.filter { $0.date >= monthStart }
        let currentStreak = computeStreak(from: entries, calendar: calendar)
        // BUG 2 FIX: compute longest streak from full history instead of always
        // using currentStreak (which made longestStreak == currentStreak always).
        let longest = computeLongestStreak(from: entries, calendar: calendar)

        return UserStats(
            currentStreak: currentStreak,
            longestStreak: longest,
            lastWorkoutDate: entries.sorted { $0.date > $1.date }.first?.date,
            weekStartDate: weekStart,
            weekWorkoutsCount: weekEntries.count,
            weekTotalMinutes: weekEntries.reduce(0) { $0 + effectiveDuration($1) },
            weekTotalCalories: weekEntries.reduce(0) { $0 + ($1.caloriesBurned ?? 0) },
            monthStartDate: monthStart,
            monthWorkoutsCount: monthEntries.count,
            monthTotalMinutes: monthEntries.reduce(0) { $0 + effectiveDuration($1) },
            monthTotalCalories: monthEntries.reduce(0) { $0 + ($1.caloriesBurned ?? 0) },
            lastUpdatedAt: today
        )
    }

    // BUG 3 FIX: fall back to the plan's estimatedDurationMinutes when the
    // recorded durationMinutes is nil (e.g. HealthKit entry with no duration).
    private func effectiveDuration(_ entry: WorkoutHistoryEntry) -> Int {
        entry.durationMinutes ?? entry.workoutPlan?.estimatedDurationMinutes ?? 0
    }

    // BUG 10 FIX: allow a 1-day gap so a streak started yesterday is still live.
    // Matches UserStatsCalculator.calculateCurrentStreak() which uses daysDiff > 1.
    private func computeStreak(from entries: [WorkoutHistoryEntry], calendar: Calendar) -> Int {
        let workoutDays = Array(
            Set(entries.map { calendar.startOfDay(for: $0.date) })
        ).sorted(by: >)
        guard let mostRecent = workoutDays.first else { return 0 }

        let today = calendar.startOfDay(for: Date())
        let daysSinceLast = calendar.dateComponents([.day], from: mostRecent, to: today).day ?? 0
        // If the last workout was more than 1 day ago the streak is broken.
        if daysSinceLast > 1 { return 0 }

        var streak = 0
        var expected = mostRecent

        for day in workoutDays {
            if day == expected {
                streak += 1
                expected = calendar.date(byAdding: .day, value: -1, to: expected)!
            } else {
                break
            }
        }
        return streak
    }

    // BUG 2 FIX: scan all history to find the historically longest consecutive streak.
    private func computeLongestStreak(from entries: [WorkoutHistoryEntry], calendar: Calendar) -> Int {
        let workoutDays = Array(
            Set(entries.map { calendar.startOfDay(for: $0.date) })
        ).sorted(by: >)
        guard !workoutDays.isEmpty else { return 0 }

        var longest = 1
        var current = 1

        for i in 1..<workoutDays.count {
            let diff = calendar.dateComponents([.day], from: workoutDays[i], to: workoutDays[i - 1]).day ?? 0
            if diff == 1 {
                current += 1
                longest = max(longest, current)
            } else {
                current = 1
            }
        }
        return longest
    }

    // MARK: - Aggregate Helpers

    private func buildDailyEntries(from entries: [WorkoutHistoryEntry]) -> [DailyChartEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Last 7 days
        let days = Array((0..<7).compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }.reversed())

        return days.map { day in
            let dayEntries = entries.filter { calendar.isDate($0.date, inSameDayAs: day) }
            return DailyChartEntry(
                date: day,
                workouts: dayEntries.count,
                minutes: dayEntries.reduce(0) { $0 + effectiveDuration($1) },
                calories: dayEntries.reduce(0) { $0 + ($1.caloriesBurned ?? 0) }
            )
        }
    }

    private func buildWeeklyEntries(from entries: [WorkoutHistoryEntry]) -> [WeeklyChartEntry] {
        let calendar = Calendar.current
        let today = Date()

        // Last 4 weeks
        return (0..<4).reversed().compactMap { weeksAgo -> WeeklyChartEntry? in
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weeksAgo, to: today.startOfWeek) else {
                return nil
            }
            guard let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
                return nil
            }

            let weekEntries = entries.filter { $0.date >= weekStart && $0.date < weekEnd }
            return WeeklyChartEntry(
                weekStart: weekStart,
                workouts: weekEntries.count,
                minutes: weekEntries.reduce(0) { $0 + effectiveDuration($1) },
                calories: weekEntries.reduce(0) { $0 + ($1.caloriesBurned ?? 0) }
            )
        }
    }
}
