# Tasks: RevenueCat SDK Integration

## Task 1 — Configurar RevenueCat no FitTodayApp

- Adicionar `import RevenueCat` em `FitTodayApp.swift`
- Chamar `Purchases.configure(withAPIKey: "test_bLxqgCKujDLuNjETLfDwtdbSCjZ")` no `init()`

## Task 2 — Criar RevenueCatEntitlementRepository

- Criar `FitToday/Data/Repositories/RevenueCatEntitlementRepository.swift`
- Implementar `EntitlementRepository` protocol
- Mapear entitlements RC → `ProEntitlement` domain model
- Implementar `entitlementStream()` via polling de customerInfo

## Task 3 — Atualizar AppContainer

- Substituir `StoreKitEntitlementRepository` por `RevenueCatEntitlementRepository`
- Manter `StoreKitService` registrado (não remover)

## Task 4 — Migrar OptimizedPaywallView para RevenueCatUI

- Substituir body por `PaywallView()` do RevenueCatUI
- Manter suporte a `onDismiss` e `onPurchaseSuccess` via `.onPurchaseCompleted`

## Task 5 — Criar branch e PR

- Branch: `feat/revenue-cat-integration`
- PR para `main` com summary dos changes
