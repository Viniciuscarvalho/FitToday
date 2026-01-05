//
//  HybridWorkoutPlanComposer.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import Foundation

struct OpenAIWorkoutPlanComposer: WorkoutPlanComposing {
    private let client: OpenAIClienting
    private let localComposer: LocalWorkoutPlanComposer
    private let logger: (String) -> Void

    init(client: OpenAIClienting, localComposer: LocalWorkoutPlanComposer, logger: @escaping (String) -> Void = { print("[OpenAI]", $0) }) {
        self.client = client
        self.localComposer = localComposer
        self.logger = logger
    }

    func composePlan(
        blocks: [WorkoutBlock],
        profile: UserProfile,
        checkIn: DailyCheckIn
    ) async throws -> WorkoutPlan {
        let prompt = promptText(blocks: blocks, profile: profile, checkIn: checkIn)
        let cacheKey = Hashing.sha256(prompt)
        let data = try await client.sendJSONPrompt(prompt: prompt, cachedKey: cacheKey)
        let response = try JSONDecoder().decode(OpenAIPlanResponse.self, from: data)
        let plan = try await assemblePlan(response: response, blocks: blocks, profile: profile, checkIn: checkIn)
        return plan
    }

    private func assemblePlan(
        response: OpenAIPlanResponse,
        blocks: [WorkoutBlock],
        profile: UserProfile,
        checkIn: DailyCheckIn
    ) async throws -> WorkoutPlan {
        let blockMap = Dictionary(uniqueKeysWithValues: blocks.map { ($0.id, $0) })
        let orderedBlocks = response.selectedBlocks.compactMap { blockMap[$0.blockId] }
        guard !orderedBlocks.isEmpty else {
            return try await awaitFallback(blocks: blocks, profile: profile, checkIn: checkIn)
        }

        var exercisePrescriptions: [ExercisePrescription] = []
        for selected in response.selectedBlocks {
            guard let block = blockMap[selected.blockId] else { continue }
            exercisePrescriptions.append(contentsOf: applyAdjustments(selected, block: block, profile: profile, soreness: checkIn.sorenessLevel))
        }

        if exercisePrescriptions.isEmpty {
            return try await awaitFallback(blocks: blocks, profile: profile, checkIn: checkIn)
        }

        let appliedFocus = checkIn.focus == .surprise ? (orderedBlocks.first?.group ?? .fullBody) : checkIn.focus
        let totalSeconds: Int = exercisePrescriptions.reduce(0) { partial, prescription in
            let avgReps = prescription.reps.average
            let work = Double(avgReps) * 3.0 * Double(prescription.sets)
            let rest = Double(prescription.restInterval) * Double(max(0, prescription.sets - 1))
            return partial + Int(work + rest)
        }
        let duration = max(20, totalSeconds / 60)
        let intensity = localComposerIntensity(for: profile.level, soreness: checkIn.sorenessLevel, goal: profile.mainGoal)

        return WorkoutPlan(
            title: localComposerTitle(for: appliedFocus, goal: profile.mainGoal),
            focus: appliedFocus,
            estimatedDurationMinutes: duration,
            intensity: intensity,
            exercises: exercisePrescriptions
        )
    }

    private func applyAdjustments(
        _ adjustment: OpenAIPlanResponse.SelectedBlock,
        block: WorkoutBlock,
        profile: UserProfile,
        soreness: MuscleSorenessLevel
    ) -> [ExercisePrescription] {
        let baseSets = block.suggestedSets.average
        let setMultiplier = adjustment.setsMultiplier ?? 1.0
        let repsMultiplier = adjustment.repsMultiplier ?? goalBias(for: profile.mainGoal)
        let restDelta = adjustment.restAdjustmentSeconds ?? restDelta(for: soreness)

        return block.exercises.map { exercise in
            let setsValue = max(1, Int(Double(baseSets) * setMultiplier))
            let lower = max(5, Int(Double(block.suggestedReps.lowerBound) * repsMultiplier))
            let upper = max(lower, Int(Double(block.suggestedReps.upperBound) * repsMultiplier))
            return ExercisePrescription(
                exercise: exercise,
                sets: setsValue,
                reps: IntRange(lower, upper),
                restInterval: max(10, block.restInterval + restDelta),
                tip: exercise.instructions.first
            )
        }
    }

