//
//  DailyQuestionnaireFlowView.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import SwiftUI
import Swinject

enum DailyQuestionnaireFlowResult {
    case planReady
    case paywallRequired
}

struct DailyQuestionnaireFlowView: View {
    @StateObject private var viewModel: DailyQuestionnaireViewModel
    @EnvironmentObject private var sessionStore: WorkoutSessionStore
    @State private var isGeneratingPlan = false
    private let onResult: (DailyQuestionnaireFlowResult) -> Void

    init(resolver: Resolver, onResult: @escaping (DailyQuestionnaireFlowResult) -> Void) {
        guard
            let entitlementRepo = resolver.resolve(EntitlementRepository.self),
            let profileRepo = resolver.resolve(UserProfileRepository.self),
            let blocksRepo = resolver.resolve(WorkoutBlocksRepository.self),
            let composer = resolver.resolve(WorkoutPlanComposing.self)
        else {
            fatalError("Dependências do questionário diário não registradas.")
        }
        _viewModel = StateObject(
            wrappedValue: DailyQuestionnaireViewModel(
                entitlementRepository: entitlementRepo,
                profileRepository: profileRepo,
                blocksRepository: blocksRepo,
                composer: composer
            )
        )
        self.onResult = onResult
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FitTodaySpacing.lg) {
                StepperHeader(
                    title: viewModel.currentStep.title,
                    step: viewModel.currentStep.rawValue + 1,
                    totalSteps: DailyQuestionnaireViewModel.Step.allCases.count
                )

                currentStepView

                if viewModel.currentStep == .energy {
                    FitBadge(
                        text: viewModel.entitlement.isPro ? "PRO liberado" : "Free: paywall após gerar",
                        style: viewModel.entitlement.isPro ? .success : .warning
                    )
                }

                Spacer(minLength: FitTodaySpacing.lg)

                actionButtons
            }
            .padding()
        }
        .background(
            ZStack {
                FitTodayColor.background
                RetroGridPattern(lineColor: FitTodayColor.gridLine.opacity(0.3), spacing: 40)  // Grid background
            }
            .ignoresSafeArea()
        )
        .navigationTitle("Questionário diário")
        .navigationBarTitleDisplayMode(.inline)
        .errorToast(errorMessage: $viewModel.errorMessage)
        .task {
            viewModel.start()
        }
        .overlay {
            if isGeneratingPlan {
                ZStack {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    VStack(spacing: FitTodaySpacing.md) {
                        ProgressView()
                            .controlSize(.large)
                            .tint(FitTodayColor.brandPrimary)
                        Text("Gerando treino personalizado...")
                            .font(FitTodayFont.display(size: 17, weight: .bold))  // Retro font
                            .tracking(0.8)
                            .foregroundStyle(FitTodayColor.textPrimary)
                    }
                    .padding(FitTodaySpacing.xl)
                    .background(
                        RoundedRectangle(cornerRadius: FitTodayRadius.md)
                            .fill(FitTodayColor.surface)
                            .retroGridOverlay(spacing: 25)  // Grid overlay
                    )
                    .techCornerBorders(length: 16, thickness: 2)  // Tech corners
                }
            }
        }
    }

    @ViewBuilder
    private var currentStepView: some View {
        switch viewModel.currentStep {
        case .focus:
            focusStep
        case .soreness:
            sorenessStep
        case .energy:
            energyStep
        }
    }

    private var focusStep: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: FitTodaySpacing.md) {
            ForEach(DailyFocus.allCases, id: \.self) { focus in
                FocusCard(
                    title: focus.displayTitle,
                    subtitle: focus.displaySubtitle,
                    icon: focus.iconName,
                    isSelected: viewModel.selectedFocus == focus
                )
                .onTapGesture {
                    viewModel.selectFocus(focus)
                }
            }
        }
        .animation(.easeInOut, value: viewModel.selectedFocus)
    }

    private var sorenessStep: some View {
        VStack(spacing: FitTodaySpacing.md) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: FitTodaySpacing.md) {
                ForEach(MuscleSorenessLevel.allCases, id: \.self) { level in
                    SorenessCard(
                        title: level.displayTitle,
                        subtitle: level.displaySubtitle,
                        color: level.displayColor,
                        isSelected: viewModel.selectedSoreness == level
                    )
                    .onTapGesture {
                        viewModel.selectSoreness(level)
                    }
                }
            }

            if viewModel.selectedSoreness == .strong {
                VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
                    Text("Onde está doendo?")
                        .font(FitTodayFont.ui(size: 17, weight: .semiBold))  // Retro font
                        .foregroundStyle(FitTodayColor.textPrimary)

                    LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: FitTodaySpacing.sm), count: 3), spacing: FitTodaySpacing.sm) {
                        ForEach(MuscleGroup.allCases, id: \.self) { group in
                            MuscleChip(
                                title: group.displayTitle,
                                isSelected: viewModel.selectedAreas.contains(group)
                            )
                            .onTapGesture {
                                viewModel.toggleArea(group)
                            }
                        }
                    }
                }
            }
        }
        .animation(.easeInOut, value: viewModel.selectedSoreness)
    }
    
    private var energyStep: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            Text("De 0 a 10, como está sua energia agora?")
                .font(FitTodayFont.ui(size: 15, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
            
            HStack {
                Text("0")
                    .font(.system(.caption, weight: .medium))
                    .foregroundStyle(FitTodayColor.textSecondary)
                Slider(
                    value: Binding(
                        get: { Double(viewModel.energyLevel) },
                        set: { viewModel.energyLevel = Int($0.rounded()) }
                    ),
                    in: 0...10,
                    step: 1
                )
                .tint(FitTodayColor.brandPrimary)
                Text("10")
                    .font(.system(.caption, weight: .medium))
                    .foregroundStyle(FitTodayColor.textSecondary)
            }
            
            HStack(spacing: FitTodaySpacing.sm) {
                Text("Energia:")
                    .font(FitTodayFont.ui(size: 17, weight: .semiBold))
                    .foregroundStyle(FitTodayColor.textPrimary)
                Text("\(viewModel.energyLevel)")
                    .font(FitTodayFont.display(size: 20, weight: .bold))
                    .foregroundStyle(FitTodayColor.brandPrimary)
            }
            .padding(.top, FitTodaySpacing.sm)
        }
        .padding()
        .background(FitTodayColor.surface)
        .cornerRadius(FitTodayRadius.md)
        .techCornerBorders(length: 12, thickness: 1.5)
        .fitCardShadow()
    }

    private var actionButtons: some View {
        VStack(spacing: FitTodaySpacing.sm) {
            Button(primaryButtonTitle) {
                handlePrimaryAction()
            }
            .fitPrimaryStyle()
            .disabled(!primaryButtonEnabled)

            if viewModel.currentStep != .focus {
                Button("Voltar") {
                    viewModel.goToPreviousStep()
                }
                .fitSecondaryStyle()
            }
        }
    }

    private var primaryButtonTitle: String {
        switch viewModel.currentStep {
        case .focus: return "Continuar"
        case .soreness: return "Continuar"
        case .energy: return "Gerar treino"
        }
    }

    private var primaryButtonEnabled: Bool {
        switch viewModel.currentStep {
        case .focus:
            return viewModel.canAdvanceFromFocus
        case .soreness:
            return viewModel.canAdvanceFromSoreness
        case .energy:
            return viewModel.canSubmit
        }
    }

    private func handlePrimaryAction() {
        switch viewModel.currentStep {
        case .focus:
            viewModel.goToNextStep()
        case .soreness:
            viewModel.goToNextStep()
        case .energy:
            do {
                let checkIn = try viewModel.buildCheckIn()
                handleSubmission(for: checkIn)
            } catch {
                viewModel.handleError(error)
            }
        }
    }

    private func handleSubmission(for checkIn: DailyCheckIn) {
        // Verificar entitlement, considerando debug override
        var isPro = viewModel.entitlement.isPro
        #if DEBUG
        if DebugEntitlementOverride.shared.isEnabled {
            isPro = DebugEntitlementOverride.shared.isPro
        }
        print("[DailyQ] handleSubmission: isPro=\(isPro) debugEnabled=\(DebugEntitlementOverride.shared.isEnabled)")
        #endif
        
        guard isPro else {
            #if DEBUG
            print("[DailyQ] ⚠️ Não é Pro - mostrando paywall")
            #endif
            onResult(.paywallRequired)
            return
        }

        isGeneratingPlan = true
        Task {
            do {
                #if DEBUG
                print("[DailyQ] Gerando plano...")
                #endif
                let plan = try await viewModel.generatePlan(for: checkIn)
                persistCheckIn(checkIn)
                UserDefaults.standard.set(Date(), forKey: AppStorageKeys.lastDailyCheckInDate)
                DailyWorkoutStateManager.shared.markSuggested(planId: plan.id)
                sessionStore.start(with: plan)
                #if DEBUG
                print("[DailyQ] ✅ Plano gerado e salvo na sessão: id=\(plan.id)")
                print("[DailyQ] ✅ sessionStore.plan != nil: \(sessionStore.plan != nil)")
                #endif
                onResult(.planReady)
            } catch {
                #if DEBUG
                print("[DailyQ] ❌ Erro na geração: \(error)")
                #endif
                viewModel.handleError(error)
            }
            isGeneratingPlan = false
        }
    }
}

