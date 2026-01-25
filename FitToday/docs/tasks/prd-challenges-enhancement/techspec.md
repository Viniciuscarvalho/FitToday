# Tech Spec: Challenges Enhancement - FitToday

**Versão:** 1.0
**Data:** 2026-01-25
**PRD Ref:** `prd-challenges-enhancement/prd.md`
**Status:** Draft

---

## 1. Visão Técnica

### 1.1 Resumo
Implementar sistema de check-in com foto obrigatório pós-treino, feed de atividades em tempo real, e celebrações visuais. A feature se integra ao fluxo existente de `WorkoutCompletionView` e utiliza Firebase Storage para armazenamento de imagens.

### 1.2 Decisões Arquiteturais

| Decisão | Escolha | Justificativa |
|---------|---------|---------------|
| Storage de fotos | Firebase Storage | Já integrado ao projeto, SDK nativo iOS |
| Compressão de imagem | 500KB max, JPEG 0.7 | Balança qualidade vs custo |
| Offline | Bloquear check-in | Simplifica v1, garante integridade |
| Estado | @Observable | Padrão do projeto (Swift 6) |
| Concorrência | async/await + actors | Padrão existente no projeto |

---

## 2. Arquitetura de Componentes

```
┌─────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                       │
├─────────────────────────────────────────────────────────────┤
│  WorkoutCompletionView  →  CheckInPhotoView (NEW)           │
│  GroupDashboardView     →  CheckInFeedView (NEW)            │
│  LeaderboardView        →  CelebrationOverlay (NEW)         │
├─────────────────────────────────────────────────────────────┤
│                       DOMAIN LAYER                           │
├─────────────────────────────────────────────────────────────┤
│  CheckInUseCase (NEW)                                        │
│  SyncWorkoutCompletionUseCase (MODIFY)                      │
├─────────────────────────────────────────────────────────────┤
│                        DATA LAYER                            │
├─────────────────────────────────────────────────────────────┤
│  CheckInRepository (NEW)     FirebaseStorageService (NEW)   │
│  FirebaseLeaderboardService (MODIFY)                        │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. Modelos de Dados

### 3.1 Novos Modelos Domain

```swift
// Domain/Entities/SocialModels.swift (ADICIONAR)

struct CheckIn: Codable, Hashable, Sendable, Identifiable {
    let id: String
    let groupId: String
    let challengeId: String
    let userId: String
    var displayName: String
    var userPhotoURL: URL?
    var checkInPhotoURL: URL          // Foto do check-in (obrigatória)
    let workoutEntryId: UUID          // Vínculo com WorkoutHistoryEntry
    var workoutDurationMinutes: Int
    let createdAt: Date
}

enum CheckInError: Error, LocalizedError {
    case workoutTooShort(minutes: Int)
    case photoRequired
    case uploadFailed(underlying: Error)
    case networkUnavailable
    case notInGroup

    var errorDescription: String? {
        switch self {
        case .workoutTooShort(let min):
            return "Treino deve ter no mínimo 30 minutos (atual: \(min) min)"
        case .photoRequired:
            return "Foto é obrigatória para fazer check-in"
        case .uploadFailed(let error):
            return "Falha no upload: \(error.localizedDescription)"
        case .networkUnavailable:
            return "Sem conexão com a internet"
        case .notInGroup:
            return "Você precisa estar em um grupo para fazer check-in"
        }
    }
}
```

### 3.2 Novos DTOs Firebase

```swift
// Data/Models/FirebaseModels.swift (ADICIONAR)

struct FBCheckIn: Codable {
    @DocumentID var id: String?
    var groupId: String
    var challengeId: String
    var userId: String
    var displayName: String
    var userPhotoURL: String?
    var checkInPhotoURL: String       // URL do Firebase Storage
    var workoutEntryId: String
    var workoutDurationMinutes: Int
    @ServerTimestamp var createdAt: Timestamp?
}
```

### 3.3 Firestore Structure

```
/groups/{groupId}/checkIns/{checkInId}
  ├── userId: string
  ├── displayName: string
  ├── userPhotoURL: string?
  ├── checkInPhotoURL: string (required)
  ├── challengeId: string
  ├── workoutEntryId: string
  ├── workoutDurationMinutes: int
  └── createdAt: timestamp

/storage/checkIns/{groupId}/{userId}/{timestamp}.jpg
```

---

## 4. Interfaces e Protocolos

### 4.1 Novo Repository Protocol

```swift
// Domain/Protocols/SocialRepositories.swift (ADICIONAR)

protocol CheckInRepository: Sendable {
    func createCheckIn(_ checkIn: CheckIn) async throws
    func getCheckIns(groupId: String, limit: Int, after: Date?) async throws -> [CheckIn]
    func observeCheckIns(groupId: String) -> AsyncStream<[CheckIn]>
    func uploadPhoto(imageData: Data, groupId: String, userId: String) async throws -> URL
}
```

### 4.2 Novo Service Protocol

```swift
// Data/Services/Firebase/FirebaseStorageService.swift (NOVO)

