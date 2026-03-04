# PRD — Migração de Programas: WGER → Catálogo Firestore

**Feature slug:** `prd-firestore-programs-migration`
**Status:** Draft | **Data:** 2026-03-03

---

## 1. Visão Geral

Os Programas de treino do FitToday carregam exercícios da API WGER (`DefaultWgerProgramWorkoutRepository`), que foi descontinuada. Toda requisição falha silenciosamente, deixando o aluno com programas sem exercícios. Com o catálogo próprio no Firestore (`exercises/{id}`, populado na Fase 1–4) e o `ExerciseImageCache` já disponível (PR #49), temos infraestrutura suficiente para substituir completamente a WGER.

---

## 2. Problema

| Sintoma | Causa raiz |
|---|---|
| Programas aparecem sem exercícios | `DefaultWgerProgramWorkoutRepository` chama API WGER inexistente |
| `ProgramExercise` tem `wgerExercise: WgerExercise` | Entidade acoplada ao modelo WGER |
| `WorkoutTemplateType.wgerCategoryIds: [Int]` | Mapeamento hardcoded para IDs numéricos da WGER |
| Sem imagens nos exercícios dos programas | `ProgramExercise.imageURL` depende de `WgerExercise.mainImageURL` |

---

## 3. Objetivos e Métricas de Sucesso

| Métrica | Baseline | Meta |
|---|---|---|
| Programas com exercícios carregados | 0% (API falha) | 100% |
| Tempo de carregamento do 1º treino | N/A | < 2s com cache |
| Crashes por referência WGER | Recorrentes | 0 |
| Exercícios com imagem exibida | 0% | > 90% |

---

## 4. User Stories

- **US-01:** Como aluno, ao selecionar um programa, quero ver os exercícios corretos de cada treino.
- **US-02:** Como aluno, quero ver a imagem animada de cada exercício para aprender a execução.
- **US-03:** Como aluno, quero que os exercícios carreguem offline após o primeiro acesso.
- **US-04:** Como aluno, quero ver o nome dos exercícios em português.

---

## 5. Escopo

**In Scope**
- Nova entidade `FirestoreExercise` substituindo `WgerExercise` nos programas
- `FirestoreProgramExerciseRepository` com query Firestore por `category` + `equipment`
- Mapeamento `WorkoutTemplateType` → `firestoreCategories: [String]`
- Integração com `ExerciseImageCache` (PR #49) para imagens
- Remoção de `DefaultWgerProgramWorkoutRepository` e `WgerProgramWorkoutRepository`

**Out of Scope**
- Alteração no `ProgramsSeed.json` (metadados dos programas permanecem no bundle)
- Edição do catálogo de exercícios pelo usuário
- Criação de novos programas pelo aluno

---

## 6. Requisitos Funcionais

- **RF-01:** `FirestoreExerciseRepository` busca exercícios por `category` e `equipment` filtrados de `WorkoutTemplateType`, com `isActive == true`
- **RF-02:** `ProgramExercise` referencia exercícios por `exerciseId: String` (ID Firestore)
- **RF-03:** Nome exibido usa `name.pt` do Firestore, com fallback para `name.en`
- **RF-04:** Imagens via `ExerciseImageCache.shared.image(for: exerciseId)` — não armazenadas na entidade
- **RF-05:** Fallback para categoria `full_body` quando template não é mapeado

---

## 7. Requisitos Não-Funcionais

| Requisito | Detalhe |
|---|---|
| Performance | Exercícios de um treino carregam em < 1s com cache |
| Offline | Imagens disponíveis via `ExerciseImageCache` após primeiro acesso |
| Retrocompatibilidade | `ProgramsSeed.json` não muda |
| Concorrência | Repositório implementado como `actor` Swift 6 |
| Testabilidade | Protocolo `ProgramExerciseRepository` injetável via `AppContainer` |

---

## 8. Riscos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| Catálogo sem exercícios para alguma categoria | Médio | Fallback `full_body` |
| Regras Firestore bloqueando leitura de `exercises` | Baixo | Verificar `allow read: if true` antes do lançamento |
| Exercício sem imagem no Storage | Baixo | SF Symbol como fallback (já implementado) |

---

## 9. Issues relacionadas

- #50 — Refactor geral de remoção WGER (coordenar remoção de arquivos)
- #52–#64 — Tasks de implementação desta feature
