//
//  DebugEntitlementOverride.swift
//  FitToday
//
//  Classe para sobrescrever status de entitlement durante testes em builds DEBUG.
//  NÃO deve ser usada em produção.
//

import Foundation
import SwiftData

#if DEBUG
/// Singleton para gerenciar override de entitlement em modo debug.
/// Permite testar fluxos Pro/Free sem depender do StoreKit real.
final class DebugEntitlementOverride: @unchecked Sendable {
    static let shared = DebugEntitlementOverride()
    
    private let queue = DispatchQueue(label: "com.fittoday.debug.entitlement")
    
    private var _isEnabled: Bool = false
    private var _isPro: Bool = false
    
    private init() {
        // Carregar do UserDefaults para persistir entre sessões
        _isEnabled = UserDefaults.standard.bool(forKey: "debug_entitlement_enabled")
        _isPro = UserDefaults.standard.bool(forKey: "debug_entitlement_is_pro")
    }
    
    var isEnabled: Bool {
        get { queue.sync { _isEnabled } }
        set {
            queue.sync {
                _isEnabled = newValue
                UserDefaults.standard.set(newValue, forKey: "debug_entitlement_enabled")
            }
        }
    }
    
    var isPro: Bool {
        get { queue.sync { _isPro } }
        set {
            queue.sync {
                _isPro = newValue
                UserDefaults.standard.set(newValue, forKey: "debug_entitlement_is_pro")
            }
        }
    }
    
    var entitlement: ProEntitlement {
        if isPro {
            return ProEntitlement(
                isPro: true,
                source: .promo,
                expirationDate: Calendar.current.date(byAdding: .year, value: 1, to: Date())
            )
        } else {
            return .free
        }
    }
    
    /// Reseta todas as configurações de debug
    func reset() {
        isEnabled = false
        isPro = false
    }
}

/// Ferramenta de debug para criar dados de teste
struct DebugDataSeeder {
    
    /// Cria um perfil de teste se não existir
    @MainActor
    static func seedTestProfileIfNeeded(in context: ModelContext) async {
        let descriptor = FetchDescriptor<SDUserProfile>()
        let profiles = try? context.fetch(descriptor)
        
        if profiles?.isEmpty ?? true {
            print("[DebugSeeder] Criando perfil de teste...")
            
            let testProfile = SDUserProfile(
                id: UUID(),
                mainGoalRaw: FitnessGoal.hypertrophy.rawValue,
                availableStructureRaw: TrainingStructure.fullGym.rawValue,
                preferredMethodRaw: TrainingMethod.mixed.rawValue,
                levelRaw: TrainingLevel.intermediate.rawValue,
                healthConditionsRaw: ["none"],
                weeklyFrequency: 4,
                createdAt: Date(),
                isProfileComplete: true
            )
            
            context.insert(testProfile)
            try? context.save()
            
            print("[DebugSeeder] ✅ Perfil de teste criado: goal=hypertrophy structure=fullGym level=intermediate")
        } else {
            print("[DebugSeeder] Perfil já existe, ignorando seed")
        }
    }
    
    /// Ativa modo Pro para testes
    static func enableProMode() {
        DebugEntitlementOverride.shared.isEnabled = true
        DebugEntitlementOverride.shared.isPro = true
        print("[DebugSeeder] ✅ Modo Pro ativado")
    }
    
    /// Simula um check-in diário
    static func seedDailyCheckIn() {
        let checkIn = DailyCheckIn(
            focus: .fullBody,
            sorenessLevel: .none,
            sorenessAreas: [],
            createdAt: Date()
        )
        
        if let data = try? JSONEncoder().encode(checkIn) {
            UserDefaults.standard.set(data, forKey: AppStorageKeys.lastDailyCheckInData)
            UserDefaults.standard.set(Date(), forKey: AppStorageKeys.lastDailyCheckInDate)
            print("[DebugSeeder] ✅ Check-in diário simulado: focus=fullBody soreness=none")
        }
    }
}
#endif
