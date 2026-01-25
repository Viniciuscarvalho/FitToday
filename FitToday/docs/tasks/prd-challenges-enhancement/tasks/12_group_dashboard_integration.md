# Task 12.0: Integrar Feed na GroupDashboardView

**Status:** ⬜ Não iniciado
**Dependência:** 9.0
**Fase:** 5 - Integração

---

## Objetivo

Adicionar tab de Feed de check-ins na área de grupos.

---

## Arquivos a Modificar

| Arquivo | Mudança |
|---------|---------|
| `Presentation/Features/Groups/GroupDashboardView.swift` | Adicionar TabView com Feed |

---

## Implementação

### 12.1 Adicionar enum para tabs

```swift
enum GroupTab: String, CaseIterable {
    case feed = "Feed"
    case leaderboard = "Ranking"

    var icon: String {
        switch self {
        case .feed: return "photo.stack"
        case .leaderboard: return "trophy"
        }
    }
}
```

### 12.2 Adicionar State

```swift
@State private var selectedTab: GroupTab = .feed
@State private var feedViewModel: CheckInFeedViewModel?
```

### 12.3 Inicializar ViewModel

```swift
private func initializeFeedViewModel() {
    guard let checkInRepo = resolver.resolve(CheckInRepository.self),
          let groupId = viewModel.group?.id else { return }

    feedViewModel = CheckInFeedViewModel(
        checkInRepository: checkInRepo,
        groupId: groupId
    )
}
```

### 12.4 Implementar TabView

```swift
var body: some View {
    VStack(spacing: 0) {
        // Tab selector
        HStack(spacing: 0) {
            ForEach(GroupTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20))
                        Text(tab.rawValue)
                            .font(.caption)
                    }
                    .foregroundStyle(selectedTab == tab ? FitTodayColor.brandPrimary : FitTodayColor.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
        }
        .background(FitTodayColor.cardBackground)

        // Content
        TabView(selection: $selectedTab) {
            // Feed tab
            if let feedVM = feedViewModel {
                CheckInFeedView(viewModel: feedVM)
                    .tag(GroupTab.feed)
            } else {
                ProgressView()
                    .tag(GroupTab.feed)
            }

            // Leaderboard tab
            LeaderboardView(viewModel: leaderboardViewModel)
                .tag(GroupTab.leaderboard)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }
    .task {
        initializeFeedViewModel()
    }
}
```

---

## Layout Final

```
┌─────────────────────────────────┐
│  Group Header (nome, membros)   │
├─────────────────────────────────┤
│  [📷 Feed]  [🏆 Ranking]        │  ← Tab selector
├─────────────────────────────────┤
│                                 │
│     Tab Content (swipeable)     │
│                                 │
└─────────────────────────────────┘
```

---

## Critérios de Aceite

- [ ] Tab selector funcional
- [ ] Swipe entre tabs
- [ ] Feed carrega check-ins do grupo
- [ ] Leaderboard mantém funcionalidade
- [ ] Transição suave entre tabs

---

## Subtasks

- [ ] 12.1 Criar enum `GroupTab`
- [ ] 12.2 Adicionar tab selector UI
- [ ] 12.3 Implementar TabView com pages
- [ ] 12.4 Integrar CheckInFeedView
- [ ] 12.5 Testar navegação
