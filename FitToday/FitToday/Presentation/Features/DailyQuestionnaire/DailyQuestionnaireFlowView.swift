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
    @State private var showError = false
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

                if viewModel.currentStep == .soreness {
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
        .background(FitTodayColor.background.ignoresSafeArea())
        .navigationTitle("Questionário diário")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Ops!", isPresented: $showError, actions: {
            Button("Ok", role: .cancel) { viewModel.errorMessage = nil }
        }, message: {
            Text(viewModel.errorMessage ?? "Algo inesperado aconteceu.")
        })
        .onChange(of: viewModel.errorMessage) { _, newValue in
            showError = newValue != nil
        }
        .task {
            viewModel.start()
        }
        .overlay {
            if isGeneratingPlan {
                ZStack {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    ProgressView("Gerando treino personalizado...")
                        .padding()
                        .background(FitTodayColor.surface)
                        .cornerRadius(FitTodayRadius.md)
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
                        .font(.system(.headline))
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

    private var actionButtons: some View {
        VStack(spacing: FitTodaySpacing.sm) {
            Button(primaryButtonTitle) {
                handlePrimaryAction()
            }
            .fitPrimaryStyle()
            .disabled(!primaryButtonEnabled)

            if viewModel.currentStep == .soreness {
                Button("Voltar") {
                    viewModel.goToPreviousStep()
                }
                .fitSecondaryStyle()
            }
        }
    }

    private var primaryButtonTitle: String {
        viewModel.currentStep == .focus ? "Continuar" : "Gerar treino"
    }

    private var primaryButtonEnabled: Bool {
        switch viewModel.currentStep {
        case .focus:
            return viewModel.canAdvanceFromFocus
        case .soreness:
            return viewModel.canSubmit
        }
    }

    private func handlePrimaryAction() {
        switch viewModel.currentStep {
        case .focus:
            viewModel.goToNextStep()
        case .soreness:
            do {
                let checkIn = try viewModel.buildCheckIn()
                handleSubmission(for: checkIn)
            } catch {
                viewModel.errorMessage = error.localizedDescription
                showError = true
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
        #endif
        
        guard isPro else {
            onResult(.paywallRequired)
            return
        }

        isGeneratingPlan = true
        Task {
            do {
                let plan = try await viewModel.generatePlan(for: checkIn)
                persistCheckIn(checkIn)
                UserDefaults.standard.set(Date(), forKey: AppStorageKeys.lastDailyCheckInDate)
                DailyWorkoutStateManager.shared.markSuggested(planId: plan.id)
                sessionStore.start(with: plan)
                onResult(.planReady)
            } catch {
                viewModel.errorMessage = error.localizedDescription
                showError = true
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
            Text(title)
                .font(.system(.headline, weight: .semibold))
                .foregroundStyle(FitTodayColor.textPrimary)
            Text(subtitle)
                .font(.system(.footnote))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .fill(isSelected ? FitTodayColor.brandPrimary.opacity(0.12) : FitTodayColor.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: FitTodayRadius.md)
                        .stroke(isSelected ? FitTodayColor.brandPrimary : FitTodayColor.outline.opacity(0.3), lineWidth: 1.5)
                )
        )
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
                .font(.system(.headline, weight: .semibold))
            Text(subtitle)
                .font(.system(.footnote))
        }
        .foregroundStyle(isSelected ? Color.white : FitTodayColor.textPrimary)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .fill(isSelected ? color : color.opacity(0.2))
        )
        .fitCardShadow()
        .contentShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
    }
}

private struct MuscleChip: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        Text(title)
            .font(.system(.caption, weight: .medium))
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

