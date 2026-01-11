# [3.0] Integrar image cache nas telas (M)

## markdown

## status: completed

<task_context>
<domain>presentation/design-system</domain>
<type>integration</type>
<scope>core_feature</scope>
<complexity>medium</complexity>
<dependencies>image-cache-service</dependencies>
</task_context>

# Tarefa 3.0: Integrar Image Cache nas Telas

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

Integrar o `ImageCacheService` criado na Task 1.0 em todas as telas que exibem imagens de exercícios, substituindo `AsyncImage` por `CachedAsyncImage` customizado e adicionando prefetch proativo de imagens ao gerar treinos. Esta task torna o app utilizável 100% offline após primeiro uso.

A integração principal é em `ExerciseMediaImage.swift` (componente usado em toda UI de exercícios) e `WorkoutPlanView.swift` (onde prefetch acontece ao gerar treino).

<requirements>
- Criar SwiftUI component `CachedAsyncImage` que usa ImageCacheService
- Substituir `AsyncImage` em `ExerciseMediaImage.swift` por `CachedAsyncImage`
- Adicionar Environment key para injetar ImageCacheService via DI
- Implementar prefetch automático em `WorkoutPlanView.onAppear`
- Placeholder inteligente: SF Symbol do músculo correspondente se imagem não disponível
- ProgressView durante primeira carga/prefetch
- Testar fluxo offline completo (modo avião)
- Indicador visual de "Preparando treino..." durante prefetch
- Graceful degradation se prefetch falhar (imagens carregam on-demand)
</requirements>

## Subtarefas

- [ ] 3.1 Criar `CachedAsyncImage` SwiftUI wrapper component
- [ ] 3.2 Criar Environment key para `ImageCacheService` (DI via SwiftUI)
- [ ] 3.3 Substituir `AsyncImage` em `ExerciseMediaImage.swift` por `CachedAsyncImage`
- [ ] 3.4 Implementar método `extractImageURLs()` em WorkoutPlan extension
- [ ] 3.5 Adicionar prefetch logic em `WorkoutPlanView.onAppear` (ou `.task`)
- [ ] 3.6 Adicionar UI feedback: "Preparando treino..." durante prefetch
- [ ] 3.7 Testar offline mode (modo avião) em device real
- [ ] 3.8 Adicionar fallback para placeholders de músculo (SF Symbols)

## Detalhes de Implementação

### Referência Completa

Ver [`techspec.md`](techspec.md) seções:
- "Pontos de Integração" → "1. ExerciseDB Integration" - CachedAsyncImage detalhado
- "Pontos de Integração" → "2. WorkoutPlanView Integration" - Prefetch logic

### CachedAsyncImage Component

```swift
import SwiftUI

/// SwiftUI component que carrega imagens via ImageCacheService
struct CachedAsyncImage: View {
  let url: URL?
  let placeholder: Image
  let size: CGSize?
  
  @Environment(\.imageCacheService) private var cacheService
  @State private var image: UIImage?
  @State private var isLoading = true
  
  init(
    url: URL?,
    placeholder: Image = Image(systemName: "photo"),
    size: CGSize? = nil
  ) {
    self.url = url
    self.placeholder = placeholder
    self.size = size
  }
  
  var body: some View {
    Group {
      if let image {
        Image(uiImage: image)
          .resizable()
          .aspectRatio(contentMode: .fit)
      } else if isLoading {
        ProgressView()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .background(FitTodayColor.surface)
      } else {
        // Fallback placeholder
        placeholder
          .resizable()
          .aspectRatio(contentMode: .fit)
          .foregroundStyle(FitTodayColor.textTertiary)
          .padding()
          .background(FitTodayColor.surface)
      }
    }
    .frame(width: size?.width, height: size?.height)
    .task {
      await loadImage()
    }
  }
  
  private func loadImage() async {
    guard let url else {
      isLoading = false
      return
    }
    
    // Try cache first (fast)
    if let cached = await cacheService.cachedImage(for: url) {
      image = cached
      isLoading = false
      return
    }
    
    // Cache miss: download and cache (slower)
    do {
      try await cacheService.cacheImage(from: url)
      image = await cacheService.cachedImage(for: url)
    } catch {
      print("[CachedAsyncImage] Failed to load \(url): \(error)")
    }
    
    isLoading = false
  }
}

// Environment key for dependency injection
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

### ExerciseMediaImage Integration

**Current state (simplified):**
```swift
struct ExerciseMediaImage: View {
  let media: ExerciseMedia?
  
