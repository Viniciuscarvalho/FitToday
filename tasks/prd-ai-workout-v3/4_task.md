# [4.0] Fase 3 — HealthKit (iPhone-only, PRO) import/export (L)

## Objective
- Integrar HealthKit (somente iPhone) para usuários PRO: importar duração/calorias de sessões e exportar treinos concluídos como `HKWorkout`, com concorrência segura (async/await + actors) e UX clara de privacidade.

## Subtasks
- [ ] 4.1 Definir modelos de domínio para autorização, métricas importadas e recibo de export
- [ ] 4.2 Criar `HealthKitServicing` + implementação (encapsular `HKHealthStore`)
- [ ] 4.3 Criar coordenador `HealthKitSyncCoordinator` (actor) para serializar import/export e evitar corrida
- [ ] 4.4 UI de conexão HealthKit (PRO): conectar/desconectar + status
- [ ] 4.5 Import: buscar workouts (janela configurável) e preencher histórico (duração/calorias)
- [ ] 4.6 Export: ao concluir treino, criar `HKWorkout` e persistir UUID associado ao histórico
- [ ] 4.7 Testes com mocks (sem depender de HealthKit real)

## Success Criteria
- Usuário PRO consegue conectar e ver status.
- Import preenche métricas quando disponíveis.
- Export cria `HKWorkout` (quando autorizado) e não quebra fluxo quando não autorizado.

## Dependencies
- 3.0 (idealmente) para já exibir métricas importadas no dashboard.

## Notes
- Requer capability HealthKit e strings de privacidade no `Info.plist`.
- Não incluir app Watch neste escopo.

## markdown

## status: pending # Options: pending, in-progress, completed, excluded

<task_context>
<domain>data/healthkit</domain>
<type>integration</type>
<scope>core_feature</scope>
<complexity>high</complexity>
<dependencies>external_apis|database</dependencies>
</task_context>

# Task 4.0: Fase 3 — HealthKit (iPhone-only, PRO) import/export

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Implementar HealthKit end-to-end (iPhone-only) com isolamento correto e degradação segura.

<requirements>
- PRO-only.
- Import (duração/calorias) e export (`HKWorkout`).
- Falhas não bloqueiam treino/histórico.
</requirements>

## Subtasks

- [ ] 4.1 Criar novos arquivos em `FitToday/FitToday/Data/Services/HealthKit/`
- [ ] 4.2 Ajustar gating/DI para expor HealthKitService somente para PRO
- [ ] 4.3 Persistir UUID do HKWorkout no histórico (SwiftData)
- [ ] 4.4 Testes unitários com mocks

## Implementation Details

Referência: `tasks/prd-ai-workout-v3/techspec.md` (Fase 3 — HealthKit) e boas práticas `swift-concurrency`.

## Success Criteria

- Import/export funcionam em device com permissões.
- Sem warnings críticos de concorrência.

## Relevant Files
- `FitToday/FitToday/Presentation/Features/Pro/` (gating UI)
- `FitToday/FitToday/Presentation/DI/AppContainer.swift`
- `FitToday/FitToday/Data/Models/SDWorkoutHistoryEntry.swift`
- `FitToday/FitToday/Data/Services/HealthKit/` (novo)

