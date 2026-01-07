# [1.0] Implementar ImageCacheService (L)

## markdown

## status: completed

<task_context>
<domain>data/services/image-cache</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>high</complexity>
<dependencies>external_apis</dependencies>
</task_context>

# Tarefa 1.0: Implementar ImageCacheService

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

Criar sistema robusto de cache de imagens com arquitetura híbrida de dois layers (URLCache para memória + DiskImageCache custom para persistência) que permite uso offline completo do app após primeiro download e melhora significativamente a performance de carregamento de imagens da ExerciseDB.

Este é o componente fundamental para suporte offline e será usado por todas as telas que exibem exercícios.

<requirements>
- Implementar protocol `ImageCaching` com métodos: cacheImage, cachedImage, prefetchImages, clearCache, cacheSize
- Cache híbrido: URLCache (memória 50MB) + custom DiskImageCache (disco 500MB) 
- Prefetch inteligente com concurrency controlada (máx 5 downloads paralelos)
- Thread-safe usando actors e async/await
- LRU (Least Recently Used) eviction policy quando cache cheio
- Configurável via `ImageCacheConfiguration` struct
- Registrado no DI container (Swinject) como singleton
- Testes unitários completos com > 90% coverage
</requirements>

## Subtarefas

- [ ] 1.1 Criar `ImageCacheConfiguration` struct com defaults e test config
- [ ] 1.2 Implementar `DiskImageCache` actor com FileManager para persistência
- [ ] 1.3 Implementar `ImageCacheService` classe integrando URLCache + DiskImageCache
- [ ] 1.4 Adicionar método `prefetchImages(_ urls:)` com withTaskGroup para concurrency
- [ ] 1.5 Implementar LRU eviction policy no DiskImageCache
- [ ] 1.6 Registrar ImageCacheService no DI container (AppContainer.swift)
- [ ] 1.7 Criar testes unitários completos (`ImageCacheServiceTests.swift`)
- [ ] 1.8 Validar performance targets com Instruments

## Detalhes de Implementação

### Referência Completa

Ver [`techspec.md`](techspec.md) seções:
- "Interface 1: ImageCaching" - Protocol e implementação detalhada
- "Interface 2: DiskImageCache" - Actor para persistência
- "Design de Implementação" - Fluxo de dados completo

### Arquitetura de Três Layers

```
┌─────────────────────────────────────┐
│  ImageCacheService (Coordinator)    │
│  - Coordena ambos caches            │
│  - Decide ordem de consulta         │
│  - Gerencia downloads               │
└────────┬────────────────────┬───────┘
         │                    │
    ┌────▼────┐          ┌────▼─────┐
    │URLCache │          │DiskImage │
    │(Memory) │          │Cache     │
    │50MB     │          │(Disk)    │
    │Fast     │          │500MB     │
    │Volatile │          │Persistent│
    └─────────┘          └──────────┘
```

### Fluxo de Read (cachedImage)

1. Check URLCache (memória) → se HIT, retorna imediatamente
2. Check DiskImageCache (disco) → se HIT, popula URLCache e retorna
3. Ambos MISS → retorna nil (caller fará download)

### Fluxo de Write (cacheImage)

1. Download da URL com URLSession
2. Validate response (status 200, valid image data)
3. Save no DiskImageCache (persiste)
4. URLCache automaticamente cacheia via URLSession
5. Retorna sucesso ou throw error

### Fluxo de Prefetch

```swift
func prefetchImages(_ urls: [URL]) async {
  await withTaskGroup(of: Void.self) { group in
    for url in urls {
      // Limit concurrency to config.prefetchConcurrency (5)
      if group.taskCount >= config.prefetchConcurrency {
        await group.next() // Wait for slot
      }
      
      group.addTask {
        try? await self.cacheImage(from: url)
      }
    }
  }
}
```

### LRU Eviction Strategy

**Metadata de acesso:**
- Usar extended attributes (xattr) para armazenar timestamp de último acesso
- Atualizar timestamp em cada read
- Quando cache cheio, ordenar por timestamp e remover mais antigos

**Implementação no DiskImageCache:**