  var body: some View {
    if let gifURL = media?.gifURL {
      AsyncImage(url: gifURL) { image in
        image.resizable()
      } placeholder: {
        ProgressView()
      }
    } else {
      placeholderImage
    }
  }
}
```

**New state:**
```swift
struct ExerciseMediaImage: View {
  let media: ExerciseMedia?
  let muscleGroup: MuscleGroup? // For fallback icon
  
  var body: some View {
    if let gifURL = media?.gifURL {
      CachedAsyncImage(
        url: gifURL,
        placeholder: musclePlaceholder,
        size: CGSize(width: 300, height: 300)
      )
      .cornerRadius(FitTodayRadius.md)
      .fitCardShadow()
    } else {
      musclePlaceholder
        .resizable()
        .frame(width: 200, height: 200)
    }
  }
  
  private var musclePlaceholder: Image {
    guard let muscle = muscleGroup else {
      return Image(systemName: "figure.walk")
    }
    
    // Map muscle group to SF Symbol
    let symbolName: String
    switch muscle {
    case .chest:
      symbolName = "figure.strengthtraining.traditional"
    case .back:
      symbolName = "figure.flexibility"
    case .legs:
      symbolName = "figure.run"
    case .shoulders:
      symbolName = "figure.arms.open"
    case .arms:
      symbolName = "figure.strengthtraining.functional"
    case .core:
      symbolName = "figure.core.training"
    case .cardio:
      symbolName = "heart.fill"
    }
    
    return Image(systemName: symbolName)
  }
}
```

### WorkoutPlan Extension (Helper)

```swift
extension WorkoutPlan {
  /// Extrai todas URLs de imagens do plano (todas as fases, todos exercícios)
  func extractImageURLs() -> [URL] {
    var urls: [URL] = []
    
    for phase in phases {
      for item in phase.items {
        if case .exercise(let prescription) = item {
          if let gifURL = prescription.exercise.media?.gifURL {
            urls.append(gifURL)
          }
          if let imageURL = prescription.exercise.media?.imageURL {
            urls.append(imageURL)
          }
        }
      }
    }
    
    return urls
  }
}
```

### WorkoutPlanView Integration

**Add prefetch logic:**

```swift
struct WorkoutPlanView: View {
  @EnvironmentObject private var sessionStore: WorkoutSessionStore
  @Environment(\.imageCacheService) private var imageCacheService
  
  @State private var isPrefetching = false
  @State private var prefetchProgress: Double = 0.0
  
  var body: some View {
    Group {
      if let plan = sessionStore.plan {
        if isPrefetching {
          prefetchingView
        } else {
          mainContent(for: plan)
        }
      } else {
        emptyStateView
      }
    }
    .task {
      await prefetchImagesIfNeeded()
    }
  }
  
  private var prefetchingView: some View {
    VStack(spacing: FitTodaySpacing.lg) {
      ProgressView(value: prefetchProgress)
        .progressViewStyle(.linear)
        .tint(FitTodayColor.brandPrimary)
      
      Text("Preparando seu treino...")
        .font(.system(.body, weight: .medium))
        .foregroundStyle(FitTodayColor.textSecondary)
      
      Text("Baixando imagens dos exercícios")
        .font(.system(.caption))
        .foregroundStyle(FitTodayColor.textTertiary)
    }
    .padding()
  }
  
  private func mainContent(for plan: WorkoutPlan) -> some View {
    // ... existing content
  }
  
