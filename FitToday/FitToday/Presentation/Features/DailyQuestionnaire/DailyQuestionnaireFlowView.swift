//
//  DailyQuestionnaireFlowView.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//  Refactored on 15/01/26 - Extracted components to separate files
//

import SwiftUI
import Swinject

enum DailyQuestionnaireFlowResult {
    case planReady
    case paywallRequired
}

struct DailyQuestionnaireFlowView: View {
    @State private var viewModel: DailyQuestionnaireViewModel?
    @State private var dependencyError: String?
    @Environment(WorkoutSessionStore.self) private var sessionStore
    @State private var isGeneratingPlan = false
    private let onResult: (DailyQuestionnaireFlowResult) -> Void

    init(resolver: Resolver, onResult: @escaping (DailyQuestionnaireFlowResult) -> Void) {
        // 💡 Learn: Com @Observable, usamos State em vez de StateObject
        if let entitlementRepo = resolver.resolve(EntitlementRepository.self),
           let profileRepo = resolver.resolve(UserProfileRepository.self),
           let blocksRepo = resolver.resolve(WorkoutBlocksRepository.self),
           let composer = resolver.resolve(WorkoutPlanComposing.self) {
            _viewModel = State(initialValue: DailyQuestionnaireViewModel(
                entitlementRepository: entitlementRepo,
                profileRepository: profileRepo,
                blocksRepository: blocksRepo,
                composer: composer
            ))
            _dependencyError = State(initialValue: nil)
        } else {
            _viewModel = State(initialValue: nil)
            _dependencyError = State(initialValue: "Erro de configuração: dependências do questionário não estão registradas.")
        }
        self.onResult = onResult
    }

    var body: some View {
        Group {
            if let error = dependencyError {
                DependencyErrorView(message: error)
            } else if let viewModel = viewModel {
                contentView(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Questionário diário")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func contentView(viewModel: DailyQuestionnaireViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FitTodaySpacing.lg) {
                StepperHeader(
                    title: viewModel.currentStep.title,
                    step: viewModel.currentStep.rawValue + 1,
                    totalSteps: DailyQuestionnaireViewModel.Step.allCases.count
                )

                currentStepView(viewModel: viewModel)

                if viewModel.currentStep == .energy {
                    FitBadge(
                        text: viewModel.entitlement.isPro ? "PRO liberado" : "Free: paywall após gerar",
                        style: viewModel.entitlement.isPro ? .success : .warning
                    )
                }

                Spacer(minLength: FitTodaySpacing.lg)

                actionButtons(viewModel: viewModel)
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
        .errorToast(errorMessage: Binding(
            get: { viewModel.errorMessage },
            set: { viewModel.errorMessage = $0 }
        ))
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
    private func currentStepView(viewModel: DailyQuestionnaireViewModel) -> some View {
        switch viewModel.currentStep {
        case .focus:
            focusStep(viewModel: viewModel)
        case .soreness:
            sorenessStep(viewModel: viewModel)
        case .energy:
            energyStep(viewModel: viewModel)
        }
    }

    private func focusStep(viewModel: DailyQuestionnaireViewModel) -> some View {
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

    private func sorenessStep(viewModel: DailyQuestionnaireViewModel) -> some View {
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
    
    private func energyStep(viewModel: DailyQuestionnaireViewModel) -> some View {
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

    private func actionButtons(viewModel: DailyQuestionnaireViewModel) -> some View {
        VStack(spacing: FitTodaySpacing.sm) {
            Button(primaryButtonTitle(for: viewModel)) {
                handlePrimaryAction(viewModel: viewModel)
            }
            .fitPrimaryStyle()
            .disabled(!primaryButtonEnabled(for: viewModel))

            if viewModel.currentStep != .focus {
                Button("Voltar") {
                    viewModel.goToPreviousStep()
                }
                .fitSecondaryStyle()
            }
        }
    }

    private func primaryButtonTitle(for viewModel: DailyQuestionnaireViewModel) -> String {
        switch viewModel.currentStep {
        case .focus: return "Continuar"
        case .soreness: return "Continuar"
        case .energy: return "Gerar treino"
        }
    }

    private func primaryButtonEnabled(for viewModel: DailyQuestionnaireViewModel) -> Bool {
        switch viewModel.currentStep {
        case .focus:
            return viewModel.canAdvanceFromFocus
        case .soreness:
            return viewModel.canAdvanceFromSoreness
        case .energy:
            return viewModel.canSubmit
        }
    }

    private func handlePrimaryAction(viewModel: DailyQuestionnaireViewModel) {
        switch viewModel.currentStep {
        case .focus:
            viewModel.goToNextStep()
        case .soreness:
            viewModel.goToNextStep()
        case .energy:
            do {
                let checkIn = try viewModel.buildCheckIn()
                handleSubmission(for: checkIn, viewModel: viewModel)
            } catch {
                viewModel.handleError(error)
            }
        }
    }

    private func handleSubmission(for checkIn: DailyCheckIn, viewModel: DailyQuestionnaireViewModel) {
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

// MARK: - Persistence Helper

private func persistCheckIn(_ checkIn: DailyCheckIn) {
    if let data = try? JSONEncoder().encode(checkIn) {
        UserDefaults.standard.set(data, forKey: AppStorageKeys.lastDailyCheckInData)
    }
}

