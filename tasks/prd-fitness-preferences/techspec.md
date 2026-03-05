# Technical Specification

**Project Name:** Fitness Preferences — Onboarding, Recomendações e Edição em Configurações
**Feature Key:** prd-fitness-preferences
**Version:** 1.0
**Date:** 2026-03-05
**Author:** Claude Code
**Status:** Draft

---

## Overview

### Problem Statement
O onboarding existe mas opera em modo progressivo (2 passos) como default, salvando `isProfileComplete = false`. O `ProgramRecommender` usa apenas `mainGoal` e `level`, e 20/26 programas têm `goalTag: strength`, tornando recomendações genéricas. Não há entrada em Settings para editar preferências.

### Goals
- Forçar onboarding completo (6 passos) para novos usuários
- Evoluir `ProgramRecommender` com mais campos do perfil
- Redistribuir `goal_tag` do seed para diversificar recomendações
- Wirear `OnboardingFlowView(isEditing: true)` em Configurações
- Adicionar banner de perfil incompleto na tela de Programas

---

## Scope

### In Scope
- `OnboardingFlowView.swift` / `OnboardingFlowViewModel.swift` — garantir modo completo
- `ProgramRecommender.swift` — adicionar score por `availableStructure` e `preferredMethod`
- `ProgramsSeed.json` — redistribuir `goal_tag` de 26 programas
- `ProgramsListView.swift` — label "Para você" + banner de perfil incompleto
- Settings (ProfileProView ou nova view) — entrada "Perfil de Treino"
- `AppStorageKeys.swift` — verificar semântica de `hasSeenWelcome`

### Out of Scope
- Recomendações por ML ou histórico de exercícios específicos
- Sincronização do perfil via Firestore (já existe via `socialUserId`)
- Onboarding de personal trainer

---

## Technical Approach

### Architecture Overview

```
Onboarding (6 passos)
       ↓
CreateOrUpdateProfileUseCase
       ↓
SwiftDataUserProfileRepository → UserProfile (local)
       ↓
ProgramRecommender.recommend(programs:, profile:, history:, limit:)
       ↓
ProgramsListView → seção "Recomendados"

Settings → "Editar Perfil de Treino"
       ↓
OnboardingFlowView(isEditing: true)   [já existe]
       ↓
OnboardingFlowViewModel.loadFromProfile(_ profile)  [novo]
       ↓
CreateOrUpdateProfileUseCase          [já existe]
```

---

## Component 1: Onboarding — Modo Completo como Default

**Arquivo:** `Features/Onboarding/OnboardingFlowView.swift`

O `OnboardingFlowView` já suporta `isEditing: Bool`, mas o `OnboardingMode` enum define `.progressive` e `.full`. Verificar onde o modo é passado na inicialização e garantir que novos usuários sempre usem `.full`.

**Verificação em `FitTodayApp.swift` / `TabRootView.swift`:**
```swift
// VERIFICAR se está assim (incorreto):
OnboardingFlowView(resolver: container, isEditing: false, onFinished: { ... })
// com OnboardingMode.progressive implícito

// DEVE estar assim (correto):
// Sempre instanciar passando modo .full para novos usuários
// O modo progressivo só deve existir para compatibilidade legada
```

**`AppStorageKeys.hasSeenWelcome` semântica:**
- Deve ser `true` apenas após finalizar os 6 passos com `isProfileComplete = true`
- Se usuário fechou no passo 3, `hasSeenWelcome` deve permanecer `false`

**`OnboardingFlowViewModel` — garantir `canSubmitFull` como gate:**
```swift
// Verificar que o botão "Criar Perfil" no último passo usa canSubmitFull, não canSubmitProgressive
// canSubmitFull requer todos os 6 campos preenchidos
var canSubmitFull: Bool {
    selectedGoal != nil &&
    selectedStructure != nil &&
    selectedMethod != nil &&
    selectedLevel != nil &&
    weeklyFrequency != nil
    // healthConditions pode ser vazio (default .none é aplicado automaticamente)
}
```

---

## Component 2: `OnboardingFlowViewModel.loadFromProfile(_:)`

**Arquivo:** `Features/Onboarding/OnboardingFlowViewModel.swift`

Novo método para pré-preencher o ViewModel a partir de um `UserProfile` existente (usado na edição via Settings).

```swift
func loadFromProfile(_ profile: UserProfile) {
    selectedGoal = profile.mainGoal
    selectedStructure = profile.availableStructure
    selectedMethod = profile.preferredMethod
    selectedLevel = profile.level
    selectedConditions = Set(profile.healthConditions)
    weeklyFrequency = profile.weeklyFrequency
}
```

