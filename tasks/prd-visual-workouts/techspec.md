# Technical Specification: Treinos do Personal (Visual Workouts)

## Arquitetura

### Camadas

```
Presentation Layer
├── Features/PersonalWorkouts/
│   ├── Views/
│   │   ├── PersonalWorkoutsListView.swift
│   │   ├── PersonalWorkoutRow.swift
│   │   └── PDFViewerView.swift
│   └── ViewModels/
│       └── PersonalWorkoutsViewModel.swift

Domain Layer
├── Entities/
│   └── PersonalWorkout.swift
├── Repositories/
│   └── PersonalWorkoutRepository.swift (protocol)
└── UseCases/
    └── FetchPersonalWorkoutsUseCase.swift (optional)

Data Layer
├── Repositories/
│   └── FirebasePersonalWorkoutRepository.swift
└── Services/
    └── PDFCacheService.swift
```

## Modelos de Domínio

### PersonalWorkout.swift

```swift
import Foundation

/// Treino enviado pelo Personal Trainer via CMS.
public struct PersonalWorkout: Identifiable, Hashable, Sendable, Codable {
    public let id: String
    public let trainerId: String
    public let userId: String
    public let title: String
    public let description: String?
    public let fileURL: String
    public let fileType: FileType
    public let createdAt: Date
    public var viewedAt: Date?

    public enum FileType: String, Codable, Sendable {
        case pdf
        case image
    }

    /// Indica se o treino ainda não foi visualizado.
    public var isNew: Bool {
        viewedAt == nil
    }

    /// URL convertida para uso no app.
    public var fileURLValue: URL? {
        URL(string: fileURL)
    }
}
```

## Repository

### Protocol

```swift
protocol PersonalWorkoutRepository: Sendable {
    /// Busca todos os treinos do personal para o usuário atual.
    func fetchWorkouts(for userId: String) async throws -> [PersonalWorkout]

    /// Marca um treino como visualizado.
    func markAsViewed(_ workoutId: String) async throws

    /// Observa mudanças em tempo real nos treinos.
    func observeWorkouts(for userId: String) -> AsyncStream<[PersonalWorkout]>
}
```

### Firebase Implementation

```swift
actor FirebasePersonalWorkoutRepository: PersonalWorkoutRepository {
    private let firestore: Firestore
    private let auth: Auth

    init(firestore: Firestore = .firestore(), auth: Auth = .auth()) {
        self.firestore = firestore
        self.auth = auth
    }

    func fetchWorkouts(for userId: String) async throws -> [PersonalWorkout] {
        let snapshot = try await firestore
            .collection("personalWorkouts")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            try? doc.data(as: PersonalWorkout.self)
        }
    }

    func markAsViewed(_ workoutId: String) async throws {
        try await firestore
            .collection("personalWorkouts")
            .document(workoutId)
            .updateData(["viewedAt": FieldValue.serverTimestamp()])
    }

    func observeWorkouts(for userId: String) -> AsyncStream<[PersonalWorkout]> {
        AsyncStream { continuation in
            let listener = firestore
                .collection("personalWorkouts")
                .whereField("userId", isEqualTo: userId)
                .order(by: "createdAt", descending: true)
                .addSnapshotListener { snapshot, error in
                    guard let documents = snapshot?.documents else { return }
                    let workouts = documents.compactMap { doc in
                        try? doc.data(as: PersonalWorkout.self)
                    }
                    continuation.yield(workouts)
                }

            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }
}
```

## PDF Cache Service

```swift
actor PDFCacheService {
    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    init() {
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = caches.appendingPathComponent("PersonalWorkoutPDFs")
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    /// Retorna o PDF do cache ou baixa do Firebase Storage.
    func getPDF(for workout: PersonalWorkout) async throws -> URL {
        let localURL = cacheDirectory.appendingPathComponent("\(workout.id).pdf")

        // Verificar cache local
        if fileManager.fileExists(atPath: localURL.path) {
            return localURL
        }

        // Baixar do Firebase Storage
        guard let remoteURL = workout.fileURLValue else {
            throw PDFCacheError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: remoteURL)
        try data.write(to: localURL)

        return localURL
    }

    /// Limpa o cache de PDFs antigos.
    func clearCache() throws {
        let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
        for file in contents {
            try fileManager.removeItem(at: file)
        }
    }
}

enum PDFCacheError: LocalizedError {
    case invalidURL
    case downloadFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "URL do arquivo inválida"
        case .downloadFailed: return "Falha ao baixar o arquivo"
        }
    }
}
```

