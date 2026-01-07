//
//  OnboardingFlowView.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import SwiftUI
import Swinject

struct OnboardingFlowView: View {
    enum Stage {
        case intro
        case setup
    }

    @EnvironmentObject private var router: AppRouter
    @StateObject private var viewModel: OnboardingFlowViewModel
    @State private var stage: Stage
    @State private var currentPage = 0
    @State private var currentStep = 0
    @State private var isSubmitting = false
    @State private var showError = false

    private let introPages = OnboardingPage.pages
    private let steps = SetupStep.allCases
    private let onFinished: () -> Void
    private let isEditing: Bool

    init(resolver: Resolver, isEditing: Bool = false, onFinished: @escaping () -> Void) {
        let repository = resolver.resolve(UserProfileRepository.self)!
        let useCase = CreateOrUpdateProfileUseCase(repository: repository)
        _viewModel = StateObject(wrappedValue: OnboardingFlowViewModel(createProfileUseCase: useCase))
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
                    // Placeholder: poderia abrir modal específico futuramente
                }
                .fitSecondaryStyle()
            }
        }
    }

    private var setupView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                StepperHeader(
                    title: steps[currentStep].title,
                    step: currentStep + 1,
                    totalSteps: steps.count
                )
                setupOptions(for: steps[currentStep])
                    .animation(.easeInOut, value: currentStep)

                if viewModel.isSaving || isSubmitting {
                    ProgressView("Salvando perfil...")
                        .frame(maxWidth: .infinity)
                }

                HStack(spacing: 12) {
                    Button("Voltar") {
                        if currentStep == 0 {
                            if isEditing {
                                // Se estiver editando, fecha a tela
                                onFinished()
                            } else {
                                stage = .intro
                            }
                        } else {
                            currentStep -= 1
                        }
                    }
                    .fitSecondaryStyle()

                    Button(currentStep == steps.count - 1 ? (isEditing ? "Salvar alterações" : "Criar perfil") : "Avançar") {
                        handleNext()
                    }
                    .fitPrimaryStyle()
                    .disabled(!canAdvance(for: steps[currentStep]) || viewModel.isSaving)
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private func handleNext() {
        if currentStep == steps.count - 1 {
            isSubmitting = true
            Task {
                let success = await viewModel.submitProfile()
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

private struct OnboardingPage: View {
    let title: String
    let bullets: [String]

    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(FitTodayFont.display(size: 32, weight: .extraBold))  // Retro font
                .tracking(1.5)
                .multilineTextAlignment(.center)
            VStack(alignment: .leading, spacing: 12) {
                ForEach(bullets, id: \.self) { bullet in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(FitTodayColor.brandPrimary)
                            .fitGlowEffect(color: FitTodayColor.brandPrimary.opacity(0.3))  // Neon glow
                        Text(bullet)
                            .font(FitTodayFont.ui(size: 17, weight: .medium))  // Retro font
                            .foregroundStyle(FitTodayColor.textPrimary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: FitTodayRadius.md)
                    .fill(FitTodayColor.surface)
                    .retroGridOverlay(spacing: 25)  // Grid overlay
            )
            .techCornerBorders(length: 14, thickness: 1.5)  // Tech corners
            .cornerRadius(FitTodayRadius.md)
            .fitCardShadow()
        }
        .padding(.horizontal, 8)
    }

    static let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Treinos que se adaptam a você",
            bullets: [
                "Responda 2 perguntas por dia e receba um treino seguro.",
                "Sem precisar pensar em séries, ordem ou ajustes."
            ]
        ),
        OnboardingPage(
            title: "Fluxo ultra rápido",
            bullets: [
                "Menos de 10 segundos para responder.",
                "Sempre alinhado ao seu objetivo atual."
            ]
        ),
        OnboardingPage(
            title: "Free vs Pro",
            bullets: [
                "Biblioteca básica gratuita para começar agora.",
                "Plano Pro libera IA, ajustes por dor e histórico."
            ]
        )
    ]
}

private struct ViewBuilderOption {
    let title: String
    let subtitle: String?
    let isSelected: Bool
    let action: () -> Void
}

private enum SetupStep: Int, CaseIterable {
    case goal, structure, method, level, health, frequency

    var title: String {
        switch self {
        case .goal: return "Qual é seu objetivo principal?"
        case .structure: return "Onde você treina?"
        case .method: return "Qual metodologia prefere?"
        case .level: return "Qual seu nível atual?"
        case .health: return "Alguma condição ou dor?"
        case .frequency: return "Quantos dias por semana você treina?"
        }
    }
}

// MARK: - Display helpers

private extension FitnessGoal {
    var title: String {
        switch self {
        case .hypertrophy: return "Hipertrofia"
        case .conditioning: return "Condicionamento"
        case .endurance: return "Resistência"
        case .weightLoss: return "Emagrecimento"
        case .performance: return "Performance"
        }
    }
    var subtitle: String {
        switch self {
        case .hypertrophy: return "Ganhe massa muscular"
        case .conditioning: return "Melhore o fôlego diário"
        case .endurance: return "Aumente resistência"
        case .weightLoss: return "Defina e reduza gordura"
        case .performance: return "Otimize performance esportiva"
        }
    }
}

private extension TrainingStructure {
    var title: String {
        switch self {
        case .fullGym: return "Academia completa"
        case .basicGym: return "Academia básica"
        case .homeDumbbells: return "Casa (halteres)"
        case .bodyweight: return "Peso corporal"
        }
    }
    var subtitle: String? {
        switch self {
        case .fullGym: return "Máquinas + pesos livres"
        case .basicGym: return "Equipamentos essenciais"
        case .homeDumbbells: return "Até 2 pares de halteres"
        case .bodyweight: return "Sem equipamentos"
        }
    }
}

private extension TrainingMethod {
    var title: String {
        switch self {
        case .traditional: return "Tradicional"
        case .circuit: return "Circuito"
        case .hiit: return "HIIT"
        case .mixed: return "Misto"
        }
    }
    var subtitle: String? {
        switch self {
        case .traditional: return "Séries e repetições"
        case .circuit: return "Blocos em sequência"
        case .hiit: return "Intervalos intensos"
        case .mixed: return "Combinação equilibrada"
        }
    }
}

private extension TrainingLevel {
    var title: String {
        switch self {
        case .beginner: return "Iniciante"
        case .intermediate: return "Intermediário"
        case .advanced: return "Avançado"
        }
    }
    var subtitle: String? {
        switch self {
        case .beginner: return "Até 6 meses treinando"
        case .intermediate: return "Entre 6 meses e 2 anos"
        case .advanced: return "2+ anos consistentes"
        }
    }
}

private extension HealthCondition {
    var title: String {
        switch self {
        case .none: return "Nenhuma"
        case .lowerBackPain: return "Dor lombar"
        case .knee: return "Joelho"
        case .shoulder: return "Ombro"
        case .other: return "Outra"
        }
    }
    var subtitle: String? {
        switch self {
        case .none: return "Tudo bem por aqui"
        case .lowerBackPain: return "Adaptações para coluna"
        case .knee: return "Proteja os joelhos"
        case .shoulder: return "Cuidados em empurrar/puxar"
        case .other: return "Tratamos com menor volume"
        }
    }
}

#Preview("Onboarding") {
    let container = Container()
    let repo = InMemoryProfileRepository()
    container.register(UserProfileRepository.self) { _ in repo }
    return OnboardingFlowView(resolver: container, isEditing: false, onFinished: {})
        .environmentObject(AppRouter())
}

#Preview("Edit Profile") {
    let container = Container()
    let repo = InMemoryProfileRepository()
    container.register(UserProfileRepository.self) { _ in repo }
    return OnboardingFlowView(resolver: container, isEditing: true, onFinished: {})
        .environmentObject(AppRouter())
}

// Preview helper
private final class InMemoryProfileRepository: UserProfileRepository {
    private var profile: UserProfile?
    func loadProfile() async throws -> UserProfile? { profile }
    func saveProfile(_ profile: UserProfile) async throws { self.profile = profile }
}

