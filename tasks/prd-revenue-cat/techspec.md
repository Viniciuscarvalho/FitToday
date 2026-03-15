# Tech Spec: RevenueCat SDK Integration

## Architecture Overview

Mudanças mínimas mantendo a arquitetura MVVM + DI existente:

```
FitTodayApp.init()
  └── Purchases.configure(withAPIKey:)         ← NOVO

AppContainer
  └── RevenueCatEntitlementRepository          ← NOVO (substitui StoreKitEntitlementRepository)
        implements EntitlementRepository
        uses Purchases.shared.customerInfo()

OptimizedPaywallView                           ← ATUALIZADO
  └── PaywallView() from RevenueCatUI
```

## Files Changed

| File                                    | Change                                                     |
| --------------------------------------- | ---------------------------------------------------------- |
| `FitTodayApp.swift`                     | Adicionar `import RevenueCat` + `Purchases.configure(...)` |
| `AppContainer.swift`                    | Registrar `RevenueCatEntitlementRepository`                |
| `OptimizedPaywallView.swift`            | Substituir corpo pelo `PaywallView()` do RevenueCatUI      |
| `RevenueCatEntitlementRepository.swift` | NOVO — implementa `EntitlementRepository`                  |

## RevenueCatEntitlementRepository

```swift
final class RevenueCatEntitlementRepository: EntitlementRepository {
    func currentEntitlement() async throws -> ProEntitlement {
        let info = try await Purchases.shared.customerInfo()
        return mapToEntitlement(info)
    }

    func entitlementStream() -> AsyncStream<ProEntitlement> { ... }

    private func mapToEntitlement(_ info: CustomerInfo) -> ProEntitlement {
        if info.entitlements["FitToday Elite"]?.isActive == true {
            return ProEntitlement(tier: .elite, source: .storeKit, expirationDate: ...)
        }
        if info.entitlements["FitToday Pro"]?.isActive == true {
            return ProEntitlement(tier: .pro, source: .storeKit, expirationDate: ...)
        }
        return .free
    }
}
```

## PaywallView Integration

```swift
// OptimizedPaywallView — substitui o corpo customizado pelo RevenueCatUI
import RevenueCatUI

struct OptimizedPaywallView: View {
    var body: some View {
        PaywallView()
    }
}
```

## API Key

`test_bLxqgCKujDLuNjETLfDwtdbSCjZ` — configurado em `FitTodayApp.init()`.

## No Breaking Changes

- `EntitlementRepository` protocol mantido
- `EntitlementPolicy`, `ProEntitlement`, `FeatureGatingUseCase` intocados
- `StoreKitService` mantido (não removido)
