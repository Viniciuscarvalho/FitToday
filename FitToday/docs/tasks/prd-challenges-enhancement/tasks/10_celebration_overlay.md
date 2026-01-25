# Task 10.0: Criar CelebrationOverlay

**Status:** ⬜ Não iniciado
**Dependência:** Nenhuma
**Fase:** 4 - Presentation Layer

---

## Objetivo

Criar animações de celebração para momentos de conquista.

---

## Arquivos a Criar

| Arquivo | Descrição |
|---------|-----------|
| `Presentation/Features/Groups/CelebrationOverlay.swift` | Overlay de celebração |
| `Presentation/Features/Groups/ConfettiView.swift` | Animação de confetti |

---

## Tipos de Celebração

| Tipo | Trigger | Visual |
|------|---------|--------|
| `checkInComplete` | Após check-in com sucesso | Confetti + mensagem |
| `rankUp` | Subiu de posição | Confetti + nova posição |
| `topThree` | Entrou no top 3 | Confetti dourado + troféu |

---

## Implementação

### 10.1 ConfettiView

```swift
struct ConfettiView: View {
    @Binding var isAnimating: Bool
    let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<50, id: \.self) { index in
                    ConfettiPiece(
                        color: colors[index % colors.count],
                        size: geo.size,
                        isAnimating: isAnimating
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}

struct ConfettiPiece: View {
    let color: Color
    let size: CGSize
    let isAnimating: Bool

    @State private var position: CGPoint = .zero
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: 10, height: 10)
            .rotationEffect(.degrees(rotation))
            .position(position)
            .opacity(opacity)
            .onAppear {
                position = CGPoint(x: size.width / 2, y: -20)
                animate()
            }
    }

    private func animate() {
        guard isAnimating else { return }

        let targetX = CGFloat.random(in: 0...size.width)
        let targetY = size.height + 50

        withAnimation(.easeOut(duration: 3)) {
            position = CGPoint(x: targetX, y: targetY)
            rotation = Double.random(in: 0...720)
            opacity = 0
        }
    }
}
```

### 10.2 CelebrationOverlay

```swift
struct CelebrationOverlay: View {
    let type: CelebrationType
    @State private var isAnimating = false
    @State private var showContent = false

    enum CelebrationType {
        case checkInComplete
        case rankUp(newRank: Int)
        case topThree
    }

    var body: some View {
        ZStack {
            // Background dim
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            // Confetti
            ConfettiView(isAnimating: $isAnimating)

            // Content
            VStack(spacing: FitTodaySpacing.lg) {
                Image(systemName: iconName)
                    .font(.system(size: 72))
                    .foregroundStyle(iconColor)
                    .scaleEffect(showContent ? 1 : 0.5)

                Text(title)
                    .font(.title.bold())
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .opacity(showContent ? 1 : 0)
        }
        .onAppear {
            isAnimating = true
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                showContent = true
            }
        }
    }

    private var iconName: String {
        switch type {
        case .checkInComplete: return "checkmark.circle.fill"
        case .rankUp: return "arrow.up.circle.fill"
        case .topThree: return "trophy.fill"
        }
    }

    private var iconColor: Color {
        switch type {
        case .checkInComplete: return .green
        case .rankUp: return .blue
        case .topThree: return .yellow
        }
    }

    private var title: String {
        switch type {
        case .checkInComplete: return "Check-in Feito!"
        case .rankUp(let rank): return "Você subiu para #\(rank)!"
        case .topThree: return "Top 3!"
        }
    }

    private var subtitle: String {
        switch type {
        case .checkInComplete: return "Seu treino foi registrado"
        case .rankUp: return "Continue assim!"
        case .topThree: return "Você está entre os melhores!"
        }
    }
}
```

---

## Critérios de Aceite

- [ ] Confetti anima de cima para baixo
- [ ] Fade out após 3 segundos
- [ ] Diferentes visuais por tipo
- [ ] Spring animation no conteúdo
- [ ] Não bloqueia interação (tap through)

---

## Subtasks

- [ ] 10.1 Criar `ConfettiView.swift`
- [ ] 10.2 Criar `CelebrationOverlay.swift`
- [ ] 10.3 Implementar animações
- [ ] 10.4 Adicionar variações visuais por tipo
- [ ] 10.5 Testar performance (50 partículas)
