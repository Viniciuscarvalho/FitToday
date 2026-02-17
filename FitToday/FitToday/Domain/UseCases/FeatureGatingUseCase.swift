//
//  FeatureGatingUseCase.swift
//  FitToday
//
//  Use case para verificar acesso a features e controlar gating.
//

import Foundation
import Combine

// MARK: - Feature Gating Protocol

protocol FeatureGating: Sendable {
    /// Verifica se o usuário pode acessar uma feature
    func checkAccess(to feature: ProFeature) async -> FeatureAccessResult

    /// Retorna o entitlement atual
    func currentEntitlement() async throws -> ProEntitlement

    /// Stream de mudanças no entitlement
    func entitlementStream() -> AsyncStream<ProEntitlement>
}

// MARK: - Feature Gating Use Case

final class FeatureGatingUseCase: FeatureGating, @unchecked Sendable {
    private let entitlementRepository: EntitlementRepository
    private let usageTracker: AIUsageTracking?

    init(entitlementRepository: EntitlementRepository, usageTracker: AIUsageTracking? = nil) {
        self.entitlementRepository = entitlementRepository
        self.usageTracker = usageTracker
    }

    func checkAccess(to feature: ProFeature) async -> FeatureAccessResult {
        do {
            let entitlement = try await entitlementRepository.currentEntitlement()

            var usageCount = 0
            if feature == .aiWorkoutGeneration, let tracker = usageTracker {
                if entitlement.isPro {
                    usageCount = await tracker.dailyUsageCount()
                } else {
                    usageCount = await tracker.weeklyUsageCount()
                }
            }

            return EntitlementPolicy.canAccess(feature, entitlement: entitlement, usageCount: usageCount)
        } catch {
            return EntitlementPolicy.canAccess(feature, entitlement: .free, usageCount: 0)
        }
    }

    func currentEntitlement() async throws -> ProEntitlement {
        try await entitlementRepository.currentEntitlement()
    }

    func entitlementStream() -> AsyncStream<ProEntitlement> {
        entitlementRepository.entitlementStream()
    }
}

// MARK: - AI Usage Tracking Protocol

protocol AIUsageTracking: Sendable {
    /// Retorna o número de usos de IA na semana atual
    func weeklyUsageCount() async -> Int

    /// Retorna o número de usos de IA no dia atual
    func dailyUsageCount() async -> Int

    /// Registra um uso de IA
    func registerUsage() async
}

// MARK: - Simple AI Usage Tracker

/// Tracker simples usando UserDefaults
actor SimpleAIUsageTracker: AIUsageTracking {
    private let userDefaults: UserDefaults
    private let weeklyUsageKey = "ai_weekly_usage"
    private let weekKey = "ai_usage_week"
    private let dailyUsageKey = "ai_daily_usage"
    private let dayKey = "ai_usage_day"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func weeklyUsageCount() async -> Int {
        let currentWeek = Calendar.current.component(.weekOfYear, from: Date())
        let savedWeek = userDefaults.integer(forKey: weekKey)

        if currentWeek != savedWeek {
            resetWeeklyUsage()
            return 0
        }

        return userDefaults.integer(forKey: weeklyUsageKey)
    }

    func dailyUsageCount() async -> Int {
        let currentDay = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let savedDay = userDefaults.integer(forKey: dayKey)

        if currentDay != savedDay {
            resetDailyUsage()
            return 0
        }

        return userDefaults.integer(forKey: dailyUsageKey)
    }

    func registerUsage() async {
        // Weekly tracking
        let currentWeek = Calendar.current.component(.weekOfYear, from: Date())
        let savedWeek = userDefaults.integer(forKey: weekKey)

        if currentWeek != savedWeek {
            userDefaults.set(currentWeek, forKey: weekKey)
            userDefaults.set(1, forKey: weeklyUsageKey)
        } else {
            let current = userDefaults.integer(forKey: weeklyUsageKey)
            userDefaults.set(current + 1, forKey: weeklyUsageKey)
        }

        // Daily tracking
        let currentDay = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let savedDay = userDefaults.integer(forKey: dayKey)

        if currentDay != savedDay {
            userDefaults.set(currentDay, forKey: dayKey)
            userDefaults.set(1, forKey: dailyUsageKey)
        } else {
            let dailyCurrent = userDefaults.integer(forKey: dailyUsageKey)
            userDefaults.set(dailyCurrent + 1, forKey: dailyUsageKey)
        }
    }

    private func resetWeeklyUsage() {
        let currentWeek = Calendar.current.component(.weekOfYear, from: Date())
        userDefaults.set(currentWeek, forKey: weekKey)
        userDefaults.set(0, forKey: weeklyUsageKey)
    }

    private func resetDailyUsage() {
        let currentDay = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        userDefaults.set(currentDay, forKey: dayKey)
        userDefaults.set(0, forKey: dailyUsageKey)
    }
}
