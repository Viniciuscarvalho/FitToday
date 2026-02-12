# Tasks: Correção da Geração de Treinos com IA

**Feature:** prd-workout-ai-fix
**Date:** 2026-02-11
**Status:** Ready for Implementation

---

## Overview

Estas tasks implementam a correção do sistema de geração de treinos com IA, conforme especificado no PRD e TechSpec.

**Problema Principal:** Os últimos 3 treinos buscados são do Apple Health (sem `workoutPlan`), resultando em lista vazia de exercícios proibidos.

**Solução:** Filtrar histórico por `source == .app` e implementar limite diário de 2 gerações.

---

## Tasks

### Task 1: Verificar e adicionar campo sourceRaw no SwiftData Model
**Priority:** P0 - Crítico
**File:** `FitToday/Data/Models/SDWorkoutHistoryEntry.swift`

**Description:**
Verificar se o campo `sourceRaw` existe no modelo SwiftData. Se não existir, adicionar com valor default "app".

**Subtasks:**
- [ ] Abrir `SDWorkoutHistoryEntry.swift`
- [ ] Verificar se existe `@Attribute var sourceRaw: String`
- [ ] Se não existir, adicionar: `@Attribute var sourceRaw: String = "app"`
- [ ] Verificar compatibilidade com schema existente

**Acceptance Criteria:**
- Campo `sourceRaw` existe no modelo
- Valor default é "app"
- Não há breaking changes no schema

---

### Task 2: Atualizar WorkoutHistoryMapper para mapear source
**Priority:** P0 - Crítico
**File:** `FitToday/Data/Mappers/WorkoutHistoryMapper.swift`

**Description:**
Garantir que o mapper converta corretamente entre `WorkoutSource` (domain) e `sourceRaw` (data).

**Subtasks:**
- [ ] Em `toDomain()`: converter `sourceRaw` para `WorkoutSource`
- [ ] Em `toModel()`: converter `WorkoutSource` para `sourceRaw`
- [ ] Adicionar fallback para "app" se valor inválido

**Code Example:**
```swift
// toDomain
let source = WorkoutSource(rawValue: model.sourceRaw) ?? .app

// toModel
sourceRaw: entry.source.rawValue
```

**Acceptance Criteria:**
- Mapeamento bidirecional funciona
- Valores inválidos têm fallback para `.app`

---

### Task 3: Adicionar método listAppEntriesWithPlan ao Protocol
**Priority:** P0 - Crítico
**File:** `FitToday/Domain/Protocols/Repositories.swift`

**Description:**
Adicionar novo método ao protocolo `WorkoutHistoryRepository` para buscar apenas treinos do app com workoutPlan válido.

**Code:**
```swift
protocol WorkoutHistoryRepository: Sendable {
    // ... métodos existentes ...

    /// Retorna apenas treinos gerados pelo app com workoutPlan válido
    /// - Parameter limit: Número máximo de entradas
    /// - Returns: Lista de entries do app com workoutPlan
    func listAppEntriesWithPlan(limit: Int) async throws -> [WorkoutHistoryEntry]
}
```

**Acceptance Criteria:**
- Método adicionado ao protocolo
- Documentação clara do propósito

---

### Task 4: Implementar listAppEntriesWithPlan no Repository
**Priority:** P0 - Crítico
**File:** `FitToday/Data/Repositories/SwiftDataWorkoutHistoryRepository.swift`

**Description:**
Implementar o método que filtra por `sourceRaw == "app"` e `workoutPlanJSON != nil`.

**Code:**
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

    #if DEBUG
    print("[HistoryRepo] Fetched \(models.count) app entries with plan (limit: \(limit))")
    #endif

    return models.compactMap(WorkoutHistoryMapper.toDomain)
}
```

**Acceptance Criteria:**
- Query filtra corretamente por source e workoutPlan
- Ordenação por data decrescente (mais recentes primeiro)
- Limite respeitado

---

### Task 5: Criar DailyGenerationLimiter
**Priority:** P0 - Crítico
**File:** `FitToday/Domain/UseCases/DailyGenerationLimiter.swift` (CRIAR)

**Description:**
Criar struct para controlar o limite de 2 gerações de treino por dia.

**Code:**
```swift
import Foundation

/// Controla o limite de gerações de treino por dia.
/// Máximo: 2 gerações por dia (reset à meia-noite local).
struct DailyGenerationLimiter: Sendable {
    private static let key = "dailyWorkoutGenerationCount"
    private let maxPerDay = 2
    private let userDefaults: UserDefaults
    private let dateProvider: () -> Date

