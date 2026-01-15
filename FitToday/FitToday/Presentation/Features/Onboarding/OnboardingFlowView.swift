//
//  OnboardingFlowView.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//  Refactored on 15/01/26 - Extracted components to separate files
//

import SwiftUI
import Swinject

struct OnboardingFlowView: View {
    enum Stage {
        case intro
        case setup
    }

    @Environment(AppRouter.self) private var router
    @Environment(\.dependencyResolver) private var resolver
    @State private var viewModel: OnboardingFlowViewModel
    @State private var stage: Stage
    @State private var currentPage = 0
    @State private var currentStep = 0
    @State private var isSubmitting = false
    @State private var showError = false
    @State private var useProgressiveMode = true // Modo progressivo por padrão
    @State private var showPaywall = false

    private let introPages = OnboardingPage.pages
    private let onFinished: () -> Void
    private let isEditing: Bool
    
    /// Steps para modo progressivo (apenas 2 passos)
    private var progressiveSteps: [SetupStep] { [.goal, .structure] }
    
    /// Steps para modo completo (6 passos)
    private var fullSteps: [SetupStep] { SetupStep.allCases }
    
    /// Steps ativos baseado no modo
    private var activeSteps: [SetupStep] {
        isEditing ? fullSteps : (useProgressiveMode ? progressiveSteps : fullSteps)
    }

    init(resolver: Resolver, isEditing: Bool = false, onFinished: @escaping () -> Void) {
        let repository = resolver.resolve(UserProfileRepository.self)!
        let useCase = CreateOrUpdateProfileUseCase(repository: repository)
        viewModel = OnboardingFlowViewModel(createProfileUseCase: useCase)
        self.onFinished = onFinished
        self.isEditing = isEditing
        // Se estiver editando, pula direto para o setup
        _stage = State(initialValue: isEditing ? .setup : .intro)
    }