## ViewModel

```swift
@MainActor
@Observable
final class PersonalWorkoutsViewModel {
    private(set) var workouts: [PersonalWorkout] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let repository: PersonalWorkoutRepository
    private let pdfCache: PDFCacheService
    private var observationTask: Task<Void, Never>?

    var newWorkoutsCount: Int {
        workouts.filter { $0.isNew }.count
    }

    init(repository: PersonalWorkoutRepository, pdfCache: PDFCacheService = PDFCacheService()) {
        self.repository = repository
        self.pdfCache = pdfCache
    }

    deinit {
        observationTask?.cancel()
    }

    func startObserving(userId: String) {
        observationTask?.cancel()
        observationTask = Task {
            for await updatedWorkouts in repository.observeWorkouts(for: userId) {
                self.workouts = updatedWorkouts
            }
        }
    }

    func loadWorkouts(userId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            workouts = try await repository.fetchWorkouts(for: userId)
        } catch {
            errorMessage = "Não foi possível carregar os treinos: \(error.localizedDescription)"
        }
    }

    func markAsViewed(_ workout: PersonalWorkout) async {
        guard workout.isNew else { return }

        do {
            try await repository.markAsViewed(workout.id)
            // Atualizar localmente
            if let index = workouts.firstIndex(where: { $0.id == workout.id }) {
                workouts[index].viewedAt = Date()
            }
        } catch {
            // Silently fail - não é crítico
            #if DEBUG
            print("[PersonalWorkouts] Failed to mark as viewed: \(error)")
            #endif
        }
    }

    func getPDFURL(for workout: PersonalWorkout) async throws -> URL {
        try await pdfCache.getPDF(for: workout)
    }
}
```

## Views

### PersonalWorkoutsListView.swift

```swift
struct PersonalWorkoutsListView: View {
    @Environment(\.dependencyResolver) private var resolver
    @State private var viewModel: PersonalWorkoutsViewModel?
    @State private var selectedWorkout: PersonalWorkout?

    var body: some View {
        Group {
            if let viewModel {
                contentView(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .task {
            initializeViewModel()
        }
    }

    @ViewBuilder
    private func contentView(viewModel: PersonalWorkoutsViewModel) -> some View {
        if viewModel.isLoading {
            ProgressView()
        } else if viewModel.workouts.isEmpty {
            emptyState
        } else {
            workoutsList(viewModel: viewModel)
        }
    }

    private var emptyState: some View {
        EmptyStateView(
            title: "Nenhum treino do Personal",
            message: "Quando seu treinador enviar um treino, ele aparecerá aqui.",
            systemIcon: "doc.text"
        )
    }

    private func workoutsList(viewModel: PersonalWorkoutsViewModel) -> some View {
        ScrollView {
            LazyVStack(spacing: FitTodaySpacing.md) {
                ForEach(viewModel.workouts) { workout in
                    PersonalWorkoutRow(workout: workout)
                        .onTapGesture {
                            selectedWorkout = workout
                        }
                }
            }
            .padding()
        }
        .sheet(item: $selectedWorkout) { workout in
            PDFViewerView(workout: workout, viewModel: viewModel)
        }
    }
}
```

### PDFViewerView.swift

```swift
import PDFKit
import SwiftUI

struct PDFViewerView: View {
    let workout: PersonalWorkout
    let viewModel: PersonalWorkoutsViewModel

    @State private var pdfURL: URL?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Carregando PDF...")
                } else if let error = errorMessage {
                    errorView(message: error)
                } else if let url = pdfURL {
                    PDFKitView(url: url)
                }
            }
            .navigationTitle(workout.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fechar") { dismiss() }
                }
            }
        }
        .task {
            await loadPDF()
        }
    }

    private func loadPDF() async {
        isLoading = true
        defer { isLoading = false }

        do {
            pdfURL = try await viewModel.getPDFURL(for: workout)
            await viewModel.markAsViewed(workout)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: FitTodaySpacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(FitTodayColor.error)
            Text("Erro ao carregar PDF")
                .font(FitTodayFont.ui(size: 18, weight: .semiBold))
            Text(message)
                .font(FitTodayFont.ui(size: 14))
                .foregroundStyle(FitTodayColor.textSecondary)
            Button("Tentar novamente") {
                Task { await loadPDF() }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

struct PDFKitView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        if let document = PDFDocument(url: url) {
            pdfView.document = document
        }
    }
}
```