    init(
        userDefaults: UserDefaults = .standard,
        dateProvider: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.userDefaults = userDefaults
        self.dateProvider = dateProvider
    }

    /// Verifica se o usuário pode gerar mais treinos hoje.
    func canGenerate() -> Bool {
        let counter = getCurrentCounter()
        return counter.count < maxPerDay
    }

    /// Incrementa o contador de gerações.
    func incrementCount() {
        var counter = getCurrentCounter()
        counter.count += 1
        saveCounter(counter)

        #if DEBUG
        print("[GenerationLimiter] Incremented to \(counter.count)/\(maxPerDay)")
        #endif
    }

    /// Retorna quantas gerações restam hoje.
    func remainingGenerations() -> Int {
        let counter = getCurrentCounter()
        return max(0, maxPerDay - counter.count)
    }

    private func getCurrentCounter() -> GenerationCounter {
        let today = todayString()

        guard let data = userDefaults.data(forKey: Self.key),
              let counter = try? JSONDecoder().decode(GenerationCounter.self, from: data),
              counter.date == today else {
            // Novo dia ou sem dados - retorna contador zerado
            return GenerationCounter(date: today, count: 0)
        }

        return counter
    }

    private func saveCounter(_ counter: GenerationCounter) {
        if let data = try? JSONEncoder().encode(counter) {
            userDefaults.set(data, forKey: Self.key)
        }
    }

    private func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: dateProvider())
    }
}

private struct GenerationCounter: Codable {
    let date: String
    var count: Int
}
```

**Acceptance Criteria:**
- `canGenerate()` retorna true quando < 2 gerações
- `incrementCount()` incrementa corretamente
- Reset automático em novo dia
- Thread-safe (Sendable)

---

### Task 6: Criar WorkoutGenerationError
**Priority:** P0 - Crítico
**File:** `FitToday/Domain/Entities/WorkoutErrors.swift` (CRIAR ou ADICIONAR)

**Description:**
Criar erro específico para limite diário atingido.

**Code:**
```swift
enum WorkoutGenerationError: LocalizedError {
    case dailyLimitReached(remaining: Int)
    case noValidHistoryFound
    case diversityValidationFailed

    var errorDescription: String? {
        switch self {
        case .dailyLimitReached:
            return "Você atingiu o limite de treinos por dia. Tente novamente amanhã!"
        case .noValidHistoryFound:
            return "Nenhum histórico válido encontrado."
        case .diversityValidationFailed:
            return "Não foi possível gerar um treino diferente."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .dailyLimitReached:
            return "O limite reseta à meia-noite. Use um treino salvo ou do seu programa."
        default:
            return nil
        }
    }
}
```

**Acceptance Criteria:**
- Erro tem mensagem clara em português
- Inclui sugestão de recuperação

---

### Task 7: Atualizar fetchRecentWorkouts no NewOpenAIWorkoutComposer
**Priority:** P0 - Crítico
**File:** `FitToday/Data/Services/OpenAI/NewOpenAIWorkoutComposer.swift`

**Description:**
Modificar o método `fetchRecentWorkouts()` para usar o novo método filtrado.

**Changes:**
```swift
private func fetchRecentWorkouts(limit: Int = 3) async throws -> [WorkoutPlan] {
    do {
        // MUDANÇA: Usar método que filtra por source == .app
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
        let totalExercises = workoutPlans.flatMap { $0.phases.flatMap(\.items) }.count
        print("[NewOpenAIComposer] 📋 Total prohibited exercises available: \(totalExercises)")
        #endif

        return workoutPlans
    } catch {
        #if DEBUG
        print("[NewOpenAIComposer] ❌ Failed to fetch app history: \(error.localizedDescription)")
        #endif
        return []
    }
}
```

**Acceptance Criteria:**
- Usa `listAppEntriesWithPlan` ao invés de `listEntries`
- Logs mostram exercícios corretos
- Fallback para array vazio em caso de erro

---

### Task 8: Integrar DailyGenerationLimiter no composePlan
**Priority:** P0 - Crítico
**File:** `FitToday/Data/Services/OpenAI/NewOpenAIWorkoutComposer.swift`

**Description:**
Adicionar verificação de limite no início de `composePlan()` e incrementar após sucesso.

**Changes no início do método:**
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
        print("[NewOpenAIComposer] ⚠️ Daily limit reached (0 remaining)")
        #endif
        throw WorkoutGenerationError.dailyLimitReached(
            remaining: limiter.remainingGenerations()
        )
    }

    #if DEBUG
    print("[NewOpenAIComposer] 📊 Generations remaining today: \(limiter.remainingGenerations())")
    #endif

    // ... resto do código existente ...
```

