# Tasks: Fix Flow Generate

## Overview

Este documento contém as tarefas detalhadas para implementação das correções identificadas no PRD e TechSpec.

---

## Phase 1: Workout Generation Cache Fix

### Task 1.1: Update WorkoutBlueprint variationSeed
**Priority:** Critical
**Complexity:** Low
**Files:**
- `FitToday/Domain/Entities/WorkoutBlueprint.swift`

**Description:**
Modificar o cálculo do `variationSeed` para incluir explicitamente o `focus` e garantir unicidade temporal.

**Steps:**
1. Localizar a computed property `variationSeed`
2. Adicionar `focus.rawValue` ao hasher
3. Incluir timestamp para garantir variação
4. Testar com diferentes grupos musculares

**Acceptance Criteria:**
- [ ] variationSeed muda quando focus muda
- [ ] Treinos diferentes gerados para grupos musculares diferentes

---

### Task 1.2: Add Cache Invalidation on Focus Change
**Priority:** Critical
**Complexity:** Medium
**Files:**
- `FitToday/Data/Services/OpenAI/OpenAIResponseCache.swift`
- `FitToday/Data/Services/OpenAI/WorkoutPromptAssembler.swift`

**Description:**
Implementar lógica para invalidar cache quando o usuário seleciona um grupo muscular diferente.

**Steps:**
1. Adicionar tracking de `lastFocus` no cache actor
2. Criar método `clearForFocusChange()`
3. Modificar `get()` para verificar mudança de focus
4. Atualizar chamadas no `WorkoutPromptAssembler`

**Acceptance Criteria:**
- [ ] Cache limpo automaticamente ao mudar focus
- [ ] Log de invalidação visível em debug

---

### Task 1.3: Update Cache Key Generation
**Priority:** High
**Complexity:** Low
**Files:**
- `FitToday/Data/Services/OpenAI/WorkoutPromptAssembler.swift`

**Description:**
Garantir que o cache key inclui todos os parâmetros relevantes para unicidade.

**Steps:**
1. Revisar método `generateCacheKey()`
2. Garantir que focus está incluído
3. Considerar adicionar session ID ou timestamp

**Acceptance Criteria:**
- [ ] Cache keys únicos por combinação de parâmetros
- [ ] Não há colisão de cache entre grupos musculares

---

## Phase 2: Title Header & Minhas Rotinas

### Task 2.1: Restore Navigation Title in WorkoutTabView
**Priority:** High
**Complexity:** Low
**Files:**
- `FitToday/Presentation/Features/Workout/Views/WorkoutTabView.swift`

**Description:**
Restaurar o título de navegação que desapareceu.

**Steps:**
1. Verificar se `.navigationTitle()` está presente
2. Garantir `.navigationBarTitleDisplayMode(.large)`
3. Verificar hierarquia de NavigationStack

**Acceptance Criteria:**
- [ ] Título "Treino" visível no header
- [ ] Título usa estilo large

---

### Task 2.2: Create SavedRoutine Domain Model
**Priority:** High
**Complexity:** Low
**Files:**
- **NEW:** `FitToday/Domain/Entities/SavedRoutine.swift`

**Description:**
Criar modelo de domínio para rotinas salvas.

**Steps:**
1. Criar struct `SavedRoutine` com propriedades necessárias
2. Implementar conformance a Identifiable, Codable, Hashable, Sendable
3. Criar initializer a partir de `Program`

**Acceptance Criteria:**
- [ ] Model compila sem erros
- [ ] Conformance a todos os protocolos

---

### Task 2.3: Create SwiftData Model for SavedRoutine
**Priority:** High
**Complexity:** Medium
**Files:**
- **NEW:** `FitToday/Data/Models/SDSavedRoutine.swift`

**Description:**
Criar modelo SwiftData para persistência de rotinas.

**Steps:**
1. Criar classe `@Model SDSavedRoutine`
2. Adicionar atributo `@Attribute(.unique)` no id
3. Implementar `toDomain()` para conversão
4. Registrar modelo no ModelContainer

**Acceptance Criteria:**
- [ ] Model persiste corretamente
- [ ] Conversão para domain model funciona

---

### Task 2.4: Create SavedRoutineRepository Protocol
**Priority:** High
**Complexity:** Low
**Files:**
- **NEW:** `FitToday/Domain/Protocols/SavedRoutineRepository.swift`

