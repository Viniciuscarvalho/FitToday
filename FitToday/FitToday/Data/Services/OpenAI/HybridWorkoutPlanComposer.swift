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
        // Base local (fallback e também fonte de fases guiadas/aquecimento/aeróbio)
        let localPlan = try await localComposer.composePlan(blocks: blocks, profile: profile, checkIn: checkIn)

        let prompt = promptText(blocks: blocks, profile: profile, checkIn: checkIn)
        let cacheKey = Hashing.sha256(prompt)
        let data = try await client.sendJSONPrompt(prompt: prompt, cachedKey: cacheKey)
        
        // 1. Decodificar resposta do Chat Completions
        let chatResponse = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        
        // 2. Extrair o conteúdo JSON da mensagem do assistente
        guard let content = chatResponse.choices.first?.message.content,
              let contentData = content.data(using: .utf8) else {
            logger("Resposta vazia do OpenAI - fallback para local")
            return localPlan
        }
        
        // 3. Decodificar o JSON do plano de treino
        let response = try JSONDecoder().decode(OpenAIPlanResponse.self, from: contentData)
        return assemblePlan(response: response, blocks: blocks, profile: profile, checkIn: checkIn, fallback: localPlan)
    }

    private func assemblePlan(
        response: OpenAIPlanResponse,
        blocks: [WorkoutBlock],
        profile: UserProfile,
        checkIn: DailyCheckIn,
        fallback: WorkoutPlan
    ) -> WorkoutPlan {
        let blockMap = Dictionary(uniqueKeysWithValues: blocks.map { ($0.id, $0) })

        // Monta fases a partir do retorno do OpenAI (apenas strength/accessory).
        let soreness = checkIn.sorenessLevel
        let mainPrescription = SpecialistSessionRules.mainPrescription(for: SpecialistSessionRules.sessionType(for: profile.mainGoal))
        let accessoryPrescription = SpecialistSessionRules.accessoryPrescription(for: SpecialistSessionRules.sessionType(for: profile.mainGoal))

        let aiPhases: [WorkoutPlanPhase] = response.phases.compactMap { phase in
            let kind = WorkoutPlanPhase.Kind(rawValue: phase.kind) ?? .strength
            let title: String
            let rpe: Int?
            let basePrescription: SpecialistSessionRules.PhasePrescription

            switch kind {
            case .strength:
                title = "Força"
                rpe = mainPrescription.rpeTarget
                basePrescription = mainPrescription
            case .accessory:
                title = "Acessórios"
                rpe = accessoryPrescription.rpeTarget
                basePrescription = accessoryPrescription
            default:
                // Para manter escopo controlado, ignoramos outros kinds retornados
                return nil
            }

            let items: [WorkoutPlanItem] = phase.selectedBlocks.flatMap { selected -> [WorkoutPlanItem] in
                guard let block = blockMap[selected.blockId] else { return [] }
                let adjusted = applyAdjustments(
                    selected,
                    block: block,
                    profile: profile,
                    soreness: soreness,
                    basePrescription: basePrescription
                )
                return adjusted.map { WorkoutPlanItem.exercise($0) }
            }

            return WorkoutPlanPhase(kind: kind, title: title, rpeTarget: rpe, items: items)
        }

        // Se IA não retornou nada útil, fallback total.
        guard !aiPhases.isEmpty, aiPhases.contains(where: { !$0.exercises.isEmpty }) else {
            return fallback
        }

        // Preserva aquecimento/aeróbio do plano local para UX consistente.
        let warmup = fallback.phases.first(where: { $0.kind == .warmup })
        let aerobic = fallback.phases.first(where: { $0.kind == .aerobic })
        let finisher = fallback.phases.first(where: { $0.kind == .finisher })

        let phases = [warmup] + aiPhases + [finisher, aerobic]
        let finalPhases = phases.compactMap { $0 }.filter { !$0.items.isEmpty }

        let duration = estimateDurationMinutes(phases: finalPhases)
        let intensity = SpecialistSessionRules.intensity(for: profile.level, soreness: checkIn.sorenessLevel, goal: profile.mainGoal)
        let appliedFocus = checkIn.focus == .surprise ? (blocks.first?.group ?? .fullBody) : checkIn.focus

        return WorkoutPlan(
            title: fallback.title,
            focus: appliedFocus,
            estimatedDurationMinutes: duration,
            intensity: intensity,
            phases: finalPhases,
            createdAt: fallback.createdAt
        )
    }

    private func applyAdjustments(
        _ adjustment: OpenAIPlanResponse.SelectedBlock,
        block: WorkoutBlock,
        profile: UserProfile,
        soreness: MuscleSorenessLevel,
        basePrescription: SpecialistSessionRules.PhasePrescription
    ) -> [ExercisePrescription] {
        // Base: usa prescrição da fase (mais coerente com personal-active) como baseline.
        let baseSets = (basePrescription.setsRange.lowerBound + basePrescription.setsRange.upperBound) / 2
        let setMultiplier = adjustment.setsMultiplier ?? 1.0
        let repsMultiplier = adjustment.repsMultiplier ?? goalBias(for: profile.mainGoal)
        let restDelta = adjustment.restAdjustmentSeconds ?? restDelta(for: soreness)

        return block.exercises.map { exercise in
            let setsValue = max(1, Int(Double(baseSets) * setMultiplier))
            let lower = max(1, Int(Double(basePrescription.repsRange.lowerBound) * repsMultiplier))
            let upper = max(lower, Int(Double(basePrescription.repsRange.upperBound) * repsMultiplier))
            return ExercisePrescription(
                exercise: exercise,
                sets: setsValue,
                reps: IntRange(lower, upper),
                restInterval: max(10, TimeInterval(basePrescription.restSeconds) + restDelta),
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
        let guidelines = loadPersonalActiveGuidelines(for: profile.mainGoal)

        return """
        Você é um personal trainer especialista. Selecione e ajuste blocos de treino do catálogo.

        GUIDELINES (personal-active, siga como regras):
        \(guidelines)

        PERFIL: objetivo=\(profile.mainGoal.rawValue), nível=\(profile.level.rawValue), estrutura=\(profile.availableStructure.rawValue)
        CHECK-IN: foco=\(checkIn.focus.rawValue), DOMS=\(checkIn.sorenessLevel.rawValue), áreas=[\(checkIn.sorenessAreas.map(\.rawValue).joined(separator: ","))]

        REGRAS POR OBJETIVO (\(profile.mainGoal.rawValue)):
        \(goalRules)

        REGRAS POR DOMS (\(checkIn.sorenessLevel.rawValue)):
        \(domsRules)

        FORMATO DE RESPOSTA (JSON OBRIGATÓRIO):
        {"phases":[{"kind":"strength","selected_blocks":[{"block_id":"ID","sets_multiplier":1.0,"reps_multiplier":1.0,"rest_adjustment_seconds":0}]},{"kind":"accessory","selected_blocks":[{"block_id":"ID","sets_multiplier":1.0,"reps_multiplier":1.0,"rest_adjustment_seconds":0}]}]}

        REGRAS CRÍTICAS:
        - Retorne APENAS JSON válido, sem texto adicional.
        - Use APENAS IDs do catálogo abaixo.
        - sets_multiplier: 0.7-1.3 (0.7=redução, 1.3=aumento)
        - reps_multiplier: 0.8-1.2
        - rest_adjustment_seconds: -30 a +60
        - Selecione 2 blocos para strength e 1-2 blocos para accessory (avançado tende a 2 acessórios).

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

    private func loadPersonalActiveGuidelines(for goal: FitnessGoal) -> String {
        let resourceName: String
        switch goal {
        case .weightLoss:
            resourceName = "personal_active_emagrecimento"
        case .hypertrophy:
            resourceName = "personal_active_forca_pura"
        case .performance:
            resourceName = "personal_active_performance"
        case .conditioning, .endurance:
            resourceName = "personal_active_condicionamento"
        }

        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "md"),
              let data = try? Data(contentsOf: url),
              let text = String(data: data, encoding: .utf8)
        else {
            return ""
        }

        // Evita prompt muito grande.
        return String(text.prefix(2500))
    }

    private func estimateDurationMinutes(phases: [WorkoutPlanPhase]) -> Int {
        let exercises = phases.flatMap(\.exercises)
        let seconds = exercises.reduce(0) { acc, prescription in
            let workTime = Double(prescription.reps.average) * 3.0 * Double(prescription.sets)
            let restTime = Double(prescription.restInterval) * Double(max(0, prescription.sets - 1))
            return acc + Int(workTime + restTime)
        }

        let activityMinutes = phases
            .flatMap(\.items)
            .compactMap { item -> Int? in
                if case .activity(let activity) = item { return activity.durationMinutes }
                return nil
            }
            .reduce(0, +)

        return max(20, Int(ceil(Double(seconds) / 60.0)) + activityMinutes + 2)
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

// MARK: - Chat Completions Response Models

/// Resposta completa da API Chat Completions
private struct ChatCompletionResponse: Decodable {
    let choices: [Choice]
    
    struct Choice: Decodable {
        let message: Message
    }
    
    struct Message: Decodable {
        let content: String?
    }
}

/// Estrutura do JSON retornado pelo modelo (dentro do content)
private struct OpenAIPlanResponse: Decodable {
    struct Phase: Decodable {
        let kind: String
        let selectedBlocks: [SelectedBlock]

        private enum CodingKeys: String, CodingKey {
            case kind
            case selectedBlocks = "selected_blocks"
        }
    }

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

    let phases: [Phase]
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

/// Capacidades de IA disponíveis apenas para usuários Pro
enum AICapability: String, CaseIterable {
    case fineTuning = "ajuste_fino"           // Ajuste fino de volume/intensidade
    case dailyPersonalization = "personalizacao_diaria"  // Personalização baseada no check-in
    case blockReordering = "reordenacao"      // Reordenação inteligente de blocos
    case explanations = "explicacoes"         // Linguagem/explicações personalizadas
}

/// Compositor que verifica dinamicamente:
/// 1. Se o usuário é PRO
/// 2. Se tem chave de API configurada
/// 3. Cria o cliente OpenAI sob demanda quando necessário
///
/// Usuários FREE sempre usam o compositor local.
struct DynamicHybridWorkoutPlanComposer: WorkoutPlanComposing {
    private let localComposer: LocalWorkoutPlanComposer
    private let usageLimiter: OpenAIUsageLimiting?
    private let entitlementProvider: (() async -> ProEntitlement)?
    private let clock: () -> Date
    private let logger: (String) -> Void

    init(
        localComposer: LocalWorkoutPlanComposer,
        usageLimiter: OpenAIUsageLimiting?,
        entitlementProvider: (() async -> ProEntitlement)? = nil,
        clock: @escaping () -> Date = { Date() },
        logger: @escaping (String) -> Void = { print("[DynamicHybrid]", $0) }
    ) {
        self.localComposer = localComposer
        self.usageLimiter = usageLimiter
        self.entitlementProvider = entitlementProvider
        self.clock = clock
        self.logger = logger
    }

    func composePlan(
        blocks: [WorkoutBlock],
        profile: UserProfile,
        checkIn: DailyCheckIn
    ) async throws -> WorkoutPlan {
        let now = clock()
        
        // GATING PRO: Verificar se usuário é Pro
        let entitlement = await resolveEntitlement()
        guard entitlement.isPro else {
            logger("Usuário FREE - usando compositor local (IA requer PRO)")
            return try await localComposer.composePlan(blocks: blocks, profile: profile, checkIn: checkIn)
        }
        
        // Verificar se o usuário tem chave de API configurada
        guard let configuration = OpenAIConfiguration.loadFromUserKey() else {
            logger("PRO sem chave de API configurada - usando compositor local")
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
            logger("PRO: Usando OpenAI para refinar plano (capacidades: ajuste fino, personalização, reordenação, explicações)")
            let plan = try await remoteComposer.composePlan(blocks: blocks, profile: profile, checkIn: checkIn)
            await usageLimiter?.registerUsage(userId: profile.id, on: now)
            return plan
        } catch {
            logger("Erro no OpenAI: \(error.localizedDescription) - fallback para local")
            return try await localComposer.composePlan(blocks: blocks, profile: profile, checkIn: checkIn)
        }
    }
    
    private func resolveEntitlement() async -> ProEntitlement {
        // Usar provider se disponível
        if let provider = entitlementProvider {
            return await provider()
        }
        
        // Verificar debug override
        #if DEBUG
        if DebugEntitlementOverride.shared.isEnabled {
            return DebugEntitlementOverride.shared.entitlement
        }
        #endif
        
        // Default: Free
        return .free
    }
}

