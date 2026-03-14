# Product Requirements Document (PRD)

**Project Name:** Sistema de Streaks & XP com Níveis
**Document Version:** 1.0
**Date:** 2026-03-12
**Author:** Vinicius Carvalho
**Status:** Draft
**Linear Issue:** PRO-90

---

## Executive Summary

**Problem Statement:**
Sem gamificação clara para treinos regulares — cada dia é isolado. Duolingo mostra que streaks funcionam; nenhum app de fitness BR implementa com XP multinível.

**Proposed Solution:**
Gamificação tipo Duolingo: Streak diário (já existe) + XP por consistência (100/treino, 200/streak-7d, 500/desafio) → Níveis (1000 XP = 1 nível) com nomes temáticos (Iniciante→Guerreiro→Titã→Lenda). Level-up animado com confetti.

**Business Value:**
Aumentar retenção d7 em 20% e engajamento diário via feedback loops de progressão.

**Success Metrics:**

- 70% dos usuários ativos com streak > 3 dias
- 50% alcançam nível 5+ em 30 dias
- Retenção d7 +20%

---

## Project Overview

### Background

O FitToday já possui streak tracking básico (contagem de dias consecutivos no home screen via `WeekStreakRow` e `UserStats`). Porém, a progressão é puramente visual sem recompensa tangível. Não há XP, níveis, ou celebrações por marcos.

### Current State

- Streak counter existe no home (`WeekStreakRow` + `DailyStatsCard`)
- `UserStats` persiste `currentStreak` e `longestStreak` via SwiftData
- `UserStatsCalculator` calcula streaks a partir do `WorkoutHistoryEntry`
- Não há XP, níveis, badges, ou animações de level-up
- Não há push notifications para streak em risco

### Desired State

- Sistema de XP com ganho automático após treinos
- Níveis temáticos com progressão visual
- Animação de level-up (confetti) ao subir de nível
- Streak em risco com notificação in-app
- XP bonificado por streaks e desafios

---

## Goals and Objectives

### Business Goals

1. Aumentar retenção d7 em 20% via feedback loops de progressão
2. Aumentar DAU/MAU ratio com incentivo diário (streak + XP)
3. Criar base para futuro sistema de recompensas/marketplace

### User Goals

1. Sentir progresso tangível a cada treino
2. Ter motivação para manter consistência diária
3. Visualizar evolução de longo prazo (nível)

---

## User Personas

### Primary Persona: Usuário Casual

**Demographics:** 25-35 anos, treina 3-4x/semana, usa o app há < 3 meses

**Goals:**

- Manter rotina de treinos
- Ver progresso visível rapidamente

**Pain Points:**

- Cada dia parece isolado, sem sensação de acúmulo
- Perde motivação após falhar 1 dia

### Secondary Persona: Usuário Engajado

**Demographics:** 20-30 anos, treina 5-6x/semana, usa desafios e grupos

**Goals:**

- Competir e mostrar nível para o grupo
- Alcançar níveis mais altos

**Pain Points:**

- Falta de diferenciação entre quem treina mais vs menos

---

## Functional Requirements

### FR-001: XP Award System [MUST]

**Description:**
Após completar um treino, o usuário recebe XP automaticamente.

**XP Table:**
| Ação | XP |
|------|-----|
| Treino completado | 100 |
| Streak 7 dias (bonus) | 200 |
| Streak 30 dias (bonus) | 500 |
| Desafio completado | 500 |

**Acceptance Criteria:**

- XP é creditado após `UpdateUserStatsUseCase` no fluxo de workout completion
- XP acumula no perfil do usuário (persistido em Firestore + SwiftData)
- Total de XP nunca decresce

---

### FR-002: Level System [MUST]

**Description:**
XP acumulado determina o nível do usuário. Cada 1000 XP = 1 nível.

