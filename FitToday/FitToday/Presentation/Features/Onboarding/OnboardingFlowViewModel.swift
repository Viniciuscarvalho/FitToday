//
//  OnboardingFlowViewModel.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import Foundation
import Combine

/// Modo de onboarding: progressivo (2 passos) ou completo (6 passos)
enum OnboardingMode {
    case progressive // Apenas objetivo + estrutura, usa defaults
    case full        // Todos os 6 passos
}

@MainActor
final class OnboardingFlowViewModel: ObservableObject {
    // MARK: - User Selections
    @Published var selectedGoal: FitnessGoal?
    @Published var selectedStructure: TrainingStructure?
    @Published var selectedMethod: TrainingMethod?
    @Published var selectedLevel: TrainingLevel?
    @Published var selectedConditions: Set<HealthCondition> = []
    @Published var weeklyFrequency: Int?
    
    // MARK: - State
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published private(set) var isProfileIncomplete = false // Indica se perfil foi salvo com defaults

    private let createProfileUseCase: CreateOrUpdateProfileUseCase
    
    // MARK: - Defaults para modo progressivo (conforme PRD F4)
    static let defaultLevel: TrainingLevel = .intermediate
    static let defaultMethod: TrainingMethod = .mixed
    static let defaultFrequency: Int = 3
    static let defaultConditions: [HealthCondition] = [.none]

    init(createProfileUseCase: CreateOrUpdateProfileUseCase) {
        self.createProfileUseCase = createProfileUseCase
    }

    // MARK: - Computed Properties
    
    /// Pode avançar no modo progressivo (apenas objetivo + estrutura)
    var canSubmitProgressive: Bool {
        selectedGoal != nil && selectedStructure != nil
    }
    
    /// Pode avançar no modo completo (todos os campos)
    var canSubmitFull: Bool {
        selectedGoal != nil &&
        selectedStructure != nil &&
        selectedMethod != nil &&
        selectedLevel != nil &&
        weeklyFrequency != nil
    }

    // MARK: - Actions

    func toggleCondition(_ condition: HealthCondition) {
        if condition == .none {
            selectedConditions = [.none]
            return
        }
        selectedConditions.remove(.none)
        if selectedConditions.contains(condition) {
            selectedConditions.remove(condition)
        } else {
            selectedConditions.insert(condition)
        }
    }

    func setFrequency(_ value: Int) {
        weeklyFrequency = value
    }
    
    /// Aplica defaults para campos não preenchidos (modo progressivo)
    func applyDefaults() {
        if selectedLevel == nil {
            selectedLevel = Self.defaultLevel
        }
        if selectedMethod == nil {
            selectedMethod = Self.defaultMethod
        }
        if weeklyFrequency == nil {
            weeklyFrequency = Self.defaultFrequency
        }
        if selectedConditions.isEmpty {
            selectedConditions = Set(Self.defaultConditions)
        }
    }

    /// Submete perfil no modo progressivo (aplica defaults e marca como incompleto)
    func submitProgressiveProfile() async -> Bool {
        guard canSubmitProgressive,
              let goal = selectedGoal,
              let structure = selectedStructure
        else {
            errorMessage = "Selecione seu objetivo e onde você treina."
            return false
        }

        // Aplicar defaults
        applyDefaults()
        
        isSaving = true
        defer { isSaving = false }

        let profile = UserProfile(
            mainGoal: goal,
            availableStructure: structure,
            preferredMethod: selectedMethod ?? Self.defaultMethod,
            level: selectedLevel ?? Self.defaultLevel,
            healthConditions: Array(selectedConditions),
            weeklyFrequency: weeklyFrequency ?? Self.defaultFrequency,
            isProfileComplete: false // Marca como incompleto para prompt futuro
        )

        do {
            try await createProfileUseCase.execute(profile)
            isProfileIncomplete = true
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    /// Submete perfil completo (modo full ou edição)
    func submitFullProfile() async -> Bool {
        guard canSubmitFull,
              let goal = selectedGoal,
              let structure = selectedStructure,
              let method = selectedMethod,
              let level = selectedLevel,
              let frequency = weeklyFrequency
        else {
            errorMessage = "Selecione uma opção em cada etapa antes de continuar."
            return false
        }

        isSaving = true
        defer { isSaving = false }

        let conditions = selectedConditions.isEmpty ? [.none] : Array(selectedConditions)
        let profile = UserProfile(
            mainGoal: goal,
            availableStructure: structure,
            preferredMethod: method,
            level: level,
            healthConditions: conditions,
            weeklyFrequency: frequency,
            isProfileComplete: true
        )

        do {
            try await createProfileUseCase.execute(profile)
            isProfileIncomplete = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    /// Alias para compatibilidade com código existente
    func submitProfile() async -> Bool {
        await submitFullProfile()
    }
}

