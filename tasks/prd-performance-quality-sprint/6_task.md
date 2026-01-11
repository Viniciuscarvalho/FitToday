# [6.0] Testing & Performance Audit (M)

## markdown

## status: pending

<task_context>
<domain>testing/performance</domain>
<type>testing</type>
<scope>quality_assurance</scope>
<complexity>medium</complexity>
<dependencies>all_previous_tasks</dependencies>
</task_context>

# Tarefa 6.0: Testing & Performance Audit

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

Consolidar e validar todas as implementações das Tasks 1-5 através de testes abrangentes e audit de performance com Instruments. Esta é a task final do sprint que garante qualidade, atingimento de targets de performance e ausência de regressões.

Focaremos em três pilares: **(1)** Atingir targets de cobertura de testes (Domain 80%, ViewModels 70%, Repos 60%), **(2)** Validar performance targets com Instruments, e **(3)** Documentar APIs públicas e atualizar README.

<requirements>
- Atingir targets de test coverage: Domain 80%+, ViewModels 70%+, Repositories 60%+
- Criar testes de integração para fluxos críticos end-to-end
- Validar performance targets com Instruments (todos < targets definidos)
- Zero memory leaks (Leaks instrument)
- Zero data races (Thread Sanitizer)
- Documentar APIs públicas com DocC comments
- Atualizar README.md com features novas
- Criar CHANGELOG.md entry para este sprint
- QA manual checklist completo
</requirements>

## Subtarefas

- [ ] 6.1 Atingir cobertura de testes: Domain 80%+
- [ ] 6.2 Atingir cobertura de testes: ViewModels 70%+
- [ ] 6.3 Atingir cobertura de testes: Repositories 60%+
- [ ] 6.4 Criar testes de integração para fluxos críticos
- [ ] 6.5 Performance audit com Instruments (todos targets validados)
- [ ] 6.6 Memory leaks audit (Leaks + Allocations)
- [ ] 6.7 Thread safety audit (Thread Sanitizer)
- [ ] 6.8 Documentar APIs públicas (DocC comments)
- [ ] 6.9 Atualizar README.md e CHANGELOG.md
- [ ] 6.10 QA manual em device real (checklist completo)

## Detalhes de Implementação

### Referência Completa

Ver [`techspec.md`](techspec.md) seções:
- "Abordagem de Testes" - Estratégia geral
- "Requisitos Especiais" → "Performance Targets" - Métricas a validar
- "Conformidade com Padrões" → Performance - Como usar Instruments

### 1. Test Coverage Targets

**Domain Layer (Target: 80%+)**

Priority tests:
- `ImageCacheService` - todos métodos (cache, prefetch, eviction)
- `DiskImageCache` - actor methods, LRU eviction
- `ErrorMapper` - todos error types mapeados
- `WorkoutPlan.extractImageURLs()` - extension

**ViewModels (Target: 70%+)**

Priority tests:
- `HomeViewModel` - load, error handling, state transitions
- `DailyQuestionnaireViewModel` - validation, generation
- `HistoryViewModel` - pagination, load more

**Repositories (Target: 60%+)**

Priority tests:
- `SwiftDataWorkoutHistoryRepository` - pagination, count
- Migration tests

### 2. Integration Tests (Critical Paths)

**Test 1: Workout Generation End-to-End**

```swift
@Suite("Workout Generation Integration")
struct WorkoutGenerationIntegrationTests {
  
  @Test("Complete flow: questionnaire → generation → cache images")
  @MainActor
  func testCompleteWorkoutFlow() async throws {
    // Setup
    let container = AppContainer.build()
    let questionnaireVM = container.resolve(DailyQuestionnaireViewModel.self)!
    let imageCacheService = container.resolve(ImageCaching.self)!
    
    // Step 1: Fill questionnaire
    questionnaireVM.selectFocus(.fullBody)
    questionnaireVM.selectSoreness(.light)
    
    // Step 2: Generate workout
    await questionnaireVM.generateWorkout()
    
    // Verify: Workout generated
    #expect(questionnaireVM.generatedPlan != nil)
    
    // Step 3: Images prefetched
    let imageURLs = questionnaireVM.generatedPlan?.extractImageURLs() ?? []
    #expect(imageURLs.count > 0)
    
    // Wait for prefetch
    try? await Task.sleep(for: .seconds(5))
    
    // Verify: Images cached
    for url in imageURLs {
      let cached = await imageCacheService.cachedImage(for: url)
      #expect(cached != nil, "Image should be cached: \(url)")
    }
  }
}
```

