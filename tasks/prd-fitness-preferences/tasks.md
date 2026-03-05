# Tasks — Fitness Preferences

**PRD:** prd-fitness-preferences
**Total Tasks:** 8

---

## Task 1: Garantir onboarding completo (6 passos) para novos usuários
**Status:** pending
**Files:** `FitTodayApp.swift`, `TabRootView.swift`, `OnboardingFlowView.swift`, `AppStorageKeys.swift`

Verificar onde `OnboardingFlowView` é instanciado no app e garantir que novos usuários sempre passem pelo fluxo completo de 6 passos. O `hasSeenWelcome` só deve ser marcado como `true` após `isProfileComplete = true`.

**Acceptance Criteria:**
- [ ] `OnboardingFlowView` instanciado sem `OnboardingMode.progressive` para novos usuários
- [ ] Botão de avançar no último passo usa `canSubmitFull` (não `canSubmitProgressive`)
- [ ] `AppStorageKeys.hasSeenWelcome = true` só após salvar perfil com `isProfileComplete = true`
- [ ] Se usuário fechar o app durante o onboarding, ao reabrir volta para onde parou (ou reinicia)
- [ ] Build sem warnings ou erros

---

## Task 2: Adicionar `loadFromProfile(_:)` no `OnboardingFlowViewModel`
**Status:** pending
**File:** `Features/Onboarding/OnboardingFlowViewModel.swift`

Adicionar método que pré-preenche o ViewModel com os dados de um `UserProfile` existente, permitindo que a edição de preferências via Settings mostre os valores atuais.

**Acceptance Criteria:**
- [ ] Método `loadFromProfile(_ profile: UserProfile)` implementado
- [ ] Preenche: `selectedGoal`, `selectedStructure`, `selectedMethod`, `selectedLevel`, `selectedConditions`, `weeklyFrequency`
- [ ] `OnboardingFlowView(isEditing: true)` chama `loadFromProfile` ao inicializar com perfil existente
- [ ] Campos aparecem pré-selecionados ao abrir a tela de edição
- [ ] Unit test: `loadFromProfile` preenche todos os 6 campos corretamente

---

## Task 3: Corrigir `ProgramGoalTag` — adicionar casos `hypertrophy` e `wellness`
**Status:** pending
**Files:** `Domain/Entities/ProgramModels.swift`, `Domain/UseCases/ProgramRecommender.swift`

O enum `ProgramGoalTag` precisa ter os casos `hypertrophy` e `wellness` antes de redistribuir o seed. Também adicionar o mapeamento correto de `FitnessGoal → ProgramGoalTag`.

**Acceptance Criteria:**
- [ ] `ProgramGoalTag` contém: `.strength`, `.conditioning`, `.endurance`, `.hypertrophy`, `.wellness`
- [ ] Mapeamento `FitnessGoal → ProgramGoalTag` em `ProgramRecommender.mapGoalToTag`:
  - `.hypertrophy → .hypertrophy`
  - `.weightLoss → .conditioning`
  - `.conditioning → .conditioning`
  - `.endurance → .endurance`
  - `.performance → .strength`
- [ ] `ProgramsView` filtros atualizados para incluir `.hypertrophy` e `.wellness`
- [ ] Build sem erros de switch exhaustivo

---

## Task 4: Redistribuir `goal_tag` no `ProgramsSeed.json`
**Status:** pending
**File:** `Data/Resources/ProgramsSeed.json`

Atualizar o campo `goal_tag` dos 26 programas conforme mapeamento do techspec. Resultado esperado: 11 strength, 6 hypertrophy, 4 conditioning, 4 wellness, 1 endurance.

**Acceptance Criteria:**
- [ ] `fullbody_*` → `hypertrophy` (exceto weightloss → `conditioning`, bodyweight → `wellness`)
- [ ] `home_*` e `beginner_complete_gym` → `wellness`
- [ ] `weightloss_intermediate_bodyweight` → `wellness`
- [ ] `weightloss_beginner_gym`, `weightloss_advanced_gym`, `glute_intermediate_gym` → `conditioning`
- [ ] `arnold_advanced_muscle_gym`, `phul_intermediate_gym`, `minimalist_beginner_gym` → `hypertrophy`
- [ ] `functional_intermediate_gym` → `endurance`
- [ ] Nenhum programa tem `goal_tag` ausente ou com valor inválido
- [ ] Unit test de integridade: todos os `goal_tag` são valores válidos do enum `ProgramGoalTag`
- [ ] Distribuição final: 0 programas a mais com `strength` do que o esperado (11)

