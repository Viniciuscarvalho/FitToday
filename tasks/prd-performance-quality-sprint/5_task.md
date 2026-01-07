# [5.0] Otimizar queries SwiftData (M)

## markdown

## status: completed

<task_context>
<domain>data/repositories</domain>
<type>implementation</type>
<scope>performance</scope>
<complexity>medium</complexity>
<dependencies>none</dependencies>
</task_context>

# Tarefa 5.0: Otimizar Queries SwiftData

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

Otimizar performance de queries SwiftData através de dois pilares: **(1)** adicionar índices em campos frequentemente consultados (`completedAt`, `status`) transformando queries O(n) em O(log n), e **(2)** implementar paginação lazy no `HistoryView` para evitar carregar todo histórico de uma vez.

Esta otimização é crítica à medida que usuários acumulam 50, 100, 200+ treinos no histórico. Sem índices e paginação, a tela de histórico fica progressivamente mais lenta.

<requirements>
- Adicionar @Attribute(.indexed) em SDWorkoutHistoryEntry: completedAt, status
- Testar migration de SwiftData (dados existentes devem migrar sem perda)
- Implementar fetchHistory(limit:offset:) no repository
- Implementar fetchHistoryCount() para total de entradas
- Refatorar HistoryView com LazyVStack e scroll infinito
- Loading indicator no final da lista durante load
- Performance target: < 100ms para carregar 20 itens
- Validar com Instruments (SwiftData profiler)
- Fallback graceful se migration falhar
</requirements>

## Subtarefas

- [ ] 5.1 Adicionar índices (@Attribute(.indexed)) em SDWorkoutHistoryEntry
- [ ] 5.2 Implementar métodos paginados no WorkoutHistoryRepository
- [ ] 5.3 Criar extension WorkoutHistoryRepository com fetchHistoryCount()
- [ ] 5.4 Refatorar HistoryViewModel para paginação (limit/offset state)
- [ ] 5.5 Refatorar HistoryView com LazyVStack e onAppear trigger
- [ ] 5.6 Adicionar loading indicator no scroll infinito
- [ ] 5.7 Testar migration com dados existentes (test database)
- [ ] 5.8 Performance testing com Instruments (SwiftData profiler)

## Detalhes de Implementação

### Referência Completa

Ver [`techspec.md`](techspec.md) seções:
- "Modelos de Dados" → "SwiftData Models (Modificações)"
- "Interface 5: WorkoutHistoryRepository (Paginated)"
- "Decisão 4: SwiftData Índices" - Justificativa técnica

### 1. Adicionar Índices

**File:** `Data/Models/SDWorkoutHistoryEntry.swift`

**Before:**

```swift
@Model
final class SDWorkoutHistoryEntry {
  @Attribute(.unique) var id: UUID
  var completedAt: Date
  var status: String
  var planTitle: String
  var focusRawValue: String
  var durationMinutes: Int
  var intensityRawValue: String
  
  // ... init
}
```

**After:**

```swift
@Model
final class SDWorkoutHistoryEntry {
  @Attribute(.unique) var id: UUID
  @Attribute(.indexed) var completedAt: Date  // ← ÍNDICE ADICIONADO
  @Attribute(.indexed) var status: String     // ← ÍNDICE ADICIONADO
  var planTitle: String
  var focusRawValue: String
  var durationMinutes: Int
  var intensityRawValue: String
  
  init(
    id: UUID,
    completedAt: Date,
    status: String,
    planTitle: String,
    focusRawValue: String,
    durationMinutes: Int,
    intensityRawValue: String
  ) {
    self.id = id
    self.completedAt = completedAt
    self.status = status
    self.planTitle = planTitle
    self.focusRawValue = focusRawValue
    self.durationMinutes = durationMinutes
    self.intensityRawValue = intensityRawValue
  }
}
```

### 2. Repository com Paginação

**File:** `Data/Repositories/SwiftDataWorkoutHistoryRepository.swift`

**Add paginated methods:**

