//
//  DebugEntitlementOverride.swift
//  FitToday
//
//  Classe para sobrescrever status de entitlement durante testes em builds DEBUG.
//  NÃO deve ser usada em produção.
//

import Foundation

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
#endif