private func persistCheckIn(_ checkIn: DailyCheckIn) {
    if let data = try? JSONEncoder().encode(checkIn) {
        UserDefaults.standard.set(data, forKey: AppStorageKeys.lastDailyCheckInData)
    }
}

// MARK: - Supporting Views

private struct FocusCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(isSelected ? FitTodayColor.brandPrimary : FitTodayColor.textSecondary)
                .fitGlowEffect(color: isSelected ? FitTodayColor.brandPrimary.opacity(0.4) : Color.clear.opacity(0))  // Neon glow
            Text(title)
                .font(FitTodayFont.ui(size: 17, weight: .semiBold))  // Retro font
                .foregroundStyle(FitTodayColor.textPrimary)
            Text(subtitle)
                .font(FitTodayFont.ui(size: 13, weight: .medium))  // Retro font
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Group {
                if isSelected {
                    RoundedRectangle(cornerRadius: FitTodayRadius.md)
                        .fill(FitTodayColor.brandPrimary.opacity(0.12))
                        .diagonalStripes(color: FitTodayColor.neonCyan, spacing: 10, opacity: 0.15)  // Diagonal stripes
                } else {
                    RoundedRectangle(cornerRadius: FitTodayRadius.md)
                        .fill(FitTodayColor.surface)
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .stroke(isSelected ? FitTodayColor.neonCyan : FitTodayColor.outline.opacity(0.3), lineWidth: 1.5)  // Neon cyan border
        )
        .techCornerBorders(color: isSelected ? FitTodayColor.neonCyan : FitTodayColor.techBorder.opacity(0.3), length: 12, thickness: 1.5)  // Tech corners
        .fitCardShadow()
        .contentShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
    }
}

