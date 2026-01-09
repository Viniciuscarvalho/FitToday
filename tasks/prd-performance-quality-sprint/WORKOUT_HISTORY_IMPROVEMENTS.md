# Melhorias Implementadas — Histórico de Treinos

## ✅ Implementação Concluída

Implementei duas melhorias importantes no sistema de histórico de treinos:

### 1. Persistência do WorkoutPlan Completo no Histórico

**Problema:** A linha 131 do `HybridWorkoutPlanComposer.swift` retornava array vazio porque as entries do histórico não continham o `WorkoutPlan` completo, impossibilitando o uso de treinos anteriores para evitar repetição de exercícios.

**Solução Implementada:**

#### A. Adicionado campo `workoutPlanJSON` ao modelo SwiftData

**Arquivo:** `SDWorkoutHistoryEntry.swift`

```swift
@Model
final class SDWorkoutHistoryEntry {
    // ... campos existentes ...
    
    // WorkoutPlan completo serializado (para histórico de variação)
    var workoutPlanJSON: Data?
}
```

#### B. Adicionado campo `workoutPlan` à entity de domínio

**Arquivo:** `HistoryModels.swift`

```swift
struct WorkoutHistoryEntry: Codable, Hashable, Sendable, Identifiable {
    // ... campos existentes ...
    
    // WorkoutPlan completo (para histórico de variação)
    var workoutPlan: WorkoutPlan?
}
```

#### C. Atualizado o Mapper para serializar/desserializar

**Arquivo:** `WorkoutHistoryMapper.swift`

```swift
static func toDomain(_ model: SDWorkoutHistoryEntry) -> WorkoutHistoryEntry? {
    // ... código existente ...
    
    // Decodificar WorkoutPlan se houver
    var workoutPlan: WorkoutPlan? = nil
    if let jsonData = model.workoutPlanJSON {
        workoutPlan = try? JSONDecoder().decode(WorkoutPlan.self, from: jsonData)
    }
    
    return WorkoutHistoryEntry(
        // ... campos existentes ...
        workoutPlan: workoutPlan
    )
}

static func toModel(_ entry: WorkoutHistoryEntry) -> SDWorkoutHistoryEntry {
    // Serializar WorkoutPlan se houver
    var workoutPlanJSON: Data? = nil
    if let plan = entry.workoutPlan {
        workoutPlanJSON = try? JSONEncoder().encode(plan)
    }
    
    return SDWorkoutHistoryEntry(
        // ... campos existentes ...
        workoutPlanJSON: workoutPlanJSON
    )
}
```

#### D. Atualizado o Use Case para salvar o plano completo

**Arquivo:** `WorkoutPlanUseCases.swift`

```swift
func execute(session: WorkoutSession, status: WorkoutStatus) async throws {
    guard status == .completed else {
        return
    }
    
    let entry = WorkoutHistoryEntry(
        planId: session.plan.id,
        title: session.plan.title,
        focus: session.plan.focus,
        status: status,
        workoutPlan: session.plan // ← Salvar o plano completo
    )
    try await historyRepository.saveEntry(entry)
}
```

#### E. Implementado `fetchRecentWorkouts` no compositor

**Arquivo:** `HybridWorkoutPlanComposer.swift`

```swift
private func fetchRecentWorkouts(limit: Int) async -> [WorkoutPlan] {
    guard let historyRepository = historyRepository else {
        return []
    }
    
    do {
        // Buscar últimas entradas de histórico
        let entries = try await historyRepository.listEntries(limit: limit, offset: 0)
        
        // Extrair WorkoutPlans das entries que tiverem
        let plans = entries.compactMap { $0.workoutPlan }
        
        #if DEBUG
        logger("Histórico carregado: \(entries.count) entradas, \(plans.count) com plano completo")
        #endif
        
        return plans
    } catch {
        logger("⚠️ Erro ao buscar histórico: \(error.localizedDescription)")
        return []
    }
}
```

**Resultado:** Agora o sistema consegue carregar os treinos anteriores completos e passá-los para a OpenAI para evitar repetição de exercícios! 🎉

---

### 2. Correção do Layout da Tela de Histórico

**Problema:** O header do histórico não estava seguindo os guidelines de design, e a listagem dos items não tinha espaçamento correto das bordas.

**Solução Implementada:**

#### A. Header das Seções Corrigido

**ANTES:**
```swift
Text(section.title)
    .font(.headline)
    .foregroundStyle(FitTodayColor.textPrimary)
    .padding(.horizontal)
    .padding(.vertical, FitTodaySpacing.xs)
```

**DEPOIS:**
```swift
Text(section.title)
    .font(.system(.subheadline, weight: .semibold))
    .foregroundStyle(FitTodayColor.textSecondary)
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, FitTodaySpacing.md)
    .padding(.top, FitTodaySpacing.lg)
    .padding(.bottom, FitTodaySpacing.sm)
    .background(FitTodayColor.background)
    .textCase(nil)
```