**Test 2: Offline Mode**

```swift
@Test("App works offline after first use")
@MainActor
func testOfflineMode() async throws {
  // Prerequisite: Run online first to cache data
  let container = AppContainer.build()
  
  // Generate workout online
  let vm = container.resolve(DailyQuestionnaireViewModel.self)!
  await vm.generateWorkout()
  
  // Simulate offline (mock URLSession to fail)
  MockURLProtocol.simulateOffline = true
  
  // Navigate to workout
  let sessionStore = container.resolve(WorkoutSessionStore.self)!
  sessionStore.start(with: vm.generatedPlan!)
  
  // Verify: Images load from cache
  let exercises = sessionStore.exercises
  for exercise in exercises {
    if let url = exercise.exercise.media?.gifURL {
      let cached = await imageCacheService.cachedImage(for: url)
      #expect(cached != nil, "Offline: image should load from cache")
    }
  }
}
```

**Test 3: Error Handling Flow**

```swift
@Test("Errors show user-friendly messages")
@MainActor
func testErrorHandlingFlow() async throws {
  let vm = HomeViewModel(
    profileRepo: MockProfileRepository(shouldFail: true)
  )
  
  await vm.loadUserData()
  
  // Verify: Error message set
  #expect(vm.errorMessage != nil)
  
  // Verify: No technical jargon
  #expect(!vm.errorMessage!.message.contains("URLError"))
  #expect(!vm.errorMessage!.message.contains("-1009"))
  
  // Verify: Action available
  #expect(vm.errorMessage!.action != nil)
}
```

**Test 4: History Pagination**

```swift
@Test("History pagination works correctly")
@MainActor
func testHistoryPagination() async throws {
  // Setup: 50 entries in database
  let container = try ModelContainer.populateWithTestData(count: 50)
  let repo = SwiftDataWorkoutHistoryRepository(modelContainer: container)
  let vm = HistoryViewModel(historyRepository: repo)
  
  // Load first page
  await vm.loadInitialHistory()
  #expect(vm.entries.count == 20) // Page size
  
  // Simulate scroll to end
  await vm.loadMoreIfNeeded(currentEntry: vm.entries.last!)
  
  // Wait for load
  try? await Task.sleep(for: .milliseconds(100))
  
  // Verify: More entries loaded
  #expect(vm.entries.count == 40)
  
  // Load last page
  await vm.loadMoreIfNeeded(currentEntry: vm.entries.last!)
  try? await Task.sleep(for: .milliseconds(100))
  
  // Verify: All 50 loaded
  #expect(vm.entries.count == 50)
  #expect(vm.hasMorePages == false)
}
```

### 3. Performance Audit with Instruments

**Targets to Validate:**

| Métrica | Target | Como Medir |
|---------|--------|------------|
| Image cache hit | < 50ms | Time Profiler |
| Prefetch completo (10 imgs) | < 15s | Manual timing |
| History load (20 items) | < 100ms | SwiftData profiler |
| Error presentation | < 16ms (1 frame) | SwiftUI instrument |
| App launch | < 2s cold start | App Launch template |

**Steps to Profile:**

1. **Build for Profiling**
   - Product → Profile (Cmd+I)
   - Select Release configuration

2. **Time Profiler**
   - Record 30s of typical usage
   - Look for hot spots > 10ms
   - Validate cache hit < 50ms

3. **SwiftData Profiler**
   - Open History view
   - Record fetch operations
   - Validate fetch < 100ms