  private func prefetchImagesIfNeeded() async {
    guard let plan = sessionStore.plan else { return }
    
    let imageURLs = plan.extractImageURLs()
    guard !imageURLs.isEmpty else { return }
    
    // Check if already cached
    var needsPrefetch = false
    for url in imageURLs {
      if await imageCacheService.cachedImage(for: url) == nil {
        needsPrefetch = true
        break
      }
    }
    
    guard needsPrefetch else { return }
    
    // Show prefetching UI
    isPrefetching = true
    
    // Prefetch with progress tracking
    let totalCount = imageURLs.count
    var completedCount = 0
    
    for url in imageURLs {
      try? await imageCacheService.cacheImage(from: url)
      completedCount += 1
      prefetchProgress = Double(completedCount) / Double(totalCount)
    }
    
    // Hide prefetching UI
    try? await Task.sleep(for: .milliseconds(300))
    isPrefetching = false
  }
}
```

### WiFi Detection (Optional Enhancement)

```swift
import Network

extension NetworkMonitor {
  static var isWiFi: Bool {
    let monitor = NWPathMonitor()
    var isWiFi = false
    let semaphore = DispatchSemaphore(value: 0)
    
    monitor.pathUpdateHandler = { path in
      isWiFi = path.usesInterfaceType(.wifi)
      semaphore.signal()
    }
    
    monitor.start(queue: .global())
    semaphore.wait()
    monitor.cancel()
    
    return isWiFi
  }
}

// In prefetch logic:
@AppStorage("prefetchOnCellular") var allowCellular = false

private func prefetchImagesIfNeeded() async {
  // Check network type
  guard NetworkMonitor.isWiFi || allowCellular else {
    print("[Prefetch] Skipping - cellular data and user disabled prefetch on cellular")
    return
  }
  
  // Continue with prefetch...
}
```

### Settings Toggle (Future Phase)

```swift
// In ProfileProView or Settings:
Toggle("Baixar imagens em dados móveis", isOn: $allowCellular)
  .font(.system(.body))
  .tint(FitTodayColor.brandPrimary)
```

## Critérios de Sucesso

### Funcionalidade
- ✅ Imagens aparecem instantaneamente após cache (< 1s)
- ✅ App funciona 100% offline em modo avião após primeiro uso
- ✅ Prefetch completa em < 15s para treino típico (10 exercícios)
- ✅ Placeholder muscle icon aparece se imagem não disponível
- ✅ ProgressView mostra durante primeira carga
- ✅ "Preparando treino..." aparece durante prefetch inicial

### Performance
- ✅ Cache hit retorna imagem em < 50ms
- ✅ Prefetch não bloqueia UI (usuário pode navegar)
- ✅ Scroll suave em lista de exercícios (60fps)
- ✅ Sem memory leaks (testar com Instruments)

### UX
- ✅ Transições suaves (sem "pop" de placeholder → imagem)
- ✅ Feedback visual claro durante loading states
- ✅ Placeholders são informativos (muscle icon, não genérico)
- ✅ Offline mode é transparente para usuário

### Compatibilidade
- ✅ Funciona em iOS 17.0+
- ✅ Light/Dark mode suportados
- ✅ Dynamic Type suportado
- ✅ Accessibility traits corretos

## Dependências

**Bloqueante:** Task 1.0 (ImageCacheService) deve estar completa.

**Arquivos modificados:**
- `ExerciseMediaImage.swift` - substituir AsyncImage
- `WorkoutPlanView.swift` - adicionar prefetch

## Observações

### Muscle Group to SF Symbol Mapping

Complete mapping:

```swift
enum MuscleGroup {
  case chest, back, shoulders, arms, legs, core, cardio, fullBody
  
  var sfSymbolName: String {
    switch self {
    case .chest: return "figure.strengthtraining.traditional"
    case .back: return "figure.flexibility"
    case .shoulders: return "figure.arms.open"
    case .arms: return "figure.strengthtraining.functional"
    case .legs: return "figure.run"
    case .core: return "figure.core.training"
    case .cardio: return "heart.fill"
    case .fullBody: return "figure.walk"
    }
  }
  