```swift
private func evictLRUIfNeeded(toFit requiredSize: Int64) {
  let currentSize = totalSize()
  guard currentSize + requiredSize > config.maxDiskSize else { return }
  
  // Get all files with access timestamps
  let files = try? fileManager.contentsOfDirectory(
    at: cacheDirectory,
    includingPropertiesForKeys: [.contentAccessDateKey]
  )
  
  // Sort by access date (oldest first)
  let sorted = files?.sorted { file1, file2 in
    let date1 = (try? file1.resourceValues(forKeys: [.contentAccessDateKey]))?.contentAccessDate
    let date2 = (try? file2.resourceValues(forKeys: [.contentAccessDateKey]))?.contentAccessDate
    return date1 ?? .distantPast < date2 ?? .distantPast
  }
  
  // Remove oldest until space available
  var freedSpace: Int64 = 0
  for file in sorted ?? [] {
    guard freedSpace < requiredSize else { break }
    let size = (try? file.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
    try? fileManager.removeItem(at: file)
    freedSpace += Int64(size)
  }
}
```

### Hash de URLs

Para nomes de arquivo seguros:

```swift
extension String {
  func sha256Hash() -> String {
    let data = Data(self.utf8)
    let hash = SHA256.hash(data: data)
    return hash.compactMap { String(format: "%02x", $0) }.joined()
  }
}

// Uso:
private func cacheFileURL(for url: URL) -> URL {
  let filename = url.absoluteString.sha256Hash()
  return cacheDirectory.appendingPathComponent(filename)
}
```

### Configuração de URLCache

```swift
let urlCache = URLCache(
  memoryCapacity: config.maxMemorySize,
  diskCapacity: 0, // Não usar disk cache do URLCache (temos custom)
  directory: nil
)
```

### Error Handling

```swift
enum ImageCacheError: Error, LocalizedError {
  case invalidResponse(statusCode: Int)
  case diskWriteFailed(underlying: Error)
  case cacheSizeExceeded
  case invalidImageData
  
  var errorDescription: String? {
    switch self {
    case .invalidResponse(let code):
      return "Invalid response: HTTP \(code)"
    case .diskWriteFailed(let error):
      return "Failed to write to disk: \(error.localizedDescription)"
    case .cacheSizeExceeded:
      return "Cache size limit exceeded"
    case .invalidImageData:
      return "Downloaded data is not a valid image"
    }
  }
}
```

## Critérios de Sucesso

### Funcionalidade
- ✅ Imagem cacheada é retornada em < 50ms (cache hit)
- ✅ Prefetch de 10 imagens completa em < 15s (WiFi típico)
- ✅ Cache sobrevive a app restart (verificar após force quit)
- ✅ Imagens inválidas/corrompidas são tratadas gracefully
- ✅ Cache respeita limite de 500MB (eviction funciona)

### Qualidade de Código
- ✅ Protocol `ImageCaching` implementado completamente
- ✅ Thread-safe (actors + async/await, sem data races)
- ✅ Testes unitários passam com > 90% coverage
- ✅ Zero warnings de compilação
- ✅ Code review aprovado (seguir Kodeco Style Guide)

### Performance
- ✅ Memory cache hit: < 10ms
- ✅ Disk cache hit: < 50ms
- ✅ Cache miss + download: depende de rede, mas não bloqueia UI
- ✅ Prefetch não impacta performance de UI (background priority)

### Testabilidade
- ✅ Mock `MockImageCacheService` funciona para outros testes
- ✅ Test configuration permite testes rápidos (10MB cache)
- ✅ Temporary directory em testes (não poluir cache real)

## Dependências

**Nenhuma** - Esta é a primeira task da fase, completamente independente.

**Frameworks necessários:**
- Foundation (FileManager, URLSession, URLCache)
- CryptoKit (SHA256 para hash)
- SwiftUI (para UIImage)

**Permissões:**
- Nenhuma permissão especial necessária (cache em app sandbox)

## Observações

### Performance Tips

1. **Usar URLSession compartilhado**: `.shared` já tem URLCache configurado
2. **Não force unwrap**: Sempre use optional binding
3. **Background thread**: DiskImageCache operations são I/O bound, actors resolvem isso
4. **Batch operations**: Prefetch usa TaskGroup para paralelismo controlado

### Testing Strategy

**Unit Tests:**
- Mock URLSession com `URLProtocol` custom
- Temporary directory para disk cache em testes
- Testar edge cases: cache cheio, imagens corrompidas, network errors

**Integration Tests:**
- Testar com ExerciseDB URLs reais (optional, em test específico)
- Validar que URLCache e DiskCache trabalham em harmonia

**Performance Tests:**
- Usar XCTMetric para medir tempo de cache hit/miss
- Validar que prefetch não bloqueia main thread

### Debug Logging