---

## Task 5: Expandir score do `ProgramRecommender`
**Status:** pending
**File:** `Domain/UseCases/ProgramRecommender.swift`

Adicionar score por `availableStructure` (+4 pts) e `preferredMethod` (+3 pts). Aumentar peso de `level` de +3 para +5.

**Acceptance Criteria:**
- [ ] `structureMatchesProgram(_ structure:, _ program:)` implementado conforme techspec
- [ ] `methodMatchesProgram(_ method:, _ program:)` implementado conforme techspec
- [ ] Score final: `mainGoal` +10, `level` +5, `structure` +4, `method` +3, repetição ontem -5
- [ ] Unit test: usuário `bodyweight` + `hypertrophy` vê programas home/bodyweight de hipertrofia no topo
- [ ] Unit test: usuário `fullGym` + `hiit` vê programas de conditioning acima dos de strength
- [ ] `recommendWorkouts` também atualizado com mesma lógica (se aplicável)

---

## Task 6: UI — Label "Para você" e banner de perfil incompleto
**Status:** pending
**File:** `Features/Programs/Views/ProgramsListView.swift`

Adicionar indicador visual "Para você" nos cards de programas recomendados. Exibir `IncompleteProfileBanner` quando `userProfile?.isProfileComplete == false`.

**Acceptance Criteria:**
- [ ] Badge "Para você" visível nos cards que estão na lista `recommendedPrograms`
- [ ] `ProgramsListViewModel.isProfileIncomplete: Bool` computado a partir de `userProfile?.isProfileComplete`
- [ ] `IncompleteProfileBanner` aparece acima da seção de recomendados quando perfil incompleto
- [ ] Banner tem ícone, título "Complete seu perfil" e subtítulo explicativo
- [ ] Tap no banner navega para `OnboardingFlowView(isEditing: true)`
- [ ] Banner desaparece após salvar perfil completo (sem restart necessário)
- [ ] Nenhuma regressão visual nas seções existentes da tela

---

## Task 7: Settings — Entrada "Perfil de Treino" com resumo e link de edição
**Status:** pending
**Files:** `Features/Pro/ProfileProView.swift`, `Presentation/Router/AppRouter.swift`

Adicionar seção "Perfil de Treino" em Configurações que mostra o resumo das preferências atuais (objetivo, nível, frequência) e botão "Editar" que abre `OnboardingFlowView(isEditing: true)`.

**Acceptance Criteria:**
- [ ] Seção "Perfil de Treino" visível em Configurações
- [ ] Exibe resumo: objetivo, nível de treino e frequência semanal como chips/badges
- [ ] Botão "Editar" (ou NavigationLink) abre `OnboardingFlowView(isEditing: true)` pré-preenchido
- [ ] Após salvar edição, resumo em Settings reflete os novos valores imediatamente
- [ ] Se perfil incompleto, exibe label "Perfil incompleto" com destaque visual
- [ ] Rota `.editPreferences` adicionada ao `AppRouter` se necessário

---

## Task 8: Testes e validação end-to-end
**Status:** pending
**Files:** `FitTodayTests/`, `FitTodayUITests/`

Escrever e executar testes unitários e de UI para cobrir os cenários críticos do fluxo de preferências.

**Acceptance Criteria:**
- [ ] Unit test: `ProgramRecommender` retorna programa correto para cada `FitnessGoal`
- [ ] Unit test: `ProgramRecommender` prioriza `structure: bodyweight` para programas home
- [ ] Unit test: `OnboardingFlowViewModel.loadFromProfile` preenche os 6 campos
- [ ] Unit test: `canSubmitFull` retorna `false` com campos faltando
- [ ] Unit test: `ProgramsSeed` — nenhum `goal_tag` inválido nos 26 programas
- [ ] UI test: banner aparece na tela de Programas com `isProfileComplete = false`
- [ ] UI test: banner não aparece com `isProfileComplete = true`
- [ ] Todos os testes existentes continuam passando (sem regressão)
