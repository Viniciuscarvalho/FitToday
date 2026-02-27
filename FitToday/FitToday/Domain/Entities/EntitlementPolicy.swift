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

    // Personal Trainer
    case personalTrainer = "personal_trainer"
    case trainerWorkouts = "trainer_workouts"

    // Social
    case simultaneousChallenges = "simultaneous_challenges"

    // AI Chat
    case aiChat = "ai_chat"

    var displayName: String {
        switch self {
        case .aiWorkoutGeneration: return "Treinos personalizados por IA"
        case .aiExerciseSubstitution: return "Substituição inteligente de exercícios"
        case .unlimitedHistory: return "Histórico ilimitado"
        case .advancedDOMSAdjustment: return "Ajuste por dor muscular"
        case .premiumPrograms: return "Programas premium"
        case .customizableSettings: return "Configurações avançadas"
        case .personalTrainer: return "Personal Trainer"
        case .trainerWorkouts: return "Treinos do Personal"
        case .simultaneousChallenges: return "Desafios simultâneos ilimitados"
        case .aiChat: return "Assistente IA FitOrb"
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
        case .limitReached(_, let limit):
            return "Você atingiu o limite de \(limit) usos. Desbloqueie o Pro para mais."
        case .requiresPro(let feature):
            return "\(feature.displayName) é um recurso Pro. Desbloqueie o Pro para acessar."
        case .trialExpired:
            return "Seu período de teste terminou. Desbloqueie o Pro para continuar."
        case .featureDisabled(let reason):
            return reason
        }
    }
}

// MARK: - Entitlement Policy

/// Política centralizada para verificação de acesso a features
struct EntitlementPolicy {

    // MARK: - Limites

    /// Número de treinos IA por semana para usuários Free
    static let freeAIWorkoutsPerWeek = 1

    /// Número de treinos IA por dia para usuários Pro
    static let proAIWorkoutsPerDay = 2

    /// Dias de histórico para usuários Free
    static let freeHistoryDaysLimit = 7

    /// Número máximo de desafios simultâneos para Free
    static let freeChallengesLimit = 5

    // MARK: - Verificação de Acesso

    /// Verifica se o usuário pode acessar uma feature
    /// - Parameters:
    ///   - feature: Feature a ser verificada
    ///   - entitlement: Entitlement atual do usuário
    ///   - usageCount: Uso atual (semanal para Free AI, diário para Pro AI, contagem ativa para desafios)
    /// - Returns: Resultado da verificação
    static func canAccess(
        _ feature: ProFeature,
        entitlement: ProEntitlement,
        usageCount: Int = 0
    ) -> FeatureAccessResult {

        // Pro tem acesso a tudo (com limites diários em IA)
        if entitlement.isPro {
            if let expiration = entitlement.expirationDate, expiration < Date() {
                return .trialExpired
            }

            switch feature {
            case .aiWorkoutGeneration:
                if usageCount >= proAIWorkoutsPerDay {
                    return .limitReached(remaining: 0, limit: proAIWorkoutsPerDay)
                }
                return .allowed
            default:
                return .allowed
            }
        }

        // Verificar features específicas para Free
        switch feature {
        case .aiWorkoutGeneration:
            if usageCount >= freeAIWorkoutsPerWeek {
                return .limitReached(remaining: 0, limit: freeAIWorkoutsPerWeek)
            }
            return .allowed

        case .simultaneousChallenges:
            if usageCount >= freeChallengesLimit {
                return .limitReached(remaining: 0, limit: freeChallengesLimit)
            }
            return .allowed

        case .aiExerciseSubstitution,
             .unlimitedHistory,
             .advancedDOMSAdjustment,
             .premiumPrograms,
             .customizableSettings,
             .personalTrainer,
             .trainerWorkouts:
            return .requiresPro(feature: feature)
        }
    }

    /// Verifica se uma feature é totalmente bloqueada para Free
    static func isProOnly(_ feature: ProFeature) -> Bool {
        switch feature {
        case .aiWorkoutGeneration, .simultaneousChallenges:
            return false // Free tem acesso limitado
        case .aiExerciseSubstitution,
             .unlimitedHistory,
             .advancedDOMSAdjustment,
             .premiumPrograms,
             .customizableSettings,
             .personalTrainer,
             .trainerWorkouts:
            return true
        }
    }

    /// Retorna o limite de uso para uma feature
    static func usageLimit(for feature: ProFeature, entitlement: ProEntitlement) -> (limit: Int, period: String)? {
        switch feature {
        case .aiWorkoutGeneration:
            if entitlement.isPro {
                return (proAIWorkoutsPerDay, "dia")
            } else {
                return (freeAIWorkoutsPerWeek, "semana")
            }
        case .simultaneousChallenges:
            if entitlement.isPro {
                return nil // ilimitado
            } else {
                return (freeChallengesLimit, "simultâneos")
            }
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
    static var limitedFreeFeatures: [(feature: ProFeature, freeLimit: String, proLimit: String)] {
        [
            (.aiWorkoutGeneration, "1/semana", "2/dia"),
            (.simultaneousChallenges, "5", "∞")
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