**Níveis Temáticos:**
| Nível | Nome | XP Necessário |
|-------|------|---------------|
| 1-4 | Iniciante | 0-3999 |
| 5-9 | Guerreiro | 4000-8999 |
| 10-14 | Titã | 9000-13999 |
| 15-19 | Lenda | 14000-18999 |
| 20+ | Imortal | 19000+ |

**Acceptance Criteria:**

- Nível é calculado a partir do total de XP (derivado, não armazenado separadamente)
- Nome temático é exibido no perfil e no home screen
- Níveis persistem entre sessões

---

### FR-003: Level-Up Animation [MUST]

**Description:**
Quando o usuário sobe de nível, uma animação de confetti é exibida com o novo nível e nome temático.

**Acceptance Criteria:**

- Animação é exibida no `WorkoutCompletionView` quando há level-up
- Inclui confetti, novo nível, e nome temático
- É dismissible com tap ou timeout de 5s
- Respeita `accessibilityReduceMotion`

---

### FR-004: XP & Level Display on Home [MUST]

**Description:**
O home screen exibe o nível atual, XP total, e progresso para o próximo nível.

**Acceptance Criteria:**

- Componente visual próximo ao `WeekStreakRow` existente
- Mostra: nível atual, nome temático, barra de progresso XP
- Barra de progresso mostra XP atual / XP necessário para o próximo nível
- Animação suave na barra ao ganhar XP

---

### FR-005: Streak Risk In-App Notification [SHOULD]

**Description:**
Quando o usuário está em risco de perder o streak (não treinou hoje e já são 18h+), uma notificação in-app é exibida.

**Acceptance Criteria:**

- Usa o sistema de notificação in-app existente (`NotificationRepository`)
- Exibida no home screen como banner
- Mostra "Seu streak de X dias está em risco!"
- Não persiste após o dia mudar

---

### FR-006: Feature Flag Gate [MUST]

**Description:**
Todo o sistema de XP/Níveis é controlado por feature flag no Firebase Remote Config.

**Acceptance Criteria:**

- Nova flag `gamification_enabled` com default `false`
- Quando desativada, nenhum componente de XP/nível é visível
- XP não é calculado ou persistido quando flag está off

---

## Non-Functional Requirements

### NFR-001: Performance [MUST]

XP award e level calculation devem completar em < 100ms. Não pode impactar o tempo de carregamento do home screen.

### NFR-002: Data Consistency [MUST]

XP total deve ser consistente entre Firestore (remote) e SwiftData (local). Em caso de conflito, Firestore é source of truth.

### NFR-003: Offline Support [SHOULD]

XP deve ser creditado localmente mesmo offline. Sync com Firestore quando conectar.

---

## Out of Scope

1. **Push notifications via APNs/FCM** — Infraestrutura não existe, alto custo para MVP
2. **Leaderboard de XP/Níveis** — Futuro, após validar engagement
3. **Rewards/Marketplace** — Fase 2
4. **Cloud Functions para cálculo server-side** — Mantemos client-side no MVP
5. **Badges/Achievements** — Futuro

---

## Release Planning

### Phase 1: MVP

- Domain entities (XP, Level)
- XP award no workout completion
- Level calculation
- Home screen display (nível + progresso)
- Level-up animation (confetti)
- Feature flag gate

### Phase 2: Enhancement

- Streak risk notification in-app
- XP bonus por desafios
- Nível visível no perfil público (grupos)

### Phase 3: Optimization

- Leaderboard de XP
- Badges/Achievements
- Push notifications para streak em risco

---

## Risks and Mitigations

| Risk                                      | Impact | Probability | Mitigation                                     |
| ----------------------------------------- | ------ | ----------- | ---------------------------------------------- |
| XP inflation (muito fácil subir de nível) | Medium | Medium      | Ajustar tabela de XP via Remote Config         |
| Overhead no workout completion            | High   | Low         | Medir performance, manter < 100ms              |
| Data inconsistency local/remote           | High   | Medium      | Firestore como source of truth, merge strategy |
