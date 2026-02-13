# Technical Specification

**Project Name:** Correção da Geração de Treinos com IA
**Version:** 1.0
**Date:** 2026-02-11
**Author:** Claude
**Status:** Em Desenvolvimento

---

## Overview

### Problem Statement

A geração de treinos com IA está produzindo treinos repetitivos porque o sistema de histórico está buscando os **treinos errados** para construir a lista de exercícios proibidos. O log mostra:

```
[NewOpenAIComposer] 📋 History entries fetched: 3
[NewOpenAIComposer]   [0] Apple Health Workout - hasWorkoutPlan: false, exercises: 0
[NewOpenAIComposer]   [1] Apple Health Workout - hasWorkoutPlan: false, exercises: 0
[NewOpenAIComposer]   [2] Apple Health Workout - hasWorkoutPlan: false, exercises: 0
[NewOpenAIComposer] 📋 WorkoutPlans with exercises: 0
[PromptBuilder] 🚫 Prohibited exercises count: 0
```

**Causa Raiz**: Os últimos 3 treinos são importados do **Apple Health** (feitos fora do app), que por definição **não têm `workoutPlan`**. O sistema de busca não está filtrando por `source == .app`.

### Proposed Solution

1. **Filtrar histórico por source**: Buscar apenas treinos com `source == .app` que têm `workoutPlan` válido
2. **Implementar limite diário**: Máximo 2 gerações de treino por dia com persistência em UserDefaults
3. **Adicionar validação de diversidade pós-fetch**: Garantir que os exercícios proibidos sejam extraídos corretamente
4. **Limpar código legado**: Remover referências antigas de cache não utilizadas

### Goals

- Garantir que exercícios dos últimos 3 treinos do app sejam enviados como proibidos
- Implementar limite de 2 gerações de treino por dia
- Validar que cada geração produz exercícios diferentes

---

## Scope

### In Scope

- Correção do método `fetchRecentWorkouts()` em `NewOpenAIWorkoutComposer`
- Adição de método de filtragem no `WorkoutHistoryRepository`
- Implementação de contador diário de gerações
- Adição de logs de debug melhorados
- Testes unitários para validar variação

### Out of Scope

- Mudanças na UI
- Novos tipos de treino
- Integração com outros serviços
- Mudanças no fluxo do Apple Health

---

## Requirements

### Functional Requirements

#### FR-001: Filtrar Histórico por Source [MUST]

O sistema DEVE buscar apenas treinos gerados pelo app (`source == .app`) ao construir a lista de exercícios proibidos.

**Acceptance Criteria:**
- `fetchRecentWorkouts()` retorna apenas treinos com `workoutPlan` não-nulo
- Treinos do Apple Health (`source == .appleHealth`) são ignorados para variação
- Log mostra corretamente os exercícios proibidos encontrados

---

#### FR-002: Limite Diário de Gerações [MUST]

O usuário pode gerar no máximo 2 treinos por dia (reset à meia-noite local).

**Acceptance Criteria:**
- Contador persiste em UserDefaults
- Reset automático à meia-noite
- Mensagem clara quando limite é atingido
- Bypass para testes (flag de desenvolvimento)

---

#### FR-003: Validação de Diversidade [SHOULD]

Após receber resposta da IA, validar que pelo menos 60% dos exercícios são diferentes dos proibidos.

**Acceptance Criteria:**
- Validação acontece após decodificação
- Máximo 2 retries se falhar
- Fallback local se todos retries falharem
- Log mostra porcentagem de diversidade

---

#### FR-004: Logs de Debug [MUST]

Adicionar logs claros para facilitar debug em produção.

**Acceptance Criteria:**
- Log da quantidade de treinos do app encontrados
- Log dos exercícios proibidos (lista)
- Log da diversidade calculada
- Log do contador diário de gerações

---

### Non-Functional Requirements

#### NFR-001: Performance [MUST]

A busca de histórico filtrado deve ser eficiente.

**Target:** Busca de histórico < 100ms para até 100 entries

---

#### NFR-002: Persistência [MUST]

O contador diário de gerações deve persistir corretamente.

**Requirements:**
- UserDefaults com chave única
- Formato: `{date: "YYYY-MM-DD", count: Int}`
- Limpeza automática de datas antigas

---

## Technical Approach

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│ FLUXO CORRIGIDO                                                 │
└─────────────────────────────────────────────────────────────────┘

1. User solicita novo treino
   └─> DailyGenerationLimiter.canGenerate()
       └─> Verifica contador em UserDefaults
           ├─> Se >= 2: Retorna erro (limite atingido)
           └─> Se < 2: Continua