4. **SwiftUI Instrument**
   - Record View rendering
   - Check "Long View Body Updates"
   - Validate < 16ms per frame

5. **Leaks Instrument**
   - Record 2-3 minutes
   - Navigate all screens
   - Verify 0 leaks

6. **Thread Sanitizer**
   - Enable in scheme: Edit Scheme → Run → Diagnostics → Thread Sanitizer
   - Run app normally
   - Verify 0 data races

### 4. DocC Documentation

**Document public APIs:**

```swift
/// Service responsible for caching exercise images with hybrid memory/disk strategy.
///
/// `ImageCacheService` provides a two-layer caching mechanism:
/// 1. **Memory Cache (URLCache)**: Fast access, 50MB limit
/// 2. **Disk Cache**: Persistent storage, 500MB limit
///
/// ## Usage
///
/// ```swift
/// let service = ImageCacheService(configuration: .default)
///
/// // Cache single image
/// try await service.cacheImage(from: exerciseURL)
///
/// // Prefetch multiple images
/// await service.prefetchImages(workoutImageURLs)
///
/// // Retrieve cached image
/// if let image = await service.cachedImage(for: url) {
///   // Use image
/// }
/// ```
///
/// ## Performance
///
/// - Cache hit: < 50ms
/// - Cache miss: depends on network, doesn't block UI
/// - Prefetch: máx 5 concurrent downloads
///
/// - Note: Images survive app restarts (disk cache)
/// - Warning: Cache can grow to 500MB. Use `clearCache()` if needed.
public final class ImageCacheService: ImageCaching {
  // ...
}
```

**Document protocols:**

```swift
/// Protocol for ViewModels that present errors to users.
///
/// Adopt this protocol to get automatic error handling with user-friendly messages.
///
/// ## Usage
///
/// ```swift
/// class MyViewModel: ObservableObject, ErrorPresenting {
///   @Published var errorMessage: ErrorMessage?
///
///   func loadData() async {
///     do {
///       try await repository.fetch()
///     } catch {
///       handleError(error) // Provided by protocol
///     }
///   }
/// }
/// ```
///
/// ## Error Messages
///
/// Technical errors are automatically mapped to user-friendly Portuguese messages.
/// See `ErrorMapper` for details.
public protocol ErrorPresenting: AnyObject {
  var errorMessage: ErrorMessage? { get set }
  func handleError(_ error: Error)
}
```

### 5. README Update

**Add section:**

```markdown
## ✨ Novas Features (v1.1)

### 🚀 Performance

- **Cache de Imagens**: Todas as imagens de exercícios são cacheadas localmente após primeiro uso
- **Modo Offline**: App funciona 100% offline após primeiro treino
- **Histórico Otimizado**: Carregamento instantâneo mesmo com 200+ treinos

### 💬 Error Handling

- **Mensagens Claras**: Todos os erros mostram mensagens em português amigável
- **Ações de Recuperação**: Botões para tentar novamente ou abrir configurações
- **Zero Jargão Técnico**: Sem mais "URLError -1009"

### 📊 Melhorias Técnicas

- Índices em SwiftData para queries 10x mais rápidas
- Paginação lazy no histórico
- Prefetch inteligente de imagens
- Arquitetura preparada para Apple Watch (próxima versão)

## 🧪 Testing

```bash
# Run all tests
xcodebuild test -scheme FitToday -destination 'platform=iOS Simulator,name=iPhone 15'

# Test coverage report
xcodebuild test -scheme FitToday -enableCodeCoverage YES
```

**Coverage Targets:**
- Domain: 80%+
- Presentation: 70%+
- Data: 60%+
```

### 6. CHANGELOG Entry

```markdown
# Changelog

## [1.1.0] - 2026-01-XX

### Added
- Image caching system with hybrid memory/disk storage
- Offline support for workout execution
- User-friendly error messages with recovery actions
- Paginated history with lazy loading
- Performance optimizations for SwiftData queries

