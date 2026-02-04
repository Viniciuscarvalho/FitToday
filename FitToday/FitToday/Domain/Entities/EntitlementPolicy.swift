//
//  EntitlementPolicy.swift
//  FitToday
//
//  Política centralizada de acesso a features baseada no entitlement.
//

import Foundation

// MARK: - Feature Enum

/// Features que requerem verificação de acesso
enum ProFeature: String, CaseIterable {
    // Treinos IA
    case aiWorkoutGeneration = "ai_workout_generation"
    case aiExerciseSubstitution = "ai_exercise_substitution"
    
    // Tracking avançado
    case unlimitedHistory = "unlimited_history"
    case advancedDOMSAdjustment = "advanced_doms_adjustment"
    
    // Biblioteca
    case premiumPrograms = "premium_programs"
    
    // Configurações
    case customizableSettings = "customizable_settings"
    
    var displayName: String {
        switch self {
        case .aiWorkoutGeneration: return "Treinos personalizados por IA"
        case .aiExerciseSubstitution: return "Substituição inteligente de exercícios"
        case .unlimitedHistory: return "Histórico ilimitado"
        case .advancedDOMSAdjustment: return "Ajuste por dor muscular"
        case .premiumPrograms: return "Programas premium"
        case .customizableSettings: return "Configurações avançadas"
        }
    }
}

// MARK: - Access Result

/// Resultado da verificação de acesso
enum FeatureAccessResult {
    case allowed
    case limitReached(remaining: Int, limit: Int)
    case requiresPro(feature: ProFeature)
    case trialExpired
    case featureDisabled(reason: String)

    var isAllowed: Bool {
        if case .allowed = self { return true }
        return false
    }

    /// Indicates if the result is due to a disabled feature flag.
    var isFeatureDisabled: Bool {
        if case .featureDisabled = self { return true }
        return false
    }

    var message: String {
        switch self {
        case .allowed:
            return ""
        case .limitReached(let remaining, let limit):
            return "Você usou \(limit - remaining)/\(limit) desta semana. Upgrade para acesso ilimitado."
        case .requiresPro(let feature):
            return "\(feature.displayName) é um recurso Pro. Assine para desbloquear."
        case .trialExpired:
            return "Seu período de teste terminou. Assine para continuar."
        case .featureDisabled(let reason):
            return reason
        }
    }
}

// MARK: - Entitlement Policy

/// Política centralizada para verificação de acesso a features
struct EntitlementPolicy {
    
    // MARK: - Limites Free
    
    /// Número de treinos IA por semana para usuários Free
    static let freeAIWorkoutsPerWeek = 1
    
    /// Dias de histórico para usuários Free
    static let freeHistoryDaysLimit = 7
    
    // MARK: - Verificação de Acesso
    
    /// Verifica se o usuário pode acessar uma feature
    /// - Parameters:
    ///   - feature: Feature a ser verificada
    ///   - entitlement: Entitlement atual do usuário
    ///   - usageCount: Uso atual (para features com limite)
    /// - Returns: Resultado da verificação
    static func canAccess(
        _ feature: ProFeature,
        entitlement: ProEntitlement,
        usageCount: Int = 0
    ) -> FeatureAccessResult {
        
        // Pro tem acesso a tudo
        if entitlement.isPro {
            // Verificar se trial expirou
            if let expiration = entitlement.expirationDate, expiration < Date() {
                return .trialExpired
            }
            return .allowed
        }
        
        // Verificar features específicas para Free
        switch feature {
        case .aiWorkoutGeneration:
            // Free pode usar 1x por semana
            if usageCount >= freeAIWorkoutsPerWeek {
                return .limitReached(remaining: 0, limit: freeAIWorkoutsPerWeek)
            }
            return .allowed
            
        case .aiExerciseSubstitution:
            // Substituição requer Pro
            return .requiresPro(feature: feature)
            
        case .unlimitedHistory:
            // Free tem acesso limitado a 7 dias
            return .requiresPro(feature: feature)
            
        case .advancedDOMSAdjustment:
            // Ajuste por DOMS requer Pro
            return .requiresPro(feature: feature)
            
        case .premiumPrograms:
            // Programas premium requerem Pro
            return .requiresPro(feature: feature)
            
        case .customizableSettings:
            // Configurações avançadas requerem Pro
            return .requiresPro(feature: feature)
        }
    }
    
    /// Verifica se uma feature é totalmente bloqueada para Free
    static func isProOnly(_ feature: ProFeature) -> Bool {
        switch feature {
        case .aiWorkoutGeneration:
            return false // Free tem acesso limitado
        case .aiExerciseSubstitution,
             .unlimitedHistory,
             .advancedDOMSAdjustment,
             .premiumPrograms,
             .customizableSettings:
            return true
        }
    }
    
    /// Retorna o limite semanal para features com limite
    static func weeklyLimit(for feature: ProFeature, entitlement: ProEntitlement) -> Int? {
        guard !entitlement.isPro else { return nil } // Sem limite para Pro
        
        switch feature {
        case .aiWorkoutGeneration:
            return freeAIWorkoutsPerWeek
        default:
            return nil
        }
    }
    
    // MARK: - Helpers para UI
    
    /// Retorna lista de features que são Pro-only para exibição
    static var proOnlyFeatures: [ProFeature] {
        ProFeature.allCases.filter { isProOnly($0) }
    }
    
    /// Retorna lista de features com limites para Free
    static var limitedFreeFeatures: [(feature: ProFeature, limit: Int)] {
        [
            (.aiWorkoutGeneration, freeAIWorkoutsPerWeek)
        ]
    }
}

// MARK: - Convenience Extensions

extension ProEntitlement {
    /// Verifica acesso a uma feature usando a policy centralizada
    func canAccess(_ feature: ProFeature, usageCount: Int = 0) -> FeatureAccessResult {
        EntitlementPolicy.canAccess(feature, entitlement: self, usageCount: usageCount)
    }
    
    /// Verifica se tem acesso a uma feature (simplificado)
    func hasAccess(to feature: ProFeature) -> Bool {
        canAccess(feature).isAllowed
    }
}

