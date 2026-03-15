# PRD: RevenueCat SDK Integration

## Problem Statement

FitToday usa StoreKit 2 nativo para gerenciar assinaturas. Migrar para RevenueCat centraliza analytics de receita, habilita A/B testing de paywall via dashboard e simplifica a gestão de entitlements entre plataformas.

## Goals

1. Configurar RevenueCat SDK no app entry point
2. Criar repositório de entitlements baseado em RevenueCat
3. Substituir `OptimizedPaywallView` pelo `PaywallView` do RevenueCatUI
4. Manter o domínio inalterado (`ProEntitlement`, `EntitlementPolicy`)

## Non-Goals

- Remover `StoreKitService` (mantido para compatibilidade)
- Alterar regras de negócio de feature gating
- Criar novo onboarding de assinatura

## Entitlement Mapping

| RevenueCat Entitlement | Domain Tier |
| ---------------------- | ----------- |
| `FitToday Pro`         | `.pro`      |
| `FitToday Elite`       | `.elite`    |
| (none)                 | `.free`     |

## Success Criteria

- RevenueCat configurado e inicializado no launch
- `customerInfo()` retorna entitlement correto
- `PaywallView` é apresentado no lugar do paywall manual
- Build e testes passam sem erros
