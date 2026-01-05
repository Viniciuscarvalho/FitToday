//
//  OnboardingFlowViewModel.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import Foundation
import Combine

@MainActor
final class OnboardingFlowViewModel: ObservableObject {
    @Published var selectedGoal: FitnessGoal?
    @Published var selectedStructure: TrainingStructure?
    @Published var selectedMethod: TrainingMethod?
    @Published var selectedLevel: TrainingLevel?
    @Published var selectedConditions: Set<HealthCondition> = []
    @Published var weeklyFrequency: Int?
    @Published var isSaving = false
    @Published var errorMessage: String?

    private let createProfileUseCase: CreateOrUpdateProfileUseCase

    init(createProfileUseCase: CreateOrUpdateProfileUseCase) {
        self.createProfileUseCase = createProfileUseCase
    }

    var canSubmit: Bool {
        selectedGoal != nil &&
        selectedStructure != nil &&
        selectedMethod != nil &&
        selectedLevel != nil &&
        weeklyFrequency != nil
    }

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

    func submitProfile() async -> Bool {
        guard canSubmit,
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
            weeklyFrequency: frequency
        )

        do {
            try await createProfileUseCase.execute(profile)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}