```swift
final class SwiftDataWorkoutHistoryRepository: WorkoutHistoryRepository {
  private let modelContainer: ModelContainer
  
  init(modelContainer: ModelContainer) {
    self.modelContainer = modelContainer
  }
  
  // NOVO: Fetch com paginação
  @MainActor
  func fetchHistory(
    limit: Int,
    offset: Int
  ) async throws -> [WorkoutHistoryEntry] {
    let context = ModelContext(modelContainer)
    
    var descriptor = FetchDescriptor<SDWorkoutHistoryEntry>(
      sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
    )
    descriptor.fetchLimit = limit
    descriptor.fetchOffset = offset
    
    let entries = try context.fetch(descriptor)
    return entries.map { WorkoutHistoryMapper.toDomain($0) }
  }
  
  // NOVO: Count total
  @MainActor
  func fetchHistoryCount() async throws -> Int {
    let context = ModelContext(modelContainer)
    let descriptor = FetchDescriptor<SDWorkoutHistoryEntry>()
    return try context.fetchCount(descriptor)
  }
  
  // Existing: Save entry
  @MainActor
  func saveEntry(_ entry: WorkoutHistoryEntry) async throws {
    let context = ModelContext(modelContainer)
    let sdEntry = WorkoutHistoryMapper.toSwiftData(entry)
    context.insert(sdEntry)
    try context.save()
  }
  
  // Existing: Fetch all (deprecated, use paginated version)
  @available(*, deprecated, message: "Use fetchHistory(limit:offset:) instead")
  @MainActor
  func fetchAllHistory() async throws -> [WorkoutHistoryEntry] {
    let context = ModelContext(modelContainer)
    let descriptor = FetchDescriptor<SDWorkoutHistoryEntry>(
      sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
    )
    let entries = try context.fetch(descriptor)
    return entries.map { WorkoutHistoryMapper.toDomain($0) }
  }
}
```

### 3. HistoryViewModel com Paginação

**File:** `Presentation/Features/History/HistoryViewModel.swift`

**Refactor to support pagination:**

```swift
@MainActor
final class HistoryViewModel: ObservableObject, ErrorPresenting {
  @Published var entries: [WorkoutHistoryEntry] = []
  @Published var isLoading = false
  @Published var isLoadingMore = false
  @Published var hasMorePages = true
  @Published var errorMessage: ErrorMessage?
  
  private let historyRepository: WorkoutHistoryRepository
  private let pageSize = 20
  private var currentOffset = 0
  
  init(historyRepository: WorkoutHistoryRepository) {
    self.historyRepository = historyRepository
  }
  
  func loadInitialHistory() async {
    // Reset state
    entries = []
    currentOffset = 0
    hasMorePages = true
    
    await loadHistory()
  }
  
  func loadMoreIfNeeded(currentEntry: WorkoutHistoryEntry) async {
    // Trigger load more when scrolling near the end
    guard !isLoadingMore && hasMorePages else { return }
    
    let thresholdIndex = entries.count - 5 // Load more 5 items before the end
    if let index = entries.firstIndex(where: { $0.id == currentEntry.id }),
       index >= thresholdIndex {
      await loadHistory()
    }
  }
  
  private func loadHistory() async {
    guard !isLoadingMore else { return }
    
    if currentOffset == 0 {
      isLoading = true
    } else {
      isLoadingMore = true
    }
    
    defer {
      isLoading = false
      isLoadingMore = false
    }
    
    do {
      let newEntries = try await historyRepository.fetchHistory(
        limit: pageSize,
        offset: currentOffset
      )
      
      if newEntries.isEmpty {
        hasMorePages = false
      } else {
        entries.append(contentsOf: newEntries)
        currentOffset += newEntries.count
      }
    } catch {
      handleError(error) // ErrorPresenting
    }
  }
  
  func refresh() async {
    await loadInitialHistory()
  }
}
```

### 4. HistoryView com Scroll Infinito

**File:** `Presentation/Features/History/HistoryView.swift`

**Refactor to lazy loading:**

