# TechSpec - Performance & Quality Sprint

## Resumo Executivo

Esta especificação técnica detalha a implementação de melhorias de performance e confiabilidade no FitToday, organizadas em 3 fases. A Fase 1 (Sprint de 2 semanas) foca em três pilares críticos:

1. **Image Caching**: Novo serviço `ImageCacheService` com cache híbrido (URLCache + custom disk) para suporte offline e performance
2. **Error Handling**: Protocolo `ErrorPresenting` e infraestrutura padronizada para apresentação consistente de erros
3. **SwiftData Optimization**: Índices em queries frequentes e paginação lazy no histórico

**Stack Tecnológica:**
- SwiftUI (iOS 17+)
- SwiftData para persistência
- async/await para concurrency
- Swinject para Dependency Injection
- XCTest para testes unitários

**Padrões Arquiteturais:**
- Clean Architecture (Domain/Data/Presentation)
- Repository Pattern
- MVVM para ViewModels
- Protocol-Oriented Programming

**Estratégia de Testes:**
- Mocks para dependências externas (OpenAI, ExerciseDB, StoreKit)
- Async tests com Swift Testing macros quando possível
- Targets de cobertura: Domain 80%, ViewModels 70%, Repositories 60%

## Arquitetura do Sistema

### Visão Geral dos Componentes

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ ViewModels   │  │ Views        │  │ Infrastructure│  │
│  │ + Error      │◄─┤ SwiftUI      │◄─┤ ErrorPresenting│ │
│  │   Presenting │  │              │  │ ErrorToastView │  │
│  └──────┬───────┘  └──────────────┘  └──────────────┘  │
└─────────┼───────────────────────────────────────────────┘
          │
┌─────────┼───────────────────────────────────────────────┐
│         ▼              Domain Layer                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ Use Cases    │  │ Entities     │  │ Protocols    │  │
│  │              │  │ UserProfile  │  │ Repositories │  │
│  └──────┬───────┘  │ WorkoutPlan  │  └──────────────┘  │
│         │          └──────────────┘                      │
└─────────┼───────────────────────────────────────────────┘
          │
┌─────────┼───────────────────────────────────────────────┐
│         ▼              Data Layer                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ Repositories │  │ Services     │  │ Models       │  │
│  │ Impl         │  │ ImageCache ◄─┤─►│ SwiftData    │  │
│  │              │  │ ExerciseDB   │  │ SDWorkout... │  │
│  └──────────────┘  │ OpenAI       │  └──────────────┘  │
│                    └──────────────┘                      │
└─────────────────────────────────────────────────────────┘
```

### Novos Componentes (Fase 1)

**Data Layer:**
- `Data/Services/ImageCache/ImageCacheService.swift` - Serviço principal de cache
- `Data/Services/ImageCache/DiskImageCache.swift` - Cache de disco persistente
- `Data/Services/ImageCache/ImageCacheConfiguration.swift` - Configuração
- `Data/Repositories/WorkoutHistoryRepository.swift` - Modificar para paginação

**Presentation Layer:**
- `Presentation/Infrastructure/ErrorPresenting.swift` - Protocol + extension
- `Presentation/Infrastructure/ErrorMessage.swift` - Model
- `Presentation/Infrastructure/ErrorMapper.swift` - Mapeamento de erros
- `Presentation/DesignSystem/ErrorToastView.swift` - Componente UI
- `Presentation/DesignSystem/CachedAsyncImage.swift` - Wrapper SwiftUI

**Domain Layer:**
- `Domain/Support/DomainError.swift` - Modificar para adicionar mensagens user-friendly

### Fluxo de Dados

**Fluxo 1: Image Caching**

```
WorkoutPlanView
       │
       ├─ onAppear: prefetch images
       │
       ▼
ImageCacheService
       │
       ├─ Check URLCache (memory)
       │     │
       │     ├─ HIT → return UIImage
       │     │
       │     └─ MISS
       │           │
       │           ▼
       ├─ Check DiskImageCache
       │     │
       │     ├─ HIT → load from disk → save to URLCache → return
       │     │
       │     └─ MISS
       │           │
       │           ▼
       └─ Download from ExerciseDB
             │
             └─ Save to Disk + URLCache → return
```

**Fluxo 2: Error Handling**

```
ViewModel (async operation)
       │
       ├─ try await repository.fetch()
       │
       └─ catch error
             │
             ▼
       handleError(error)  ← ErrorPresenting protocol
             │
             ▼
       ErrorMapper.userFriendlyMessage(for: error)
             │
             ▼
       @Published errorMessage = ErrorMessage(...)
             │
             ▼
       View reacts → shows ErrorToastView
```

## Design de Implementação

### Interfaces Principais

#### Interface 1: ImageCaching

```swift
/// Protocol para serviço de cache de imagens
protocol ImageCaching: Sendable {
  /// Cacheia uma imagem da URL fornecida
  func cacheImage(from url: URL) async throws
  
  /// Retorna imagem cacheada se disponível
  func cachedImage(for url: URL) async -> UIImage?
  
  /// Pre-fetcha múltiplas imagens em paralelo
  func prefetchImages(_ urls: [URL]) async
  
