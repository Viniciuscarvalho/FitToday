//
//  ComputeHistoryInsightsUseCase.swift
//  FitToday
//
//  Created by AI on 12/01/26.
//

import Foundation

// MARK: - Models

struct HistoryInsights: Sendable, Hashable {
    let currentStreak: Int
    let bestStreak: Int
    let weekly: [WeekBucket]
    let monthSummary: MonthSummary
    
    struct WeekBucket: Sendable, Hashable, Identifiable {
        let id: Date // weekStart
        let weekStart: Date
        let sessions: Int
        let minutes: Int
    }
    
    struct MonthSummary: Sendable, Hashable {
        let monthStart: Date
        let sessions: Int
        let minutes: Int
        let bestStreakInMonth: Int
    }
}

// MARK: - Use case

struct ComputeHistoryInsightsUseCase: Sendable {
    private let calendar: Calendar
    private let now: () -> Date
    
    init(calendar: Calendar = Calendar(identifier: .iso8601), now: @escaping () -> Date = Date.init) {
        self.calendar = calendar
        self.now = now
    }
    
    func execute(entries: [WorkoutHistoryEntry]) -> HistoryInsights {
        let completed = entries.filter { $0.status == .completed }
        
        let currentStreak = computeCurrentStreak(completed)
        let bestStreak = computeBestStreak(completed)
        let weekly = computeWeeklyBuckets(completed, weeksBack: 8)
        let monthSummary = computeMonthSummary(completed)
        
        return HistoryInsights(
            currentStreak: currentStreak,
            bestStreak: bestStreak,
            weekly: weekly,
            monthSummary: monthSummary
        )
    }
    
    // MARK: - Streaks
    
    private func computeCurrentStreak(_ entries: [WorkoutHistoryEntry]) -> Int {
        let daySet = Set(entries.map { startOfDay($0.date) })
        let today = startOfDay(now())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        
        // Streak começa em hoje se treinou hoje; senão, em ontem (se treinou ontem).
        let start: Date?
        if daySet.contains(today) {
            start = today
        } else if daySet.contains(yesterday) {
            start = yesterday
        } else {
            start = nil
        }
        
        guard var cursor = start else { return 0 }
        
        var streak = 0
        while daySet.contains(cursor) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }
    
    private func computeBestStreak(_ entries: [WorkoutHistoryEntry]) -> Int {
        let uniqueDays = Array(Set(entries.map { startOfDay($0.date) })).sorted()
        guard !uniqueDays.isEmpty else { return 0 }
        
        var best = 1
        var current = 1
        
        for i in 1..<uniqueDays.count {
            let prev = uniqueDays[i - 1]
            let day = uniqueDays[i]
            let expected = calendar.date(byAdding: .day, value: 1, to: prev)
            
            if expected == day {
                current += 1
                best = max(best, current)
            } else {
                current = 1
            }
        }
        
        return best
    }
    
    // MARK: - Weekly
    
    private func computeWeeklyBuckets(_ entries: [WorkoutHistoryEntry], weeksBack: Int) -> [HistoryInsights.WeekBucket] {
        let nowDate = now()
        let thisWeekStart = startOfWeek(nowDate)
        let startLimit = calendar.date(byAdding: .weekOfYear, value: -(weeksBack - 1), to: thisWeekStart) ?? thisWeekStart
        
        var map: [Date: (sessions: Int, minutes: Int)] = [:]
        
        for e in entries {
            let weekStart = startOfWeek(e.date)
            guard weekStart >= startLimit && weekStart <= thisWeekStart else { continue }
            
            let minutes = minutesForEntry(e)
            let existing = map[weekStart] ?? (0, 0)
            map[weekStart] = (existing.sessions + 1, existing.minutes + minutes)
        }
        
        // Preencher semanas vazias com 0 para sparkline consistente
        var buckets: [HistoryInsights.WeekBucket] = []
        for i in 0..<weeksBack {
            let week = calendar.date(byAdding: .weekOfYear, value: -i, to: thisWeekStart) ?? thisWeekStart
            let start = startOfWeek(week)
            let data = map[start] ?? (0, 0)
            buckets.append(.init(id: start, weekStart: start, sessions: data.sessions, minutes: data.minutes))
        }
        
        return buckets.sorted { $0.weekStart < $1.weekStart }
    }
    
    // MARK: - Month
    
    private func computeMonthSummary(_ entries: [WorkoutHistoryEntry]) -> HistoryInsights.MonthSummary {
        let today = now()
        let monthStart = startOfMonth(today)
        
        let monthEntries = entries.filter {
            let d = $0.date
            return d >= monthStart && d <= today
        }
        
        let sessions = monthEntries.count
        let minutes = monthEntries.reduce(0) { $0 + minutesForEntry($1) }
        let bestStreakInMonth = computeBestStreak(monthEntries)
        
        return .init(monthStart: monthStart, sessions: sessions, minutes: minutes, bestStreakInMonth: bestStreakInMonth)
    }
    
    // MARK: - Date helpers
    
    private func startOfDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }
    
    private func startOfWeek(_ date: Date) -> Date {
        let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: comps) ?? startOfDay(date)
    }
    
    private func startOfMonth(_ date: Date) -> Date {
        let comps = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: comps) ?? startOfDay(date)
    }
    
    private func minutesForEntry(_ entry: WorkoutHistoryEntry) -> Int {
        if let m = entry.durationMinutes { return max(0, m) }
        if let plan = entry.workoutPlan { return max(0, plan.estimatedDurationMinutes) }
        return 0
    }
}

