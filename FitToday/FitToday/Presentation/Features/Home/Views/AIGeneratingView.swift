//
//  AIGeneratingView.swift
//  FitToday
//
//  Loading view displayed while AI generates a workout.
//

import SwiftUI

/// State of the AI generation process.
enum AIGenerationState: Equatable, Sendable {
    case idle
    case analyzing
    case generating
    case optimizing
    case completed
    case failed(String)

    var message: String {
        switch self {
        case .idle: return "Preparando..."
        case .analyzing: return "Analisando suas preferências..."
        case .generating: return "Gerando treino personalizado..."
        case .optimizing: return "Otimizando exercícios..."
        case .completed: return "Treino pronto!"
        case .failed(let error): return "Erro: \(error)"
        }
    }

    var progress: Double {
        switch self {
        case .idle: return 0.0
        case .analyzing: return 0.25
        case .generating: return 0.5
        case .optimizing: return 0.75
        case .completed: return 1.0
        case .failed: return 0.0
        }
    }

    var icon: String {
        switch self {
        case .idle: return "sparkles"
        case .analyzing: return "brain.head.profile"
        case .generating: return "wand.and.stars"
        case .optimizing: return "slider.horizontal.3"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        }
    }
}

/// View displayed while AI is generating a workout.
struct AIGeneratingView: View {
    @Binding var state: AIGenerationState
    let onCancel: () -> Void
    let onRetry: (() -> Void)?

    @State private var animationPhase = 0.0
    @State private var pulseScale = 1.0
    @State private var rotationAngle = 0.0

    init(
        state: Binding<AIGenerationState>,
        onCancel: @escaping () -> Void,
        onRetry: (() -> Void)? = nil
    ) {
        self._state = state
        self.onCancel = onCancel
        self.onRetry = onRetry
    }

    var body: some View {
        VStack(spacing: FitTodaySpacing.xl) {
            Spacer()

            // Animated Icon
            animatedIcon

            // Status Text
            statusSection

            // Progress Bar
            progressBar

            // Tips
            if case .failed = state {
                errorSection
            } else {
                tipsSection
            }

            Spacer()

            // Cancel Button
            cancelButton
        }
        .padding(FitTodaySpacing.lg)
        .background(FitTodayColor.background)
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Animated Icon

    private var animatedIcon: some View {
        ZStack {
            // Outer rotating ring
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [FitTodayColor.brandPrimary, FitTodayColor.brandSecondary, FitTodayColor.brandPrimary],
                        center: .center
                    ),
                    lineWidth: 4
                )
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(rotationAngle))

            // Pulse background
            Circle()
                .fill(
                    RadialGradient(
                        colors: [FitTodayColor.brandPrimary.opacity(0.3), FitTodayColor.brandPrimary.opacity(0.0)],
                        center: .center,
                        startRadius: 20,
                        endRadius: 60
                    )
                )
                .frame(width: 100, height: 100)
                .scaleEffect(pulseScale)

            // Inner circle with icon
            Circle()
                .fill(FitTodayColor.surface)
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: state.icon)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(iconColor)
                        .symbolEffect(.pulse, options: .repeating, isActive: isAnimating)
                )
        }
    }

    private var iconColor: Color {
        if case .failed = state {
            return .red
        } else if case .completed = state {
            return .green
        } else {
            return FitTodayColor.brandPrimary
        }
    }

    private var isAnimating: Bool {
        switch state {
        case .idle, .analyzing, .generating, .optimizing:
            return true
        case .completed, .failed:
            return false
        }
    }

    // MARK: - Status Section

    private var statusSection: some View {
        VStack(spacing: FitTodaySpacing.sm) {
            Text(state.message)
                .font(FitTodayFont.ui(size: 18, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)
                .multilineTextAlignment(.center)

            if isAnimating {
                Text("Isso pode levar alguns segundos...")
                    .font(FitTodayFont.ui(size: 14, weight: .medium))
                    .foregroundStyle(FitTodayColor.textSecondary)
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        VStack(spacing: FitTodaySpacing.sm) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 6)
                        .fill(FitTodayColor.outline)
                        .frame(height: 12)

                    // Progress
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [FitTodayColor.brandPrimary, FitTodayColor.brandSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * state.progress, height: 12)
                        .animation(.easeInOut(duration: 0.5), value: state.progress)
                }
            }
            .frame(height: 12)
            .padding(.horizontal, FitTodaySpacing.xl)

            // Progress percentage
            Text("\(Int(state.progress * 100))%")
                .font(FitTodayFont.ui(size: 14, weight: .bold))
                .foregroundStyle(FitTodayColor.brandPrimary)
        }
    }

    // MARK: - Tips Section

    private var tipsSection: some View {
        VStack(spacing: FitTodaySpacing.sm) {
            Text("Dica")
                .font(FitTodayFont.ui(size: 12, weight: .semiBold))
                .foregroundStyle(FitTodayColor.textTertiary)

            Text(currentTip)
                .font(FitTodayFont.ui(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
        }
        .padding(FitTodaySpacing.md)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .fill(FitTodayColor.surface)
        )
    }

    private var currentTip: String {
        let tips = [
            "A IA considera sua fadiga para ajustar o volume do treino",
            "Treinos personalizados consideram seus equipamentos disponíveis",
            "Você pode salvar o treino gerado como template",
            "A IA evita músculos que você treinou recentemente"
        ]
        return tips[Int(animationPhase) % tips.count]
    }

    // MARK: - Error Section

    private var errorSection: some View {
        VStack(spacing: FitTodaySpacing.md) {
            Text("Algo deu errado")
                .font(FitTodayFont.ui(size: 16, weight: .bold))
                .foregroundStyle(.red)

            if let onRetry {
                Button {
                    onRetry()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Tentar novamente")
                    }
                    .font(FitTodayFont.ui(size: 14, weight: .semiBold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, FitTodaySpacing.lg)
                    .padding(.vertical, FitTodaySpacing.sm)
                    .background(
                        Capsule()
                            .fill(FitTodayColor.brandPrimary)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(FitTodaySpacing.md)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .fill(Color.red.opacity(0.1))
        )
    }

    // MARK: - Cancel Button

    private var cancelButton: some View {
        Button(action: onCancel) {
            Text("Cancelar")
                .font(FitTodayFont.ui(size: 16, weight: .semiBold))
                .foregroundStyle(FitTodayColor.textSecondary)
                .padding(.vertical, FitTodaySpacing.md)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Animations

    private func startAnimations() {
        // Rotation animation
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }

        // Pulse animation
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.2
        }

        // Tips rotation
        Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { _ in
            withAnimation {
                animationPhase += 1
            }
        }
    }
}

// MARK: - Preview

#Preview("Analyzing") {
    AIGeneratingView(
        state: .constant(.analyzing),
        onCancel: {}
    )
    .preferredColorScheme(.dark)
}

#Preview("Generating") {
    AIGeneratingView(
        state: .constant(.generating),
        onCancel: {}
    )
    .preferredColorScheme(.dark)
}

#Preview("Completed") {
    AIGeneratingView(
        state: .constant(.completed),
        onCancel: {}
    )
    .preferredColorScheme(.dark)
}

#Preview("Failed") {
    AIGeneratingView(
        state: .constant(.failed("Não foi possível conectar ao servidor")),
        onCancel: {},
        onRetry: {}
    )
    .preferredColorScheme(.dark)
}
