# [4.0] Implementar error handling nos ViewModels (L)

## markdown

## status: completed

<task_context>
<domain>presentation/features</domain>
<type>integration</type>
<scope>core_feature</scope>
<complexity>high</complexity>
<dependencies>error-handling-infrastructure</dependencies>
</task_context>

# Tarefa 4.0: Implementar Error Handling nos ViewModels

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

Adotar o protocol `ErrorPresenting` criado na Task 2.0 em todos os ViewModels principais do app, substituindo tratamento de erro ad-hoc e inconsistente por apresentação padronizada com `ErrorToastView`. Esta task garante que 100% dos erros mostrem mensagens user-friendly e ações de recuperação claras.

Focaremos em 5 ViewModels críticos: `HomeViewModel`, `WorkoutPlanViewModel`, `DailyQuestionnaireViewModel`, `LibraryViewModel` e `HistoryViewModel`.

<requirements>
- Implementar protocol `ErrorPresenting` em todos ViewModels principais
- Adicionar @Published var errorMessage: ErrorMessage? em cada ViewModel
- Substituir try-catch genéricos por calls a handleError()
- Adicionar .errorToast modifier nas Views correspondentes
- Testar todos cenários de erro (network, API, business logic)
- Configurar retry closures para ações de recuperação
- Garantir que nenhum erro técnico seja exposto ao usuário
- Logging técnico mantido em console para debugging
- Code review para consistency across ViewModels
</requirements>

## Subtarefas

- [ ] 4.1 Implementar ErrorPresenting em `HomeViewModel`
- [ ] 4.2 Implementar ErrorPresenting em `WorkoutPlanViewModel` (se existir separado)
- [ ] 4.3 Implementar ErrorPresenting em `DailyQuestionnaireViewModel`
- [ ] 4.4 Implementar ErrorPresenting em `LibraryViewModel`
- [ ] 4.5 Implementar ErrorPresenting em `HistoryViewModel`
- [ ] 4.6 Adicionar .errorToast() nas Views correspondentes
- [ ] 4.7 Testar cenários de erro em cada tela (forçar erros)
- [ ] 4.8 Code review para consistency e completeness

## Detalhes de Implementação

### Referência Completa

Ver [`techspec.md`](techspec.md) seções:
- "Interface 3: ErrorPresenting" - Protocol implementation
- "Interface 4: ErrorMapper" - Como erros são mapeados
- "Design de Implementação" - Fluxo completo de erro

### Pattern de Implementação

**Antes (HomeViewModel example):**

```swift
class HomeViewModel: ObservableObject {
  @Published var journeyState: JourneyState = .loading
  
  func loadUserData() async {
    do {
      let profile = try await profileRepo.loadProfile()
      // process...
    } catch {
      // Inconsistent error handling
      print("Error: \(error)")
      journeyState = .error(message: "Algo deu errado")
    }
  }
}
```

**Depois:**

```swift
class HomeViewModel: ObservableObject, ErrorPresenting {
  @Published var journeyState: JourneyState = .loading
  @Published var errorMessage: ErrorMessage? // ← NOVO
  
  private let profileRepo: UserProfileRepository
  private let entitlementRepo: EntitlementRepository
  
  func loadUserData() async {
    do {
      let profile = try await profileRepo.loadProfile()
      // process...
    } catch {
      handleError(error) // ← NOVO: ErrorPresenting protocol
    }
  }
  
  // Retry closure for specific operations
  private func retryLoadUserData() {
    Task {
      await loadUserData()
    }
  }
}

// In HomeView:
struct HomeView: View {
  @StateObject var viewModel: HomeViewModel
  
  var body: some View {
    content
      .errorToast(errorMessage: $viewModel.errorMessage) // ← NOVO
  }
}
```

### Implementação por ViewModel

#### 1. HomeViewModel

**File:** `Presentation/Features/Home/HomeViewModel.swift`

**Error scenarios:**
- Profile load failure
- Entitlement check failure
- Daily check-in load failure
- Programs load failure

**Implementation:**