2. NewOpenAIWorkoutComposer.composePlan()
   └─> fetchRecentAppWorkouts(limit: 3)      // NOVO MÉTODO
       └─> historyRepository.listAppEntries(limit: 3)  // FILTRADO
           └─> Filtra: source == .app AND workoutPlan != nil

   └─> NewWorkoutPromptBuilder.buildPrompt()
       └─> formatProhibitedWorkouts(previousWorkouts)
           └─> Extrai nomes de exercícios (agora populado!)

3. Após geração bem-sucedida
   └─> DailyGenerationLimiter.incrementCount()
```

### Key Technologies

- **SwiftData**: Persistência do histórico de treinos
- **UserDefaults**: Contador diário de gerações
- **OpenAI API**: Geração de treinos via GPT-4

### Components

#### Component 1: DailyGenerationLimiter

**Purpose:** Controlar o limite de gerações diárias de treino

**Responsibilities:**
- Verificar se usuário pode gerar treino
- Incrementar contador após geração
- Resetar contador à meia-noite

**Interface:**
```swift
struct DailyGenerationLimiter {
    private let maxGenerationsPerDay = 2
    private let userDefaults: UserDefaults

    func canGenerate() -> Bool
    func incrementCount()
    func remainingGenerations() -> Int
    func resetIfNeeded()
}
```

---

#### Component 2: WorkoutHistoryRepository (Extensão)

**Purpose:** Adicionar método de filtragem por source

**Responsibilities:**
- Listar apenas treinos do app com workoutPlan
- Manter performance com queries otimizadas

**Interface:**
```swift
extension WorkoutHistoryRepository {
    /// Retorna apenas treinos gerados pelo app com workoutPlan válido
    func listAppEntriesWithPlan(limit: Int) async throws -> [WorkoutHistoryEntry]
}
```

---

### Data Model

#### Entity: GenerationCounter (UserDefaults)

```swift
struct GenerationCounter: Codable {
    let date: String       // "YYYY-MM-DD"
    var count: Int         // 0, 1, ou 2
}
```

#### Entity: WorkoutHistoryEntry (Existente - Sem Mudanças)

```swift
struct WorkoutHistoryEntry {
    var source: WorkoutSource  // .app, .appleHealth, .merged
    var workoutPlan: WorkoutPlan?
    // ... outros campos
}
```

---

## Implementation Considerations

### Design Patterns

- **Strategy**: `WorkoutPlanComposing` já implementa padrão para troca entre OpenAI e Local
- **Repository**: Mantém separação entre camada de dados e domínio

### Error Handling

```swift
enum WorkoutGenerationError: LocalizedError {
    case dailyLimitReached(remaining: Int)
    case noValidHistoryFound
    case diversityValidationFailed

    var errorDescription: String? {
        switch self {
        case .dailyLimitReached:
            return "Você atingiu o limite de 2 treinos por dia. Tente novamente amanhã!"
        case .noValidHistoryFound:
            return "Nenhum histórico válido encontrado para variação."
        case .diversityValidationFailed:
            return "Não foi possível gerar um treino suficientemente diferente."
        }
    }
}
```

### Logging and Monitoring

**Key Logs:**
```
[GenerationLimiter] Remaining generations today: 1/2
[NewOpenAIComposer] 📋 App workout entries fetched: 3
[NewOpenAIComposer] 📋 Exercises from history: 42
[PromptBuilder] 🚫 Prohibited exercises: Bench Press, Squat, Deadlift, ...
[NewOpenAIComposer] ✅ Diversity: 85% (target: 60%)
```

---

## Testing Strategy

### Unit Testing

**Coverage Target:** 80%

**Focus Areas:**
- `DailyGenerationLimiter` - todas as condições de borda
- `fetchRecentAppWorkouts()` - filtragem correta
- `WorkoutVariationValidator` - cálculo de diversidade

### Test Cases

#### Test 1: Filtragem por Source
```swift
func test_fetchRecentWorkouts_filtersOutAppleHealthWorkouts() async throws {
    // Given: 5 entries (2 app, 3 appleHealth)
    // When: fetchRecentAppWorkouts(limit: 3)
    // Then: Retorna apenas os 2 do app
}
```

#### Test 2: Limite Diário
```swift
func test_dailyLimiter_blocksAfterTwoGenerations() {
    // Given: 2 gerações já feitas hoje
    // When: canGenerate()
    // Then: false
}

func test_dailyLimiter_resetsAtMidnight() {
    // Given: 2 gerações feitas ontem
    // When: canGenerate() (hoje)
    // Then: true
}
```

#### Test 3: Diversidade
```swift
func test_diversityValidation_passesWithEnoughNewExercises() {
    // Given: 10 exercícios gerados, 3 proibidos
    // When: validateDiversity() com 60% threshold
    // Then: true (70% diferentes)
}
```

---

## Implementation Tasks

### Task 1: Criar DailyGenerationLimiter

**Arquivo:** `FitToday/Domain/UseCases/DailyGenerationLimiter.swift`

```swift
struct DailyGenerationLimiter {
    private static let key = "dailyWorkoutGenerationCount"
    private let maxPerDay = 2
    private let userDefaults: UserDefaults
    private let calendar: Calendar