protocol StorageServicing: Sendable {
    func uploadImage(data: Data, path: String) async throws -> URL
    func deleteImage(path: String) async throws
}

actor FirebaseStorageService: StorageServicing {
    private let storage = Storage.storage()

    func uploadImage(data: Data, path: String) async throws -> URL {
        let ref = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await ref.putDataAsync(data, metadata: metadata)
        return try await ref.downloadURL()
    }
}
```

---

## 5. Use Cases

### 5.1 CheckInUseCase (NOVO)

```swift
// Domain/UseCases/CheckInUseCase.swift

struct CheckInUseCase: Sendable {
    private let checkInRepository: CheckInRepository
    private let authRepository: AuthenticationRepository
    private let imageCompressor: ImageCompressing
    private let networkMonitor: NetworkMonitor

    private static let minimumWorkoutMinutes = 30
    private static let maxImageSizeBytes = 500_000 // 500KB

    func execute(
        workoutEntry: WorkoutHistoryEntry,
        photoData: Data
    ) async throws -> CheckIn {
        // 1. Validate network
        guard networkMonitor.isConnected else {
            throw CheckInError.networkUnavailable
        }

        // 2. Validate user is in group
        guard let user = try await authRepository.currentUser(),
              let groupId = user.currentGroupId else {
            throw CheckInError.notInGroup
        }

        // 3. Validate workout duration
        let duration = workoutEntry.durationMinutes ?? 0
        guard duration >= Self.minimumWorkoutMinutes else {
            throw CheckInError.workoutTooShort(minutes: duration)
        }

        // 4. Compress image
        let compressed = try imageCompressor.compress(
            data: photoData,
            maxBytes: Self.maxImageSizeBytes,
            quality: 0.7
        )

        // 5. Upload photo
        let photoURL = try await checkInRepository.uploadPhoto(
            imageData: compressed,
            groupId: groupId,
            userId: user.id
        )

        // 6. Create check-in record
        let checkIn = CheckIn(
            id: UUID().uuidString,
            groupId: groupId,
            challengeId: "", // Set by repository
            userId: user.id,
            displayName: user.displayName,
            userPhotoURL: user.photoURL,
            checkInPhotoURL: photoURL,
            workoutEntryId: workoutEntry.id,
            workoutDurationMinutes: duration,
            createdAt: Date()
        )

        try await checkInRepository.createCheckIn(checkIn)

        return checkIn
    }
}
```

---

## 6. Views (SwiftUI)

### 6.1 CheckInPhotoView

```swift
// Presentation/Features/Groups/CheckInPhotoView.swift (NOVO)