**Integração em `OnboardingFlowView`:**
```swift
init(resolver: Resolver, isEditing: Bool = false, onFinished: @escaping () -> Void) {
    // ...
    if isEditing {
        // Carregar profile atual e pré-preencher ViewModel
        Task {
            if let profile = try? await profileRepository.loadProfile() {
                viewModel.loadFromProfile(profile)
            }
        }
    }
}
```

---

## Component 3: `ProgramRecommender` — Score Expandido

**Arquivo:** `Domain/UseCases/ProgramRecommender.swift`

### Score atual vs proposto

| Campo | Atual | Proposto |
|---|---|---|
| `mainGoal` match | +10 | +10 |
| `level` match | +3 | +5 |
| `availableStructure` match (novo) | — | +4 |
| `preferredMethod` match (novo) | — | +3 |
| Repetição ontem | -5 | -5 |

### Mapeamento `availableStructure` → equipamento do programa

```swift
private func structureMatchesProgram(_ structure: TrainingStructure, _ program: Program) -> Bool {
    let programId = program.id.lowercased()
    switch structure {
    case .fullGym:
        return programId.contains("gym")
    case .basicGym:
        return programId.contains("gym") || programId.contains("dumbbell")
    case .homeDumbbells:
        return programId.contains("dumbbell") || programId.contains("home")
    case .bodyweight:
        return programId.contains("bodyweight") || programId.contains("home")
    }
}
```

### Mapeamento `preferredMethod` → goalTag do programa

```swift
private func methodMatchesProgram(_ method: TrainingMethod, _ program: Program) -> Bool {
    switch method {
    case .traditional:
        return program.goalTag == .strength || program.goalTag == .hypertrophy
    case .circuit:
        return program.goalTag == .conditioning
    case .hiit:
        return program.goalTag == .conditioning || program.goalTag == .endurance
    case .mixed:
        return true // misto combina com qualquer programa
    }
}
```

### Score final atualizado

```swift
var score = 0

if program.goalTag == preferredTag { score += 10 }
if program.level == mapLevelToProgram(profile.level) { score += 5 }
if structureMatchesProgram(profile.availableStructure, program) { score += 4 }
if methodMatchesProgram(profile.preferredMethod, program) { score += 3 }
if trainedYesterday, let yesterdayTag = yesterdayGoalTag, program.goalTag == yesterdayTag {
    score -= 5
}
```

---

## Component 4: `ProgramsSeed.json` — Redistribuição de `goal_tag`

**Arquivo:** `Data/Resources/ProgramsSeed.json`

### Mapeamento atual → proposto

| `id` do programa | `goal_tag` atual | `goal_tag` proposto |
|---|---|---|
| `ppl_beginner_muscle_gym` | `strength` | `strength` |
| `ppl_intermediate_muscle_gym` | `strength` | `strength` |
| `ppl_advanced_strength_gym` | `strength` | `strength` |
| `upperlower_beginner_muscle_gym` | `strength` | `strength` |
| `upperlower_intermediate_strength_gym` | `strength` | `strength` |
| `upperlower_advanced_muscle_gym` | `strength` | `strength` |
| `upperlower_intermediate_muscle_dumbbell` | `strength` | `strength` |
| `brosplit_intermediate_muscle_gym` | `strength` | `strength` |
| `brosplit_advanced_muscle_gym` | `strength` | `strength` |
| `strength_beginner_gym` | `strength` | `strength` |
| `strength_intermediate_5x5_gym` | `strength` | `strength` |
| `fullbody_beginner_muscle_gym` | `strength` | `hypertrophy` |
| `fullbody_beginner_muscle_dumbbell` | `strength` | `hypertrophy` |
| `fullbody_intermediate_weightloss_gym` | `strength` | `conditioning` |
| `fullbody_beginner_muscle_bodyweight` | `strength` | `wellness` |
| `weightloss_beginner_gym` | `conditioning` | `conditioning` |
| `weightloss_intermediate_bodyweight` | `conditioning` | `wellness` |
| `weightloss_advanced_gym` | `conditioning` | `conditioning` |
| `home_beginner_muscle` | `conditioning` | `wellness` |
| `home_intermediate_muscle` | `conditioning` | `wellness` |
| `arnold_advanced_muscle_gym` | `strength` | `hypertrophy` |
| `phul_intermediate_gym` | `strength` | `hypertrophy` |
| `minimalist_beginner_gym` | `strength` | `hypertrophy` |
| `glute_intermediate_gym` | `strength` | `conditioning` |
| `functional_intermediate_gym` | `strength` | `endurance` |
| `beginner_complete_gym` | `strength` | `wellness` |

### Distribuição final

| `goal_tag` | Count | Programas |
|---|---|---|
| `strength` | 11 | PPL x3, UpperLower x4, BroSplit x2, Strength x2 |
| `hypertrophy` | 6 | FullBody x2, Arnold, PHUL, Minimalist + 1 extra |
| `conditioning` | 4 | Weightloss x2, Glute, Fullbody weightloss |
| `wellness` | 4 | Home x2, Bodyweight, Beginner Complete |
| `endurance` | 1 | Functional |

