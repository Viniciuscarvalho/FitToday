//
//  DebugDataSeeder.swift
//  FitToday
//
//  Classe para criar dados de teste durante desenvolvimento em builds DEBUG.
//  NÃO deve ser usada em produção.
//

import Foundation
import SwiftData

#if DEBUG
/// Classe utilitária para criar dados de teste para debug.
final class DebugDataSeeder {
    
    /// Cria um perfil de teste no SwiftData se não existir.
    /// Perfil de teste: Hipertrofia + Academia Full + Tradicional + Intermediário + 4x/semana
    static func seedTestProfileIfNeeded(in context: ModelContext) async {
        // Verifica se já existe um perfil
        let descriptor = FetchDescriptor<SDUserProfile>()
        if let existing = try? context.fetch(descriptor).first {
            print("[DebugDataSeeder] Perfil já existe: \(existing.id)")
            return
        }
        
        // Cria perfil de teste
        let testProfile = UserProfile(
            id: UUID(),
            mainGoal: .hypertrophy,
            availableStructure: .fullGym,
            preferredMethod: .traditional,
            level: .intermediate,
            healthConditions: [.none],
            weeklyFrequency: 4,
            createdAt: Date(),
            isProfileComplete: true
        )
        
        let model = UserProfileMapper.toModel(testProfile)
        context.insert(model)
        
        do {
            try context.save()
            print("[DebugDataSeeder] ✅ Perfil de teste criado: \(testProfile.id)")
            print("[DebugDataSeeder]   Objetivo: Hipertrofia")
            print("[DebugDataSeeder]   Estrutura: Academia Full")
            print("[DebugDataSeeder]   Método: Tradicional")
            print("[DebugDataSeeder]   Nível: Intermediário")
            print("[DebugDataSeeder]   Frequência: 4x/semana")
        } catch {
            print("[DebugDataSeeder] ❌ Erro ao salvar perfil de teste: \(error)")
        }
    }
    
    /// Ativa modo Pro usando DebugEntitlementOverride.
    static func enableProMode() {
        DebugEntitlementOverride.shared.isEnabled = true
        DebugEntitlementOverride.shared.isPro = true
        print("[DebugDataSeeder] ✅ Modo Pro ativado via DebugEntitlementOverride")
    }
    
    /// Cria um check-in diário de teste.
    /// Check-in de teste: FullBody + Sem dor
    static func seedDailyCheckIn() {
        let checkIn = DailyCheckIn(
            focus: .fullBody,
            sorenessLevel: .none,
            sorenessAreas: [],
            energyLevel: 7,
            createdAt: Date()
        )
        
        // Salva no UserDefaults (mesmo padrão usado pelo app)
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(checkIn)
            UserDefaults.standard.set(data, forKey: AppStorageKeys.lastDailyCheckInData)
            UserDefaults.standard.set(Date(), forKey: AppStorageKeys.lastDailyCheckInDate)
            
            // Marca como sugerido (caso o DailyWorkoutStateManager seja necessário)
            // Nota: DailyWorkoutStateManager não foi encontrado, então pulamos essa parte
            
            print("[DebugDataSeeder] ✅ Check-in diário criado")
            print("[DebugDataSeeder]   Foco: FullBody")
            print("[DebugDataSeeder]   Nível de dor: Nenhum")
        } catch {
            print("[DebugDataSeeder] ❌ Erro ao criar check-in de teste: \(error)")
        }
    }
}
#endif


