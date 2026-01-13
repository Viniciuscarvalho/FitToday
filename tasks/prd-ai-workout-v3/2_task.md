# [2.0] Observabilidade + testes do pipeline IA (M)

## Objective
- Garantir confiança no fluxo IA (OpenAI → validação → quality gate → fallback) com logs/telemetria mínima e testes que cubram cenários críticos.

## Subtasks
- [ ] 2.1 Definir eventos/métricas mínimas (ex.: gate status, fallback reason, timeout)
- [ ] 2.2 Padronizar logging do compositor remoto (sem PII)
- [ ] 2.3 Testes unitários do prompt/cacheKey e do quality gate (cenários de falha)
- [ ] 2.4 Teste de integração: concluir treino → salvar histórico com plano → próximo treino evita repetição

## Success Criteria
- Logs permitem diagnosticar: timeout, erro HTTP, falha de validação, falha de diversidade.
- Pelo menos 1 teste de integração prova que histórico influencia diversidade.

## Dependencies
- 1.0 (igualização) concluída ou parcialmente pronta (para wiring real).

## Notes
- Evitar assert frágil em logs; testar comportamento (ex.: `previousWorkouts` aplicado) e não strings específicas.

## markdown

## status: pending # Options: pending, in-progress, completed, excluded

<task_context>
<domain>engine/infra/observability</domain>
<type>testing</type>
<scope>performance</scope>
<complexity>medium</complexity>
<dependencies>external_apis|database</dependencies>
</task_context>

# Task 2.0: Observabilidade + testes do pipeline IA

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Adicionar instrumentação mínima e testes para reduzir regressões e facilitar debugging do fluxo IA.

<requirements>
- Logging estruturado para motivos de fallback.
- Testes async com mocks para OpenAI e repositórios.
</requirements>

## Subtasks

- [ ] 2.1 Implementar/ajustar logs no `OpenAIWorkoutPlanComposer` e `OpenAIClient`
- [ ] 2.2 Criar mocks (`OpenAIClienting`, `WorkoutHistoryRepository`) para testes
- [ ] 2.3 Adicionar testes em `FitToday/FitTodayTests/` cobrindo casos críticos

## Implementation Details

Referência: `tasks/prd-ai-workout-v3/techspec.md` (Testing Strategy + Observabilidade).

## Success Criteria

- Testes passam em CI/local.
- Debug logs permitem identificar claramente o motivo de fallback.

## Relevant Files
- `FitToday/FitToday/Data/Services/OpenAI/HybridWorkoutPlanComposer.swift`
- `FitToday/FitToday/Data/Services/OpenAI/OpenAIClient.swift`
- `FitToday/FitTodayTests/`