    var body: some View {
        VStack {
            switch stage {
            case .intro:
                introView
            case .setup:
                setupView
            }
        }
        .padding()
        .background(
            ZStack {
                FitTodayColor.background
                RetroGridPattern(lineColor: FitTodayColor.gridLine.opacity(0.3), spacing: 40)  // Grid background
            }
            .ignoresSafeArea()
        )
        .navigationTitle(isEditing ? "Editar Perfil" : "Configuração")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Ops", isPresented: $showError, actions: {
            Button("Ok", role: .cancel) {}
        }, message: {
            Text(viewModel.errorMessage ?? "Algo inesperado aconteceu.")
        })
        .onChange(of: viewModel.errorMessage) { _, newValue in
            showError = newValue != nil
        }
        .sheet(isPresented: $showPaywall) {
            if let storeKitRepo = resolver.resolve(EntitlementRepository.self) as? StoreKitEntitlementRepository {
                OptimizedPaywallView(
                    storeService: storeKitRepo.service,
                    onPurchaseSuccess: {
                        showPaywall = false
                    },
                    onDismiss: {
                        showPaywall = false
                    }
                )
            }
        }
    }

    private var introView: some View {
        VStack(spacing: 24) {
            TabView(selection: $currentPage) {
                ForEach(introPages.indices, id: \.self) { index in
                    introPages[index]
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 360)

            Button(currentPage == introPages.count - 1 ? "Configurar meu perfil" : "Continuar") {
                if currentPage == introPages.count - 1 {
                    stage = .setup
                } else {
                    withAnimation {
                        currentPage += 1
                    }
                }
            }
            .fitPrimaryStyle()

            if currentPage == introPages.count - 1 {
                Button("Ver diferenças Free x Pro") {
                    showPaywall = true
                }
                .fitSecondaryStyle()
            }
        }
    }

    private var setupView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                StepperHeader(
                    title: activeSteps[currentStep].title,
                    step: currentStep + 1,
                    totalSteps: activeSteps.count
                )
                setupOptions(for: activeSteps[currentStep])
                    .animation(.easeInOut, value: currentStep)

                if viewModel.isSaving || isSubmitting {
                    ProgressView("Salvando perfil...")
                        .frame(maxWidth: .infinity)
                }

                // Botões de ação
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Button("Voltar") {
                            if currentStep == 0 {
                                if isEditing {
                                    onFinished()
                                } else {
                                    stage = .intro
                                }
                            } else {
                                currentStep -= 1
                            }
                        }
                        .fitSecondaryStyle()

                        Button(nextButtonTitle) {
                            handleNext()
                        }
                        .fitPrimaryStyle()
                        .disabled(!canAdvance(for: activeSteps[currentStep]) || viewModel.isSaving)
                    }
                    
                    // Opção de personalizar completamente (apenas no modo progressivo, último passo)
                    if useProgressiveMode && !isEditing && currentStep == activeSteps.count - 1 {
                        Button("Quero personalizar mais") {
                            useProgressiveMode = false
                            // Não reseta currentStep, apenas muda o modo
                        }
                        .font(.footnote)
                        .foregroundStyle(FitTodayColor.textSecondary)
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
    }
    
    /// Título do botão de avançar/concluir
    private var nextButtonTitle: String {
        let isLastStep = currentStep == activeSteps.count - 1
        if isEditing {
            return isLastStep ? "Salvar alterações" : "Avançar"
        }
        if useProgressiveMode && isLastStep {
            return "Gerar meu primeiro treino"
        }
        return isLastStep ? "Criar perfil" : "Avançar"
    }

    private func handleNext() {
        let isLastStep = currentStep == activeSteps.count - 1
        
        if isLastStep {
            isSubmitting = true
            Task {
                let success: Bool
                if useProgressiveMode && !isEditing {
                    // Modo progressivo: salva com defaults
                    success = await viewModel.submitProgressiveProfile()
                } else {
                    // Modo completo ou edição: salva perfil completo
                    success = await viewModel.submitFullProfile()
                }
                await MainActor.run {
                    isSubmitting = false
                    if success {
                        onFinished()
                    }
                }
            }
        } else {
            currentStep += 1
        }
    }

    @ViewBuilder
    private func setupOptions(for step: SetupStep) -> some View {
        switch step {
        case .goal:
            optionList(FitnessGoal.allCases, selected: viewModel.selectedGoal) { goal in
                ViewBuilderOption(
                    title: goal.title,
                    subtitle: goal.subtitle,
                    isSelected: viewModel.selectedGoal == goal
                ) {
                    viewModel.selectedGoal = goal
                }
            }
        case .structure:
            optionList(TrainingStructure.allCases, selected: viewModel.selectedStructure) { structure in
                ViewBuilderOption(
                    title: structure.title,
                    subtitle: structure.subtitle,
                    isSelected: viewModel.selectedStructure == structure
                ) {
                    viewModel.selectedStructure = structure
                }
            }
        case .method:
            optionList(TrainingMethod.allCases, selected: viewModel.selectedMethod) { method in
                ViewBuilderOption(
                    title: method.title,
                    subtitle: method.subtitle,
                    isSelected: viewModel.selectedMethod == method
                ) {
                    viewModel.selectedMethod = method
                }
            }
        case .level:
            optionList(TrainingLevel.allCases, selected: viewModel.selectedLevel) { level in
                ViewBuilderOption(
                    title: level.title,
                    subtitle: level.subtitle,
                    isSelected: viewModel.selectedLevel == level
                ) {
                    viewModel.selectedLevel = level
                }
            }
        case .health:
            VStack(spacing: 12) {
                ForEach(HealthCondition.allCases, id: \.self) { condition in
                    OptionCard(
                        title: condition.title,
                        subtitle: condition.subtitle,
                        isSelected: viewModel.selectedConditions.contains(condition)
                    )
                    .onTapGesture {
                        viewModel.toggleCondition(condition)
                    }
                }
            }
        case .frequency:
            let options = [2, 3, 4, 5]
            VStack(spacing: 12) {
                ForEach(options, id: \.self) { number in
                    OptionCard(
                        title: "\(number)x por semana",
                        subtitle: number >= 4 ? "Maior consistência → resultados mais rápidos" : nil,
                        isSelected: viewModel.weeklyFrequency == number
                    )
                    .onTapGesture {
                        viewModel.setFrequency(number)
                    }
                }
            }
        }
    }

    private func canAdvance(for step: SetupStep) -> Bool {
        switch step {
        case .goal: return viewModel.selectedGoal != nil
        case .structure: return viewModel.selectedStructure != nil
        case .method: return viewModel.selectedMethod != nil
        case .level: return viewModel.selectedLevel != nil
        case .health: return true
        case .frequency: return viewModel.weeklyFrequency != nil
        }
    }

    @ViewBuilder
    private func optionList<T: Hashable>(
        _ values: [T],
        selected: T?,
        builder: @escaping (T) -> ViewBuilderOption
    ) -> some View {
        VStack(spacing: 12) {
            ForEach(values, id: \.self) { value in
                let option = builder(value)
                OptionCard(
                    title: option.title,
                    subtitle: option.subtitle,
                    isSelected: option.isSelected
                )
                .onTapGesture(perform: option.action)
            }
        }
    }
}

// MARK: - Helper Models

private struct ViewBuilderOption {
    let title: String
    let subtitle: String?
    let isSelected: Bool
    let action: () -> Void
}

#Preview("Onboarding") {
    let container = Container()
    let repo = InMemoryProfileRepository()
    container.register(UserProfileRepository.self) { _ in repo }
    return OnboardingFlowView(resolver: container, isEditing: false, onFinished: {})
        .environment(AppRouter())
}

#Preview("Edit Profile") {
    let container = Container()
    let repo = InMemoryProfileRepository()
    container.register(UserProfileRepository.self) { _ in repo }
    return OnboardingFlowView(resolver: container, isEditing: true, onFinished: {})
        .environment(AppRouter())
}

// Preview helper
private final class InMemoryProfileRepository: UserProfileRepository {
    private var profile: UserProfile?
    func loadProfile() async throws -> UserProfile? { profile }
    func saveProfile(_ profile: UserProfile) async throws { self.profile = profile }
}

