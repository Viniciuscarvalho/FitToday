//
//  OnboardingDisplayHelpers.swift
//  FitToday
//
//  Created by AI on 15/01/26.
//

import Foundation

// MARK: - SetupStep

enum SetupStep: Int, CaseIterable {
    case goal, structure, method, level, health, frequency

    var title: String {
        switch self {
        case .goal: return "onboarding.step.goal".localized
        case .structure: return "onboarding.step.structure".localized
        case .method: return "onboarding.step.method".localized
        case .level: return "onboarding.step.level".localized
        case .health: return "onboarding.step.health".localized
        case .frequency: return "onboarding.step.frequency".localized
        }
    }
}

// MARK: - FitnessGoal Extensions

extension FitnessGoal {
    var title: String {
        switch self {
        case .hypertrophy: return "goal.hypertrophy.title".localized
        case .conditioning: return "goal.conditioning.title".localized
        case .endurance: return "goal.endurance.title".localized
        case .weightLoss: return "goal.weightloss.title".localized
        case .performance: return "goal.performance.title".localized
        }
    }
    var subtitle: String {
        switch self {
        case .hypertrophy: return "goal.hypertrophy.subtitle".localized
        case .conditioning: return "goal.conditioning.subtitle".localized
        case .endurance: return "goal.endurance.subtitle".localized
        case .weightLoss: return "goal.weightloss.subtitle".localized
        case .performance: return "goal.performance.subtitle".localized
        }
    }
}

// MARK: - TrainingStructure Extensions

extension TrainingStructure {
    var title: String {
        switch self {
        case .fullGym: return "structure.fullgym.title".localized
        case .basicGym: return "structure.basicgym.title".localized
        case .homeDumbbells: return "structure.homedumbbells.title".localized
        case .bodyweight: return "structure.bodyweight.title".localized
        }
    }
    var subtitle: String? {
        switch self {
        case .fullGym: return "structure.fullgym.subtitle".localized
        case .basicGym: return "structure.basicgym.subtitle".localized
        case .homeDumbbells: return "structure.homedumbbells.subtitle".localized
        case .bodyweight: return "structure.bodyweight.subtitle".localized
        }
    }
}

// MARK: - TrainingMethod Extensions

extension TrainingMethod {
    var title: String {
        switch self {
        case .traditional: return "method.traditional.title".localized
        case .circuit: return "method.circuit.title".localized
        case .hiit: return "method.hiit.title".localized
        case .mixed: return "method.mixed.title".localized
        }
    }
    var subtitle: String? {
        switch self {
        case .traditional: return "method.traditional.subtitle".localized
        case .circuit: return "method.circuit.subtitle".localized
        case .hiit: return "method.hiit.subtitle".localized
        case .mixed: return "method.mixed.subtitle".localized
        }
    }
}

// MARK: - TrainingLevel Extensions

extension TrainingLevel {
    var title: String {
        switch self {
        case .beginner: return "level.beginner.title".localized
        case .intermediate: return "level.intermediate.title".localized
        case .advanced: return "level.advanced.title".localized
        }
    }
    var subtitle: String? {
        switch self {
        case .beginner: return "level.beginner.subtitle".localized
        case .intermediate: return "level.intermediate.subtitle".localized
        case .advanced: return "level.advanced.subtitle".localized
        }
    }
}

// MARK: - HealthCondition Extensions

extension HealthCondition {
    var title: String {
        switch self {
        case .none: return "health.none.title".localized
        case .lowerBackPain: return "health.lowerbackpain.title".localized
        case .knee: return "health.knee.title".localized
        case .shoulder: return "health.shoulder.title".localized
        case .other: return "health.other.title".localized
        }
    }
    var subtitle: String? {
        switch self {
        case .none: return "health.none.subtitle".localized
        case .lowerBackPain: return "health.lowerbackpain.subtitle".localized
        case .knee: return "health.knee.subtitle".localized
        case .shoulder: return "health.shoulder.subtitle".localized
        case .other: return "health.other.subtitle".localized
        }
    }
}