**Description:**
Criar protocolo do repositório de rotinas.

**Steps:**
1. Definir métodos: listRoutines, saveRoutine, deleteRoutine, canSaveMore
2. Marcar como Sendable
3. Usar async throws onde apropriado

**Acceptance Criteria:**
- [ ] Protocolo define todas as operações necessárias
- [ ] Compatível com Swift Concurrency

---

### Task 2.5: Implement SwiftDataSavedRoutineRepository
**Priority:** High
**Complexity:** Medium
**Files:**
- **NEW:** `FitToday/Data/Repositories/SwiftDataSavedRoutineRepository.swift`

**Description:**
Implementar repositório usando SwiftData.

**Steps:**
1. Implementar todos os métodos do protocolo
2. Adicionar lógica de limite (max 5 rotinas)
3. Criar enum `RoutineError`
4. Registrar no container de DI

**Acceptance Criteria:**
- [ ] CRUD operations funcionam
- [ ] Limite de 5 é enforçado
- [ ] Erro apropriado retornado ao exceder limite

---

### Task 2.6: Update MyWorkoutsView with Routines Section
**Priority:** High
**Complexity:** Medium
**Files:**
- `FitToday/Presentation/Features/Workout/Views/MyWorkoutsView.swift`

**Description:**
Adicionar seção "Minhas Rotinas" na view.

**Steps:**
1. Adicionar @State para savedRoutines
2. Injetar repository via @Injected
3. Criar seção visual para rotinas
4. Implementar delete com swipe
5. Mostrar contador "X/5"

**Acceptance Criteria:**
- [ ] Seção visível quando há rotinas
- [ ] Delete funciona
- [ ] Contador exibido corretamente

---

### Task 2.7: Add Save Button to ProgramDetailView
**Priority:** Medium
**Complexity:** Low
**Files:**
- `FitToday/Presentation/Features/Programs/ProgramDetailView.swift`

**Description:**
Adicionar botão "Salvar como Rotina" nos detalhes do programa.

**Steps:**
1. Adicionar botão na toolbar ou hero section
2. Verificar `canSaveMore()` antes de exibir
3. Chamar `saveRoutine()` ao clicar
4. Mostrar feedback de sucesso/erro

**Acceptance Criteria:**
- [ ] Botão visível quando pode salvar
- [ ] Botão desabilitado/oculto no limite
- [ ] Feedback visual após salvar

---

### Task 2.8: Create SavedRoutineCard Component
**Priority:** Medium
**Complexity:** Low
**Files:**
- **NEW:** `FitToday/Presentation/Features/Workout/Components/SavedRoutineCard.swift`

**Description:**
Criar componente visual para card de rotina salva.

**Steps:**
1. Criar view com nome, goal tag, level
2. Adicionar indicador de workouts count
3. Implementar delete callback
4. Usar cores consistentes com design system

**Acceptance Criteria:**
- [ ] Card exibe todas as informações
- [ ] Visual consistente com outros cards
- [ ] Swipe to delete funcional

---

## Phase 3: Exercise Description Translation

### Task 3.1: Create ExerciseTranslationService
**Priority:** High
**Complexity:** Medium
**Files:**
- **NEW:** `FitToday/Data/Services/Translation/ExerciseTranslationService.swift`

**Description:**
Criar serviço para detectar idioma e fornecer fallback.

**Steps:**
1. Criar actor `ExerciseTranslationService`
2. Usar NLLanguageRecognizer para detecção
3. Implementar cache em memória
4. Criar fallback para português genérico

**Acceptance Criteria:**
- [ ] Detecta idioma corretamente
- [ ] Filtra espanhol
- [ ] Fallback funciona para idiomas desconhecidos

---

### Task 3.2: Update WgerModels Description Method
**Priority:** High
**Complexity:** Low
**Files:**
- `FitToday/Domain/Entities/WgerModels.swift`

**Description:**
Tornar o método de descrição mais restritivo.

**Steps:**
1. Localizar `description(for languageId:)`
2. Garantir que só retorna PT ou EN
3. Retornar nil para outros idiomas
4. Atualizar documentação

**Acceptance Criteria:**
- [ ] Nunca retorna espanhol
- [ ] Retorna nil para idiomas não suportados

---