    init(userDefaults: UserDefaults = .standard, calendar: Calendar = .current) {
        self.userDefaults = userDefaults
        self.calendar = calendar
    }

    func canGenerate() -> Bool {
        resetIfNeeded()
        return currentCount() < maxPerDay
    }

    func incrementCount() {
        resetIfNeeded()
        let current = currentCount()
        saveCount(current + 1)
    }

    func remainingGenerations() -> Int {
        resetIfNeeded()
        return max(0, maxPerDay - currentCount())
    }

    private func currentCount() -> Int {
        guard let data = userDefaults.data(forKey: Self.key),
              let counter = try? JSONDecoder().decode(GenerationCounter.self, from: data) else {
            return 0
        }
        return counter.count
    }

    private func saveCount(_ count: Int) {
        let counter = GenerationCounter(
            date: todayString(),
            count: count
        )
        if let data = try? JSONEncoder().encode(counter) {
            userDefaults.set(data, forKey: Self.key)
        }
    }

    private func resetIfNeeded() {
        guard let data = userDefaults.data(forKey: Self.key),
              let counter = try? JSONDecoder().decode(GenerationCounter.self, from: data) else {
            return
        }
        if counter.date != todayString() {
            saveCount(0)
        }
    }

    private func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

private struct GenerationCounter: Codable {
    let date: String
    var count: Int
}
```

---

### Task 2: Adicionar método filtrado no Repository Protocol

**Arquivo:** `FitToday/Domain/Protocols/Repositories.swift`

Adicionar ao protocolo `WorkoutHistoryRepository`:

```swift
/// Retorna apenas treinos do app com workoutPlan válido
func listAppEntriesWithPlan(limit: Int) async throws -> [WorkoutHistoryEntry]
```

---

### Task 3: Implementar método no SwiftDataWorkoutHistoryRepository

**Arquivo:** `FitToday/Data/Repositories/SwiftDataWorkoutHistoryRepository.swift`

```swift
func listAppEntriesWithPlan(limit: Int) async throws -> [WorkoutHistoryEntry] {
    var descriptor = FetchDescriptor<SDWorkoutHistoryEntry>(
        predicate: #Predicate {
            $0.sourceRaw == "app" && $0.workoutPlanJSON != nil
        },
        sortBy: [SortDescriptor(\.date, order: .reverse)]
    )
    descriptor.fetchLimit = limit

    let models = try context().fetch(descriptor)
    return models.compactMap(WorkoutHistoryMapper.toDomain)
}
```

---

### Task 4: Atualizar NewOpenAIWorkoutComposer

**Arquivo:** `FitToday/Data/Services/OpenAI/NewOpenAIWorkoutComposer.swift`

Mudar `fetchRecentWorkouts()`:

```swift
private func fetchRecentWorkouts(limit: Int = 3) async throws -> [WorkoutPlan] {
    do {
        // MUDANÇA: Usar novo método que filtra por source == .app
        let entries = try await historyRepository.listAppEntriesWithPlan(limit: limit)

        #if DEBUG
        print("[NewOpenAIComposer] 📋 App entries with plan: \(entries.count)")
        for (index, entry) in entries.enumerated() {
            let exerciseCount = entry.workoutPlan?.phases.flatMap(\.items).count ?? 0
            print("[NewOpenAIComposer]   [\(index)] \(entry.title) - exercises: \(exerciseCount)")
        }
        #endif

        let workoutPlans = entries.compactMap { $0.workoutPlan }

        #if DEBUG
        print("[NewOpenAIComposer] 📋 WorkoutPlans with exercises: \(workoutPlans.count)")
        #endif

        return workoutPlans
    } catch {
        #if DEBUG
        print("[NewOpenAIComposer] ❌ Failed to fetch history: \(error.localizedDescription)")
        #endif
        return []
    }
}
```

---

### Task 5: Integrar DailyGenerationLimiter no Composer

**Arquivo:** `FitToday/Data/Services/OpenAI/NewOpenAIWorkoutComposer.swift`

Adicionar verificação no início de `composePlan()`:

```swift
func composePlan(
    blocks: [WorkoutBlock],
    profile: UserProfile,
    checkIn: DailyCheckIn
) async throws -> WorkoutPlan {
    // NOVO: Verificar limite diário
    let limiter = DailyGenerationLimiter()
    guard limiter.canGenerate() else {
        #if DEBUG
        print("[NewOpenAIComposer] ⚠️ Daily limit reached")
        #endif
        throw WorkoutGenerationError.dailyLimitReached(
            remaining: limiter.remainingGenerations()
        )
    }

    // ... resto do código existente ...

    // NOVO: Incrementar contador após sucesso
    limiter.incrementCount()

    #if DEBUG
    print("[NewOpenAIComposer] ✅ Generation successful. Remaining today: \(limiter.remainingGenerations())")
    #endif

    return workoutPlan
}
```

---

### Task 6: Adicionar sourceRaw ao SDWorkoutHistoryEntry

**Arquivo:** `FitToday/Data/Models/SDWorkoutHistoryEntry.swift`

Verificar se existe campo `sourceRaw`. Se não existir, adicionar:

```swift
@Attribute var sourceRaw: String = "app"
```

E atualizar o Mapper para mapear corretamente.

---

### Task 7: Testes Unitários

**Arquivo:** `FitTodayTests/WorkoutGeneration/DailyGenerationLimiterTests.swift`

```swift
final class DailyGenerationLimiterTests: XCTestCase {

