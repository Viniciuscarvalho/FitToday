# [2.0] Criar infraestrutura de Error Handling (M)

## markdown

## status: completed

<task_context>
<domain>presentation/infrastructure</domain>
<type>implementation</type>
<scope>middleware</scope>
<complexity>medium</complexity>
<dependencies>none</dependencies>
</task_context>

# Tarefa 2.0: Criar infraestrutura de Error Handling

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

Padronizar a apresentação de erros em toda a aplicação através de uma infraestrutura consistente que inclui: protocol `ErrorPresenting` com implementação default, model `ErrorMessage` para dados de erro, classe `ErrorMapper` para tradução de erros técnicos em mensagens user-friendly, e componente SwiftUI `ErrorToastView` para apresentação visual.

Esta infraestrutura resolve o problema atual de erros técnicos expostos ao usuário ("URLError -1009") e inconsistência no tratamento entre ViewModels diferentes.

<requirements>
- Protocol `ErrorPresenting` com extensão default implementando handleError()
- Struct `ErrorMessage` conformando Identifiable para uso em Views
- Enum `ErrorAction` com cases: retry(closure), openSettings, dismiss
- Class `ErrorMapper` com método estático userFriendlyMessage(for:)
- SwiftUI component `ErrorToastView` com animações suaves
- Mapear todos cases de DomainError, URLError e OpenAIError
- Mensagens em português brasileiro coloquial, sem termos técnicos
- Logging técnico mantido em console para debugging
- Suportar ações de recuperação (retry, abrir Settings, dismiss)
- Testes unitários para ErrorMapper com 100% dos casos
</requirements>

## Subtarefas

- [ ] 2.1 Criar struct `ErrorMessage` model (Identifiable, Equatable)
- [ ] 2.2 Criar enum `ErrorAction` com cases e labels
- [ ] 2.3 Criar protocol `ErrorPresenting` com extensão default
- [ ] 2.4 Implementar classe `ErrorMapper` com métodos privados por tipo de erro
- [ ] 2.5 Adicionar computed property `userFacingMessage` em DomainError
- [ ] 2.6 Criar `ErrorToastView` SwiftUI component com animações
- [ ] 2.7 Criar testes unitários (`ErrorPresentingTests.swift`)
- [ ] 2.8 Documentar usage com exemplo completo

## Detalhes de Implementação

### Referência Completa

Ver [`techspec.md`](techspec.md) seções:
- "Interface 3: ErrorPresenting" - Protocol e implementação completa
- "Interface 4: ErrorMapper" - Mapeamento de todos tipos de erro
- "Design de Implementação" - Fluxo de erro end-to-end

### Arquitetura de Error Handling

```
┌─────────────────────────────────────────┐
│ ViewModel (async operation)              │
│  try await repository.fetch()            │
│  catch error → handleError(error)        │
└──────────────────┬──────────────────────┘
                   │ ErrorPresenting protocol
                   ▼
┌─────────────────────────────────────────┐
│ ErrorMapper.userFriendlyMessage(error)  │
│  - Switch on error type                 │
│  - Map to ErrorMessage                  │
│  - Add appropriate action               │
└──────────────────┬──────────────────────┘
                   │ ErrorMessage
                   ▼
┌─────────────────────────────────────────┐
│ @Published var errorMessage: ErrorMessage?│
│ View observes and shows ErrorToastView  │
└─────────────────────────────────────────┘
```

### ErrorMessage Model

```swift
struct ErrorMessage: Identifiable, Equatable {
  let id = UUID()
  let title: String
  let message: String
  let action: ErrorAction?
  
  init(title: String, message: String, action: ErrorAction? = nil) {
    self.title = title
    self.message = message
    self.action = action
  }
  
  static func == (lhs: ErrorMessage, rhs: ErrorMessage) -> Bool {
    lhs.id == rhs.id
  }
}
```

### ErrorAction Enum

```swift
enum ErrorAction: Equatable {
  case retry(() -> Void)
  case openSettings
  case dismiss
  
  var label: String {
    switch self {
    case .retry: return "Tentar Novamente"
    case .openSettings: return "Abrir Configurações"
    case .dismiss: return "OK"
    }
  }
  
  var systemImage: String {
    switch self {
    case .retry: return "arrow.clockwise"
    case .openSettings: return "gearshape"
    case .dismiss: return "xmark"
    }
  }
  
  func execute() {
    switch self {
    case .retry(let closure):
      closure()
    case .openSettings:
      if let url = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(url)
      }
    case .dismiss:
      break // View dismisses automatically
    }
  }
  
  static func == (lhs: ErrorAction, rhs: ErrorAction) -> Bool {
    switch (lhs, rhs) {
    case (.retry, .retry): return true
    case (.openSettings, .openSettings): return true
    case (.dismiss, .dismiss): return true
    default: return false
    }
  }
}
```