### Changed
- History view now loads 20 items at a time (was: all at once)
- Error messages now in Portuguese (was: technical English)
- Images load from cache first (was: always from network)

### Performance
- Image cache hit: < 50ms (10x faster)
- History load: < 100ms for 20 items (5x faster with 100+ entries)
- Prefetch: 10 images in < 15s
- App works offline after first use

### Fixed
- Memory leak in image loading
- Slow history loading with 100+ workouts
- Confusing error messages ("URLError -1009")
- Images not loading in airplane mode

### Technical
- Added SwiftData indices on `completedAt` and `status`
- Implemented LRU eviction policy for disk cache
- ErrorPresenting protocol for consistent error handling
- Thread-safe image cache with actors
```

### 7. QA Manual Checklist

**Pre-flight:**
- [ ] Build succeeds without warnings
- [ ] All tests pass
- [ ] Code coverage targets met

**Image Caching:**
- [ ] Generate workout → wait for "Preparando treino..."
- [ ] Images appear instantly on second view
- [ ] Enable Airplane Mode → images still load
- [ ] Clear cache in Settings → images re-download

**Error Handling:**
- [ ] Disable WiFi → see "Sem conexão" message
- [ ] Tap "Abrir Configurações" → Settings opens
- [ ] Force API timeout → see user-friendly message
- [ ] All toasts auto-dismiss after 4s

**History Performance:**
- [ ] Navigate to History with 50+ entries → loads quickly
- [ ] Scroll to bottom → more entries load
- [ ] Pull to refresh → reloads from top
- [ ] Delete entry → updates immediately

**Offline Mode:**
- [ ] Generate workout online
- [ ] Enable Airplane Mode
- [ ] Open workout → all images load
- [ ] Navigate between exercises → no errors
- [ ] Try to generate new workout → clear error message

**Accessibility:**
- [ ] VoiceOver announces error toasts
- [ ] Dynamic Type works (test at accessibility5)
- [ ] Reduced Motion disables animations
- [ ] High Contrast maintains readability

**Memory & Stability:**
- [ ] Use app for 5 minutes → no memory warnings
- [ ] Navigate all screens → no crashes
- [ ] Force quit → data persists on relaunch
- [ ] Run Thread Sanitizer → no data races

## Critérios de Sucesso

### Test Coverage
- ✅ Domain layer: 80%+ coverage
- ✅ ViewModels: 70%+ coverage
- ✅ Repositories: 60%+ coverage
- ✅ All integration tests pass
- ✅ Zero flaky tests

### Performance
- ✅ All targets met (validated with Instruments)
- ✅ No regressions from baseline
- ✅ 60fps scroll in all lists
- ✅ < 2s cold app launch

### Quality
- ✅ Zero memory leaks
- ✅ Zero data races
- ✅ Zero compiler warnings
- ✅ All QA checklist items pass

### Documentation
- ✅ Public APIs documented with DocC
- ✅ README updated
- ✅ CHANGELOG entry created
- ✅ Code review approved

## Dependências

**Bloqueante:** Tasks 1-5 devem estar completas.

**Tools necessários:**
- Xcode 15.2+ (Swift Testing, Instruments)
- iOS 17+ device para testing real
- Instruments app

## Observações

### Test Coverage Tools

**Generate coverage report:**

```bash
xcodebuild test \
  -scheme FitToday \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -enableCodeCoverage YES \
  -derivedDataPath DerivedData