    func test_canGenerate_returnsTrueWhenNoGenerationsToday() {
        let defaults = UserDefaults(suiteName: "test")!
        defaults.removePersistentDomain(forName: "test")
        let limiter = DailyGenerationLimiter(userDefaults: defaults)

        XCTAssertTrue(limiter.canGenerate())
    }

    func test_canGenerate_returnsFalseAfterTwoGenerations() {
        let defaults = UserDefaults(suiteName: "test")!
        defaults.removePersistentDomain(forName: "test")
        let limiter = DailyGenerationLimiter(userDefaults: defaults)

        limiter.incrementCount()
        limiter.incrementCount()

        XCTAssertFalse(limiter.canGenerate())
    }

    func test_remainingGenerations_returnsCorrectValue() {
        let defaults = UserDefaults(suiteName: "test")!
        defaults.removePersistentDomain(forName: "test")
        let limiter = DailyGenerationLimiter(userDefaults: defaults)

        XCTAssertEqual(limiter.remainingGenerations(), 2)

        limiter.incrementCount()
        XCTAssertEqual(limiter.remainingGenerations(), 1)

        limiter.incrementCount()
        XCTAssertEqual(limiter.remainingGenerations(), 0)
    }
}
```

---

## Dependencies

### External Dependencies

| Dependency | Version | Purpose | Risk |
|------------|---------|---------|------|
| OpenAI API | gpt-4 | Geração de treinos | Baixo - fallback local existe |
| SwiftData | iOS 17+ | Persistência | Baixo - já em uso |

### Internal Dependencies

- `WorkoutHistoryRepository` - Para buscar histórico filtrado
- `NewWorkoutPromptBuilder` - Para construir prompts
- `WorkoutVariationValidator` - Para validar diversidade
- `EnhancedLocalWorkoutPlanComposer` - Fallback quando OpenAI falha

---

## Risks and Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| SDWorkoutHistoryEntry não tem sourceRaw | Alto | Média | Verificar modelo e adicionar migração se necessário |
| Predicate complexo afeta performance | Médio | Baixa | Testar com volume alto, adicionar índice se necessário |
| Usuário sem histórico do app | Baixo | Alta | Aceitar lista vazia de proibidos (primeiro treino) |

---

## Success Criteria

- [ ] Log mostra exercícios proibidos populados (quando há histórico do app)
- [ ] Treinos consecutivos têm pelo menos 60% de exercícios diferentes
- [ ] Limite de 2 gerações/dia funciona corretamente
- [ ] Reset à meia-noite funciona
- [ ] Fallback local funciona quando limite é atingido
- [ ] Todos testes unitários passando
- [ ] Build sem warnings

---

## File Changes Summary

| Arquivo | Mudança | Prioridade |
|---------|---------|------------|
| `Domain/UseCases/DailyGenerationLimiter.swift` | CRIAR | P0 |
| `Domain/Protocols/Repositories.swift` | ADICIONAR método | P0 |
| `Data/Repositories/SwiftDataWorkoutHistoryRepository.swift` | IMPLEMENTAR método | P0 |
| `Data/Services/OpenAI/NewOpenAIWorkoutComposer.swift` | MODIFICAR fetchRecentWorkouts | P0 |
| `Data/Models/SDWorkoutHistoryEntry.swift` | VERIFICAR sourceRaw | P0 |
| `Data/Mappers/WorkoutHistoryMapper.swift` | VERIFICAR mapeamento source | P0 |
| `Tests/DailyGenerationLimiterTests.swift` | CRIAR | P1 |

---

**Document End**