**Melhorias:**
- Fonte menor e mais sutil (`.subheadline` com `.semibold`)
- Cor secundária (`.textSecondary`) ao invés de primária
- Espaçamento superior maior (`.lg`)
- Alinhamento à esquerda explícito
- `.textCase(nil)` para evitar uppercase automático

#### B. Espaçamento dos Items Corrigido

**ANTES:**
```swift
LazyVStack(spacing: FitTodaySpacing.md, pinnedViews: [.sectionHeaders]) {
    ForEach(viewModel.sections) { section in
        Section {
            ForEach(section.entries) { entry in
                HistoryRow(entry: entry)
            }
        }
    }
}
.padding(.vertical)
```

**DEPOIS:**
```swift
LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
    ForEach(viewModel.sections) { section in
        Section {
            ForEach(section.entries) { entry in
                HistoryRow(entry: entry)
                    .padding(.horizontal, FitTodaySpacing.md)
                    .padding(.vertical, FitTodaySpacing.sm)
                
                // Divider entre items (exceto o último da seção)
                if entry.id != section.entries.last?.id {
                    Divider()
                        .padding(.leading, FitTodaySpacing.md)
                }
            }
        }
    }
}
```

**Melhorias:**
- Spacing zero no `LazyVStack` (controle manual de espaçamento)
- Padding horizontal (`FitTodaySpacing.md`) aplicado aos items
- Padding vertical (`FitTodaySpacing.sm`) para respiração
- Dividers entre items (exceto o último da seção)
- Divider com padding leading para alinhamento visual

#### C. Tipografia do HistoryRow Melhorada

**ANTES:**
```swift
Text(entry.title)
    .font(.headline)

Text("\(entry.focusTitle) • \(hourString)")
    .font(.subheadline)
```

**DEPOIS:**
```swift
Text(entry.title)
    .font(.system(.body, weight: .semibold))
    .foregroundStyle(FitTodayColor.textPrimary)

Text("\(entry.focusTitle) • \(hourString)")
    .font(.system(.subheadline))
    .foregroundStyle(FitTodayColor.textSecondary)
```

**Melhorias:**
- Título com `.body` + `.semibold` (mais consistente com o design system)
- Cores explícitas (`.textPrimary` e `.textSecondary`)
- Espaçamento interno reduzido (2pt ao invés de `.xxs`)

---

## Resultado Visual

### Antes
```
HOJE                          ← Header grande e escuro
Força Upper - 14:30           ← Sem padding nas bordas
Full body workout - 10:00
                              ← Muito espaçamento
ONTEM
...
```

### Depois
```
HOJE                          ← Header sutil e cinza, bem espaçado

  Força Upper - 14:30         ← Padding correto nas bordas
  Superior • 14:30            ← Tipografia melhorada
  ─────────────────────────   ← Divider entre items
  
  Full body workout - 10:00
  Full body • 10:00
  
ONTEM                         ← Espaçamento consistente

  Lower Strength - 09:15
  ...
```

---

## Arquivos Modificados

1. **`FitToday/FitToday/Data/Models/SDWorkoutHistoryEntry.swift`**
   - Adicionado `workoutPlanJSON: Data?`

2. **`FitToday/FitToday/Domain/Entities/HistoryModels.swift`**
   - Adicionado `workoutPlan: WorkoutPlan?`

3. **`FitToday/FitToday/Data/Mappers/WorkoutHistoryMapper.swift`**
   - Serialização e desserialização do `WorkoutPlan`

4. **`FitToday/FitToday/Domain/UseCases/WorkoutPlanUseCases.swift`**
   - Salvando `workoutPlan` no histórico

5. **`FitToday/FitToday/Data/Services/OpenAI/HybridWorkoutPlanComposer.swift`**
   - Implementado `fetchRecentWorkouts()` para extrair planos do histórico

6. **`FitToday/FitToday/Presentation/Features/History/HistoryView.swift`**
   - Layout do header corrigido
   - Espaçamento dos items corrigido
   - Dividers adicionados
   - Tipografia melhorada

---

## Build

✅ **BUILD SUCCEEDED** - 0 erros

---

## Próximos Passos (Teste Manual)

1. **Testar Persistência:**
   - Completar um treino
   - Fechar e reabrir o app
   - Gerar novo treino do mesmo tipo
   - **Verificar nos logs:** "Histórico carregado: 1 entradas, 1 com plano completo"

2. **Testar Layout:**
   - Navegar para a tela de Histórico
   - **Verificar:**
     - Headers com texto cinza e bem espaçados
     - Items com padding correto nas bordas
     - Dividers entre items
     - Tipografia consistente

---

**Data:** 09/01/2026
**Responsável:** AI Assistant
**Status:** ✅ Implementado e Buildado