**Changes antes do return final:**
```swift
    // NOVO: Incrementar contador após sucesso
    limiter.incrementCount()

    #if DEBUG
    print("[NewOpenAIComposer] ✅ Generation successful. Remaining: \(limiter.remainingGenerations())")
    #endif

    return workoutPlan
}
```

**Acceptance Criteria:**
- Erro lançado quando limite atingido
- Contador incrementado apenas após sucesso
- Logs claros do estado

---

### Task 9: Tratar erro de limite na UI
**Priority:** P1 - Importante
**File:** `FitToday/Presentation/Infrastructure/ErrorMapper.swift`

**Description:**
Mapear o erro `WorkoutGenerationError.dailyLimitReached` para mensagem amigável na UI.

**Code:**
```swift
// Adicionar case no ErrorMapper
case let error as WorkoutGenerationError:
    switch error {
    case .dailyLimitReached:
        return UserFacingError(
            title: "Limite Diário Atingido",
            message: error.errorDescription ?? "Tente novamente amanhã.",
            suggestion: error.recoverySuggestion
        )
    default:
        return UserFacingError(
            title: "Erro na Geração",
            message: error.localizedDescription
        )
    }
```

**Acceptance Criteria:**
- Mensagem amigável exibida ao usuário
- Sugestão de usar treino salvo ou programa

---

### Task 10: Criar testes unitários
**Priority:** P1 - Importante
**File:** `FitTodayTests/WorkoutGeneration/DailyGenerationLimiterTests.swift` (CRIAR)

**Description:**
Criar testes para validar o comportamento do limitador.

**Test Cases:**
1. `canGenerate` retorna `true` sem gerações anteriores
2. `canGenerate` retorna `false` após 2 gerações
3. `remainingGenerations` retorna valor correto
4. Reset automático em novo dia

**Acceptance Criteria:**
- Todos os testes passando
- Cobertura dos casos de borda

---

### Task 11: Build e verificação manual
**Priority:** P0 - Crítico

**Description:**
Compilar o projeto e verificar que não há erros.

**Subtasks:**
- [ ] Executar build no simulador
- [ ] Verificar logs de debug
- [ ] Testar fluxo de geração de treino
- [ ] Verificar limite diário funciona

**Acceptance Criteria:**
- Build compila sem erros
- Sem warnings relacionados às mudanças
- Fluxo funciona corretamente

---

## Execution Order

```
1. Task 1 → Verificar sourceRaw (base para filtro)
2. Task 2 → Atualizar Mapper (depende de Task 1)
3. Task 3 → Adicionar método ao Protocol
4. Task 4 → Implementar método no Repository (depende de Task 1, 2, 3)
5. Task 5 → Criar DailyGenerationLimiter (independente)
6. Task 6 → Criar WorkoutGenerationError (independente)
7. Task 7 → Atualizar fetchRecentWorkouts (depende de Task 4)
8. Task 8 → Integrar limiter (depende de Task 5, 6)
9. Task 9 → Tratar erro na UI (depende de Task 6)
10. Task 10 → Testes (depende de Task 5)
11. Task 11 → Build e verificação (todas as tasks)
```

---

## Summary

| Task | Priority | Status | Dependencies |
|------|----------|--------|--------------|
| 1. Verificar sourceRaw | P0 | Pending | - |
| 2. Atualizar Mapper | P0 | Pending | Task 1 |
| 3. Adicionar método Protocol | P0 | Pending | - |
| 4. Implementar método Repository | P0 | Pending | Tasks 1, 2, 3 |
| 5. Criar DailyGenerationLimiter | P0 | Pending | - |
| 6. Criar WorkoutGenerationError | P0 | Pending | - |
| 7. Atualizar fetchRecentWorkouts | P0 | Pending | Task 4 |
| 8. Integrar limiter | P0 | Pending | Tasks 5, 6 |
| 9. Tratar erro UI | P1 | Pending | Task 6 |
| 10. Criar testes | P1 | Pending | Task 5 |
| 11. Build e verificação | P0 | Pending | All |

**Total Tasks:** 11
**P0 Tasks:** 9
**P1 Tasks:** 2

---

**Document End**