```swift
class HomeViewModel: ObservableObject, ErrorPresenting {
  @Published var journeyState: JourneyState = .loading
  @Published var errorMessage: ErrorMessage?
  @Published var dailyWorkoutState: DailyWorkoutState
  
  private let profileRepo: UserProfileRepository
  private let entitlementRepo: EntitlementRepository
  
  func refresh() async {
    await loadUserData()
  }
  
  private func loadUserData() async {
    journeyState = .loading
    
    do {
      let profile = try await profileRepo.loadProfile()
      let entitlement = try await entitlementRepo.currentEntitlement()
      
      guard let profile else {
        journeyState = .noProfile
        return
      }
      
      journeyState = .ready(profile: profile)
    } catch {
      handleError(error) // ErrorPresenting
      journeyState = .error(message: "Não foi possível carregar seus dados")
    }
  }
}

// In HomeView:
.errorToast(errorMessage: $viewModel.errorMessage)
```

#### 2. DailyQuestionnaireViewModel

**File:** `Presentation/Features/DailyQuestionnaire/DailyQuestionnaireViewModel.swift`

**Error scenarios:**
- Invalid input validation
- Profile not found
- Workout generation failure (OpenAI timeout, network)

**Implementation:**

```swift
class DailyQuestionnaireViewModel: ObservableObject, ErrorPresenting {
  @Published var currentStep: QuestionStep = .focus
  @Published var isGenerating = false
  @Published var errorMessage: ErrorMessage?
  
  private let generateWorkoutUseCase: GenerateWorkoutUseCase
  
  func generateWorkout() async {
    guard validateInputs() else {
      errorMessage = ErrorMessage(
        title: "Responda todas as perguntas",
        message: "Por favor, complete o questionário antes de gerar o treino.",
        action: .dismiss
      )
      return
    }
    
    isGenerating = true
    defer { isGenerating = false }
    
    do {
      let plan = try await generateWorkoutUseCase.execute(
        profile: profile,
        checkIn: dailyCheckIn
      )
      // Navigate to workout...
    } catch {
      handleError(error) // ErrorPresenting
      // Offer retry
      errorMessage?.action = .retry { [weak self] in
        Task {
          await self?.generateWorkout()
        }
      }
    }
  }
  
  private func validateInputs() -> Bool {
    // validation logic...
  }
}

// In DailyQuestionnaireFlowView:
.errorToast(errorMessage: $viewModel.errorMessage)
```

#### 3. LibraryViewModel

**File:** `Presentation/Features/Library/LibraryViewModel.swift`

**Error scenarios:**
- Workout blocks load failure
- Invalid workout selection

**Implementation:**

```swift
class LibraryViewModel: ObservableObject, ErrorPresenting {
  @Published var workouts: [WorkoutTemplate] = []
  @Published var isLoading = false
  @Published var errorMessage: ErrorMessage?
  
  private let blocksRepo: WorkoutBlocksRepository
  
  func loadWorkouts() async {
    isLoading = true
    defer { isLoading = false }
    
    do {
      let blocks = try await blocksRepo.loadBlocks()
      workouts = processBlocks(blocks)
    } catch {
      handleError(error) // ErrorPresenting
    }
  }
  
  func selectWorkout(_ workout: WorkoutTemplate) async {
    do {
      // Validation...
      guard workout.isAvailable else {
        throw DomainError.invalidInput(
          reason: "Este treino requer equipamentos que você não selecionou no perfil."
        )
      }
      // Navigate...
    } catch {
      handleError(error)
    }
  }
}

// In LibraryView:
.errorToast(errorMessage: $viewModel.errorMessage)
```

#### 4. HistoryViewModel

**File:** `Presentation/Features/History/HistoryViewModel.swift`

**Error scenarios:**
- History load failure
- Pagination error
- Delete entry failure

**Implementation:**

```swift
class HistoryViewModel: ObservableObject, ErrorPresenting {
  @Published var entries: [WorkoutHistoryEntry] = []
  @Published var isLoading = false
  @Published var errorMessage: ErrorMessage?
  
  private let historyRepo: WorkoutHistoryRepository
  private var currentOffset = 0
  private let pageSize = 20
  
  func loadHistory() async {
    isLoading = true
    defer { isLoading = false }
    
    do {
      let newEntries = try await historyRepo.fetchHistory(
        limit: pageSize,
        offset: currentOffset
      )
      entries.append(contentsOf: newEntries)
      currentOffset += pageSize
    } catch {
      handleError(error) // ErrorPresenting
      errorMessage?.action = .retry { [weak self] in
        Task {
          await self?.loadHistory()
        }
      }
    }
  }
  
  func deleteEntry(_ entry: WorkoutHistoryEntry) async {
    do {
      try await historyRepo.deleteEntry(entry.id)
      entries.removeAll { $0.id == entry.id }
    } catch {
      handleError(error)
    }
  }
}

// In HistoryView:
.errorToast(errorMessage: $viewModel.errorMessage)
```