  /// Limpa todo o cache (memória + disco)
  func clearCache() async
  
  /// Retorna tamanho atual do cache em bytes
  func cacheSize() async -> Int64
}
```

**Implementação:**

```swift
final class ImageCacheService: ImageCaching {
  private let urlCache: URLCache
  private let diskCache: DiskImageCache
  private let session: URLSession
  private let config: ImageCacheConfiguration
  
  init(
    configuration: ImageCacheConfiguration,
    urlCache: URLCache = .shared,
    session: URLSession = .shared
  ) {
    self.config = configuration
    self.urlCache = urlCache
    self.session = session
    self.diskCache = DiskImageCache(configuration: configuration)
  }
  
  func cachedImage(for url: URL) async -> UIImage? {
    // 1. Check memory (URLCache)
    if let cachedResponse = urlCache.cachedResponse(for: URLRequest(url: url)),
       let image = UIImage(data: cachedResponse.data) {
      return image
    }
    
    // 2. Check disk
    if let data = await diskCache.data(for: url),
       let image = UIImage(data: data) {
      // Populate memory cache
      let response = URLResponse(
        url: url,
        mimeType: "image/jpeg",
        expectedContentLength: data.count,
        textEncodingName: nil
      )
      let cachedResponse = CachedURLResponse(
        response: response,
        data: data
      )
      urlCache.storeCachedResponse(
        cachedResponse,
        for: URLRequest(url: url)
      )
      return image
    }
    
    return nil
  }
  
  func cacheImage(from url: URL) async throws {
    // Skip if already cached
    if await cachedImage(for: url) != nil {
      return
    }
    
    // Download
    let (data, response) = try await session.data(from: url)
    
    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
      throw ImageCacheError.invalidResponse
    }
    
    // Save to disk
    await diskCache.save(data, for: url)
    
    // Save to memory (URLCache handles this automatically)
  }
  
  func prefetchImages(_ urls: [URL]) async {
    await withTaskGroup(of: Void.self) { group in
      for url in urls {
        // Limit concurrency to 5
        if group.taskCount >= config.prefetchConcurrency {
          await group.next()
        }
        
        group.addTask {
          try? await self.cacheImage(from: url)
        }
      }
    }
  }
  
  func clearCache() async {
    urlCache.removeAllCachedResponses()
    await diskCache.clearAll()
  }
  
  func cacheSize() async -> Int64 {
    await diskCache.totalSize()
  }
}

enum ImageCacheError: Error {
  case invalidResponse
  case diskWriteFailed
  case cacheSizeExceeded
}
```

#### Interface 2: DiskImageCache

```swift
actor DiskImageCache {
  private let config: ImageCacheConfiguration
  private let fileManager: FileManager
  private let cacheDirectory: URL
  
  init(configuration: ImageCacheConfiguration) {
    self.config = configuration
    self.fileManager = .default
    self.cacheDirectory = configuration.cacheDirectory
    
    // Create directory if needed
    try? fileManager.createDirectory(
      at: cacheDirectory,
      withIntermediateDirectories: true
    )
  }
  
  func data(for url: URL) -> Data? {
    let fileURL = cacheFileURL(for: url)
    return try? Data(contentsOf: fileURL)
  }
  
  func save(_ data: Data, for url: URL) {
    let fileURL = cacheFileURL(for: url)
    
    // Check size limit
    guard totalSize() + Int64(data.count) <= config.maxDiskSize else {
      // Evict LRU entries if needed
      evictLRUIfNeeded(toFit: Int64(data.count))
      return
    }
    
    try? data.write(to: fileURL)
    
    // Update access time metadata
    updateAccessTime(for: fileURL)
  }
  
  func clearAll() {
    try? fileManager.removeItem(at: cacheDirectory)
    try? fileManager.createDirectory(
      at: cacheDirectory,
      withIntermediateDirectories: true
    )
  }
  
  func totalSize() -> Int64 {
    guard let contents = try? fileManager.contentsOfDirectory(
      at: cacheDirectory,
      includingPropertiesForKeys: [.fileSizeKey]
    ) else {
      return 0
    }
    
    return contents.reduce(0) { total, url in
      let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
      return total + Int64(size)
    }
  }
  
  private func cacheFileURL(for url: URL) -> URL {
    let filename = url.absoluteString.sha256Hash() // Hash da URL
    return cacheDirectory.appendingPathComponent(filename)
  }
  
  private func updateAccessTime(for fileURL: URL) {
    // Update extended attribute with current timestamp for LRU
    let timestamp = Date().timeIntervalSince1970
    let data = withUnsafeBytes(of: timestamp) { Data($0) }
    try? fileURL.setExtendedAttribute(data: data, forName: "lastAccess")
  }
  
  private func evictLRUIfNeeded(toFit requiredSize: Int64) {
    // Implementation of LRU eviction
    // Sort files by lastAccess timestamp, remove oldest until space available
  }
}
```

#### Interface 3: ErrorPresenting

```swift
/// Protocol para ViewModels que apresentam erros
protocol ErrorPresenting: AnyObject {
  var errorMessage: ErrorMessage? { get set }
  func handleError(_ error: Error)
}