    private func promptText(blocks: [WorkoutBlock], profile: UserProfile, checkIn: DailyCheckIn) -> String {
        let limitedBlocks = Array(blocks.prefix(8))
        let blockSummaries = limitedBlocks.map {
            """
            {
                "id": "\($0.id)",
                "group": "\($0.group)",
                "level": "\($0.level)",
                "equip": "\( $0.equipmentOptions.first?.rawValue ?? "unknown")",
                "sets": \($0.suggestedSets.lowerBound)-\($0.suggestedSets.upperBound),
                "reps": \($0.suggestedReps.lowerBound)-\($0.suggestedReps.upperBound)
            }
            """
        }.joined(separator: ",\n")

        return """
        Você é um planejador de treino. Escolha blocos do catálogo abaixo usando apenas os IDs fornecidos. Ajuste séries/reps e descanso, mas mantenha valores seguros.

        Perfil: objetivo=\(profile.mainGoal), nível=\(profile.level), estrutura=\(profile.availableStructure)
        Check-in: foco=\(checkIn.focus), dor=\(checkIn.sorenessLevel), áreas=\(checkIn.sorenessAreas)

        Regras:
        - Retorne somente JSON.
        - Campo selected_blocks: lista de objetos { "block_id", "sets_multiplier", "reps_multiplier", "rest_adjustment_seconds" }.
        - Mínimo 1 bloco, máximo 3.
        - Não invente blocos/exercícios.

        Catálogo:
        [\(blockSummaries)]
        """
    }

    private func goalBias(for goal: FitnessGoal) -> Double {
        switch goal {
        case .weightLoss, .conditioning:
            return 1.1
        case .performance:
            return 1.05
        default:
            return 1.0
        }
    }

    private func restDelta(for soreness: MuscleSorenessLevel) -> Double {
        switch soreness {
        case .strong: return 30
        case .moderate: return 10
        default: return 0
        }
    }

    private func awaitFallback(
        blocks: [WorkoutBlock],
        profile: UserProfile,
        checkIn: DailyCheckIn
    ) async throws -> WorkoutPlan {
        logger("Fallback para motor local")
        return try await localComposer.composePlan(blocks: blocks, profile: profile, checkIn: checkIn)
    }

    private func localComposerTitle(for focus: DailyFocus, goal: FitnessGoal) -> String {
        switch focus {
        case .upper: return "Upper \(goalTitle(goal))"
        case .lower: return "Lower \(goalTitle(goal))"
        case .cardio: return "Cardio inteligente"
        case .core: return "Core + estabilidade"
        case .fullBody: return "Full body eficiente"
        case .surprise: return "Treino surpresa"
        }
    }

    private func localComposerIntensity(for level: TrainingLevel, soreness: MuscleSorenessLevel, goal: FitnessGoal) -> WorkoutIntensity {
        if soreness == .strong { return .low }
        if level == .advanced && soreness == .none { return .high }
        if goal == .weightLoss || goal == .conditioning { return .moderate }
        return .moderate
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
}

private struct OpenAIPlanResponse: Decodable {
    struct SelectedBlock: Decodable {
        let blockId: String
        let setsMultiplier: Double?
        let repsMultiplier: Double?
        let restAdjustmentSeconds: Double?

        private enum CodingKeys: String, CodingKey {
            case blockId = "block_id"
            case setsMultiplier = "sets_multiplier"
            case repsMultiplier = "reps_multiplier"
            case restAdjustmentSeconds = "rest_adjustment_seconds"
        }
    }

    let selectedBlocks: [SelectedBlock]

    private enum CodingKeys: String, CodingKey {
        case selectedBlocks = "selected_blocks"
    }
}

struct HybridWorkoutPlanComposer: WorkoutPlanComposing {
    private let remoteComposer: OpenAIWorkoutPlanComposer?
    private let localComposer: LocalWorkoutPlanComposer
    private let usageLimiter: OpenAIUsageLimiting?
    private let clock: () -> Date

    init(
        remoteComposer: OpenAIWorkoutPlanComposer?,
        localComposer: LocalWorkoutPlanComposer,
        usageLimiter: OpenAIUsageLimiting?,
        clock: @escaping () -> Date = { Date() }
    ) {
        self.remoteComposer = remoteComposer
        self.localComposer = localComposer
        self.usageLimiter = usageLimiter
        self.clock = clock
    }

    func composePlan(
        blocks: [WorkoutBlock],
        profile: UserProfile,
        checkIn: DailyCheckIn
    ) async throws -> WorkoutPlan {
        let now = clock()
        if
            let remote = remoteComposer,
            await usageLimiter?.canUseAI(userId: profile.id, on: now) ?? true
        {
            do {
                let plan = try await remote.composePlan(blocks: blocks, profile: profile, checkIn: checkIn)
                await usageLimiter?.registerUsage(userId: profile.id, on: now)
                return plan
            } catch {
                // Logado internamente pelo remote; continuar com fallback
            }
        }
        return try await localComposer.composePlan(blocks: blocks, profile: profile, checkIn: checkIn)
    }
}