```swift
struct HistoryView: View {
  @StateObject var viewModel: HistoryViewModel
  
  var body: some View {
    Group {
      if viewModel.isLoading && viewModel.entries.isEmpty {
        ProgressView("Carregando histórico...")
      } else if viewModel.entries.isEmpty {
        emptyStateView
      } else {
        historyList
      }
    }
    .navigationTitle("Histórico")
    .task {
      await viewModel.loadInitialHistory()
    }
    .refreshable {
      await viewModel.refresh()
    }
    .errorToast(errorMessage: $viewModel.errorMessage)
  }
  
  private var historyList: some View {
    ScrollView {
      LazyVStack(spacing: FitTodaySpacing.md) {
        ForEach(viewModel.entries) { entry in
          HistoryEntryCard(entry: entry)
            .onAppear {
              // Trigger pagination
              Task {
                await viewModel.loadMoreIfNeeded(currentEntry: entry)
              }
            }
        }
        
        // Loading indicator at bottom
        if viewModel.isLoadingMore {
          ProgressView()
            .padding()
        }
        
        // End of list message
        if !viewModel.hasMorePages && !viewModel.entries.isEmpty {
          Text("Você viu todos os treinos")
            .font(.system(.caption))
            .foregroundStyle(FitTodayColor.textTertiary)
            .padding()
        }
      }
      .padding()
    }
  }
  
  private var emptyStateView: some View {
    VStack(spacing: FitTodaySpacing.md) {
      Image(systemName: "calendar.badge.exclamationmark")
        .font(.system(size: 60))
        .foregroundStyle(FitTodayColor.textTertiary)
      
      Text("Nenhum treino registrado")
        .font(.system(.title3, weight: .semibold))
        .foregroundStyle(FitTodayColor.textPrimary)
      
      Text("Complete seu primeiro treino para ver o histórico")
        .font(.system(.body))
        .foregroundStyle(FitTodayColor.textSecondary)
        .multilineTextAlignment(.center)
    }
    .padding()
  }
}
```

### 5. Migration Testing

**Test migration with existing data:**

```swift
@Suite("SwiftData Migration Tests")
struct MigrationTests {
  
  @Test("Migration adds indices without data loss")
  @MainActor
  func testMigration() async throws {
    // 1. Create old schema container (without indices)
    let oldSchema = Schema([
      OldSDWorkoutHistoryEntry.self
    ])
    let oldContainer = try ModelContainer(
      for: oldSchema,
      configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
    )
    
    // 2. Insert test data
    let context = ModelContext(oldContainer)
    for i in 0..<50 {
      let entry = OldSDWorkoutHistoryEntry(
        id: UUID(),
        completedAt: Date().addingTimeInterval(TimeInterval(-i * 86400)),
        status: i % 2 == 0 ? "completed" : "skipped",
        planTitle: "Workout \(i)",
        focusRawValue: "fullBody",
        durationMinutes: 45,
        intensityRawValue: "moderate"
      )
      context.insert(entry)
    }
    try context.save()
    
    // 3. Create new schema container (with indices)
    let newSchema = Schema([
      SDWorkoutHistoryEntry.self
    ])
    let newContainer = try ModelContainer(
      for: newSchema,
      configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
    )
    
    // 4. Verify data migrated
    let newContext = ModelContext(newContainer)
    let descriptor = FetchDescriptor<SDWorkoutHistoryEntry>()
    let entries = try newContext.fetch(descriptor)
    
    #expect(entries.count == 50)
    
    // 5. Verify indexed queries are fast
    let start = Date()
    var indexedDescriptor = FetchDescriptor<SDWorkoutHistoryEntry>(
      predicate: #Predicate { $0.completedAt > Date().addingTimeInterval(-7 * 86400) }
    )
    indexedDescriptor.sortBy = [SortDescriptor(\.completedAt, order: .reverse)]
    let recentEntries = try newContext.fetch(indexedDescriptor)
    let duration = Date().timeIntervalSince(start)
    
    #expect(duration < 0.1) // Should be fast with index
    #expect(recentEntries.count == 7)
  }
}
```

### 6. Performance Benchmarking

**Measure query performance:**

