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
            {"id":"\($0.id)","group":"\($0.group.rawValue)","level":"\($0.level.rawValue)","equip":"\($0.equipmentOptions.first?.rawValue ?? "bodyweight")","sets":"\($0.suggestedSets.lowerBound)-\($0.suggestedSets.upperBound)","reps":"\($0.suggestedReps.lowerBound)-\($0.suggestedReps.upperBound)"}
            """
        }.joined(separator: ",")

        let goalRules = goalSpecificRules(for: profile.mainGoal)
        let domsRules = domsSpecificRules(for: checkIn.sorenessLevel)

        return """
        Você é um personal trainer especialista. Selecione e ajuste blocos de treino do catálogo.

        PERFIL: objetivo=\(profile.mainGoal.rawValue), nível=\(profile.level.rawValue), estrutura=\(profile.availableStructure.rawValue)
        CHECK-IN: foco=\(checkIn.focus.rawValue), DOMS=\(checkIn.sorenessLevel.rawValue), áreas=[\(checkIn.sorenessAreas.map(\.rawValue).joined(separator: ","))]

        REGRAS POR OBJETIVO (\(profile.mainGoal.rawValue)):
        \(goalRules)

        REGRAS POR DOMS (\(checkIn.sorenessLevel.rawValue)):
        \(domsRules)

        FORMATO DE RESPOSTA (JSON OBRIGATÓRIO):
        {"selected_blocks":[{"block_id":"ID","sets_multiplier":1.0,"reps_multiplier":1.0,"rest_adjustment_seconds":0}]}

        REGRAS CRÍTICAS:
        - Retorne APENAS JSON válido, sem texto adicional.
        - Use APENAS IDs do catálogo abaixo.
        - sets_multiplier: 0.7-1.3 (0.7=redução, 1.3=aumento)
        - reps_multiplier: 0.8-1.2
        - rest_adjustment_seconds: -30 a +60
        - Selecione 2-3 blocos compatíveis com o foco do dia.

        CATÁLOGO:
        [\(blockSummaries)]
        """
    }
    
    private func goalSpecificRules(for goal: FitnessGoal) -> String {
        switch goal {
        case .hypertrophy:
            return """
            - Priorize exercícios multiarticulares pesados
            - Sets: 3-5, Reps: 1-6, Descanso longo (2-5min)
            - Evite falha muscular frequente
            - RPE alvo: 7-9
            """
        case .performance:
            return """
            - Movimentos rápidos e explosivos
            - Sets: 3-4, Reps: 3-8, Descanso adequado
            - Alternância de estímulos
            - Qualidade > quantidade
            """
        case .weightLoss:
            return """
            - Circuitos metabólicos, intervalos curtos
            - Sets: 3-4, Reps: 10-15, Descanso: 30-60s
            - Alta densidade, baixo impacto
            - RPE: 6-8
            """
        case .conditioning:
            return """
            - Força + resistência equilibrados
            - Sets: 3-4, Reps: 10-15, Descanso: 45-90s
            - Full body preferencial
            - RPE: 6-7
            """
        case .endurance:
            return """
            - Volume alto, descanso curto
            - Sets: 2-4, Reps: 15-25, Descanso: 20-45s
            - Ritmo constante
            - RPE: 5-7
            """
        }
    }
    
    private func domsSpecificRules(for soreness: MuscleSorenessLevel) -> String {
        switch soreness {
        case .none, .light:
            return """
            - Sem restrições
            - Progressão normal permitida
            """
        case .moderate:
            return """
            - Reduzir volume em 10%: sets_multiplier=0.9
            - Evitar falha muscular
            - Aumentar descanso em 15s
            """
        case .strong:
            return """
            - Reduzir volume em 25-35%: sets_multiplier=0.65-0.75
            - PROIBIDO: falha muscular, pliometria, saltos
            - Aumentar descanso em 30-45s
            - Priorizar técnica e controle
            - Evitar áreas com dor severa
            """
        }
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

/// Compositor que verifica dinamicamente se o usuário tem chave de API configurada
/// Cria o cliente OpenAI sob demanda quando necessário
struct DynamicHybridWorkoutPlanComposer: WorkoutPlanComposing {
    private let localComposer: LocalWorkoutPlanComposer
    private let usageLimiter: OpenAIUsageLimiting?
    private let clock: () -> Date
    private let logger: (String) -> Void

    init(
        localComposer: LocalWorkoutPlanComposer,
        usageLimiter: OpenAIUsageLimiting?,
        clock: @escaping () -> Date = { Date() },
        logger: @escaping (String) -> Void = { print("[DynamicHybrid]", $0) }
    ) {
        self.localComposer = localComposer
        self.usageLimiter = usageLimiter
        self.clock = clock
        self.logger = logger
    }

    func composePlan(
        blocks: [WorkoutBlock],
        profile: UserProfile,
        checkIn: DailyCheckIn
    ) async throws -> WorkoutPlan {
        let now = clock()
        
        // Verificar se o usuário tem chave de API configurada
        guard let configuration = OpenAIConfiguration.loadFromUserKey() else {
            logger("Sem chave de API do usuário - usando compositor local")
            return try await localComposer.composePlan(blocks: blocks, profile: profile, checkIn: checkIn)
        }
        
        // Verificar limite de uso
        guard await usageLimiter?.canUseAI(userId: profile.id, on: now) ?? true else {
            logger("Limite de uso atingido - usando compositor local")
            return try await localComposer.composePlan(blocks: blocks, profile: profile, checkIn: checkIn)
        }
        
        // Criar cliente sob demanda
        let client = OpenAIClient(configuration: configuration)
        let remoteComposer = OpenAIWorkoutPlanComposer(
            client: client,
            localComposer: localComposer,
            logger: logger
        )
        
        do {
            logger("Usando OpenAI para refinar plano")
            let plan = try await remoteComposer.composePlan(blocks: blocks, profile: profile, checkIn: checkIn)
            await usageLimiter?.registerUsage(userId: profile.id, on: now)
            return plan
        } catch {
            logger("Erro no OpenAI: \(error.localizedDescription) - fallback para local")
            return try await localComposer.composePlan(blocks: blocks, profile: profile, checkIn: checkIn)
        }
    }
}