### ErrorPresenting Protocol

```swift
/// Protocol para ViewModels que apresentam erros ao usuário
protocol ErrorPresenting: AnyObject {
  var errorMessage: ErrorMessage? { get set }
  func handleError(_ error: Error)
}

extension ErrorPresenting where Self: ObservableObject {
  /// Implementação default que mapeia erro e publica ErrorMessage
  func handleError(_ error: Error) {
    // Log technical error
    print("[Error] \(type(of: self)): \(error)")
    
    // Map to user-friendly message
    let mapped = ErrorMapper.userFriendlyMessage(for: error)
    
    // Publish on main thread
    Task { @MainActor in
      errorMessage = mapped
    }
  }
}
```

### ErrorMapper Implementation

```swift
enum ErrorMapper {
  static func userFriendlyMessage(for error: Error) -> ErrorMessage {
    switch error {
    case let urlError as URLError:
      return handleURLError(urlError)
      
    case let domainError as DomainError:
      return handleDomainError(domainError)
      
    case let openAIError as OpenAIError:
      return handleOpenAIError(openAIError)
      
    default:
      return ErrorMessage(
        title: "Ops!",
        message: "Algo inesperado aconteceu. Tente novamente.",
        action: .dismiss
      )
    }
  }
  
  private static func handleURLError(_ error: URLError) -> ErrorMessage {
    switch error.code {
    case .notConnectedToInternet, .networkConnectionLost:
      return ErrorMessage(
        title: "Sem conexão",
        message: "Verifique sua internet e tente novamente.",
        action: .openSettings
      )
      
    case .timedOut:
      return ErrorMessage(
        title: "Tempo esgotado",
        message: "A operação demorou muito. Tente novamente.",
        action: .retry({})
      )
      
    case .cannotFindHost, .cannotConnectToHost:
      return ErrorMessage(
        title: "Servidor indisponível",
        message: "Não conseguimos conectar ao servidor. Tente novamente mais tarde.",
        action: .dismiss
      )
      
    default:
      return ErrorMessage(
        title: "Erro de conexão",
        message: "Não conseguimos conectar. Tente novamente.",
        action: .retry({})
      )
    }
  }
  
  private static func handleDomainError(_ error: DomainError) -> ErrorMessage {
    switch error {
    case .profileNotFound:
      return ErrorMessage(
        title: "Perfil não encontrado",
        message: "Complete seu perfil para gerar treinos personalizados.",
        action: .dismiss
      )
      
    case .networkFailure:
      return ErrorMessage(
        title: "Sem conexão",
        message: "Verifique sua internet e tente novamente.",
        action: .openSettings
      )
      
    case .subscriptionExpired:
      return ErrorMessage(
        title: "Assinatura expirada",
        message: "Renove sua assinatura para continuar usando recursos Pro.",
        action: .dismiss
      )
      
    case .invalidInput(let reason):
      return ErrorMessage(
        title: "Dados inválidos",
        message: reason,
        action: .dismiss
      )
      
    case .repositoryFailure(let reason):
      return ErrorMessage(
        title: "Erro ao salvar",
        message: "Não conseguimos salvar os dados. \(reason)",
        action: .retry({})
      )
      
    default:
      return ErrorMessage(
        title: "Ops!",
        message: "Algo deu errado. Tente novamente.",
        action: .dismiss
      )
    }
  }
  
  private static func handleOpenAIError(_ error: OpenAIError) -> ErrorMessage {
    ErrorMessage(
      title: "IA temporariamente indisponível",
      message: "Geramos um ótimo treino local para você hoje.",
      action: .dismiss
    )
  }
}
```

### ErrorToastView Component

