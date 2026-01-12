# [3.0] Fase 2 — Progresso no histórico (streak/semana/mês) (M/L)

## Objective
- Entregar “dopamina” no histórico com um dashboard simples (streak, minutos/semana, sessões/semana, mês em números) sem travar UI e respeitando paginação.

## Subtasks
- [ ] 3.1 Criar use case `ComputeHistoryInsightsUseCase` (Domain) e modelos `HistoryInsights`
- [ ] 3.2 Implementar streak atual e melhor streak (baseado em dias consecutivos com treino concluído)
- [ ] 3.3 Implementar buckets semanais: minutos/semana e sessões/semana
- [ ] 3.4 Implementar “Mês em números” (sessões, minutos, melhor streak do mês)
- [ ] 3.5 UI: header no `HistoryView` exibindo métricas e gráfico simples (Charts ou fallback)
- [ ] 3.6 Testes unitários do use case (streak e agregações)

## Success Criteria
- Header do histórico aparece com métricas coerentes para dados reais e vazios.
- Cálculo é assíncrono/eficiente e não bloqueia scroll.
- Testes validam streak/buckets em casos edge (intervalos, mudança de mês).

## Dependencies
- 1.0 (para garantir que histórico guarda planos e métricas) e/ou dados mínimos no histórico.

## Notes
- PRs sem carga: registrar como “recordes” de consistência/tempo.
- Se `durationMinutes` não existir, usar fallback do `workoutPlan` quando disponível.

## markdown

## status: pending # Options: pending, in-progress, completed, excluded

<task_context>
<domain>presentation/history</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>high</complexity>
<dependencies>database</dependencies>
</task_context>

# Task 3.0: Fase 2 — Progresso no histórico (streak/semana/mês)

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Adicionar insights visuais simples no topo do histórico e agregações no Domain para manter lógica testável e performática.

<requirements>
- Streak atual e melhor streak.
- Minutos/semana + sessões/semana.
- “Mês em números”.
</requirements>

## Subtasks

- [ ] 3.1 Criar modelos/UseCase em `FitToday/FitToday/Domain/UseCases/`
- [ ] 3.2 Integrar no `HistoryViewModel` com `Task` e atualização no main actor
- [ ] 3.3 Atualizar `HistoryView` para renderizar header e gráfico
- [ ] 3.4 Adicionar testes em `FitToday/FitTodayTests/Domain/` (ou pasta adequada)

## Implementation Details

Referência: `tasks/prd-ai-workout-v3/techspec.md` (Fase 2 — dashboard + concorrência).

## Success Criteria

- UI não engasga e paginação permanece funcionando.
- Agregações corretas e testadas.

## Relevant Files
- `FitToday/FitToday/Presentation/Features/History/HistoryView.swift`
- `FitToday/FitToday/Presentation/Features/History/HistoryViewModel.swift`
- `FitToday/FitToday/Domain/UseCases/`