```swift
#if DEBUG
private func logCacheStats() {
  print("[ImageCache] Memory cache: \(urlCache.currentMemoryUsage / 1024)KB")
  print("[ImageCache] Disk cache: \(await diskCache.totalSize() / 1024 / 1024)MB")
  print("[ImageCache] Hit rate: \(calculateHitRate() * 100)%")
}
#endif
```

### Future Enhancements (Out of Scope)

- ❌ Image compression/optimization (usar imagens como vêm da API)
- ❌ Progressive image loading (baixar thumbnail → full res)
- ❌ WebP support (apenas JPEG/PNG/GIF por agora)
- ❌ Background fetch (apenas on-demand)

## Arquivos relevantes

### Criar (novos arquivos)

```
FitToday/FitToday/Data/Services/ImageCache/
├── ImageCacheService.swift          (~250 linhas)
├── DiskImageCache.swift             (~180 linhas)
└── ImageCacheConfiguration.swift    (~40 linhas)

FitTodayTests/Data/Services/
└── ImageCacheServiceTests.swift     (~300 linhas)
```

### Modificar (existentes)

```
FitToday/FitToday/Presentation/DI/
└── AppContainer.swift               (adicionar registro do serviço)
```

### Estrutura de Arquivos Detalhada

**ImageCacheConfiguration.swift:**
```swift
import Foundation

struct ImageCacheConfiguration {
  let maxDiskSize: Int64
  let maxMemorySize: Int64
  let cacheDirectory: URL
  let prefetchConcurrency: Int
  
  static let `default`: ImageCacheConfiguration
  static let test: ImageCacheConfiguration
}
```

**DiskImageCache.swift:**
```swift
import Foundation

actor DiskImageCache {
  private let config: ImageCacheConfiguration
  private let fileManager: FileManager
  private let cacheDirectory: URL
  
  init(configuration: ImageCacheConfiguration)
  func data(for url: URL) -> Data?
  func save(_ data: Data, for url: URL)
  func clearAll()
  func totalSize() -> Int64
  private func cacheFileURL(for url: URL) -> URL
  private func updateAccessTime(for fileURL: URL)
  private func evictLRUIfNeeded(toFit requiredSize: Int64)
}
```

**ImageCacheService.swift:**
```swift
import Foundation
import UIKit

protocol ImageCaching: Sendable {
  func cacheImage(from url: URL) async throws
  func cachedImage(for url: URL) async -> UIImage?
  func prefetchImages(_ urls: [URL]) async
  func clearCache() async
  func cacheSize() async -> Int64
}

final class ImageCacheService: ImageCaching {
  private let urlCache: URLCache
  private let diskCache: DiskImageCache
  private let session: URLSession
  private let config: ImageCacheConfiguration
  
  init(configuration: ImageCacheConfiguration,
       urlCache: URLCache = .shared,
       session: URLSession = .shared)
       
  // Implement protocol methods...
}

enum ImageCacheError: Error, LocalizedError {
  case invalidResponse(statusCode: Int)
  case diskWriteFailed(underlying: Error)
  case cacheSizeExceeded
  case invalidImageData
}
```

**ImageCacheServiceTests.swift:**
```swift
import Testing
@testable import FitToday

@Suite("ImageCacheService Tests")
struct ImageCacheServiceTests {
  let service: ImageCacheService
  let testURL: URL
  
  @Test("Cache miss returns nil")
  func testCacheMiss() async
  
  @Test("Successful cache and retrieval")
  func testCacheHit() async throws
  
  @Test("Prefetch downloads multiple images")
  func testPrefetch() async throws
  
  @Test("Cache respects size limits")
  func testSizeLimit() async throws
  
  @Test("LRU eviction works correctly")
  func testLRUEviction() async throws
  
  @Test("Invalid response throws error")
  func testInvalidResponse() async throws
  
  @Test("Concurrent access is thread-safe")
  func testThreadSafety() async throws
}
```

### Estimativa de Tempo

- **1.1** Config struct: 30 min
- **1.2** DiskImageCache: 3-4h
- **1.3** ImageCacheService: 3-4h
- **1.4** Prefetch com concurrency: 1-2h
- **1.5** LRU eviction: 2h
- **1.6** DI registration: 30 min
- **1.7** Testes unitários: 3-4h
- **1.8** Performance validation: 1h

**Total: ~14-18 horas (2 dias de trabalho)**

### Checklist de Finalização

- [ ] Código compila sem warnings
- [ ] Todos testes passam
- [ ] Performance validada com Instruments
- [ ] Code review completo
- [ ] Documentação (DocC comments) em APIs públicas
- [ ] README atualizado mencionando nova feature
- [ ] Commit message descritivo