```swift
struct ErrorToastView: View {
  let errorMessage: ErrorMessage
  let onDismiss: () -> Void
  
  @Environment(\.accessibilityReduceMotion) var reduceMotion
  @State private var isPresented = false
  
  var body: some View {
    VStack(spacing: FitTodaySpacing.sm) {
      HStack(alignment: .top, spacing: FitTodaySpacing.md) {
        Image(systemName: "exclamationmark.triangle.fill")
          .font(.system(.title3, weight: .semibold))
          .foregroundStyle(Color.orange)
        
        VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
          Text(errorMessage.title)
            .font(.system(.body, weight: .semibold))
            .foregroundStyle(FitTodayColor.textPrimary)
          
          Text(errorMessage.message)
            .font(.system(.footnote))
            .foregroundStyle(FitTodayColor.textSecondary)
            .multilineTextAlignment(.leading)
        }
        
        Spacer()
        
        Button(action: onDismiss) {
          Image(systemName: "xmark.circle.fill")
            .font(.system(.title3))
            .foregroundStyle(FitTodayColor.textTertiary)
        }
      }
      
      if let action = errorMessage.action {
        Button(action: {
          action.execute()
          onDismiss()
        }) {
          Label(action.label, systemImage: action.systemImage)
            .font(.system(.footnote, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, FitTodaySpacing.sm)
        }
        .fitSecondaryStyle()
      }
    }
    .padding(FitTodaySpacing.md)
    .background(
      RoundedRectangle(cornerRadius: FitTodayRadius.md)
        .fill(FitTodayColor.surface)
        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 4)
    )
    .padding(.horizontal, FitTodaySpacing.md)
    .offset(y: isPresented ? 0 : -200)
    .animation(
      reduceMotion ? .easeInOut : .spring(response: 0.4, dampingFraction: 0.8),
      value: isPresented
    )
    .onAppear {
      isPresented = true
      
      // Auto-dismiss after 4 seconds
      Task {
        try? await Task.sleep(for: .seconds(4))
        withAnimation {
          isPresented = false
        }
        Task {
          try? await Task.sleep(for: .seconds(0.3))
          onDismiss()
        }
      }
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(errorMessage.title). \(errorMessage.message)")
    .accessibilityAddTraits(.isStaticText)
  }
}

// View modifier for easy usage
extension View {
  func errorToast(
    errorMessage: Binding<ErrorMessage?>
  ) -> some View {
    ZStack(alignment: .top) {
      self
      
      if let message = errorMessage.wrappedValue {
        ErrorToastView(errorMessage: message) {
          errorMessage.wrappedValue = nil
        }
        .padding(.top, FitTodaySpacing.lg)
        .transition(.move(edge: .top).combined(with: .opacity))
        .zIndex(999)
      }
    }
    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: errorMessage.wrappedValue)
  }
}
```

### Exemplo de Uso

```swift
class HomeViewModel: ObservableObject, ErrorPresenting {
  @Published var errorMessage: ErrorMessage?
  @Published var isLoading = false
  
  private let repository: WorkoutHistoryRepository
  
  func loadHistory() async {
    isLoading = true
    defer { isLoading = false }
    
    do {
      let history = try await repository.fetchHistory(limit: 20, offset: 0)
      // process history...
    } catch {
      handleError(error) // ErrorPresenting protocol
    }
  }
}

// In View:
struct HomeView: View {
  @StateObject var viewModel: HomeViewModel
  
  var body: some View {
    content
      .errorToast(errorMessage: $viewModel.errorMessage)
  }
}
```

## Critérios de Sucesso

### Funcionalidade
- ✅ ViewModels podem implementar `ErrorPresenting` facilmente
- ✅ Toast aparece com animação suave (spring ou fade)
- ✅ Todos DomainError cases mapeados para mensagens PT-BR
- ✅ URLError cases principais cobertos (network, timeout, etc)
- ✅ Actions funcionam corretamente (retry executa closure, openSettings abre app Settings)
- ✅ Auto-dismiss após 4 segundos
- ✅ Manual dismiss com botão X funciona

### Qualidade de Código
- ✅ Zero warnings de compilação
- ✅ Testes cobrem 100% dos error mappings
- ✅ Code review aprovado
- ✅ Seguir Kodeco Style Guide (2 spaces, protocol-first, etc)

### UX/Acessibilidade
- ✅ Mensagens claras, sem jargão técnico
- ✅ VoiceOver anuncia toast automaticamente
- ✅ Dynamic Type suportado (até accessibility5)
- ✅ Reduced Motion respeitado (fade simples)
- ✅ Cores mantêm contraste mínimo 4.5:1

### Testabilidade
- ✅ ErrorMapper pode ser testado isoladamente
- ✅ ErrorPresenting pode ser testado com ViewModel mock
- ✅ Testes não dependem de SwiftUI rendering

## Dependências

**Nenhuma** - Task independente, pode ser desenvolvida em paralelo com Task 1.0.

**Modificações necessárias:**
- `DomainError.swift` - adicionar casos se necessário

## Observações

### Mensagens User-Friendly - Guidelines

**DO:**
- ✅ Use linguagem coloquial: "Verifique sua internet"
- ✅ Seja específico: "Tempo esgotado" em vez de "Erro"
- ✅ Dê ação clara: "Tente novamente" ou "Abrir Configurações"
- ✅ Seja empático: "Ops!" em vez de "ERROR"

**DON'T:**
- ❌ Expor termos técnicos: "URLError -1009"
- ❌ Stack traces ou detalhes de implementação
- ❌ Mensagens genéricas: "Ocorreu um erro"
- ❌ Blame user: "Você esqueceu de..."