private struct SorenessCard: View {
    let title: String
    let subtitle: String
    let color: Color
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
            Text(title)
                .font(FitTodayFont.ui(size: 17, weight: .semiBold))  // Retro font
            Text(subtitle)
                .font(FitTodayFont.ui(size: 13, weight: .medium))  // Retro font
        }
        .foregroundStyle(isSelected ? Color.white : FitTodayColor.textPrimary)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .fill(isSelected ? color : color.opacity(0.2))
        )
        .techCornerBorders(color: isSelected ? Color.white.opacity(0.5) : color.opacity(0.4), length: 12, thickness: 1.5)  // Tech corners
        .fitCardShadow()
        .contentShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
    }
}

private struct MuscleChip: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        Text(title)
            .font(FitTodayFont.ui(size: 12, weight: .medium))  // Retro font
            .padding(.horizontal, FitTodaySpacing.sm)
            .padding(.vertical, FitTodaySpacing.xs)
            .background(
                Capsule()
                    .fill(isSelected ? FitTodayColor.brandPrimary.opacity(0.2) : FitTodayColor.surface)
                    .overlay(
                        Capsule()
                            .stroke(isSelected ? FitTodayColor.brandPrimary : FitTodayColor.outline.opacity(0.4), lineWidth: 1)
                    )
            )
            .foregroundStyle(isSelected ? FitTodayColor.brandPrimary : FitTodayColor.textSecondary)
    }
}

// MARK: - Display helpers

private extension DailyFocus {
    var displayTitle: String {
        switch self {
        case .fullBody: return "Corpo inteiro"
        case .upper: return "Superior"
        case .lower: return "Inferior"
        case .cardio: return "Cardio"
        case .core: return "Core"
        case .surprise: return "Surpreenda-me"
        }
    }

    var displaySubtitle: String {
        switch self {
        case .fullBody: return "Equilíbrio total"
        case .upper: return "Peito, costas e braços"
        case .lower: return "Glúteos e pernas"
        case .cardio: return "Foco em fôlego"
        case .core: return "Estabilidade e ABS"
        case .surprise: return "Deixe a IA decidir"
        }
    }

    var iconName: String {
        switch self {
        case .fullBody: return "figure.walk"
        case .upper: return "figure.strengthtraining.traditional"
        case .lower: return "figure.step.training"
        case .cardio: return "figure.run"
        case .core: return "circle.grid.cross"
        case .surprise: return "sparkles"
        }
    }
}

private extension MuscleSorenessLevel {
    var displayTitle: String {
        switch self {
        case .none: return "Nada"
        case .light: return "Leve"
        case .moderate: return "Moderada"
        case .strong: return "Forte"
        }
    }

    var displaySubtitle: String {
        switch self {
        case .none: return "Pronto para ir ao limite"
        case .light: return "Só um incômodo leve"
        case .moderate: return "Precisa de ajustes"
        case .strong: return "Vamos proteger seu corpo"
        }
    }

    var displayColor: Color {
        switch self {
        case .none: return Color.green
        case .light: return Color.blue
        case .moderate: return Color.orange
        case .strong: return Color.red
        }
    }
}

// MuscleGroup.displayTitle movido para WorkoutDisplayHelpers.swift