  var color: Color {
    switch self {
    case .chest: return .blue
    case .back: return .green
    case .shoulders: return .orange
    case .arms: return .purple
    case .legs: return .red
    case .core: return .yellow
    case .cardio: return .pink
    case .fullBody: return .gray
    }
  }
}
```

### Prefetch Strategy Decisions

**When to prefetch:**
- ✅ On workout generation (WorkoutPlanView appears)
- ✅ On app launch if workout exists (future phase)
- ❌ NOT on every tab switch (too aggressive)

**What to prefetch:**
- ✅ GIF URLs (primary media)
- ✅ Image URLs (fallback/alternative)
- ❌ NOT entire library (only current workout)

**How to handle failures:**
- Silently fail individual images (log error)
- Continue prefetch for remaining images
- Fallback to on-demand loading if user opens exercise before prefetch done

### Testing Offline Mode

**Manual test steps:**
1. Clean install app (delete data)
2. Connect WiFi
3. Generate workout
4. Wait for "Preparando treino..." to complete
5. Enable Airplane Mode (Settings → Airplane Mode ON)
6. Navigate through workout, open all exercises
7. Verify all images load instantly
8. Try generating new workout → should fail gracefully with error message

### Performance Testing with Instruments

**Metrics to validate:**
- Time Profiler: `cachedImage(for:)` should be < 50ms
- Allocations: No memory growth during scroll
- Network: Zero network requests after prefetch
- SwiftUI: Long View Body Updates should be minimal

### Error Scenarios to Handle

1. **Network timeout during prefetch**: Continue with remaining images
2. **Invalid image data**: Show placeholder, don't crash
3. **Cache full during prefetch**: Evict LRU, continue
4. **User force quits during prefetch**: Resume on next launch (idempotent)

### Future Enhancements (Out of Scope)

- ❌ Progressive image loading (thumbnail → full res)
- ❌ Prefetch prediction (predict next workout based on history)
- ❌ Background fetch (download images when app in background)
- ❌ Cache analytics (hit rate, size trends)

## Arquivos relevantes

### Criar (novos arquivos)

```
FitToday/FitToday/Presentation/DesignSystem/
└── CachedAsyncImage.swift       (~100 linhas)

FitToday/FitToday/Domain/Entities/
└── WorkoutModels+Extensions.swift (extension com extractImageURLs)
```

### Modificar (existentes)

```
FitToday/FitToday/Presentation/DesignSystem/
└── ExerciseMediaImage.swift     (substituir AsyncImage, ~50 linhas modificadas)

FitToday/FitToday/Presentation/Features/Workout/
└── WorkoutPlanView.swift        (adicionar prefetch logic, ~80 linhas adicionadas)

FitToday/FitToday/Presentation/Root/
└── TabRootView.swift            (opcional: injetar imageCacheService via environment)
```

### Estrutura Detalhada

**CachedAsyncImage.swift:**
```swift
import SwiftUI

struct CachedAsyncImage: View {
  let url: URL?
  let placeholder: Image
  let size: CGSize?
  
  @Environment(\.imageCacheService) private var cacheService
  @State private var image: UIImage?
  @State private var isLoading = true
  
  var body: some View { ... }
  private func loadImage() async { ... }
}

// Environment key
private struct ImageCacheServiceKey: EnvironmentKey { ... }
extension EnvironmentValues { ... }
```

**WorkoutModels+Extensions.swift:**
```swift
extension WorkoutPlan {
  func extractImageURLs() -> [URL] { ... }
}
```

### Estimativa de Tempo

- **3.1** CachedAsyncImage component: 2h
- **3.2** Environment key setup: 30 min
- **3.3** Substituir AsyncImage: 1h
- **3.4** extractImageURLs extension: 30 min
- **3.5** Prefetch logic: 2h
- **3.6** UI feedback: 1h
- **3.7** Offline testing: 1h
- **3.8** Placeholder fallbacks: 1h

**Total: ~9 horas (1 dia de trabalho)**

### Checklist de Finalização

- [ ] Código compila sem warnings
- [ ] CachedAsyncImage testado em simulator e device
- [ ] Offline mode testado em device real (modo avião)
- [ ] Prefetch testado com 10+ exercícios
- [ ] Placeholders testados (muscle icons aparecem)
- [ ] Performance validada com Instruments
- [ ] Memory leaks verificados (nenhum)
- [ ] Code review aprovado
- [ ] Screenshots de before/after (opcional)