### Task 3.3: Integrate Translation in WgerAPIService
**Priority:** High
**Complexity:** Medium
**Files:**
- `FitToday/Data/Services/Wger/WgerAPIService.swift`

**Description:**
Integrar serviço de tradução no fluxo de fetch.

**Steps:**
1. Instanciar `ExerciseTranslationService`
2. Chamar `ensureLocalizedDescription()` após obter descrição
3. Usar fallback quando nil

**Acceptance Criteria:**
- [ ] Todas as descrições passam pelo serviço
- [ ] Nenhuma descrição em espanhol exibida

---

### Task 3.4: Add Localization Strings for Fallbacks
**Priority:** Low
**Complexity:** Low
**Files:**
- `FitToday/Resources/pt-BR.lproj/Localizable.strings`
- `FitToday/Resources/en.lproj/Localizable.strings`

**Description:**
Adicionar strings de fallback localizadas.

**Steps:**
1. Adicionar chave para descrição genérica de exercício
2. Traduzir para ambos os idiomas

**Acceptance Criteria:**
- [ ] Strings adicionadas em ambos os arquivos
- [ ] Fallback faz sentido contextualmente

---

## Phase 4: Streaks Sync & Photo Check-in

### Task 4.1: Create StreakCalculator Utility
**Priority:** Critical
**Complexity:** Medium
**Files:**
- **NEW:** `FitToday/Domain/Utilities/StreakCalculator.swift`

**Description:**
Criar utilitário centralizado para cálculo de streak.

**Steps:**
1. Criar struct `StreakCalculator` com método estático
2. Usar timezone local do usuário
3. Filtrar por duração mínima (30 min)
4. Remover duplicatas de mesmo dia
5. Contar dias consecutivos

**Acceptance Criteria:**
- [ ] Cálculo consistente
- [ ] Timezone sempre local
- [ ] Testes unitários passando

---

### Task 4.2: Update HomeViewModel to Use StreakCalculator
**Priority:** High
**Complexity:** Low
**Files:**
- `FitToday/Presentation/Features/Home/HomeViewModel.swift`

**Description:**
Substituir lógica inline pelo utilitário.

**Steps:**
1. Importar `StreakCalculator`
2. Substituir computed property `streakDays`
3. Garantir que `activeDays` usa mesma fonte

**Acceptance Criteria:**
- [ ] Valores consistentes na UI
- [ ] Sem código duplicado

---

### Task 4.3: Update SyncWorkoutCompletionUseCase
**Priority:** High
**Complexity:** Low
**Files:**
- `FitToday/Domain/UseCases/SyncWorkoutCompletionUseCase.swift`

**Description:**
Usar StreakCalculator no use case.

**Steps:**
1. Substituir `computeCurrentStreak()` por `StreakCalculator.calculateStreak()`
2. Remover método privado duplicado

**Acceptance Criteria:**
- [ ] Uma única fonte de verdade para streak
- [ ] Sync usa mesma lógica que UI

---

### Task 4.4: Add Retry Logic to CheckInUseCase
**Priority:** High
**Complexity:** Medium
**Files:**
- `FitToday/Domain/UseCases/CheckInUseCase.swift`

**Description:**
Implementar retry para compressão e upload.

**Steps:**
1. Criar método `compressWithRetry()`
2. Criar método `uploadWithRetry()`
3. Usar exponential backoff
4. Adicionar logs detalhados

**Acceptance Criteria:**
- [ ] 3 tentativas antes de falhar
- [ ] Logs úteis para debug
- [ ] Erro final informativo

---

### Task 4.5: Improve Error Handling in CheckInUseCase
**Priority:** High
**Complexity:** Low
**Files:**
- `FitToday/Domain/UseCases/CheckInUseCase.swift`

**Description:**
Criar enum de erros específicos.

**Steps:**
1. Criar `CheckInError` enum
2. Implementar `LocalizedError`
3. Usar erros específicos em cada ponto de falha

**Acceptance Criteria:**
- [ ] Erros descritivos
- [ ] Mensagens localizadas

---

### Task 4.6: Update CheckInSheet UI
**Priority:** Medium
**Complexity:** Medium
**Files:**
- `FitToday/Presentation/Features/Activity/Views/CheckInSheet.swift`

**Description:**
Melhorar feedback visual no check-in.