### Error Mapping Strategy

**Priority 1 (Must map):**
- Network errors (URLError)
- Domain business logic errors (DomainError)
- External API errors (OpenAIError)

**Priority 2 (Future):**
- StoreKit errors (subscription validation)
- SwiftData errors (database)
- File system errors (cache, storage)

### Testing Strategy

**Unit Tests:**
```swift
@Test("Network error maps to user-friendly message")
func testNetworkError() {
  let error = URLError(.notConnectedToInternet)
  let message = ErrorMapper.userFriendlyMessage(for: error)
  
  #expect(message.title == "Sem conexão")
  #expect(message.message.contains("internet"))
  #expect(message.action != nil)
}

@Test("ViewModel adopts ErrorPresenting")
func testViewModelAdoption() {
  class TestVM: ObservableObject, ErrorPresenting {
    @Published var errorMessage: ErrorMessage?
  }
  
  let vm = TestVM()
  vm.handleError(DomainError.profileNotFound)
  
  #expect(vm.errorMessage?.title == "Perfil não encontrado")
}
```

### Debug Logging

```swift
#if DEBUG
extension ErrorPresenting {
  func handleError(_ error: Error) {
    // Log detailed error for debugging
    print("""
      [Error] \(type(of: self))
      Type: \(type(of: error))
      Description: \(error.localizedDescription)
      """)
    
    // Continue with normal flow...
  }
}
#endif
```

### Performance Considerations

- ErrorMapper é stateless (apenas métodos estáticos)
- Mapping é O(1) (switch statement)
- Toast animation é GPU-accelerated (SwiftUI)
- Auto-dismiss usa Task.sleep (não bloqueia thread)

### Future Enhancements (Out of Scope)

- ❌ Analytics tracking (qual erro ocorreu quando)
- ❌ Error recovery suggestions baseadas em contexto
- ❌ Retry automático com exponential backoff
- ❌ Offline mode indicator permanente

## Arquivos relevantes

### Criar (novos arquivos)

```
FitToday/FitToday/Presentation/Infrastructure/
├── ErrorPresenting.swift       (~50 linhas)
├── ErrorMessage.swift          (~30 linhas)
└── ErrorMapper.swift           (~150 linhas)

FitToday/FitToday/Presentation/DesignSystem/
└── ErrorToastView.swift        (~120 linhas)

FitTodayTests/Presentation/
└── ErrorPresentingTests.swift  (~200 linhas)
```

### Modificar (existentes)

```
FitToday/FitToday/Domain/Support/
└── DomainError.swift           (verificar casos, adicionar se necessário)
```

### Estrutura Detalhada

**ErrorPresenting.swift:**
```swift
import Foundation
import Combine

protocol ErrorPresenting: AnyObject {
  var errorMessage: ErrorMessage? { get set }
  func handleError(_ error: Error)
}

extension ErrorPresenting where Self: ObservableObject {
  func handleError(_ error: Error) { ... }
}
```

**ErrorMessage.swift:**
```swift
import Foundation

struct ErrorMessage: Identifiable, Equatable { ... }

enum ErrorAction: Equatable { ... }
```

**ErrorMapper.swift:**
```swift
import Foundation

enum ErrorMapper {
  static func userFriendlyMessage(for error: Error) -> ErrorMessage
  private static func handleURLError(_ error: URLError) -> ErrorMessage
  private static func handleDomainError(_ error: DomainError) -> ErrorMessage
  private static func handleOpenAIError(_ error: OpenAIError) -> ErrorMessage
}
```

**ErrorToastView.swift:**
```swift
import SwiftUI

struct ErrorToastView: View {
  let errorMessage: ErrorMessage
  let onDismiss: () -> Void
  var body: some View { ... }
}

extension View {
  func errorToast(errorMessage: Binding<ErrorMessage?>) -> some View { ... }
}
```

### Estimativa de Tempo

- **2.1** ErrorMessage model: 30 min
- **2.2** ErrorAction enum: 30 min
- **2.3** ErrorPresenting protocol: 1h
- **2.4** ErrorMapper implementation: 2-3h
- **2.5** DomainError modifications: 30 min
- **2.6** ErrorToastView component: 2h
- **2.7** Testes unitários: 2h
- **2.8** Documentação e exemplo: 30 min

**Total: ~9-10 horas (1 dia de trabalho)**

### Checklist de Finalização

- [ ] Código compila sem warnings
- [ ] Todos testes passam
- [ ] ErrorToastView testado em device real (animações)
- [ ] VoiceOver testado
- [ ] Dynamic Type testado (até accessibility5)
- [ ] Code review aprovado
- [ ] Exemplo de uso documentado
- [ ] Commit message descritivo

