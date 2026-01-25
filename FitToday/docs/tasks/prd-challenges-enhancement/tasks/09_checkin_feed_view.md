# Task 9.0: Criar CheckInFeedView + ViewModel

**Status:** ⬜ Não iniciado
**Dependência:** 5.0
**Fase:** 4 - Presentation Layer

---

## Objetivo

Criar feed cronológico de check-ins do grupo com real-time updates.

---

## Arquivos a Criar

| Arquivo | Descrição |
|---------|-----------|
| `Presentation/Features/Groups/CheckInFeedView.swift` | View do feed |
| `Presentation/Features/Groups/CheckInFeedViewModel.swift` | ViewModel |
| `Presentation/Features/Groups/CheckInCardView.swift` | Card individual |

---

## Implementação

### 9.1 ViewModel

```swift
@MainActor
@Observable
final class CheckInFeedViewModel {
    var checkIns: [CheckIn] = []
    var isLoading = false
    var errorMessage: String?

    private let checkInRepository: CheckInRepository
    private let groupId: String
    private var observeTask: Task<Void, Never>?

    init(checkInRepository: CheckInRepository, groupId: String) {
        self.checkInRepository = checkInRepository
        self.groupId = groupId
    }

    func startObserving() async {
        observeTask?.cancel()
        observeTask = Task {
            for await newCheckIns in checkInRepository.observeCheckIns(groupId: groupId) {
                self.checkIns = newCheckIns
            }
        }
    }

    func stopObserving() {
        observeTask?.cancel()
        observeTask = nil
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        do {
            checkIns = try await checkInRepository.getCheckIns(
                groupId: groupId,
                limit: 50,
                after: nil
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

### 9.2 CheckInCardView

```swift
struct CheckInCardView: View {
    let checkIn: CheckIn

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            // Header: avatar + name + time
            HStack(spacing: FitTodaySpacing.sm) {
                AsyncImage(url: checkIn.userPhotoURL) { image in
                    image.resizable()
                } placeholder: {
                    Circle().fill(FitTodayColor.brandPrimary.opacity(0.2))
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(checkIn.displayName)
                        .font(.subheadline.weight(.semibold))
                    Text(checkIn.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(FitTodayColor.textSecondary)
                }

                Spacer()

                // Duration badge
                Text("\(checkIn.workoutDurationMinutes) min")
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(FitTodayColor.brandPrimary.opacity(0.1))
                    .cornerRadius(FitTodayRadius.sm)
            }

            // Photo
            AsyncImage(url: checkIn.checkInPhotoURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(4/3, contentMode: .fill)
                case .failure:
                    Rectangle()
                        .fill(FitTodayColor.cardBackground)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(FitTodayColor.textSecondary)
                        }
                case .empty:
                    ProgressView()
                @unknown default:
                    EmptyView()
                }
            }
            .frame(height: 200)
            .cornerRadius(FitTodayRadius.md)
            .clipped()
        }
        .padding()
        .background(FitTodayColor.cardBackground)
        .cornerRadius(FitTodayRadius.lg)
    }
}
```

### 9.3 CheckInFeedView

```swift
struct CheckInFeedView: View {
    @State private var viewModel: CheckInFeedViewModel

    init(viewModel: CheckInFeedViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: FitTodaySpacing.md) {
                ForEach(viewModel.checkIns) { checkIn in
                    CheckInCardView(checkIn: checkIn)
                }

                if viewModel.checkIns.isEmpty && !viewModel.isLoading {
                    EmptyFeedView()
                }
            }
            .padding()
        }
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            await viewModel.startObserving()
        }
        .onDisappear {
            viewModel.stopObserving()
        }
    }
}

struct EmptyFeedView: View {
    var body: some View {
        VStack(spacing: FitTodaySpacing.md) {
            Image(systemName: "photo.stack")
                .font(.system(size: 48))
                .foregroundStyle(FitTodayColor.textSecondary)
            Text("Nenhum check-in ainda")
                .font(.headline)
            Text("Seja o primeiro a fazer check-in!")
                .font(.subheadline)
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .padding(.vertical, 60)
    }
}
```

---

## Critérios de Aceite

- [ ] Real-time updates via AsyncStream
- [ ] Pull-to-refresh funcional
- [ ] Empty state quando sem check-ins
- [ ] Foto carrega com placeholder
- [ ] Tempo relativo (há X minutos)

---

## Subtasks

- [ ] 9.1 Criar `CheckInFeedViewModel.swift`
- [ ] 9.2 Criar `CheckInCardView.swift`
- [ ] 9.3 Criar `CheckInFeedView.swift`
- [ ] 9.4 Criar `EmptyFeedView`
- [ ] 9.5 Testar real-time updates