extension ErrorPresenting where Self: ObservableObject {
  func handleError(_ error: Error) {
    let mapped = ErrorMapper.userFriendlyMessage(for: error)
    errorMessage = mapped
  }
}

/// Model representando mensagem de erro para usuário
struct ErrorMessage: Identifiable, Equatable {
  let id = UUID()
  let title: String
  let message: String
  let action: ErrorAction?
  
  init(
    title: String,
    message: String,
    action: ErrorAction? = nil
  ) {
    self.title = title
    self.message = message
    self.action = action
  }
  
  static func == (lhs: ErrorMessage, rhs: ErrorMessage) -> Bool {
    lhs.id == rhs.id
  }
}

/// Ações disponíveis em mensagens de erro
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

#### Interface 4: ErrorMapper

```swift
enum ErrorMapper {
  static func userFriendlyMessage(for error: Error) -> ErrorMessage {
    switch error {
    // Network errors
    case let urlError as URLError:
      return handleURLError(urlError)
      
    // Domain errors
    case let domainError as DomainError:
      return handleDomainError(domainError)
      
    // OpenAI errors
    case let openAIError as OpenAIError:
      return handleOpenAIError(openAIError)
      
    // Generic fallback
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
        message: "Complete seu perfil para gerar treinos.",
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

#### Interface 5: WorkoutHistoryRepository (Paginated)

```swift
protocol WorkoutHistoryRepository: Sendable {
  /// Busca histórico com paginação
  func fetchHistory(
    limit: Int,
    offset: Int
  ) async throws -> [WorkoutHistoryEntry]
  
  /// Retorna contagem total de entradas
  func fetchHistoryCount() async throws -> Int
  
  /// Salva entrada de treino no histórico
  func saveEntry(_ entry: WorkoutHistoryEntry) async throws
}

// Implementação com SwiftData
final class SwiftDataWorkoutHistoryRepository: WorkoutHistoryRepository {
  private let modelContainer: ModelContainer
  
  init(modelContainer: ModelContainer) {
    self.modelContainer = modelContainer
  }
  
  @MainActor
  func fetchHistory(
    limit: Int,
    offset: Int
  ) async throws -> [WorkoutHistoryEntry] {
    let context = ModelContext(modelContainer)
    
    // Query com sort e paginação
    var descriptor = FetchDescriptor<SDWorkoutHistoryEntry>(
      sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
    )
    descriptor.fetchLimit = limit
    descriptor.fetchOffset = offset
    
    let entries = try context.fetch(descriptor)
    return entries.map { WorkoutHistoryMapper.toDomain($0) }
  }
  
  @MainActor
  func fetchHistoryCount() async throws -> Int {
    let context = ModelContext(modelContainer)
    let descriptor = FetchDescriptor<SDWorkoutHistoryEntry>()
    return try context.fetchCount(descriptor)
  }
  
  @MainActor
  func saveEntry(_ entry: WorkoutHistoryEntry) async throws {
    let context = ModelContext(modelContainer)
    let sdEntry = WorkoutHistoryMapper.toSwiftData(entry)
    context.insert(sdEntry)
    try context.save()
  }
}
```

### Modelos de Dados

#### ImageCacheConfiguration

```swift
struct ImageCacheConfiguration {
  let maxDiskSize: Int64
  let maxMemorySize: Int64
  let cacheDirectory: URL
  let prefetchConcurrency: Int
  
