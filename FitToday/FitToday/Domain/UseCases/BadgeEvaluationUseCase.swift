//
//  BadgeEvaluationUseCase.swift
//  FitToday
//

import Foundation

final class BadgeEvaluationUseCase: @unchecked Sendable {
    private let badgeRepository: BadgeRepository
    private let historyRepository: WorkoutHistoryRepository
    private let featureFlags: FeatureFlagChecking

    init(
        badgeRepository: BadgeRepository,
        historyRepository: WorkoutHistoryRepository,
        featureFlags: FeatureFlagChecking
    ) {
        self.badgeRepository = badgeRepository
        self.historyRepository = historyRepository
        self.featureFlags = featureFlags
    }

    /// Evaluates all badge criteria and returns newly unlocked badges.
    func evaluate(userId: String) async throws -> [Badge] {
        guard await featureFlags.isFeatureEnabled(.publicProfileBadgesEnabled) else {
            return []
        }

        let existingBadges = try await badgeRepository.getUserBadges(userId: userId)
        let unlockedTypes = Set(existingBadges.filter(\.isUnlocked).map(\.type))

        let entries = try await historyRepository.listEntries()
        let now = Date()

        var newlyUnlocked: [Badge] = []

        for badgeType in BadgeType.allCases {
            guard !unlockedTypes.contains(badgeType) else { continue }
            if isCriteriaMet(badgeType, entries: entries) {
                let badge = Badge.unlocked(type: badgeType, at: now)
                try await badgeRepository.saveBadge(badge, userId: userId)
                newlyUnlocked.append(badge)
            }
        }

        return newlyUnlocked
    }

    /// Returns all badges (locked + unlocked) for display.
    func getAllBadges(userId: String) async throws -> [Badge] {
        guard await featureFlags.isFeatureEnabled(.publicProfileBadgesEnabled) else {
            return []
        }

        let existing = try await badgeRepository.getUserBadges(userId: userId)
        let existingByType = Dictionary(uniqueKeysWithValues: existing.map { ($0.type, $0) })

        return BadgeType.allCases.map { type in
            existingByType[type] ?? Badge.locked(type: type)
        }
    }

    // MARK: - Criteria Evaluation

    func isCriteriaMet(_ type: BadgeType, entries: [WorkoutHistoryEntry]) -> Bool {
        let completedEntries = entries.filter { $0.status == .completed }

        switch type {
        case .firstWorkout:
            return completedEntries.count >= 1

        case .workouts50:
            return completedEntries.count >= 50

        case .workouts100:
            return completedEntries.count >= 100

        case .streak7:
            return computeMaxStreak(from: completedEntries) >= 7

        case .streak30:
            return computeMaxStreak(from: completedEntries) >= 30

        case .streak100:
            return computeMaxStreak(from: completedEntries) >= 100

        case .earlyBird:
            let earlyCount = completedEntries.filter {
                Calendar.current.component(.hour, from: $0.date) < 7
            }.count
            return earlyCount >= 5

        case .weekWarrior:
            return hasWeekWith7Workouts(completedEntries)

        case .monthlyConsistency:
            return hasFourConsecutiveWeeksWithWorkouts(completedEntries)
        }
    }

    // MARK: - Helpers

    private func computeMaxStreak(from entries: [WorkoutHistoryEntry]) -> Int {
        let calendar = Calendar.current
        let uniqueDays = Set(entries.map { calendar.startOfDay(for: $0.date) })
        let sortedDays = uniqueDays.sorted()

        guard !sortedDays.isEmpty else { return 0 }

        var maxStreak = 1
        var currentStreak = 1

        for i in 1..<sortedDays.count {
            if let expected = calendar.date(byAdding: .day, value: 1, to: sortedDays[i - 1]),
               calendar.isDate(sortedDays[i], inSameDayAs: expected) {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else {
                currentStreak = 1
            }
        }

        return maxStreak
    }

    private func hasWeekWith7Workouts(_ entries: [WorkoutHistoryEntry]) -> Bool {
        let calendar = Calendar.current
        var weekCounts: [Int: Set<Date>] = [:]

        for entry in entries {
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: entry.date)
            let weekKey = (components.yearForWeekOfYear ?? 0) * 100 + (components.weekOfYear ?? 0)
            let day = calendar.startOfDay(for: entry.date)
            weekCounts[weekKey, default: []].insert(day)
        }

        return weekCounts.values.contains { $0.count >= 7 }
    }

    private func hasFourConsecutiveWeeksWithWorkouts(_ entries: [WorkoutHistoryEntry]) -> Bool {
        let calendar = Calendar.current
        var weeksWithWorkouts: Set<Int> = []

        for entry in entries {
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: entry.date)
            let weekKey = (components.yearForWeekOfYear ?? 0) * 100 + (components.weekOfYear ?? 0)
            weeksWithWorkouts.insert(weekKey)
        }

        let sortedWeeks = weeksWithWorkouts.sorted()
        guard sortedWeeks.count >= 4 else { return false }

        var consecutive = 1
        for i in 1..<sortedWeeks.count {
            let diff = sortedWeeks[i] - sortedWeeks[i - 1]
            if diff == 1 || (sortedWeeks[i - 1] % 100 >= 52 && diff > 50) {
                consecutive += 1
                if consecutive >= 4 { return true }
            } else {
                consecutive = 1
            }
        }

        return false
    }
}