```swift
import Testing

@Suite("SwiftData Performance Tests")
struct PerformanceTests {
  
  @Test("Indexed query is faster than full scan", .timeLimit(.seconds(5)))
  @MainActor
  func testIndexedQueryPerformance() async throws {
    let container = try ModelContainer.testContainer()
    let context = ModelContext(container)
    
    // Insert 1000 entries
    for i in 0..<1000 {
      let entry = SDWorkoutHistoryEntry(
        id: UUID(),
        completedAt: Date().addingTimeInterval(TimeInterval(-i * 3600)),
        status: "completed",
        planTitle: "Workout \(i)",
        focusRawValue: "fullBody",
        durationMinutes: 45,
        intensityRawValue: "moderate"
      )
      context.insert(entry)
    }
    try context.save()
    
    // Measure indexed query
    let start = Date()
    var descriptor = FetchDescriptor<SDWorkoutHistoryEntry>(
      sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
    )
    descriptor.fetchLimit = 20
    let entries = try context.fetch(descriptor)
    let duration = Date().timeIntervalSince(start)
    
    print("[Performance] Query 20 of 1000: \(duration * 1000)ms")
    
    #expect(duration < 0.1) // Target: < 100ms
    #expect(entries.count == 20)
  }
}
```

### 7. Fallback para Migration Failure

**In AppContainer:**

```swift
extension AppContainer {
  static func buildModelContainer() -> ModelContainer {
    let schema = Schema([
      SDUserProfile.self,
      SDWorkoutHistoryEntry.self,
      SDProEntitlementSnapshot.self
    ])
    
    let config = ModelConfiguration(
      schema: schema,
      isStoredInMemoryOnly: false
    )
    
    do {
      let container = try ModelContainer(for: schema, configurations: [config])
      return container
    } catch {
      print("[Migration] Failed: \(error)")
      
      // Show alert to user (future task)
      // For now, crash gracefully with explanation
      fatalError("""
        Failed to migrate database.
        Please contact support or reinstall the app.
        Error: \(error)
        """)
    }
  }
}
```

## Critérios de Sucesso

### Performance
- ✅ Query de 20 itens completa em < 100ms (target principal)
- ✅ Query de 100 itens completa em < 200ms
- ✅ Scroll suave (60fps) mesmo com 200+ entradas
- ✅ Memory usage constante (paginação funciona)

### Funcionalidade
- ✅ Paginação carrega 20 itens por vez
- ✅ Scroll infinito funciona (trigger próximo ao fim)
- ✅ Loading indicator aparece durante load more
- ✅ "Você viu todos os treinos" aparece no final
- ✅ Pull-to-refresh recarrega do início

### Migration
- ✅ Dados existentes migram sem perda
- ✅ Índices adicionados corretamente
- ✅ Queries antigas ainda funcionam (backwards compatible)
- ✅ Fallback graceful se migration falhar

### Testing
- ✅ Testes de migration passam
- ✅ Testes de performance validam < 100ms
- ✅ Validado com Instruments (SwiftData profiler)

## Dependências

**Nenhuma** - Task independente, pode ser desenvolvida em paralelo com outras.

**Frameworks:**
- SwiftData (built-in iOS 17+)
- Testing (Swift Testing, se disponível)

## Observações

### SwiftData Index Types

SwiftData suporta 3 tipos de índices:

1. **`.unique`** - Garante unicidade (já usado em `id`)
2. **`.indexed`** - Index B-tree para queries rápidas (nosso caso)
3. **`.spotlight`** - Integration com Spotlight (não necessário)

### Query Optimization Tips

**DO:**
- ✅ Use `fetchLimit` e `fetchOffset` para paginação
- ✅ Use índices em campos filtrados/sorted
- ✅ Use `@MainActor` em métodos que acessam ModelContext

**DON'T:**
- ❌ Fetch all entries sem limit (escalabilidade)
- ❌ Sort in-memory (deixe SwiftData fazer)
- ❌ Multiple contexts sem sync (data races)

### Memory Management

**Pagination benefits:**
- Apenas 20 entries em memória por vez
- SwiftData fault objects automaticamente
- Scroll infinito carrega sob demanda