#### 5. Additional ViewModels (if exists)

- `OnboardingFlowViewModel` - profile creation errors
- `ProfileProViewModel` - subscription errors
- Any other ViewModel with async operations

### Custom Error Messages (Context-Specific)

Sometimes you need custom messages beyond ErrorMapper:

```swift
func generateWorkout() async {
  do {
    try await generateUseCase.execute()
  } catch OpenAIError.rateLimitExceeded {
    // Custom message for specific case
    errorMessage = ErrorMessage(
      title: "Limite diário atingido",
      message: "Você atingiu o limite de treinos com IA hoje. Tente novamente amanhã ou use treinos da biblioteca.",
      action: .dismiss
    )
  } catch {
    // Fallback to default mapping
    handleError(error)
  }
}
```

### Retry Closures Best Practices

**DO:**
- ✅ Capture `[weak self]` em retry closures
- ✅ Retry a operação específica que falhou
- ✅ Manter estado (ex: lastAttempt) para evitar retry infinito

```swift
errorMessage?.action = .retry { [weak self] in
  guard let self else { return }
  Task {
    await self.specificOperation()
  }
}
```

**DON'T:**
- ❌ Retry operações caras sem limite
- ❌ Strong capture de self (memory leak)
- ❌ Retry operations que garantidamente vão falhar novamente

### Testing Error Scenarios

**Force errors for testing:**

```swift
#if DEBUG
extension HomeViewModel {
  func simulateNetworkError() {
    handleError(URLError(.notConnectedToInternet))
  }
  
  func simulateProfileError() {
    handleError(DomainError.profileNotFound)
  }
}
#endif

// In view (debug menu):
#if DEBUG
Button("Simular erro de rede") {
  viewModel.simulateNetworkError()
}
#endif
```

## Critérios de Sucesso

### Funcionalidade
- ✅ Todos ViewModels principais implementam ErrorPresenting
- ✅ Todos erros mostram toast com mensagem user-friendly
- ✅ Retry actions funcionam corretamente quando aplicável
- ✅ OpenSettings action abre Settings do iOS
- ✅ Auto-dismiss após 4s funciona
- ✅ Manual dismiss com X funciona

### Qualidade de Código
- ✅ Zero warnings de compilação
- ✅ Consistent implementation across ViewModels
- ✅ No strong reference cycles (memory leaks)
- ✅ Code review aprovado
- ✅ Testes unitários para ViewModels principais

### UX
- ✅ Nenhum erro técnico exposto (URLError -1009, etc)
- ✅ Mensagens são claras e acionáveis
- ✅ Toast não bloqueia interação (pode dismiss manualmente)
- ✅ Animações suaves

### Coverage
- ✅ Pelo menos 1 erro testado por ViewModel
- ✅ Network errors testados (force airplane mode)
- ✅ Business logic errors testados
- ✅ OpenAI timeout testado

## Dependências

**Bloqueante:** Task 2.0 (Error Handling Infrastructure) deve estar completa.

**Arquivos necessários:**
- `ErrorPresenting.swift` (Task 2.0)
- `ErrorMessage.swift` (Task 2.0)
- `ErrorMapper.swift` (Task 2.0)
- `ErrorToastView.swift` (Task 2.0)

## Observações

### ViewModels Priority

**Priority 1 (Must implement):**
- HomeViewModel (critical - entry point)
- DailyQuestionnaireViewModel (critical - core flow)
- WorkoutPlanViewModel or equivalent (critical - treino execution)

**Priority 2 (Should implement):**
- LibraryViewModel (important - fallback option)
- HistoryViewModel (important - user data)

**Priority 3 (Can implement later):**
- OnboardingFlowViewModel (edge case - first use only)
- ProfileProViewModel (edge case - settings)

### Common Error Patterns

**Network operations:**
```swift
do {
  let data = try await repository.fetch()
} catch {
  handleError(error)
  errorMessage?.action = .retry { [weak self] in
    Task { await self?.fetch() }
  }
}
```

**Business logic validation:**
```swift
guard isValid else {
  errorMessage = ErrorMessage(
    title: "Dados inválidos",
    message: "Descrição específica do problema",
    action: .dismiss
  )
  return
}
```

**Optional chaining:**
```swift
guard let profile else {
  errorMessage = ErrorMessage(
    title: "Perfil não encontrado",
    message: "Configure seu perfil antes de continuar",
    action: .dismiss
  )
  return
}
```

### Memory Management

**Weak self in closures:**