**Steps:**
1. Adicionar ProgressView durante upload
2. Mostrar mensagem de erro em vermelho
3. Adicionar alert de sucesso
4. Desabilitar botão durante processo

**Acceptance Criteria:**
- [ ] Estado de loading visível
- [ ] Erro exibido claramente
- [ ] Sucesso confirma ação

---

### Task 4.7: Add New Localization Strings
**Priority:** Low
**Complexity:** Low
**Files:**
- `FitToday/Resources/pt-BR.lproj/Localizable.strings`
- `FitToday/Resources/en.lproj/Localizable.strings`

**Description:**
Adicionar todas as novas strings de localização.

**Steps:**
1. Adicionar strings de rotinas
2. Adicionar strings de check-in
3. Revisar traduções

**Acceptance Criteria:**
- [ ] Todas as novas strings presentes
- [ ] Traduções corretas

---

## Phase 5: Testing & Validation

### Task 5.1: Write Unit Tests for StreakCalculator
**Priority:** High
**Complexity:** Medium
**Files:**
- **NEW:** `FitTodayTests/Domain/Utilities/StreakCalculatorTests.swift`

**Description:**
Testes unitários para o calculador de streak.

**Test Cases:**
- [ ] Empty entries returns 0
- [ ] Single workout returns 1
- [ ] Consecutive days counted correctly
- [ ] Gap breaks streak
- [ ] Same-day duplicates handled
- [ ] Workouts under 30 min excluded
- [ ] Future dates handled

---

### Task 5.2: Write Unit Tests for SavedRoutineRepository
**Priority:** High
**Complexity:** Medium
**Files:**
- **NEW:** `FitTodayTests/Data/Repositories/SwiftDataSavedRoutineRepositoryTests.swift`

**Description:**
Testes para repositório de rotinas.

**Test Cases:**
- [ ] Save routine success
- [ ] Save fails at limit (5)
- [ ] Delete routine success
- [ ] List returns sorted by date
- [ ] canSaveMore returns correct value

---

### Task 5.3: Write Unit Tests for ExerciseTranslationService
**Priority:** Medium
**Complexity:** Low
**Files:**
- **NEW:** `FitTodayTests/Data/Services/ExerciseTranslationServiceTests.swift`

**Description:**
Testes para serviço de tradução.

**Test Cases:**
- [ ] Portuguese text passthrough
- [ ] English text passthrough
- [ ] Spanish text returns fallback
- [ ] Cache works correctly
- [ ] Unknown language returns fallback

---

### Task 5.4: Build and Run All Tests
**Priority:** Critical
**Complexity:** Low
**Files:** N/A

**Description:**
Executar build e todos os testes.

**Steps:**
1. Run `xcodebuild clean`
2. Run `xcodebuild build`
3. Run `xcodebuild test`
4. Fix any failures

**Acceptance Criteria:**
- [ ] Build succeeds without errors
- [ ] All tests pass
- [ ] No compiler warnings in new code

---

## Phase 6: Commit & PR

### Task 6.1: Stage and Commit Changes
**Priority:** Critical
**Complexity:** Low

**Description:**
Commitar todas as mudanças com mensagem descritiva.

**Commit Message:**
```
feat: fix workout generation, add routines, translate exercises, sync streaks

- Fix cache collision in workout generation by including focus in seed
- Add cache invalidation when muscle group changes
- Restore navigation title in WorkoutTabView
- Add "Minhas Rotinas" section with 5-routine limit
- Create SavedRoutine model and SwiftData persistence
- Implement ExerciseTranslationService to filter Spanish
- Unify streak calculation with StreakCalculator utility
- Add retry logic to photo upload in CheckInUseCase
- Add comprehensive error handling for check-in flow
- Add localization strings for new features
```

---

### Task 6.2: Create Pull Request
**Priority:** Critical
**Complexity:** Low

**Description:**
Criar PR com descrição completa.

**PR Title:** `feat: fix workout generation flow and related issues`

---

## Summary

| Phase | Tasks | Priority |
|-------|-------|----------|
| 1. Cache Fix | 3 | Critical |
| 2. Routines | 8 | High |
| 3. Translation | 4 | High |
| 4. Streaks/Photo | 7 | High |
| 5. Testing | 4 | High |
| 6. Commit | 2 | Critical |

**Total Tasks:** 28
