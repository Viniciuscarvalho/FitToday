# [12.0] Pro: Paywall + StoreKit 2 assinatura + restore + entitlements + gating (L)

## Objetivo
- Implementar monetização do MVP com assinatura Pro real via StoreKit 2, paywall pós-questionário diário e propagação de entitlement para liberar features Pro.

## Subtarefas
- [ ] 12.1 Definir produtos (product identifiers) e adicionar StoreKit Test Configuration para desenvolvimento/testes.
- [ ] 12.2 Implementar `StoreKitEntitlementRepository`:
  - fetch de produtos
  - purchase
  - restore
  - observação de transações (entitlement changes)
- [ ] 12.3 Implementar cache local do entitlement (SwiftData snapshot) para startup rápido e offline.
- [ ] 12.4 Implementar UI do Paywall (headline + bullets + CTA assinar + alternativa “ver treinos básicos”).
- [ ] 12.5 Integrar gating no fluxo: após “Gerar treino” (free) → paywall; após compra → gerar treino.
- [ ] 12.6 Implementar área de Perfil/Pro: gerenciar assinatura e restaurar compra.

## Critérios de Sucesso
- Compra e restore funcionam no sandbox (StoreKit testing).
- `isPro` liga/desliga features de forma reativa sem reiniciar o app.
- Paywall aparece no momento correto e oferece saída (Biblioteca) sem fricção.

## Dependências
- 1.0 Fundação (DI/Router).
- 2.0 Design System (UI do paywall).
- 3.0 Domain (EntitlementRepository).
- 7.0 Questionário diário (momento do gating).
- 4.0 Data (snapshot/caches).

## Observações
- StoreKit é fonte comum de bugs: priorizar logs claros e testes com configuração oficial.

## markdown

## status: pending # Opções: pending, in-progress, completed, excluded

<task_context>
<domain>integration/storekit</domain>
<type>integration</type>
<scope>core_feature</scope>
<complexity>high</complexity>
<dependencies>external_apis</dependencies>
</task_context>

# Tarefa 12.0: Pro (StoreKit 2 + Paywall + Entitlements)

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

Habilitar o Pro com assinatura real. O app precisa detectar entitlement, exibir paywall quando apropriado e reagir a mudanças de assinatura durante o uso.

<requirements>
- Paywall após tentativa de gerar treino (Free).
- Compra e restore via StoreKit 2.
- Entitlements observáveis (AsyncStream) e cache local.
</requirements>

## Subtarefas

- [ ] 12.1 Adicionar StoreKit Test Configuration e IDs de produto.
- [ ] 12.2 Implementar repositório de entitlement StoreKit + observação de transações.
- [ ] 12.3 Implementar paywall e tela de perfil/pro.
- [ ] 12.4 Integrar gating no Router/fluxos.

## Detalhes de Implementação

Referenciar:
- “Área Gratuita vs Pro” e “Paywall” em `prd.md`.
- “StoreKit 2 / EntitlementRepository” em `techspec.md`.

## Critérios de Sucesso

- Fluxo: questionário diário → paywall → compra → treino funciona.
- Restore recupera entitlement corretamente.

## Arquivos relevantes
- `tasks/prd-mvp-fittoday/prd.md`
- `tasks/prd-mvp-fittoday/techspec.md`