**Before (all entries):**
```
Memory: 50 entries × ~1KB = ~50KB
```

**After (paginated):**
```
Memory: 20 entries × ~1KB = ~20KB (60% reduction)
```

### Instruments Profiling

**Steps to profile:**

1. Open Instruments (Cmd+I)
2. Select "SwiftData" template
3. Record while scrolling history
4. Look for:
   - Fetch duration < 100ms
   - No redundant fetches
   - Minimal faulting (cache working)

**Metrics to check:**
- Fetch Count (should be low)
- Fetch Duration (< 100ms target)
- Fault Rate (< 10% of fetches)

### Migration Scenarios

**Scenario 1: Fresh install**
- No migration needed
- Indices created on first run

**Scenario 2: Existing data (no history)**
- Migration is lightweight
- Only schema changes

**Scenario 3: Existing data (100+ entries)**
- Migration rebuilds indices
- May take 1-2 seconds
- Should be transparent to user

### Fallback Strategy

If migration fails:

1. Log detailed error
2. Show user-friendly alert
3. Offer options:
   - Reset data (destructive)
   - Contact support
   - Continue without history (read-only mode)

### Testing with Large Datasets

**Generate test data:**

```swift
extension ModelContainer {
  @MainActor
  static func populateWithTestData(count: Int) throws -> ModelContainer {
    let container = try testContainer()
    let context = ModelContext(container)
    
    for i in 0..<count {
      let entry = SDWorkoutHistoryEntry(
        id: UUID(),
        completedAt: Date().addingTimeInterval(TimeInterval(-i * 3600)),
        status: ["completed", "skipped"].randomElement()!,
        planTitle: "Test Workout \(i)",
        focusRawValue: DailyFocus.allCases.randomElement()!.rawValue,
        durationMinutes: Int.random(in: 30...60),
        intensityRawValue: WorkoutIntensity.allCases.randomElement()!.rawValue
      )
      context.insert(entry)
    }
    
    try context.save()
    return container
  }
}

// Usage in tests:
let container = try ModelContainer.populateWithTestData(count: 500)
```

### Future Optimizations (Out of Scope)

- ❌ Compound indices (ex: status + completedAt)
- ❌ Virtual scrolling (recycle cells)
- ❌ Aggressive prefetching (next page)
- ❌ Custom caching layer above SwiftData

## Arquivos relevantes

### Modificar (existentes)

```
FitToday/FitToday/Data/Models/
└── SDWorkoutHistoryEntry.swift  (~5 linhas modificadas - add indices)

FitToday/FitToday/Data/Repositories/
└── SwiftDataWorkoutHistoryRepository.swift  (~50 linhas adicionadas - pagination)

FitToday/FitToday/Presentation/Features/History/
├── HistoryViewModel.swift       (~60 linhas modificadas - pagination state)
└── HistoryView.swift            (~40 linhas modificadas - lazy loading)

FitToday/FitToday/Presentation/DI/
└── AppContainer.swift           (~10 linhas modificadas - migration handling)
```

### Criar (novos arquivos - opcional)

```
FitTodayTests/Data/
└── SwiftDataMigrationTests.swift  (~100 linhas - migration tests)
```

### Estimativa de Tempo

- **5.1** Adicionar índices: 30 min
- **5.2** Repository pagination: 2h
- **5.3** fetchHistoryCount: 30 min
- **5.4** HistoryViewModel refactor: 2h
- **5.5** HistoryView LazyVStack: 1.5h
- **5.6** Loading indicators: 30 min
- **5.7** Migration testing: 1.5h
- **5.8** Performance profiling: 1h

**Total: ~9.5 horas (1 dia de trabalho)**

### Checklist de Finalização

- [ ] Índices adicionados e app compila
- [ ] Paginação implementada e testada
- [ ] Scroll infinito funciona suavemente
- [ ] Performance < 100ms validada
- [ ] Migration testada com dados existentes
- [ ] Instruments profiling completo
- [ ] Memory leaks verificados
- [ ] Code review aprovado
- [ ] Documentation atualizada

