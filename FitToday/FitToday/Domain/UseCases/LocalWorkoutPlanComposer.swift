//
//  LocalWorkoutPlanComposer.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import Foundation

struct LocalWorkoutPlanComposer: WorkoutPlanComposing, Sendable {
    func composePlan(
        blocks: [WorkoutBlock],
        profile: UserProfile,
        checkIn: DailyCheckIn
    ) async throws -> WorkoutPlan {
        let filtered = filterBlocks(blocks, profile: profile, checkIn: checkIn)
        let chosenBlocks = selectBlocks(filtered, checkIn: checkIn)

        guard !chosenBlocks.isEmpty else {
            return try fallbackPlan(allBlocks: blocks, profile: profile, checkIn: checkIn)
        }

        return assemblePlan(chosenBlocks, profile: profile, checkIn: checkIn)
    }

    private func filterBlocks(
        _ blocks: [WorkoutBlock],
        profile: UserProfile,
        checkIn: DailyCheckIn
    ) -> [(block: WorkoutBlock, score: Int)] {
        let focusTargets = targets(for: checkIn.focus)
        let soreMuscles = Set(checkIn.sorenessAreas)

        return blocks
            .filter { focusTargets.contains($0.group) }
            .filter { $0.matches(profile: profile, checkIn: checkIn, soreMuscles: soreMuscles) }
            .map { ($0, compatibilityScore(for: $0, profile: profile, checkIn: checkIn)) }
            .sorted { $0.score > $1.score }
    }

    private func selectBlocks(
        _ candidates: [(block: WorkoutBlock, score: Int)],
        checkIn: DailyCheckIn
    ) -> [WorkoutBlock] {
        let needed = blocksNeeded(for: checkIn.focus)
        guard needed > 0 else { return [] }
        return Array(candidates.prefix(needed).map(\.block))
    }

    private func blocksNeeded(for focus: DailyFocus) -> Int {
        switch focus {
        case .cardio, .core:
            return 1
        case .surprise:
            return 2
        default:
            return 2
        }
    }

    private func targets(for focus: DailyFocus) -> [DailyFocus] {
        switch focus {
        case .surprise:
            return [.fullBody, .upper, .lower, .cardio, .core]
        default:
            return [focus]
        }
    }

    private func assemblePlan(
        _ blocks: [WorkoutBlock],
        profile: UserProfile,
        checkIn: DailyCheckIn
    ) -> WorkoutPlan {
        let appliedFocus = checkIn.focus == .surprise ? (blocks.first?.group ?? .fullBody) : checkIn.focus
        let prescriptions = blocks.flatMap {
            self.prescriptions(from: $0, profile: profile, checkIn: checkIn)
        }

        let duration = estimatedDuration(for: prescriptions)
        let intensity = intensity(for: profile.level, soreness: checkIn.sorenessLevel, goal: profile.mainGoal)

        return WorkoutPlan(
            title: makeTitle(focus: appliedFocus, goal: profile.mainGoal),
            focus: appliedFocus,
            estimatedDurationMinutes: duration,
            intensity: intensity,
            exercises: prescriptions
        )
    }

    private func prescriptions(
        from block: WorkoutBlock,
        profile: UserProfile,
        checkIn: DailyCheckIn
    ) -> [ExercisePrescription] {
        let adjustment = adjustmentFactor(for: profile.level, soreness: checkIn.sorenessLevel)
        let rest = adjustedRest(base: block.restInterval, soreness: checkIn.sorenessLevel)

        return block.exercises.map { exercise in
            ExercisePrescription(
                exercise: exercise,
                sets: adjustedSets(baseRange: block.suggestedSets, adjustment: adjustment),
                reps: adjustedReps(baseRange: block.suggestedReps, profile: profile, adjustment: adjustment),
                restInterval: rest,
                tip: exercise.instructions.first
            )
        }
    }

    private func adjustmentFactor(for level: TrainingLevel, soreness: MuscleSorenessLevel) -> Double {
        var factor: Double = 1.0
        if level == .advanced && soreness == .none {
            factor += 0.2
        }
        if soreness == .moderate {
            factor -= 0.1
        } else if soreness == .strong {
            factor -= 0.25
        }
        return max(0.6, factor)
    }

