# [8.0] Workout Timer & Progress Tracking (L)

## Objetivo
- Implementar execução de treino com timer de descanso, tracking de séries (checkboxes), indicador de progresso do treino e persistência do estado (sobrevive app kill), garantindo UX fluida em SwiftUI.

## Subtarefas
- [x] 8.1 Definir modelo de estado de execução (exercício atual, séries concluídas, descanso, progresso) ✅
- [x] 8.2 Implementar timer de descanso configurável (default sugerido pelo treino) ✅
- [x] 8.3 Implementar UI de tracking por exercício (sets/reps) com marcação de concluído ✅
- [x] 8.4 Implementar persistência do progresso (SwiftData ou storage apropriado) e restore ao reabrir ✅
- [x] 8.5 Adicionar feedback (haptics) e micro-UX (auto-advance opcional) ✅
- [x] 8.6 Testes unitários em XCTest (timer, persistência, reducers/state transitions) ✅

## Critérios de Sucesso
- Timer funciona com iniciar/pausar/resetar e não drift significativo.
- Usuário consegue marcar séries e ver progresso geral do treino (ex: 5/10).
- Progresso persiste ao fechar e reabrir o app.
- Testes em XCTest cobrindo regras do timer e transições principais de estado.

## Dependências
- Fase 1 concluída (offline + cache + error handling), para execução robusta.
- Modelos de treino existentes (`WorkoutPlan`, `ExercisePrescription`, `WorkoutSessionStore`).

## Observações
- Testes devem ser em **XCTest**.
- Evitar excesso de re-render em SwiftUI (seguir boas práticas da `techspec.md`).

## markdown

## status: completed

<task_context>
<domain>presentation/features/workout</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>high</complexity>
<dependencies>database</dependencies>
</task_context>

# Tarefa 8.0: Workout Timer & Progress Tracking

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

Hoje o app já possui estrutura de execução (`WorkoutTimerStore`, `WorkoutSessionStore`), porém o tracking por série e a persistência do progresso ainda não estão completos. Esta tarefa adiciona o “modo execução” completo: timer de descanso, checkboxes de séries, progresso global e persistência para retomar facilmente.

<requirements>
- Timer de descanso configurável (default via treino)
- Tracking por exercício: marcar séries concluídas e visualizar progresso
- Indicador de progresso do treino (exercícios concluídos / total)
- Persistência do progresso (sobrevive app kill)
- Feedback de UX (haptics, microcopy)
- Testes em XCTest (timer + persistência + state transitions)
</requirements>

## Subtarefas

- [x] 8.1 Revisar PRD: F5 (Workout Timer & Progress Tracking) e alinhar UX ✅
- [x] 8.2 Implementar modelo de estado de execução (por exercício e por série) ✅
- [x] 8.3 Implementar timer de descanso com notificações/haptics conforme necessário ✅
- [x] 8.4 Implementar UI para marcar séries e exibir progresso (SwiftUI) ✅
- [x] 8.5 Implementar persistência (SwiftData ou storage) e restore de sessão ✅
- [x] 8.6 Integrar com `WorkoutPlanView` / `WorkoutExerciseDetailView` sem regressões ✅
- [x] 8.7 Testes unitários em XCTest (timer, restore, edge cases) ✅

## Detalhes de Implementação

- Referenciar `techspec.md` para práticas de performance em SwiftUI e padrão de ViewModels.
- Evitar `@Published` “global” causando recomputes grandes; preferir estado granular.
- Persistência: escolher storage que faça sentido com Clean Architecture (Domain → Repo → SwiftData).

## Critérios de Sucesso

- Timer consistente e confiável.
- Persistência funcionando (retomar exatamente onde parou).
- UX clara e sem ruído (principalmente em tela de execução).
- Testes em XCTest cobrindo principais cenários.

## Arquivos relevantes
- `FitToday/FitToday/Presentation/Features/Workout/WorkoutPlanView.swift`
- `FitToday/FitToday/Presentation/Features/Workout/WorkoutExerciseDetailView.swift`
- `FitToday/FitToday/Presentation/Features/Workout/WorkoutSessionStore.swift`
- `FitToday/FitToday/Presentation/Features/Workout/WorkoutTimerStore.swift`
- `FitToday/FitToday/Domain/Entities/WorkoutModels.swift`