```swift
errorMessage?.action = .retry { [weak self] in
  guard let self else { return }
  Task {
    await self.operation()
  }
}
```

**Cancel ongoing tasks:**

```swift
private var loadTask: Task<Void, Never>?

func loadData() async {
  loadTask?.cancel()
  
  loadTask = Task {
    do {
      // async work...
    } catch {
      handleError(error)
    }
  }
}

deinit {
  loadTask?.cancel()
}
```

### Debug Logging

Keep technical logs for debugging:

```swift
extension ErrorPresenting {
  func handleError(_ error: Error) {
    #if DEBUG
    print("""
      [Error] \(type(of: self))
      Type: \(type(of: error))
      Description: \(error.localizedDescription)
      """)
    #endif
    
    let mapped = ErrorMapper.userFriendlyMessage(for: error)
    errorMessage = mapped
  }
}
```

### Testing Strategy

**Unit tests:**

```swift
@Suite("HomeViewModel Error Handling")
struct HomeViewModelTests {
  @Test("Network error shows toast")
  func testNetworkError() async {
    let viewModel = HomeViewModel(
      profileRepo: MockProfileRepository(shouldFail: true)
    )
    
    await viewModel.loadUserData()
    
    #expect(viewModel.errorMessage != nil)
    #expect(viewModel.errorMessage?.title.contains("conexão"))
  }
  
  @Test("Retry action works")
  func testRetry() async {
    let mockRepo = MockProfileRepository(shouldFail: true)
    let viewModel = HomeViewModel(profileRepo: mockRepo)
    
    await viewModel.loadUserData()
    
    // Simulate retry
    mockRepo.shouldFail = false
    viewModel.errorMessage?.action?.execute()
    
    // Wait for async
    try? await Task.sleep(for: .milliseconds(100))
    
    #expect(viewModel.journeyState == .ready)
  }
}
```

### Future Enhancements (Out of Scope)

- ❌ Analytics tracking (qual erro, quando, onde)
- ❌ Error grouping (múltiplos erros → 1 toast)
- ❌ Undo actions (desfazer após erro)
- ❌ Smart retry (exponential backoff)

## Arquivos relevantes

### Modificar (existentes)

```
FitToday/FitToday/Presentation/Features/Home/
├── HomeViewModel.swift          (~30 linhas modificadas)
└── HomeView.swift               (~5 linhas adicionadas)

FitToday/FitToday/Presentation/Features/DailyQuestionnaire/
├── DailyQuestionnaireViewModel.swift  (~40 linhas modificadas)
└── DailyQuestionnaireFlowView.swift   (~5 linhas adicionadas)

FitToday/FitToday/Presentation/Features/Library/
├── LibraryViewModel.swift       (~20 linhas modificadas)
└── LibraryView.swift            (~5 linhas adicionadas)

FitToday/FitToday/Presentation/Features/History/
├── HistoryViewModel.swift       (~25 linhas modificadas)
└── HistoryView.swift            (~5 linhas adicionadas)

FitToday/FitToday/Presentation/Features/Workout/
└── WorkoutSessionStore.swift    (~15 linhas modificadas, se necessário)
```

### Modificações Detalhadas

**HomeViewModel.swift:**
- Add: `ErrorPresenting` conformance
- Add: `@Published var errorMessage: ErrorMessage?`
- Modify: All `catch` blocks to call `handleError(error)`

**HomeView.swift:**
- Add: `.errorToast(errorMessage: $viewModel.errorMessage)`

*(Repeat pattern for other ViewModels/Views)*

### Estimativa de Tempo

- **4.1** HomeViewModel: 2h
- **4.2** WorkoutPlanViewModel: 1.5h
- **4.3** DailyQuestionnaireViewModel: 2h
- **4.4** LibraryViewModel: 1h
- **4.5** HistoryViewModel: 1h
- **4.6** Add .errorToast to Views: 1h
- **4.7** Test all error scenarios: 2h
- **4.8** Code review and fixes: 1.5h

**Total: ~12 horas (1.5 dias de trabalho)**

### Checklist de Finalização

- [ ] Todos ViewModels principais implementam ErrorPresenting
- [ ] Todas Views mostram .errorToast
- [ ] Zero erros técnicos expostos ao usuário
- [ ] Retry actions testadas e funcionando
- [ ] Memory leaks verificados (Instruments)
- [ ] Code review completo
- [ ] Testes unitários passando
- [ ] QA manual em device real
- [ ] Documentation atualizada