## Integração no WorkoutTabView

Modificar o `WorkoutTabView` existente para adicionar a terceira aba:

```swift
// Em WorkoutTabView.swift
enum WorkoutTab: String, CaseIterable {
    case myWorkouts = "Meus Treinos"
    case programs = "Programas"
    case personal = "Personal"  // NOVO

    var icon: String {
        switch self {
        case .myWorkouts: return "figure.strengthtraining.traditional"
        case .programs: return "list.bullet.rectangle"
        case .personal: return "person.fill"  // NOVO
        }
    }
}
```

## Firebase Rules

### Firestore Rules (adicionar ao firestore.rules)

```javascript
// Personal Workouts collection
match /personalWorkouts/{workoutId} {
    // Usuário pode ler seus próprios treinos
    allow read: if isAuthenticated() &&
                   resource.data.userId == request.auth.uid;

    // Apenas trainers/admin podem criar/atualizar (via CMS)
    allow create, update: if isAuthenticated() &&
                            get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['trainer', 'admin'];

    // Usuário pode atualizar apenas o campo viewedAt
    allow update: if isAuthenticated() &&
                    resource.data.userId == request.auth.uid &&
                    request.resource.data.diff(resource.data).affectedKeys().hasOnly(['viewedAt']);
}
```

### Storage Rules (adicionar ao storage.rules)

```javascript
// Personal Workout files
match /personalWorkouts/{trainerId}/{userId}/{fileName} {
    // Usuário pode ler seus próprios arquivos
    allow read: if isAuthenticated() && request.auth.uid == userId;

    // Apenas o treinador pode fazer upload
    allow write: if isAuthenticated() && request.auth.uid == trainerId;
}
```

## Dependency Injection

Registrar no container Swinject:

```swift
// Em DependencyContainer.swift ou similar
container.register(PersonalWorkoutRepository.self) { _ in
    FirebasePersonalWorkoutRepository()
}

container.register(PDFCacheService.self) { _ in
    PDFCacheService()
}

container.register(PersonalWorkoutsViewModel.self) { resolver in
    PersonalWorkoutsViewModel(
        repository: resolver.resolve(PersonalWorkoutRepository.self)!,
        pdfCache: resolver.resolve(PDFCacheService.self)!
    )
}
```

## Testes

### PersonalWorkoutsViewModelTests.swift

```swift
@MainActor
final class PersonalWorkoutsViewModelTests: XCTestCase {
    var sut: PersonalWorkoutsViewModel!
    var mockRepository: MockPersonalWorkoutRepository!

    override func setUp() {
        mockRepository = MockPersonalWorkoutRepository()
        sut = PersonalWorkoutsViewModel(repository: mockRepository)
    }

    func test_loadWorkouts_success() async {
        // Given
        let expectedWorkouts = [PersonalWorkout.fixture()]
        mockRepository.workoutsToReturn = expectedWorkouts

        // When
        await sut.loadWorkouts(userId: "user123")

        // Then
        XCTAssertEqual(sut.workouts, expectedWorkouts)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }

    func test_newWorkoutsCount_returnsCorrectCount() async {
        // Given
        let workouts = [
            PersonalWorkout.fixture(viewedAt: nil),
            PersonalWorkout.fixture(viewedAt: Date()),
            PersonalWorkout.fixture(viewedAt: nil)
        ]
        mockRepository.workoutsToReturn = workouts

        // When
        await sut.loadWorkouts(userId: "user123")

        // Then
        XCTAssertEqual(sut.newWorkoutsCount, 2)
    }
}
```

## Localization

Adicionar aos arquivos Localizable.strings:

```
// pt-BR
"personal.title" = "Personal";
"personal.empty.title" = "Nenhum treino do Personal";
"personal.empty.message" = "Quando seu treinador enviar um treino, ele aparecerá aqui.";
"personal.loading" = "Carregando PDF...";
"personal.error.load" = "Erro ao carregar PDF";
"personal.new_badge" = "Novo";

// en
"personal.title" = "Personal";
"personal.empty.title" = "No Personal Workouts";
"personal.empty.message" = "When your trainer sends a workout, it will appear here.";
"personal.loading" = "Loading PDF...";
"personal.error.load" = "Error loading PDF";
"personal.new_badge" = "New";
```
