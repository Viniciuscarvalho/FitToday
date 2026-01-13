# [1.0] Fase 1 — Equalização do treino via IA + segurança (L)

## Objective
- Tornar a geração via IA previsível e segura: adicionar energia no check-in, simplificar o prompt, corrigir o wiring do histórico no compositor híbrido e remover código morto que atrapalha manutenção.

## Subtasks
- [ ] 1.1 Adicionar energia (0–10) em `DailyCheckIn` e ajustar todos os pontos de criação/serialização
- [ ] 1.2 Simplificar `WorkoutPromptAssembler`: contrato objetivo (perfil+check-in+blueprint+catálogo+histórico) e regras de segurança
- [ ] 1.3 Ajustar cacheKey do prompt para considerar novos inputs que alteram geração (energia)
- [ ] 1.4 Corrigir DI: injetar `WorkoutHistoryRepository` no `DynamicHybridWorkoutPlanComposer`
- [ ] 1.5 Remover código morto/legado em `HybridWorkoutPlanComposer.swift` (ex.: modelos não usados)
- [ ] 1.6 (Opcional) Implementar 1 retry usando feedback do `WorkoutPlanQualityGate.generateRetryFeedback(...)` antes do fallback local

## Success Criteria
- O app compila e testes passam.
- O check-in suporta energia 0–10 e o valor aparece no prompt enviado.
- IA passa mais vezes no quality gate e evita repetição com base no histórico persistido.
- `HybridWorkoutPlanComposer.swift` fica mais enxuto (sem tipos não utilizados).

## Dependencies
- PRD e Tech Spec deste folder (`prd.md` e `techspec.md`).

## Notes
- Atenção a `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (evitar “espalhar” MainActor indevidamente).
- Energia baixa deve influenciar o treino de forma conservadora; manter regras explícitas no prompt.

## markdown

## status: pending # Options: pending, in-progress, completed, excluded

<task_context>
<domain>data/openai</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>high</complexity>
<dependencies>external_apis|database</dependencies>
</task_context>

# Task 1.0: Fase 1 — Equalização do treino via IA + segurança

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Implementar os ajustes de modelo, prompt e DI para deixar o fluxo híbrido (OpenAI + local) correto e simples.

<requirements>
- Adicionar energia (0–10) ao `DailyCheckIn`.
- Simplificar prompt e incluir energia + histórico recente + healthConditions.
- Corrigir DI do compositor híbrido para chegar `WorkoutHistoryRepository`.
</requirements>

## Subtasks

- [ ] 1.1 Atualizar `FitToday/FitToday/Domain/Entities/DailyCheckIn.swift` e usos
- [ ] 1.2 Refatorar `FitToday/FitToday/Data/Services/OpenAI/WorkoutPromptAssembler.swift`
- [ ] 1.3 Refatorar `FitToday/FitToday/Data/Services/OpenAI/HybridWorkoutPlanComposer.swift`
- [ ] 1.4 Ajustar `FitToday/FitToday/Presentation/DI/AppContainer.swift` (injeção do histórico)
- [ ] 1.5 Atualizar/adição de testes em `FitToday/FitTodayTests/`

## Implementation Details

Referência: `tasks/prd-ai-workout-v3/techspec.md` (seções Fase 1, Prompt/IA, DI e wiring).

## Success Criteria

- Prompt inclui energia e histórico de treinos (quando existir).
- Compositor remoto evita repetição (fetchRecentWorkouts retorna planos).
- Sem regressões na geração local.

## Relevant Files
- `FitToday/FitToday/Domain/Entities/DailyCheckIn.swift`
- `FitToday/FitToday/Data/Services/OpenAI/WorkoutPromptAssembler.swift`
- `FitToday/FitToday/Data/Services/OpenAI/HybridWorkoutPlanComposer.swift`
- `FitToday/FitToday/Presentation/DI/AppContainer.swift`