# View report
xcrun xccov view --report DerivedData/Logs/Test/*.xcresult
```

**View in Xcode:**
1. Product → Test (Cmd+U)
2. View → Navigators → Show Report Navigator (Cmd+9)
3. Select test run → Coverage tab

### Instruments Best Practices

**DO:**
- ✅ Profile in Release configuration
- ✅ Profile on real device (performance realistic)
- ✅ Record 30-60s of typical usage
- ✅ Focus on hot spots (> 10ms)

**DON'T:**
- ❌ Profile in Debug (não representativo)
- ❌ Profile apenas em Simulator (muito rápido)
- ❌ Record > 5 minutes (arquivo enorme)
- ❌ Optimize prematuramente

### Memory Leak Debugging

**Common sources:**
- Retain cycles in closures (`[weak self]` missing)
- Observers not removed (`deinit` missing)
- Strong references in delegates

**Use Leaks instrument:**
1. Record session
2. Look for red bars (leaks detected)
3. Inspect stack trace
4. Fix retain cycle

### Thread Sanitizer

**Enable:**
- Edit Scheme → Run → Diagnostics
- Check "Thread Sanitizer"

**Common issues:**
- Shared mutable state without actors/locks
- Race conditions in @Published properties
- Concurrent access to collections

### Documentation Guidelines

**DocC format:**

```swift
/// Brief description (one line)
///
/// Detailed explanation (multiple paragraphs OK)
///
/// ## Section Title
///
/// More details...
///
/// - Parameter name: Description
/// - Returns: What it returns
/// - Throws: What errors can be thrown
/// - Note: Additional info
/// - Warning: Critical information
public func method(name: String) throws -> Result { }
```

### Performance Regression Prevention

**Baseline metrics (before this sprint):**
- App launch: ~3s
- History load (20 items): ~300ms
- Image load: Network-dependent, no cache

**After this sprint:**
- App launch: < 2s (33% faster)
- History load (20 items): < 100ms (3x faster)
- Image load: < 50ms from cache (10x+ faster)

**Monitor in CI:**
```yaml
# .github/workflows/performance.yml
- name: Performance Test
  run: |
    xcodebuild test -scheme FitToday \
      -testPlan PerformanceTests
    # Fail if > 10% regression
```

### Future Testing Enhancements (Out of Scope)

- ❌ UI testing (XCUITest)
- ❌ Snapshot testing
- ❌ Load testing (stress test)
- ❌ A/B testing infrastructure

## Arquivos relevantes

### Criar (novos arquivos)

```
FitTodayTests/Integration/
├── WorkoutGenerationFlowTests.swift  (~100 linhas)
├── OfflineModeTests.swift            (~80 linhas)
└── ErrorHandlingFlowTests.swift      (~60 linhas)

Documentation/
├── CHANGELOG.md                      (adicionar entry v1.1)
└── PERFORMANCE.md                    (opcional - metrics baseline)
```

### Modificar (existentes)

```
README.md                             (adicionar seção Features v1.1)
FitToday.xcodeproj                    (code coverage settings)
FitTodayTests/                        (adicionar testes faltantes)
```

### Test Files to Expand

**Already exist, need more coverage:**

```
FitTodayTests/Data/Services/
├── ImageCacheServiceTests.swift      (expand to 90%+ coverage)
├── ErrorPresentingTests.swift        (add more scenarios)
└── WorkoutHistoryRepositoryTests.swift (add pagination tests)

FitTodayTests/Presentation/
├── HomeViewModelTests.swift          (add error scenarios)
├── DailyQuestionnaireViewModelTests.swift
└── HistoryViewModelTests.swift       (pagination edge cases)
```

### Estimativa de Tempo

- **6.1-6.3** Atingir coverage targets: 4h
- **6.4** Integration tests: 2h
- **6.5** Performance audit: 2h
- **6.6** Memory leaks audit: 1h
- **6.7** Thread safety audit: 1h
- **6.8** Documentation: 1.5h
- **6.9** README/CHANGELOG: 1h
- **6.10** QA manual: 1.5h

**Total: ~14 horas (1.5 dias de trabalho)**

### Checklist de Finalização

- [ ] All tests pass
- [ ] Coverage targets met
- [ ] Performance targets validated
- [ ] Zero memory leaks
- [ ] Zero data races
- [ ] Zero warnings
- [ ] Documentation complete
- [ ] README updated
- [ ] CHANGELOG updated
- [ ] QA checklist complete
- [ ] Code review approved
- [ ] Ready for production deploy 🚀

