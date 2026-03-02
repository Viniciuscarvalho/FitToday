# Tasks — FitOrb AI Chat Integration

**Feature:** prd-chat-ai-creator
**Total Tasks:** 19
**Phases:** 7

---

## Phase 1: Infrastructure Foundation

| # | Task | Size | Dependencies | Status |
|---|------|------|-------------|--------|
| 1 | ChatRepository Protocol + SDChatMessage Model + Mapper | M | None | pending |
| 2 | SwiftDataChatRepository Implementation | M | Task 1 | pending |
| 3 | Register SDChatMessage Schema + ChatRepository DI | S | Task 2 | pending |
| 4 | Add sendChat() to NewOpenAIClient | M | None | pending |
| 5 | Refactor AIChatService to Delegate to NewOpenAIClient | M | Task 4 | pending |

**Parallelism:** Tasks 1-3 (persistence) and Tasks 4-5 (service refactor) can run in parallel.

---

## Phase 2: Personalized System Prompt

| # | Task | Size | Dependencies | Status |
|---|------|------|-------------|--------|
| 6 | ChatSystemPromptBuilder | M | None | pending |
| 7 | Integrate Builder into AIChatService + Update DI | M | Tasks 5, 6 | pending |

**Parallelism:** Task 6 can run in parallel with Phase 1.

---

## Phase 3: ViewModel + Persistence

| # | Task | Size | Dependencies | Status |
|---|------|------|-------------|--------|
| 8 | Adopt ErrorPresenting in AIChatViewModel | S | Task 7 | pending |
| 9 | Integrate ChatRepository in ViewModel + View Updates | M | Tasks 3, 8 | pending |

---

## Phase 4: Typing Effect

| # | Task | Size | Dependencies | Status |
|---|------|------|-------------|--------|
| 10 | Simulated Typing Animation (ViewModel + View) | M | Task 9 | pending |

---

## Phase 5: Freemium Gating

| # | Task | Size | Dependencies | Status |
|---|------|------|-------------|--------|
| 11 | Add ProFeature.aiChat + Limits to EntitlementPolicy | S | None | pending |
| 12 | AI Chat Usage Tracking | S | Task 11 | pending |
| 13 | Enforce Message Limits in ViewModel | S | Tasks 9, 12 | pending |

**Parallelism:** Task 11 can run in parallel with earlier phases.

---

## Phase 6: Extras

| # | Task | Size | Dependencies | Status |
|---|------|------|-------------|--------|
| 14 | Contextual Quick Actions | S | Task 9 | pending |
| 15 | Localization for All New Keys (EN + PT-BR) | S | Tasks 1-14 | pending |

---

## Phase 7: Quality & Polish

| # | Task | Size | Dependencies | Status |
|---|------|------|-------------|--------|
| 16 | Error Mapping for Chat Errors (DomainError + ErrorMapper) | S | Task 8 | pending |
| 17 | Comprehensive Test Suite (Mocks + Fixtures + Tests) | L | Tasks 1-16 | pending |
| 18 | Security Audit — API Key + Message Privacy | S | Task 5 | pending |
| 19 | Build Verification + Integration Test | S | All | pending |

---

## Dependency Graph

```
Tasks 1→2→3 (persistence pipeline)     ⟶ Task 9
Tasks 4→5 (client refactor)            ⟶ Task 7
Task 6 (prompt builder, independent)   ⟶ Task 7
Tasks 5+6→7 (service integration)      ⟶ Task 8
Task 8→9 (viewmodel + persistence)     ⟶ Tasks 10, 13, 14
Tasks 11→12→13 (freemium gating)
Task 15 (localization, after all features)
Tasks 16-19 (quality, after all features)
```

---

## Parallel Execution Strategy

**Wave 1 (independent):** Tasks 1, 4, 6, 11
**Wave 2 (depends on Wave 1):** Tasks 2, 5, 12
**Wave 3:** Tasks 3, 7
**Wave 4:** Tasks 8, 16
**Wave 5:** Task 9
**Wave 6:** Tasks 10, 13, 14
**Wave 7:** Task 15
**Wave 8:** Tasks 17, 18, 19
