# Product Requirements Document (PRD)

**Project Name:** Fitness Preferences — Onboarding, Recomendações e Edição em Configurações
**Feature Key:** prd-fitness-preferences
**Version:** 1.0
**Date:** 2026-03-05
**Author:** Claude Code
**Status:** Draft

---

## Executive Summary

**Problem Statement:**
O FitToday já possui um onboarding com 6 perguntas de preferência do usuário (`FitnessGoal`, `TrainingStructure`, `TrainingMethod`, `TrainingLevel`, `HealthCondition`, `weeklyFrequency`) e um `ProgramRecommender` que usa o perfil para ordenar programas. No entanto, existem lacunas críticas: (1) o perfil criado em modo progressivo usa defaults sem que o usuário saiba; (2) não há entrada em Configurações para editar preferências; (3) o `goalTag` de 20/26 programas é `.strength`, tornando as recomendações insensíveis ao objetivo real do usuário.

**Proposed Solution:**
Auditar e fechar as lacunas do fluxo de preferências: garantir que o onboarding completo (6 passos) seja exibido no primeiro acesso, que as preferências sejam persistidas corretamente, que a tela de Programas use-as de forma eficaz, e que o usuário possa editá-las em Configurações.

**Business Value:**
- Usuário vê programas relevantes ao seu objetivo desde o primeiro acesso
- Reduz abandono por irrelevância das sugestões
- Consolida a proposta de valor de personalização do FitToday

**Success Metrics:**
- 100% dos novos usuários completa o onboarding de 6 passos (modo completo)
- `isProfileComplete = true` para todos os usuários que finalizaram o onboarding
- Programas recomendados na tela de Programas refletem o `mainGoal` do usuário
- Tela "Editar Preferências" acessível via Configurações → Perfil

---

## Contexto Técnico (Estado Atual)

### O que já existe ✅

| Componente | Localização | Status |
|---|---|---|
| `OnboardingFlowView` (6 passos) | `Features/Onboarding/OnboardingFlowView.swift` | ✅ Existe, tem `isEditing: Bool` |
| `OnboardingFlowViewModel` | `Features/Onboarding/OnboardingFlowViewModel.swift` | ✅ Existe |
| `UserProfile` entity | `Domain/Entities/UserProfile.swift` | ✅ 6 campos: `mainGoal`, `availableStructure`, `preferredMethod`, `level`, `healthConditions`, `weeklyFrequency` |
| `ProgramRecommender` | `Domain/UseCases/ProgramRecommender.swift` | ✅ Usa `mainGoal` (+10 pts) e `level` (+3 pts) |
| `ProgramsListViewModel` | `Features/Programs/Views/ProgramsListView.swift` | ✅ Chama `profileRepository?.loadProfile()` e usa recommender |
| Persistência local | `SwiftDataUserProfileRepository` | ✅ SwiftData local |

### O que está faltando ❌

| Gap | Impacto |
|---|---|
| Onboarding exibe modo progressivo (2 passos) por default | Perfil salvo com defaults, `isProfileComplete = false` |
| Nenhuma entrada em Settings para editar preferências | Usuário não pode atualizar seus dados |
| 20 de 26 programas têm `goalTag: .strength` | Recomendações insensíveis ao objetivo real |
| Sem indicador visual de "recomendado para você" na tela de Programas | Usuário não sabe que a lista é personalizada |
| `availableStructure`, `preferredMethod` e `weeklyFrequency` não influenciam o score do `ProgramRecommender` | Apenas `mainGoal` e `level` são usados |

---

## Functional Requirements

### FR-001: Onboarding Completo no Primeiro Acesso [MUST]

**Description:**
Todo novo usuário deve passar pelo onboarding de **6 passos completos** ao abrir o app pela primeira vez. O modo progressivo (2 passos com defaults) não deve mais ser o caminho default.

**Os 6 passos:**
1. **Objetivo** — `FitnessGoal`: hipertrofia, condicionamento, resistência, perda de peso, performance
2. **Onde treina** — `TrainingStructure`: academia completa, academia básica, em casa com halteres, peso corporal
3. **Método preferido** — `TrainingMethod`: tradicional, circuito, HIIT, misto
4. **Nível** — `TrainingLevel`: iniciante, intermediário, avançado
5. **Condições de saúde** — `HealthCondition`: nenhuma, lombar, joelho, ombro, outro
6. **Frequência semanal** — `weeklyFrequency`: 2–6 dias/semana

**Acceptance Criteria:**
- `OnboardingFlowView` instanciado com `isEditing: false` exibe todos os 6 passos
- Ao finalizar, `isProfileComplete = true` é salvo no `UserProfile`
- `AppStorageKeys.hasSeenWelcome` é marcado como `true` somente após completar os 6 passos
- Não deve ser possível pular o onboarding (exceto tela de boas-vindas)

---

### FR-002: Preferências Salvas e Persistidas Corretamente [MUST]

**Description:**
O `UserProfile` preenchido no onboarding deve ser persistido localmente via SwiftData e sincronizado com o Firestore quando o usuário estiver autenticado.

**Acceptance Criteria:**
- `CreateOrUpdateProfileUseCase` é chamado ao finalizar o onboarding com todos os 6 campos preenchidos
- `isProfileComplete = true` para usuários que completaram o fluxo
- Profile carrega corretamente após restart do app (SwiftData)
- Após login com conta existente, preferências do Firestore sobrescrevem o SwiftData local
- `UserProfile.socialUserId` é populado com o Firebase UID após autenticação