struct CheckInPhotoView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CheckInViewModel

    let workoutEntry: WorkoutHistoryEntry
    let onSuccess: (CheckIn) -> Void

    var body: some View {
        NavigationStack {
            VStack {
                // Photo preview ou camera/gallery picker
                PhotoPickerView(selectedImage: $viewModel.selectedImage)

                // Check-in button
                Button("Fazer Check-in") {
                    Task { await viewModel.submitCheckIn() }
                }
                .fitPrimaryStyle()
                .disabled(!viewModel.canSubmit)
            }
            .overlay { if viewModel.isLoading { ProgressView() } }
            .alert("Erro", isPresented: $viewModel.showError) {
                Button("OK") {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}
```

### 6.2 CheckInFeedView

```swift
// Presentation/Features/Groups/CheckInFeedView.swift (NOVO)

struct CheckInFeedView: View {
    @State private var viewModel: CheckInFeedViewModel

    var body: some View {
        ScrollView {
            LazyVStack(spacing: FitTodaySpacing.md) {
                ForEach(viewModel.checkIns) { checkIn in
                    CheckInCardView(checkIn: checkIn)
                }
            }
        }
        .refreshable { await viewModel.refresh() }
        .task { await viewModel.startObserving() }
    }
}

struct CheckInCardView: View {
    let checkIn: CheckIn

    var body: some View {
        VStack(alignment: .leading) {
            // Header: avatar + name + time
            HStack {
                AsyncImage(url: checkIn.userPhotoURL)
                VStack(alignment: .leading) {
                    Text(checkIn.displayName)
                    Text(checkIn.createdAt, style: .relative)
                }
            }
            // Photo
            AsyncImage(url: checkIn.checkInPhotoURL)
                .aspectRatio(4/3, contentMode: .fill)
                .cornerRadius(FitTodayRadius.md)
            // Stats
            Text("\(checkIn.workoutDurationMinutes) min")
        }
        .padding()
        .background(FitTodayColor.cardBackground)
        .cornerRadius(FitTodayRadius.lg)
    }
}
```

### 6.3 CelebrationOverlay

```swift
// Presentation/Features/Groups/CelebrationOverlay.swift (NOVO)

struct CelebrationOverlay: View {
    let type: CelebrationType
    @State private var isAnimating = false

    enum CelebrationType {
        case checkInComplete
        case rankUp(newRank: Int)
        case topThree
    }

    var body: some View {
        ZStack {
            // Confetti particles
            ConfettiView(isAnimating: $isAnimating)

            // Message
            VStack {
                Image(systemName: iconName)
                    .font(.system(size: 60))
                Text(message)
                    .font(.title2.bold())
            }
        }
        .onAppear { isAnimating = true }
    }
}
```

---

## 7. Integração com Fluxo Existente

### 7.1 WorkoutCompletionView (MODIFICAR)

```swift
// Adicionar botão de check-in após rating

if status == .completed && hasRated && isInGroup {
    Button("Fazer Check-in com Foto") {
        showCheckInSheet = true
    }
    .fitPrimaryStyle()
}

.sheet(isPresented: $showCheckInSheet) {
    CheckInPhotoView(
        workoutEntry: currentEntry,
        onSuccess: { checkIn in
            showCelebration = true
        }
    )
}
```

### 7.2 GroupDashboardView (MODIFICAR)

```swift
// Adicionar tab de Feed antes do Leaderboard

TabView {
    CheckInFeedView(viewModel: feedViewModel)
        .tabItem { Label("Feed", systemImage: "photo.stack") }

    LeaderboardView(viewModel: leaderboardViewModel)
        .tabItem { Label("Ranking", systemImage: "trophy") }
}
```

---

## 8. Dependency Injection

```swift
// Presentation/DI/AppContainer.swift (ADICIONAR)

// Firebase Storage Service
container.register(StorageServicing.self) { _ in
    FirebaseStorageService()
}
.inObjectScope(.container)

// Image Compressor
container.register(ImageCompressing.self) { _ in
    ImageCompressor()
}
.inObjectScope(.container)

// Check-In Repository
container.register(CheckInRepository.self) { resolver in
    FirebaseCheckInRepository(
        storageService: resolver.resolve(StorageServicing.self)!
    )
}
.inObjectScope(.container)

// Check-In Use Case
container.register(CheckInUseCase.self) { resolver in
    CheckInUseCase(
        checkInRepository: resolver.resolve(CheckInRepository.self)!,
        authRepository: resolver.resolve(AuthenticationRepository.self)!,
        imageCompressor: resolver.resolve(ImageCompressing.self)!,
        networkMonitor: resolver.resolve(NetworkMonitor.self)!
    )
}
.inObjectScope(.container)
```

---

## 9. Testes

### 9.1 Unit Tests

| Componente | Cenários Críticos |
|------------|-------------------|
| CheckInUseCase | Workout < 30min rejeita, foto comprime corretamente, sem rede bloqueia |
| ImageCompressor | Output ≤ 500KB, qualidade preservada |
| CheckInViewModel | Estados loading/error/success |

### 9.2 Integration Tests

| Fluxo | Validação |
|-------|-----------|
| Upload foto → Storage | URL válida retornada |
| Create check-in → Firestore | Documento criado com campos corretos |
| Observe feed | Real-time updates funcionam |

---

## 10. Arquivos a Criar/Modificar

### Novos Arquivos

| Caminho | Descrição |
|---------|-----------|
| `Domain/Entities/CheckInModels.swift` | Modelos CheckIn, CheckInError |
| `Domain/UseCases/CheckInUseCase.swift` | Lógica de check-in |
| `Domain/Protocols/CheckInRepository.swift` | Protocol |
| `Data/Services/Firebase/FirebaseStorageService.swift` | Upload de imagens |
| `Data/Repositories/FirebaseCheckInRepository.swift` | Implementação |
| `Data/Services/ImageCompressor.swift` | Compressão de imagem |
| `Presentation/Features/Groups/CheckInPhotoView.swift` | UI de foto |
| `Presentation/Features/Groups/CheckInFeedView.swift` | Feed de check-ins |
| `Presentation/Features/Groups/CheckInViewModel.swift` | ViewModel |
| `Presentation/Features/Groups/CheckInFeedViewModel.swift` | ViewModel Feed |
| `Presentation/Features/Groups/CelebrationOverlay.swift` | Animações |

### Arquivos a Modificar

| Caminho | Mudança |
|---------|---------|
| `Data/Models/FirebaseModels.swift` | Adicionar FBCheckIn |
| `Presentation/DI/AppContainer.swift` | Registrar novos serviços |
| `Presentation/Features/Workout/WorkoutCompletionView.swift` | Botão check-in |
| `Presentation/Features/Groups/GroupDashboardView.swift` | Tab Feed |
| `Resources/en.lproj/Localizable.strings` | Novas strings |
| `Resources/pt-BR.lproj/Localizable.strings` | Novas strings |

---

## 11. Open Questions Técnicas

1. **Lifecycle de fotos:** Implementar cleanup automático após 90 dias via Cloud Function?
2. **Moderação:** Adicionar flag `isReported` no modelo para denúncias futuras?
3. **Cache de imagens:** Usar cache existente (ImageCacheService) ou SDWebImage?