    private func adjustedSets(baseRange: IntRange, adjustment: Double) -> Int {
        let base = Double(baseRange.average)
        let value = Int((base * adjustment).rounded(.toNearestOrEven))
        return max(1, value)
    }

    private func adjustedReps(
        baseRange: IntRange,
        profile: UserProfile,
        adjustment: Double
    ) -> IntRange {
        let goalBias: Double
        switch profile.mainGoal {
        case .weightLoss, .conditioning:
            goalBias = 1.1
        case .performance:
            goalBias = 1.05
        default:
            goalBias = 1.0
        }
        let scale = adjustment * goalBias
        let lower = max(5, Int(Double(baseRange.lowerBound) * scale))
        let upper = max(lower, Int(Double(baseRange.upperBound) * scale))
        return IntRange(lower, upper)
    }

    private func adjustedRest(base: TimeInterval, soreness: MuscleSorenessLevel) -> TimeInterval {
        switch soreness {
        case .strong:
            return base + 30
        case .moderate:
            return base + 10
        default:
            return base
        }
    }

    private func estimatedDuration(for exercises: [ExercisePrescription]) -> Int {
        let seconds = exercises.reduce(0) { acc, prescription in
            let work = Double(prescription.reps.average) * 3.0 * Double(prescription.sets)
            let rest = Double(prescription.restInterval) * Double(max(0, prescription.sets - 1))
            return acc + Int(work + rest)
        }
        return max(20, Int(ceil(Double(seconds) / 60.0)))
    }

    private func intensity(
        for level: TrainingLevel,
        soreness: MuscleSorenessLevel,
        goal: FitnessGoal
    ) -> WorkoutIntensity {
        if soreness == .strong { return .low }
        if level == .advanced && soreness == .none { return .high }
        if goal == .weightLoss || goal == .conditioning { return .moderate }
        return .moderate
    }

    private func makeTitle(focus: DailyFocus, goal: FitnessGoal) -> String {
        switch focus {
        case .upper: return "Upper \(goalTitle(goal))"
        case .lower: return "Lower \(goalTitle(goal))"
        case .cardio: return "Cardio inteligente"
        case .core: return "Core + estabilidade"
        case .fullBody: return "Full body eficiente"
        case .surprise: return "Treino surpresa"
        }
    }

    private func goalTitle(_ goal: FitnessGoal) -> String {
        switch goal {
        case .hypertrophy: return "Power"
        case .conditioning: return "Conditioning"
        case .endurance: return "Endurance"
        case .weightLoss: return "Fat Burn"
        case .performance: return "Performance"
        }
    }

    private func fallbackPlan(
        allBlocks: [WorkoutBlock],
        profile: UserProfile,
        checkIn: DailyCheckIn
    ) throws -> WorkoutPlan {
        let safeBlocks = allBlocks
            .filter { $0.group == .fullBody }
            .filter { $0.matches(profile: profile, checkIn: checkIn, soreMuscles: Set()) }

        if let block = safeBlocks.first {
            return assemblePlan([block], profile: profile, checkIn: checkIn)
        }

        guard let lightBlock = allBlocks
            .sorted(by: { $0.level.rawValue < $1.level.rawValue })
            .first else {
            throw DomainError.noCompatibleBlocks
        }

        return assemblePlan([lightBlock], profile: profile, checkIn: checkIn)
    }

    private func compatibilityScore(
        for block: WorkoutBlock,
        profile: UserProfile,
        checkIn: DailyCheckIn
    ) -> Int {
        var score = 0
        if block.group == checkIn.focus { score += 5 }
        if checkIn.focus == .surprise && block.group == .fullBody { score += 3 }
        if block.level == profile.level { score += 3 }
        if block.equipmentOptions.contains(where: { $0 == preferredEquipment(for: profile.availableStructure) }) {
            score += 1
        }
        if profile.mainGoal == .hypertrophy && block.suggestedSets.average >= 4 { score += 1 }
        if checkIn.sorenessLevel == .none && block.level == .advanced {
            score += 1
        }
        return score
    }

    private func preferredEquipment(for structure: TrainingStructure) -> EquipmentType {
        switch structure {
        case .bodyweight:
            return .bodyweight
        case .homeDumbbells:
            return .dumbbell
        case .basicGym, .fullGym:
            return .machine
        }
    }
}