> **Nota:** Verificar se o enum `ProgramGoalTag` em Swift tem case `.hypertrophy` e `.wellness`. Se não, adicionar antes de fazer a mudança no seed.

---

## Component 5: `ProgramsListView` — UI de Recomendações e Banner

**Arquivo:** `Features/Programs/Views/ProgramsListView.swift`

### 5a. Label "Para você" nos cards recomendados

```swift
// No card de programa recomendado, adicionar badge
if recommendedPrograms.contains(where: { $0.id == program.id }) {
    Text("Para você")
        .font(FitTodayFont.ui(size: 10, weight: .semiBold))
        .foregroundStyle(FitTodayColor.brandPrimary)
        .padding(.horizontal, FitTodaySpacing.xs)
        .padding(.vertical, 2)
        .background(FitTodayColor.brandPrimary.opacity(0.15))
        .clipShape(Capsule())
}
```

### 5b. Banner de perfil incompleto

```swift
// Injetar via ProgramsListViewModel
var isProfileIncomplete: Bool {
    userProfile?.isProfileComplete == false
}
```

```swift
// Na ProgramsListView, logo acima da seção de Recomendados:
if viewModel.isProfileIncomplete {
    IncompleteProfileBanner(onTap: { router.push(.editPreferences) })
}
```

```swift
struct IncompleteProfileBanner: View {
    let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: FitTodaySpacing.sm) {
                Image(systemName: "person.crop.circle.badge.exclamationmark")
                    .foregroundStyle(FitTodayColor.brandAccent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Complete seu perfil")
                        .font(FitTodayFont.ui(size: 14, weight: .semiBold))
                        .foregroundStyle(FitTodayColor.textPrimary)
                    Text("Melhore suas recomendações respondendo mais perguntas")
                        .font(FitTodayFont.ui(size: 12, weight: .medium))
                        .foregroundStyle(FitTodayColor.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(FitTodayColor.textTertiary)
                    .font(.system(size: 12))
            }
            .padding(FitTodaySpacing.md)
            .background(FitTodayColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: FitTodayRadius.md)
                    .strokeBorder(FitTodayColor.brandAccent.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
```

---

## Component 6: Settings — Entrada "Perfil de Treino"

**Arquivo:** `Features/Pro/ProfileProView.swift` (ou novo `EditPreferencesView.swift`)

### Resumo das preferências atuais

```swift
struct TrainingProfileSummaryRow: View {
    let profile: UserProfile

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
            HStack {
                Text("Perfil de Treino")
                    .font(FitTodayFont.ui(size: 16, weight: .semiBold))
                    .foregroundStyle(FitTodayColor.textPrimary)
                Spacer()
                NavigationLink("Editar") {
                    OnboardingFlowView(resolver: resolver, isEditing: true, onFinished: { })
                }
                .font(FitTodayFont.ui(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.brandPrimary)
            }

            HStack(spacing: FitTodaySpacing.sm) {
                ProfileChip(label: profile.mainGoal.title)
                ProfileChip(label: profile.level.title)
                ProfileChip(label: "\(profile.weeklyFrequency)x/sem")
            }
        }
        .padding(FitTodaySpacing.md)
        .background(FitTodayColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
    }
}
```

### Rota de navegação

Verificar `AppRouter.swift` e adicionar rota `.editPreferences` se necessário:
```swift
// AppRouter.swift
case editPreferences
// NavDestination handler
case .editPreferences:
    OnboardingFlowView(resolver: resolver, isEditing: true, onFinished: {
        router.pop(on: .profile)
    })
```

---

## Testing Strategy

| Área | Tipo | Descrição |
|---|---|---|
| `ProgramRecommender` | Unit | Score correto para cada combinação de `mainGoal` + `level` + `availableStructure` |
| `ProgramRecommender` | Unit | Programas com `goalTag: hypertrophy` são top para usuário com `mainGoal: .hypertrophy` |
| `OnboardingFlowViewModel` | Unit | `loadFromProfile` pré-preenche todos os 6 campos corretamente |
| `OnboardingFlowViewModel` | Unit | `canSubmitFull` só retorna true com todos os campos |
| `ProgramsSeed` | Unit | Nenhum `goal_tag` ausente ou inválido em todos os 26 programas |
| `ProgramsListView` | UI | Banner aparece quando `isProfileComplete = false` |
| `ProgramsListView` | UI | Banner não aparece quando `isProfileComplete = true` |

---

## Migration / Rollout

- Usuários com `isProfileComplete = false` veem o banner na tela de Programas
- Nenhum dado existente é perdido — apenas `goal_tag` do seed é atualizado (não afeta histórico)
- `OnboardingFlowView` retrocompatível — `isEditing: true` preexiste
