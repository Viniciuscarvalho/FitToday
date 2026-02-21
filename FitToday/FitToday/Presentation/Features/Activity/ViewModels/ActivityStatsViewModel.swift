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
        "Sem \(Calendar.current.component(.weekOfMonth, from: weekStart))"
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
    var errorMessage: String?

    // MARK: - Dependencies

    private let statsRepository: UserStatsRepository?
    private let historyRepository: WorkoutHistoryRepository?

    // MARK: - Init

    init(resolver: Resolver) {
        self.statsRepository = resolver.resolve(UserStatsRepository.self)
        self.historyRepository = resolver.resolve(WorkoutHistoryRepository.self)
    }

    // MARK: - Load

    func loadStats() async {
        isLoading = true
        defer { isLoading = false }

        do {
            stats = try await statsRepository?.getCurrentStats()

            let entries = try await historyRepository?.listEntries() ?? []
            let completed = entries.filter { $0.status == .completed }

            dailyEntries = buildDailyEntries(from: completed)
            weeklyEntries = buildWeeklyEntries(from: completed)
        } catch {
            errorMessage = error.localizedDescription
            #if DEBUG
            print("[ActivityStatsViewModel] Error: \(error)")
            #endif
        }
    }

    // MARK: - Aggregate Helpers

    private func buildDailyEntries(from entries: [WorkoutHistoryEntry]) -> [DailyChartEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Last 7 days
        let days = (0..<7).compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }.reversed()

        return days.map { day in
            let dayEntries = entries.filter { calendar.isDate($0.date, inSameDayAs: day) }
            return DailyChartEntry(
                date: day,
                workouts: dayEntries.count,
                minutes: dayEntries.reduce(0) { $0 + ($1.durationMinutes ?? 0) },
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
                minutes: weekEntries.reduce(0) { $0 + ($1.durationMinutes ?? 0) },
                calories: weekEntries.reduce(0) { $0 + ($1.caloriesBurned ?? 0) }
            )
        }
    }
}
