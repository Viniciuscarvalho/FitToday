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
            
            // Para features com limite de uso, buscar o contador atual
            var usageCount = 0
            if feature == .aiWorkoutGeneration, let tracker = usageTracker {
                usageCount = await tracker.weeklyUsageCount()
            }
            
            return EntitlementPolicy.canAccess(feature, entitlement: entitlement, usageCount: usageCount)
        } catch {
            // Em caso de erro, assumir Free
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
    
    /// Registra um uso de IA
    func registerUsage() async
}

// MARK: - Simple AI Usage Tracker

/// Tracker simples usando UserDefaults
actor SimpleAIUsageTracker: AIUsageTracking {
    private let userDefaults: UserDefaults
    private let usageKey = "ai_weekly_usage"
    private let weekKey = "ai_usage_week"
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func weeklyUsageCount() async -> Int {
        // Verificar se estamos na mesma semana
        let currentWeek = Calendar.current.component(.weekOfYear, from: Date())
        let savedWeek = userDefaults.integer(forKey: weekKey)
        
        if currentWeek != savedWeek {
            // Nova semana, resetar contador
            await resetUsage()
            return 0
        }
        
        return userDefaults.integer(forKey: usageKey)
    }
    
    func registerUsage() async {
        let currentWeek = Calendar.current.component(.weekOfYear, from: Date())
        let savedWeek = userDefaults.integer(forKey: weekKey)
        
        if currentWeek != savedWeek {
            // Nova semana
            userDefaults.set(currentWeek, forKey: weekKey)
            userDefaults.set(1, forKey: usageKey)
        } else {
            let current = userDefaults.integer(forKey: usageKey)
            userDefaults.set(current + 1, forKey: usageKey)
        }
    }
    
    private func resetUsage() {
        let currentWeek = Calendar.current.component(.weekOfYear, from: Date())
        userDefaults.set(currentWeek, forKey: weekKey)
        userDefaults.set(0, forKey: usageKey)
    }
}