  static let `default` = ImageCacheConfiguration(
    maxDiskSize: 500 * 1024 * 1024, // 500MB
    maxMemorySize: 50 * 1024 * 1024, // 50MB
    cacheDirectory: FileManager.default
      .urls(for: .cachesDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("ImageCache"),
    prefetchConcurrency: 5
  )
  
  static let test = ImageCacheConfiguration(
    maxDiskSize: 10 * 1024 * 1024, // 10MB for tests
    maxMemorySize: 1 * 1024 * 1024, // 1MB
    cacheDirectory: FileManager.default
      .temporaryDirectory
      .appendingPathComponent("TestImageCache"),
    prefetchConcurrency: 2
  )
}
```

#### SwiftData Models (Modificações)

```swift
@Model
final class SDWorkoutHistoryEntry {
  @Attribute(.unique) var id: UUID
  @Attribute(.indexed) var completedAt: Date  // ← NOVO índice
  @Attribute(.indexed) var status: String     // ← NOVO índice
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

### Endpoints de API

Não aplicável para esta fase. Integrações com APIs externas existentes:

#### ExerciseDB API (Existente)

- **Endpoint**: `GET https://exercisedb.p.rapidapi.com/image`
- **Headers**: `x-rapidapi-key`, `x-rapidapi-host`
- **Uso**: Download de imagens de exercícios via `ImageCacheService`
- **Tratamento de erro**: Retry 2x com exponential backoff, fallback para placeholder

#### OpenAI API (Existente)

- **Endpoint**: `POST https://api.openai.com/v1/chat/completions`
- **Uso**: Geração de treinos personalizados (já implementado)
- **Fallback**: Local composer se timeout/erro
- **Tratamento de erro**: `ErrorMapper` traduz para mensagem amigável

## Pontos de Integração

### 1. ExerciseDB Integration

**Current State:**
- `ExerciseMediaImage.swift` usa `AsyncImage` direto da URL
- Nenhum cache persistente

**New State:**
- `CachedAsyncImage` wrapper usa `ImageCacheService`
- Prefetch automático ao gerar treino
- Placeholder com SF Symbol se não disponível

**Implementation:**

```swift
struct CachedAsyncImage: View {
  let url: URL?
  let placeholder: Image
  
  @Environment(\.imageCacheService) private var cacheService
  @State private var image: UIImage?
  @State private var isLoading = true
  
  var body: some View {
    Group {
      if let image {
        Image(uiImage: image)
          .resizable()
      } else if isLoading {
        ProgressView()
      } else {
        placeholder
          .resizable()
      }
    }
    .task {
      await loadImage()
    }
  }
  
  private func loadImage() async {
    guard let url else {
      isLoading = false
      return
    }
    
    // Try cache first
    if let cached = await cacheService.cachedImage(for: url) {
      image = cached
      isLoading = false
      return
    }
    
    // Download and cache
    do {
      try await cacheService.cacheImage(from: url)
      image = await cacheService.cachedImage(for: url)
    } catch {
      print("[ImageCache] Failed to load: \(error)")
    }
    
    isLoading = false
  }
}

// Environment key for DI
private struct ImageCacheServiceKey: EnvironmentKey {
  static let defaultValue: ImageCaching = ImageCacheService(
    configuration: .default
  )
}

extension EnvironmentValues {
  var imageCacheService: ImageCaching {
    get { self[ImageCacheServiceKey.self] }
    set { self[ImageCacheServiceKey.self] = newValue }
  }
}
```

### 2. WorkoutPlanView Integration

**Prefetch on workout generation:**

```swift
struct WorkoutPlanView: View {
  @Environment(WorkoutSessionStore.self) private var sessionStore
  @Environment(\.imageCacheService) private var imageCacheService
  @State private var isPrefetching = false
  
  var body: some View {
    // ... existing UI
    
    .task {
      await prefetchImages()
    }
  }
  
  private func prefetchImages() async {
    guard let plan = sessionStore.plan else { return }
    
    let imageURLs = plan.exercises.compactMap { $0.exercise.media?.gifURL }
    
    guard !imageURLs.isEmpty else { return }
    
    isPrefetching = true
    await imageCacheService.prefetchImages(imageURLs)
    isPrefetching = false
  }
}
```

### 3. Dependency Injection (Swinject)

**Register new services:**

```swift
extension AppContainer {
  static func registerServices(_ container: Container) {
    // Image Cache Service
    container.register(ImageCaching.self) { _ in
      ImageCacheService(configuration: .default)
    }.inObjectScope(.container) // Singleton
    
    // Other existing services...
  }
}
```

## Abordagem de Testes

### Testes Unitários

#### ImageCacheServiceTests

```swift
import Testing
@testable import FitToday

@Suite("ImageCacheService Tests")
struct ImageCacheServiceTests {
  let service: ImageCacheService
  let testURL = URL(string: "https://example.com/test.jpg")!
  
  init() {
    service = ImageCacheService(configuration: .test)
  }
  
  @Test("Cache miss returns nil")
  func testCacheMiss() async {
    let image = await service.cachedImage(for: testURL)
    #expect(image == nil)
  }
  
  @Test("Prefetch downloads and caches images")
  func testPrefetch() async throws {
    // Mock URLSession with test image data
    let mockSession = MockURLSession()
    let service = ImageCacheService(
      configuration: .test,
      session: mockSession
    )
    
    await service.prefetchImages([testURL])
    
    let cached = await service.cachedImage(for: testURL)
    #expect(cached != nil)
  }
  
  @Test("Cache size respects limits")
  func testCacheSizeLimit() async throws {
    let config = ImageCacheConfiguration(
      maxDiskSize: 1024, // 1KB limit
      maxMemorySize: 512,
      cacheDirectory: FileManager.default.temporaryDirectory,
      prefetchConcurrency: 2
    )
    let service = ImageCacheService(configuration: config)
    
    // Attempt to cache large image (> 1KB)
    let largeData = Data(repeating: 0, count: 2048)
    // ... should evict or fail gracefully
  }
  
  @Test("Concurrent prefetch works correctly")
  func testConcurrentPrefetch() async {
    let urls = (1...10).map { URL(string: "https://example.com/\($0).jpg")! }
    
    await service.prefetchImages(urls)
    
    // All should be attempted (success depends on mock)
    let size = await service.cacheSize()
    #expect(size > 0)
  }
}
```

#### ErrorPresentingTests

```swift
import Testing
@testable import FitToday

@Suite("ErrorPresenting Tests")
struct ErrorPresentingTests {
  
  @Test("DomainError maps to user-friendly message")
  func testDomainErrorMapping() {
    let error = DomainError.networkFailure
    let message = ErrorMapper.userFriendlyMessage(for: error)
    
    #expect(message.title == "Sem conexão")
    #expect(message.message.contains("internet"))
    #expect(message.action != nil)
  }
  
  @Test("URLError timeout maps correctly")
  func testURLErrorTimeout() {
    let error = URLError(.timedOut)
    let message = ErrorMapper.userFriendlyMessage(for: error)
    
    #expect(message.title == "Tempo esgotado")
    #expect(message.message.contains("Tente novamente"))
  }
  
  @Test("ViewModel can adopt ErrorPresenting")
  func testViewModelAdoption() {
    class TestViewModel: ObservableObject, ErrorPresenting {
      @Published var errorMessage: ErrorMessage?
    }
    
    let vm = TestViewModel()
    vm.handleError(DomainError.profileNotFound)
    
    #expect(vm.errorMessage != nil)
    #expect(vm.errorMessage?.title == "Perfil não encontrado")
  }
}
```

#### WorkoutHistoryRepositoryTests

```swift
@Suite("WorkoutHistoryRepository Pagination Tests")
struct WorkoutHistoryRepositoryTests {
  
  @Test("Pagination returns correct subset")
  @MainActor
  func testPagination() async throws {
    let container = ModelContainer.testContainer()
    let repo = SwiftDataWorkoutHistoryRepository(modelContainer: container)
    
    // Insert 30 test entries
    for i in 0..<30 {
      let entry = WorkoutHistoryEntry.mock(id: UUID())
      try await repo.saveEntry(entry)
    }
    
    // Fetch page 1 (0-19)
    let page1 = try await repo.fetchHistory(limit: 20, offset: 0)
    #expect(page1.count == 20)
    
    // Fetch page 2 (20-29)
    let page2 = try await repo.fetchHistory(limit: 20, offset: 20)
    #expect(page2.count == 10)
    
    // Verify no overlap
    let page1IDs = Set(page1.map(\.id))
    let page2IDs = Set(page2.map(\.id))
    #expect(page1IDs.isDisjoint(with: page2IDs))
  }
  
  @Test("Count returns total entries")
  @MainActor
  func testCount() async throws {
    let container = ModelContainer.testContainer()
    let repo = SwiftDataWorkoutHistoryRepository(modelContainer: container)
    
    // Insert 15 entries
    for _ in 0..<15 {
      try await repo.saveEntry(WorkoutHistoryEntry.mock())
    }
    
    let count = try await repo.fetchHistoryCount()
    #expect(count == 15)
  }
}
```

### Mocks

#### MockImageCacheService

```swift
final class MockImageCacheService: ImageCaching {
  var cachedImages: [URL: UIImage] = [:]
  var prefetchedURLs: [URL] = []
  
  func cacheImage(from url: URL) async throws {
    cachedImages[url] = UIImage(systemName: "photo")
  }
  
  func cachedImage(for url: URL) async -> UIImage? {
    cachedImages[url]
  }
  
  func prefetchImages(_ urls: [URL]) async {
    prefetchedURLs.append(contentsOf: urls)
    for url in urls {
      try? await cacheImage(from: url)
    }
  }
  
  func clearCache() async {
    cachedImages.removeAll()
  }
  
  func cacheSize() async -> Int64 {
    Int64(cachedImages.count * 1024)
  }
}
```

#### MockWorkoutHistoryRepository

```swift
final class MockWorkoutHistoryRepository: WorkoutHistoryRepository {
  var entries: [WorkoutHistoryEntry] = []
  
  func fetchHistory(limit: Int, offset: Int) async throws -> [WorkoutHistoryEntry] {
    let sorted = entries.sorted { $0.completedAt > $1.completedAt }
    let start = offset
    let end = min(offset + limit, sorted.count)
    return Array(sorted[start..<end])
  }
  
  func fetchHistoryCount() async throws -> Int {
    entries.count
  }
  
  func saveEntry(_ entry: WorkoutHistoryEntry) async throws {
    entries.append(entry)
  }
}
```

## Sequenciamento de Desenvolvimento

### Ordem de Construção

**Fase 1 - Sprint de 2 semanas (tasks executadas em ordem):**

#### 1. Task 1.0: ImageCacheService (2 dias)
**Por que primeiro:** Base fundamental, independente de outros componentes

**Subtarefas:**
1. Criar `ImageCacheConfiguration` struct
2. Implementar `DiskImageCache` actor
3. Implementar `ImageCacheService` com protocol
4. Adicionar método `prefetchImages` com concurrency
5. Registrar no DI container (AppContainer)
6. Criar testes unitários completos

**Entregável:** ImageCacheService funcional com testes passando

#### 2. Task 2.0: Error Handling Infrastructure (1 dia)
**Por que agora:** Paralelo com Task 1.0, independente

**Subtarefas:**
1. Criar `ErrorMessage` model
2. Criar protocol `ErrorPresenting` com extension
3. Implementar `ErrorMapper` para DomainError, URLError, OpenAIError
4. Criar `ErrorToastView` SwiftUI component
5. Testes unitários para ErrorMapper
6. Documentação com exemplo de uso

**Entregável:** Infraestrutura de error handling pronta para adoção

#### 3. Task 3.0: Integrar cache nas telas (1 dia)
**Depende de:** Task 1.0 (precisa ImageCacheService)

**Subtarefas:**
1. Criar `CachedAsyncImage` SwiftUI wrapper
2. Substituir `AsyncImage` em `ExerciseMediaImage.swift`
3. Adicionar prefetch em `WorkoutPlanView.onAppear`
4. Implementar placeholder com SF Symbol
5. Adicionar ProgressView durante prefetch
6. Testar fluxo offline (modo avião)

**Entregável:** Imagens cacheadas em toda UI de treino

#### 4. Task 4.0: Error handling nos ViewModels (1.5 dias)
**Depende de:** Task 2.0 (precisa ErrorPresenting)

**Subtarefas:**
1. Implementar `ErrorPresenting` em `HomeViewModel`
2. Implementar em `WorkoutPlanViewModel`
3. Implementar em `DailyQuestionnaireViewModel`
4. Implementar em `LibraryViewModel`
5. Adicionar `ErrorToastView` nas respectivas Views
6. Testar todos cenários de erro

**Entregável:** Error handling consistente em todos ViewModels principais

#### 5. Task 5.0: SwiftData Optimization (1 dia)
**Paralelo:** Independente das outras tasks

**Subtarefas:**
1. Adicionar `@Attribute(.indexed)` em `SDWorkoutHistoryEntry`
2. Implementar métodos paginados no repository
3. Refatorar `HistoryView` com LazyVStack e onAppear
4. Adicionar loading indicator no scroll infinito
5. Testar migration com dados existentes
6. Performance testing com Instruments

**Entregável:** Histórico rápido mesmo com 100+ treinos

#### 6. Task 6.0: Testing & Performance Audit (1.5 dias)
**Por que no final:** Consolida e valida tudo

**Subtarefas:**
1. Atingir targets de cobertura (Domain 80%, ViewModels 70%, Repos 60%)
2. Adicionar testes de integração para fluxos críticos
3. Performance testing com SwiftUI Instrument
4. Documentar APIs públicas (DocC comments)
5. README atualizado com novas features
6. Checklist de QA manual

**Entregável:** Suite de testes completa, performance validada

### Dependências Técnicas

**Bloqueantes:**
- Nenhuma infraestrutura nova necessária
- Todas dependências já presentes (SwiftUI, SwiftData, Swinject)

**Não-bloqueantes (bom ter):**
- Xcode 15.2+ para Swift Testing macros
- iOS 17.2+ device para teste de SwiftData migration
- Instruments app para performance profiling

## Considerações Técnicas

### Decisões Principais

#### Decisão 1: Cache Híbrido (URLCache + Disk)

**Escolha:** Implementar DiskImageCache custom + usar URLCache do sistema

**Justificativa:**
- **URLCache**: Rápido (memória), gerenciado pelo sistema, integração nativa com URLSession
- **Disk cache custom**: Persistente entre launches, controle total sobre eviction policy (LRU)
- **Híbrido**: Melhor dos dois mundos - performance + persistência

**Trade-offs:**
- ✅ Performance excelente (hit em memória < 10ms)
- ✅ Persistência entre app kills
- ✅ Controle total sobre disk space
- ❌ Código extra para gerenciar disk cache
- ❌ Complexidade de sincronização entre layers

**Alternativas rejeitadas:**
- ❌ **Apenas URLCache**: Não persiste entre launches, usuário perde cache sempre
- ❌ **Apenas custom disk**: Reinventa roda para cache de memória, performance pior
- ❌ **Third-party (Kingfisher, SDWebImage)**: Dependency extra, overkill para nosso caso

**Implementação:**
- `ImageCacheService` coordena ambos layers
- Read path: URLCache → Disk → Network
- Write path: Network → Disk + URLCache
- Actor `DiskImageCache` para thread-safety

#### Decisão 2: Prefetch Strategy

**Escolha:** Background prefetch após gerar treino, não bloquear UI

**Justificativa:**
- Usuário quer ver lista de exercícios rapidamente (< 2s)
- Download pode levar 10-15s dependendo de conexão
- Primeiras 3 imagens priorizadas, resto em background

**Trade-offs:**
- ✅ UX fluida, usuário não espera
- ✅ App utilizável enquanto prefetch roda
- ❌ Usa mais banda (download todas imagens mesmo se usuário não ver todas)
- ❌ Prefetch pode não completar se usuário fecha app rápido

**Mitigação do trade-off:**
- Detectar WiFi vs cellular: apenas WiFi por default
- Settings toggle: "Baixar imagens em dados móveis"
- Apenas imagens do treino atual, não toda biblioteca (savings de 90%)

**Implementação:**
```swift
.task {
  if Network.isWiFi || userAllowsCellular {
    await imageCacheService.prefetchImages(imageURLs)
  }
}
```

#### Decisão 3: Error Presentation Pattern

**Escolha:** Protocol `ErrorPresenting` + `ErrorMessage` model + `ErrorToastView`

**Justificativa:**
- **Consistência**: Todos ViewModels apresentam erros da mesma forma
- **Testabilidade**: Mock ErrorMessage facilmente, testar cada caso
- **Extensibilidade**: Adicionar analytics tracking depois sem mudar ViewModels
- **Separation of Concerns**: Mapeamento de erros separado de apresentação

**Trade-offs:**
- ✅ Código limpo e consistente
- ✅ Fácil adicionar novos ViewModels
- ✅ Testável 100%
- ❌ Boilerplate inicial (criar protocol, mapper, view)
- ❌ ViewModels precisam implementar protocol

**Alternativas rejeitadas:**
- ❌ **ViewModels fazem próprio error handling**: Inconsistente, duplicação de código
- ❌ **Global error handler singleton**: Acoplamento alto, difícil testar, não contextual
- ❌ **SwiftUI ErrorAlert modifier**: Não customizável suficiente, estilo iOS genérico

**Implementação:**
- Protocol com default implementation
- Extension adiciona `handleError` automaticamente
- ViewModel só precisa chamar `handleError(error)` em catch blocks

#### Decisão 4: SwiftData Índices

**Escolha:** Adicionar `.indexed` em `completedAt` e `status`

**Justificativa:**
- Queries sempre fazem sort por `completedAt DESC`
- Filtros futuros podem usar `status` (completed, skipped)
- Índices transformam O(n) em O(log n) para essas queries

**Trade-offs:**
- ✅ Performance improvement significativo (10x-100x em grandes datasets)
- ✅ Custo baixo (apenas 2 índices, fields pequenos)
- ❌ Requer migration (risco de falha)
- ❌ Disk space extra (~5% do database size)

**Mitigação do risco de migration:**
```swift
// Migration strategy
let schema = Schema([
  SDWorkoutHistoryEntry.self,
  // ... other models
])

let config = ModelConfiguration(
  schema: schema,
  isStoredInMemoryOnly: false,
  allowsSave: true
)

// SwiftData handles lightweight migrations automatically
// If fails, app will request to clear data (last resort)
```

### Riscos Conhecidos

#### Risco 1: Cache Disk Size

**Problema:** 500MB pode ser muito para alguns usuários (iPhones antigos com 64GB)

**Probabilidade:** Média (20% dos usuários)

**Impacto:** Alto (usuário pode desinstalar app)

**Mitigação:**
1. **Settings**: Botão "Limpar Cache de Imagens" em Settings/Storage
2. **Smart eviction**: LRU garante que imagens antigas são removidas
3. **Monitoring**: Log cache size em console durante development
4. **Future**: Analytics para decidir limite ideal baseado em dados reais

**Plano B:** Se muitas reclamações, reduzir para 250MB

#### Risco 2: Prefetch Usa Muita Banda

**Problema:** Usuários com plano de dados limitado (1-5GB/mês) podem ter custo extra

**Probabilidade:** Média (30% dos usuários em Brasil)

**Impacto:** Alto (bad reviews, churn)

**Mitigação:**
1. **WiFi-only por default**: `Network.isWiFi` check antes de prefetch
2. **Settings toggle**: "Baixar imagens em dados móveis" (OFF por default)
3. **User education**: Toast na primeira vez: "Imagens serão baixadas em WiFi automaticamente"
4. **Progressive download**: Apenas primeiras 3 imagens em cellular, resto em WiFi

**Plano B:** Se reviews mencionam uso de dados, adicionar alerta mais proeminente

#### Risco 3: SwiftData Migration Failure

**Problema:** Adicionar índices requer migration, pode falhar em alguns devices

**Probabilidade:** Baixa (5% dos usuários)

**Impacto:** Crítico (app crash ao abrir)

**Mitigação:**
1. **Testing extensivo**: Testar migration em iOS 17.0, 17.1, 17.2+ 
2. **Fallback graceful**: Catch migration error, oferecer "Resetar Dados"
3. **Backup**: Antes de migration, export dados para JSON (se possível)
4. **Gradual rollout**: Release para 10% → 50% → 100% (crash rate monitoring)

**Código de fallback:**
```swift
do {
  let container = try ModelContainer(for: schema, configurations: [config])
} catch {
  // Migration failed
  print("[Migration] Failed: \(error)")
  // Offer user to reset data
  showResetDataAlert()
}
```

### Requisitos Especiais

#### Performance Targets

| Métrica | Target | Como Medir |
|---------|--------|------------|
| Image cache hit | < 50ms | Instruments: Time Profiler |
| Prefetch completo (10 imgs) | < 15s | Timer em WorkoutPlanView |
| History load (20 items) | < 100ms | Instruments: SwiftData profiler |
| Error presentation | < 16ms (1 frame) | Instruments: SwiftUI instrument |
| App launch | < 2s cold start | Instruments: App Launch |

**Validação:**
- Rodar SwiftUI Instrument antes/depois de cada task
- Comparar métricas com baseline
- Se degradação > 10%, investigar e otimizar

#### Monitoramento (Development)

Durante desenvolvimento, logar métricas em console:

```swift
#if DEBUG
print("[Performance] Image cache hit in \(duration)ms")
print("[Performance] History loaded in \(duration)ms")
print("[Cache] Current size: \(size / 1024 / 1024)MB")
print("[Cache] Hit rate: \(hitRate * 100)%")
#endif
```

**Targets para marcar verde:**
- Cache hit rate > 95%
- Prefetch success rate > 98%
- Zero errors técnicos em logs (apenas errors user-friendly)

#### Acessibilidade

1. **VoiceOver**: ErrorToastView deve anunciar automaticamente quando aparecer
```swift
.accessibilityLabel("\(title). \(message)")
.accessibilityAddTraits(.isStaticText)
```

2. **Dynamic Type**: ErrorToastView suporta até accessibility5
```swift
Text(title)
  .font(.headline)
  .dynamicTypeSize(...DynamicTypeSize.accessibility5)
```

3. **Reduced Motion**: Toast usa fade simples se `accessibilityReduceMotion` ativo
```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

.transition(reduceMotion ? .opacity : .move(edge: .top))
```

### Conformidade com Padrões

#### Code Standards (.cursor/rules/code-standards.md)

**Seguir Kodeco Swift Style Guide:**

1. **Indentation**: 2 spaces (não tabs)
```swift
func example() {
  if condition {
    doSomething()
  }
}
```

2. **Protocol-Oriented Design**: Protocols antes de implementação
```swift
protocol ImageCaching: Sendable {
  func cacheImage(from url: URL) async throws
}

final class ImageCacheService: ImageCaching {
  // implementation
}
```

3. **Value Types**: Structs por default, classes quando referência necessária
```swift
struct ErrorMessage { } // Value semantics ✓
final class ImageCacheService { } // Precisa ser referência ✓
```

4. **Guard for Golden Path**: Early returns com guard
```swift
func loadImage() async {
  guard let url else { return }
  guard let data = try? await download(url) else { return }
  // Happy path continua
}
```

5. **Async/Await**: Sempre para operações assíncronas
```swift
func prefetchImages(_ urls: [URL]) async {
  await withTaskGroup { group in
    // concurrent tasks
  }
}
```

#### iOS Development Skill (.cursor/skills/ios-development-skill/)

**Protocol-First APIs:**
- `ImageCaching` protocol definido antes de `ImageCacheService`
- `ErrorPresenting` protocol com default implementation
- Fácil mockar para testes

**Async/Await Patterns:**
- `async throws` para operações que podem falhar
- `await` para operações assíncronas
- `withTaskGroup` para concurrency controlada

**Memory Management:**
- `[weak self]` em closures que escapam
- Actors para shared mutable state (`DiskImageCache`)
- Sendable conformance para thread-safety

#### SwiftUI Performance (.cursor/skills/swiftui-performance-audit/)

**Evitar work em `body`:**
```swift
// ❌ BAD
var body: some View {
  let formattedDate = formatDate(date) // Runs every render
  Text(formattedDate)
}

// ✅ GOOD
@State private var formattedDate: String

.task {
  formattedDate = formatDate(date) // Runs once
}
```

**Granular ViewModels:**
- ViewModel específico para cada View
- Não passar `@EnvironmentObject` gigante
- Apenas state necessário em `@Published`

**Profile com Instruments:**
- Usar SwiftUI Instrument para detectar Long View Body Updates
- Time Profiler para hot paths
- Testar em device real (não apenas simulator)

### Arquivos Relevantes

#### Arquivos a Modificar

| Arquivo | Modificação | Motivo |
|---------|-------------|---------|
| `ExerciseMediaImage.swift` | Substituir AsyncImage por CachedAsyncImage | Integrar cache |
| `WorkoutPlanView.swift` | Adicionar prefetch onAppear | Download proativo |
| `HistoryView.swift` | LazyVStack + pagination | Performance |
| `HomeViewModel.swift` | Implementar ErrorPresenting | Error handling |
| `DailyQuestionnaireViewModel.swift` | Implementar ErrorPresenting | Error handling |
| `WorkoutHistoryRepository.swift` | Adicionar paginação | Performance |
| `DomainError.swift` | Adicionar userFacingMessage | Error mapping |
| `SDWorkoutHistoryEntry.swift` | Adicionar índices | Query performance |
| `AppContainer.swift` | Registrar ImageCacheService | DI |

#### Arquivos a Criar

**Data Layer:**
- `Data/Services/ImageCache/ImageCacheService.swift`
- `Data/Services/ImageCache/DiskImageCache.swift`
- `Data/Services/ImageCache/ImageCacheConfiguration.swift`

**Presentation Layer:**
- `Presentation/Infrastructure/ErrorPresenting.swift`
- `Presentation/Infrastructure/ErrorMessage.swift`
- `Presentation/Infrastructure/ErrorMapper.swift`
- `Presentation/DesignSystem/ErrorToastView.swift`
- `Presentation/DesignSystem/CachedAsyncImage.swift`

**Tests:**
- `FitTodayTests/Data/Services/ImageCacheServiceTests.swift`
- `FitTodayTests/Data/Services/DiskImageCacheTests.swift`
- `FitTodayTests/Presentation/ErrorPresentingTests.swift`
- `FitTodayTests/Presentation/ErrorMapperTests.swift`
- `FitTodayTests/Data/Repositories/WorkoutHistoryRepositoryTests.swift`

**Total:** 9 arquivos modificados, 13 arquivos criados, 5 arquivos de teste