---

### FR-003: Programas Recomendados com Base nas Preferências [MUST]

**Description:**
A tela **Treino → Programas** deve exibir programas ordenados por relevância com base nas preferências do usuário. O `ProgramRecommender` deve evoluir para considerar mais campos do perfil.

**Melhorias no `ProgramRecommender`:**

| Campo | Score atual | Score proposto |
|---|---|---|
| `mainGoal` | +10 se match | +10 se match |
| `level` | +3 se match | +5 se match |
| `availableStructure` (novo) | — | +4 se equipamento disponível |
| `preferredMethod` (novo) | — | +3 se método combina |
| Repetição recente | -5 | -5 |

**Distribuição de `goalTag` no seed (fix obrigatório):**
O `ProgramsSeed.json` tem 20/26 programas com `goalTag: "strength"`. Redistribuir corretamente:

| `goalTag` proposto | Programas |
|---|---|
| `strength` | PPL x3, UpperLower x4, BroSplit x2, Arnold, PHUL |
| `conditioning` | Weightloss x3, HIIT-based, Functional |
| `endurance` | Cardio/functional programs |
| `hypertrophy` | FullBody x4, Minimalist |
| `wellness` | Home workouts x2, Beginner x2 |

**Acceptance Criteria:**
- Seção "Programas Recomendados" exibe ≤6 programas ordenados por score de perfil
- Usuário com `mainGoal: .hypertrophy` vê programas de hipertrofia no topo
- Usuário com `availableStructure: .bodyweight` vê programas de peso corporal priorizados
- Programas com `goalTag` corretamente distribuído no seed (não 20/26 = strength)
- Label "Para você" ou indicador visual nos cards recomendados

---

### FR-004: Editar Preferências em Configurações [MUST]

**Description:**
O usuário deve poder acessar e editar suas preferências de treino a partir da tela de Configurações.

**Fluxo:**
`Configurações → Perfil de Treino → Editar Preferências` → `OnboardingFlowView(isEditing: true)`

**Acceptance Criteria:**
- `OnboardingFlowView(isEditing: true)` já existe — apenas precisa ser wireado em Settings
- Entrada "Perfil de Treino" visível na tela de Configurações (seção Perfil)
- Mostra resumo das preferências atuais: objetivo, nível, frequência, onde treina
- Ao salvar, `UserProfile` é atualizado via `CreateOrUpdateProfileUseCase`
- A tela de Programas reflete as novas preferências imediatamente após edição
- Botão "Salvar alterações" ao invés de "Criar perfil" quando `isEditing: true` (já implementado)

---

### FR-005: Indicador de Perfil Incompleto [SHOULD]

**Description:**
Se o `UserProfile` do usuário tiver `isProfileComplete = false` (onboarding feito em modo progressivo no passado), exibir um banner na home ou em Programas incentivando completar o perfil.

**Acceptance Criteria:**
- Banner "Complete seu perfil para melhores recomendações" visível na tela de Programas quando `isProfileComplete = false`
- Tapping no banner abre `OnboardingFlowView(isEditing: true)` pré-preenchido com os valores atuais
- Banner desaparece após completar o perfil
- Não interrompe o fluxo normal do app

---

### FR-006: Preferências Pré-preenchidas na Edição [SHOULD]

**Description:**
Ao abrir "Editar Preferências", os campos devem estar pré-preenchidos com os valores atuais do `UserProfile`.

**Acceptance Criteria:**
- `OnboardingFlowViewModel` expõe método `loadFromProfile(_ profile: UserProfile)` para pré-preencher
- Todos os 6 campos aparecem com o valor salvo ao abrir a tela de edição
- Usuário pode alterar qualquer campo e salvar

---

## Non-Functional Requirements

- **Performance:** carregamento do perfil para recomendações em < 200ms (SwiftData local, não network)
- **Offline:** preferências persistem e são usadas mesmo sem conexão
- **Privacidade:** nenhuma dado de preferência enviado para terceiros além do Firestore do próprio app

---

## Out of Scope

- Recomendações baseadas em histórico de exercícios específicos (apenas tipo de treino)
- Machine learning / modelo de recomendação avançado
- Preferências de nutrição ou sono
- Onboarding de personal trainer (fluxo separado)

---

## Arquivos a Criar / Modificar

| Arquivo | Ação | Descrição |
|---|---|---|
| `Features/Onboarding/OnboardingFlowViewModel.swift` | Modificar | Adicionar `loadFromProfile(_ profile: UserProfile)` |
| `Features/Onboarding/OnboardingFlowView.swift` | Verificar | Confirmar que modo completo (6 passos) é o default |
| `Domain/UseCases/ProgramRecommender.swift` | Modificar | Adicionar score por `availableStructure` e `preferredMethod` |
| `Data/Resources/ProgramsSeed.json` | Modificar | Redistribuir `goal_tag` dos 26 programas |
| `Features/Programs/Views/ProgramsListView.swift` | Modificar | Adicionar indicador "Para você" nos cards recomendados + banner de perfil incompleto |
| `Features/Pro/ProfileProView.swift` (ou Settings) | Modificar | Adicionar entrada "Perfil de Treino" com resumo + botão "Editar" |
| `Presentation/Support/AppStorageKeys.swift` | Verificar | Confirmar que `hasSeenWelcome` só é setado após onboarding completo |
