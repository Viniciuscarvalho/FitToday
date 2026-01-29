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
    private let blueprintEngine: WorkoutBlueprintEngine
    private let promptAssembler: WorkoutPromptAssembler
    private let qualityGate: WorkoutPlanQualityGate
    private let historyRepository: WorkoutHistoryRepository?
    private let feedbackAnalyzer: FeedbackAnalyzing
    private let exerciseNameNormalizer: ExerciseNameNormalizing
    private let mediaResolver: ExerciseMediaResolving?
    private let logger: (String) -> Void

    init(
        client: OpenAIClienting,
        localComposer: LocalWorkoutPlanComposer,
        exerciseNameNormalizer: ExerciseNameNormalizing,
        mediaResolver: ExerciseMediaResolving? = nil,
        blueprintEngine: WorkoutBlueprintEngine = WorkoutBlueprintEngine(),
        promptAssembler: WorkoutPromptAssembler = WorkoutPromptAssembler(),
        qualityGate: WorkoutPlanQualityGate = WorkoutPlanQualityGate(),
        historyRepository: WorkoutHistoryRepository? = nil,
        feedbackAnalyzer: FeedbackAnalyzing = FeedbackAnalyzer(),
        logger: @escaping (String) -> Void = { print("[OpenAI]", $0) }
    ) {
        self.client = client
        self.localComposer = localComposer
        self.exerciseNameNormalizer = exerciseNameNormalizer
        self.mediaResolver = mediaResolver
        self.blueprintEngine = blueprintEngine
        self.promptAssembler = promptAssembler
        self.qualityGate = qualityGate
        self.historyRepository = historyRepository
        self.feedbackAnalyzer = feedbackAnalyzer
        self.logger = logger
    }

    func composePlan(
        blocks: [WorkoutBlock],
        profile: UserProfile,
        checkIn: DailyCheckIn
    ) async throws -> WorkoutPlan {
        // 1. Gerar blueprint determinístico
        let blueprint = blueprintEngine.generateBlueprint(profile: profile, checkIn: checkIn)

        logger("Blueprint gerado: \(blueprint.title) (seed=\(blueprint.variationSeed))")

        // 2. Buscar treinos anteriores para evitar repetição (expandido para 7 dias)
        let previousWorkouts = await fetchRecentWorkouts(limit: 7)

        if !previousWorkouts.isEmpty {
            logger("Histórico: \(previousWorkouts.count) treinos recentes para evitar repetição")
        }

        // 3. Buscar e analisar feedback do usuário
        let recentRatings = await fetchRecentRatings(limit: 5)
        let intensityAdjustment = feedbackAnalyzer.analyzeRecentFeedback(
            ratings: recentRatings,
            currentIntensity: blueprint.intensity
        )

        if intensityAdjustment != .noChange {
            logger("Ajuste de intensidade: \(intensityAdjustment.recommendation)")
        }

        // 4. Montar prompt com variação baseada em seed e feedback
        let workoutPrompt = promptAssembler.assemblePrompt(
            blueprint: blueprint,
            blocks: blocks,
            profile: profile,
            checkIn: checkIn,
            previousWorkouts: previousWorkouts,
            intensityAdjustment: intensityAdjustment
        )
        
        logger("Prompt montado: \(workoutPrompt.systemMessage.count + workoutPrompt.userMessage.count) chars")
        
        // 4. Chamar OpenAI
        let promptText = formatPromptForOpenAI(workoutPrompt)
        let cacheKey = workoutPrompt.cacheKey
        
        logger("Chamando OpenAI... (timeout: 60s)")
        
        do {
            let data = try await client.sendJSONPrompt(prompt: promptText, cachedKey: cacheKey)
            
            logger("✅ Resposta recebida: \(data.count) bytes")
            
            // 5. Decodificar resposta
            let chatResponse = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
            
            guard let content = chatResponse.choices.first?.message.content,
                  let contentData = OpenAIResponseValidator.extractJSON(from: content) else {
                logger("⚠️ Resposta vazia do OpenAI - fallback para local")
                return try await localComposer.composePlan(blocks: blocks, profile: profile, checkIn: checkIn)
            }
            
            // 6. Validar resposta
            let openAIResponse = try OpenAIResponseValidator.validate(
                jsonData: contentData,
                expectedBlueprint: blueprint
            )
            
            logger("✅ Resposta validada: \(openAIResponse.phases.count) fases")
            
            // 7. Converter resposta OpenAI em WorkoutPlan
            let plan = await convertOpenAIResponseToPlan(
                response: openAIResponse,
                blueprint: blueprint,
                profile: profile,
                checkIn: checkIn,
                blocks: blocks
            )
            
            // 8. Quality Gate (validação + normalização + diversidade)
            let gateResult = qualityGate.process(
                plan: plan,
                blueprint: blueprint,
                profile: profile,
                previousPlans: previousWorkouts
            )
            
            if gateResult.succeeded || gateResult.status == .normalizedAndPassed {
                logger("✅ Quality gate passou: \(gateResult.status)")
                return gateResult.finalPlan!
            } else {
                // Retry único guiado por feedback do quality gate antes do fallback local
                if let feedback = qualityGate.generateRetryFeedback(from: gateResult) {
                    logger("⚠️ Quality gate falhou: \(gateResult.status) - retry único com feedback")
                    if let retriedPlan = try await retryOnce(
                        basePromptText: promptText,
                        feedback: feedback,
                        blueprint: blueprint,
                        profile: profile,
                        checkIn: checkIn,
                        blocks: blocks,
                        previousWorkouts: previousWorkouts
                    ) {
                        return retriedPlan
                    }
                }
                
                logger("⚠️ Quality gate falhou: \(gateResult.status) - usando fallback local")
                return try await localComposer.composePlan(blocks: blocks, profile: profile, checkIn: checkIn)
            }
            
        } catch let urlError as URLError {
            switch urlError.code {
            case .timedOut:
                logger("⏰ TIMEOUT: OpenAI demorou mais de 60s - usando fallback local")
            case .notConnectedToInternet, .networkConnectionLost:
                logger("📶 SEM CONEXÃO: Verifique sua internet - usando fallback local")
            default:
                logger("❌ Erro de rede: \(urlError.localizedDescription) - fallback local")
            }
            return try await localComposer.composePlan(blocks: blocks, profile: profile, checkIn: checkIn)
        } catch let openAIError as OpenAIClientError {
            switch openAIError {
            case .httpError(let status, let message):
                if status == 429 {
                    logger("🚫 RATE LIMIT: Muitas requisições - aguarde e tente novamente")
                } else {
                    logger("❌ Erro HTTP \(status): \(message.prefix(100))... - fallback local")
                }
            default:
                logger("❌ Erro OpenAI: \(openAIError.localizedDescription) - fallback local")
            }
            return try await localComposer.composePlan(blocks: blocks, profile: profile, checkIn: checkIn)
        } catch {
            logger("❌ Erro inesperado: \(error.localizedDescription) - fallback local")
            return try await localComposer.composePlan(blocks: blocks, profile: profile, checkIn: checkIn)
        }
    }
    
    // MARK: - Helpers
    
    private func fetchRecentWorkouts(limit: Int) async -> [WorkoutPlan] {
        guard let historyRepository = historyRepository else {
            return []
        }

        do {
            // Buscar últimas entradas de histórico
            let entries = try await historyRepository.listEntries(limit: limit, offset: 0)

            // Extrair WorkoutPlans das entries que tiverem
            let plans = entries.compactMap { $0.workoutPlan }

            #if DEBUG
            logger("Histórico carregado: \(entries.count) entradas, \(plans.count) com plano completo")
            #endif

            return plans
        } catch {
            logger("⚠️ Erro ao buscar histórico: \(error.localizedDescription)")
            return []
        }
    }

    private func fetchRecentRatings(limit: Int) async -> [WorkoutRating] {
        guard let historyRepository = historyRepository else {
            return []
        }

        do {
            // Buscar últimas entradas de histórico com avaliação
            let entries = try await historyRepository.listEntries(limit: limit, offset: 0)

            // Extrair ratings das entries que tiverem
            let ratings = entries.compactMap { $0.userRating }

            #if DEBUG
            if !ratings.isEmpty {
                logger("Feedback carregado: \(ratings.count) avaliações recentes")
            }
            #endif

            return ratings
        } catch {
            logger("⚠️ Erro ao buscar avaliações: \(error.localizedDescription)")
            return []
        }
    }
    
    private func formatPromptForOpenAI(_ workoutPrompt: WorkoutPrompt) -> String {
        """
        SYSTEM:
        \(workoutPrompt.systemMessage)
        
        USER:
        \(workoutPrompt.userMessage)
        """
    }
    
    private func retryOnce(
        basePromptText: String,
        feedback: String,
        blueprint: WorkoutBlueprint,
        profile: UserProfile,
        checkIn: DailyCheckIn,
        blocks: [WorkoutBlock],
        previousWorkouts: [WorkoutPlan]
    ) async throws -> WorkoutPlan? {
        let retryPrompt = basePromptText + "\n\n# FEEDBACK DE CORREÇÃO\n" + feedback + "\n\nRetorne APENAS o JSON final."
        
        let data = try await client.sendJSONPrompt(prompt: retryPrompt, cachedKey: nil)
        logger("🔁 Retry: resposta recebida: \(data.count) bytes")
        
        let chatResponse = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        guard let content = chatResponse.choices.first?.message.content,
              let contentData = OpenAIResponseValidator.extractJSON(from: content) else {
            logger("🔁 Retry: resposta vazia")
            return nil
        }
        
        let openAIResponse = try OpenAIResponseValidator.validate(
            jsonData: contentData,
            expectedBlueprint: blueprint
        )
        
        let plan = await convertOpenAIResponseToPlan(
            response: openAIResponse,
            blueprint: blueprint,
            profile: profile,
            checkIn: checkIn,
            blocks: blocks
        )
        
        let gateResult = qualityGate.process(
            plan: plan,
            blueprint: blueprint,
            profile: profile,
            previousPlans: previousWorkouts
        )
        
        if gateResult.succeeded || gateResult.status == .normalizedAndPassed {
            logger("✅ Retry passou: \(gateResult.status)")
            return gateResult.finalPlan
        }
        
        logger("🔁 Retry falhou: \(gateResult.status)")
        return nil
    }
    
    private func convertOpenAIResponseToPlan(
        response: OpenAIWorkoutResponse,
        blueprint: WorkoutBlueprint,
        profile: UserProfile,
        checkIn: DailyCheckIn,
        blocks: [WorkoutBlock]
    ) async -> WorkoutPlan {
        var phases: [WorkoutPlanPhase] = []
        
        // Mapear exercícios disponíveis por nome para facilitar lookup
        let allExercises = blocks.flatMap { $0.exercises }
        let exercisesByName = Dictionary(
            allExercises.map { ($0.name.lowercased(), $0) },
            uniquingKeysWith: { first, _ in first }
        )
        
        for openAIPhase in response.phases {
            // Determinar tipo de fase
            guard let phaseKind = WorkoutPlanPhase.Kind(rawValue: openAIPhase.kind) else {
                logger("⚠️ Tipo de fase desconhecido: \(openAIPhase.kind)")
                continue
            }
            
            var items: [WorkoutPlanItem] = []
            
            // Adicionar atividade guiada se houver
            if let activity = openAIPhase.activity {
                if let activityKind = ActivityPrescription.Kind(rawValue: activity.kind) {
                    items.append(.activity(ActivityPrescription(
                        kind: activityKind,
                        title: activity.title,
                        durationMinutes: activity.durationMinutes,
                        notes: activity.notes
                    )))
                }
            }
            
            // Adicionar exercícios
            if let exercises = openAIPhase.exercises {
                for ex in exercises {
                    // Normalizar nome antes de fazer matching
                    let normalizedName: String
                    do {
                        normalizedName = try await exerciseNameNormalizer.normalize(
                            exerciseName: ex.name,
                            equipment: ex.equipment,
                            muscleGroup: ex.muscleGroup
                        )
                    } catch {
                        logger("⚠️ Erro ao normalizar '\(ex.name)': \(error.localizedDescription) - usando nome original")
                        normalizedName = ex.name
                    }

                    // Tentar encontrar exercício no catálogo com nome normalizado
                    var exercise = exercisesByName[normalizedName.lowercased()]

                    // Se não encontrar, tentar busca parcial
                    if exercise == nil {
                        let searchName = normalizedName.lowercased()
                        exercise = allExercises.first { exerc in
                            exerc.name.lowercased().contains(searchName) ||
                            searchName.contains(exerc.name.lowercased())
                        }
                    }

                    // Se ainda não encontrar, tentar buscar por grupo muscular
                    if exercise == nil {
                        if let muscleGroup = MuscleGroup(rawValue: ex.muscleGroup.lowercased()) {
                            exercise = allExercises.first { $0.mainMuscle == muscleGroup }
                            if let foundExercise = exercise {
                                logger("⚠️ Substituindo '\(ex.name)' por '\(foundExercise.name)' (mesmo grupo muscular)")
                            }
                        }
                    }

                    // Fallback para criar exercício com nome da OpenAI + buscar mídia via Wger
                    let foundExercise: WorkoutExercise
                    if let catalogExercise = exercise {
                        foundExercise = catalogExercise
                    } else {
                        // Criar exercício temporário com nome normalizado
                        var newExercise = WorkoutExercise(
                            id: UUID().uuidString,
                            name: normalizedName, // Usar nome normalizado para buscar mídia
                            mainMuscle: MuscleGroup(rawValue: ex.muscleGroup.lowercased()) ?? .chest,
                            equipment: EquipmentType(rawValue: ex.equipment.lowercased()) ?? .bodyweight,
                            instructions: [], // OpenAI não retorna instruções na resposta
                            media: nil
                        )

                        // Buscar mídia usando o nome normalizado
                        // 💡 Learn: Usar do-catch para não quebrar o fluxo se houver erro de rede
                        if let resolver = mediaResolver {
                            do {
                                let resolvedMedia = await resolver.resolveMedia(for: newExercise, context: .card)
                                if resolvedMedia.hasMedia {
                                    newExercise = WorkoutExercise(
                                        id: newExercise.id,
                                        name: ex.name, // Mostrar nome original da OpenAI ao usuário
                                        mainMuscle: newExercise.mainMuscle,
                                        equipment: newExercise.equipment,
                                        instructions: newExercise.instructions,
                                        media: ExerciseMedia(
                                            imageURL: resolvedMedia.imageURL,
                                            gifURL: resolvedMedia.gifURL
                                        )
                                    )
                                    logger("✅ Mídia encontrada para '\(ex.name)' via nome normalizado '\(normalizedName)'")
                                } else {
                                    // Usar nome original da OpenAI se não encontrar mídia
                                    newExercise = WorkoutExercise(
                                        id: newExercise.id,
                                        name: ex.name,
                                        mainMuscle: newExercise.mainMuscle,
                                        equipment: newExercise.equipment,
                                        instructions: newExercise.instructions,
                                        media: nil
                                    )
                                    logger("⚠️ Exercício '\(ex.name)' não encontrado no catálogo e sem mídia na API Wger")
                                }
                            } catch {
                                // Se houver erro ao buscar mídia (ex: timeout), continuar sem mídia
                                newExercise = WorkoutExercise(
                                    id: newExercise.id,
                                    name: ex.name,
                                    mainMuscle: newExercise.mainMuscle,
                                    equipment: newExercise.equipment,
                                    instructions: newExercise.instructions,
                                    media: nil
                                )
                                logger("⚠️ Erro ao buscar mídia para '\(ex.name)': \(error.localizedDescription) - continuando sem mídia")
                            }
                        } else {
                            // Sem media resolver, usar nome original
                            newExercise = WorkoutExercise(
                                id: newExercise.id,
                                name: ex.name,
                                mainMuscle: newExercise.mainMuscle,
                                equipment: newExercise.equipment,
                                instructions: newExercise.instructions,
                                media: nil
                            )
                            logger("⚠️ Exercício '\(ex.name)' não encontrado no catálogo - usando nome da OpenAI")
                        }

                        foundExercise = newExercise
                    }

                    // Parsear reps
                    let repsComponents = ex.reps.components(separatedBy: "-")
                    let minReps = Int(repsComponents.first ?? "10") ?? 10
                    let maxReps = Int(repsComponents.last ?? "12") ?? 12
                    
                    items.append(.exercise(ExercisePrescription(
                        exercise: foundExercise,
                        sets: ex.sets,
                        reps: IntRange(minReps, maxReps),
                        restInterval: TimeInterval(ex.restSeconds),
                        tip: ex.notes
                    )))
                }
            }
            
            // Criar fase se houver items
            if !items.isEmpty {
                // Buscar RPE do blueprint para esta fase
                let blueprintBlock = blueprint.blocks.first { $0.phaseKind == phaseKind }
                let rpeTarget = blueprintBlock?.rpeTarget ?? 7
                
                // Usar título da fase do blueprint quando disponível
                let title: String
                if let blueprintTitle = blueprintBlock?.title {
                    title = blueprintTitle
                } else if let activityTitle = openAIPhase.activity?.title {
                    title = activityTitle
                } else {
                    title = phaseKind.rawValue.capitalized
                }
                
                phases.append(WorkoutPlanPhase(
                    kind: phaseKind,
                    title: title,
                    rpeTarget: rpeTarget,
                    items: items
                ))
            }
        }
        
        // Criar WorkoutPlan - usar título do blueprint que já tem o objetivo correto
        let title = response.title ?? blueprint.title
        let duration = blueprint.estimatedDurationMinutes
        
        return WorkoutPlan(
            title: title,
            focus: blueprint.focus,
            estimatedDurationMinutes: duration,
            intensity: blueprint.intensity,
            phases: phases,
            createdAt: Date()
        )
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
    private let exerciseNameNormalizer: ExerciseNameNormalizing?
    private let mediaResolver: ExerciseMediaResolving?
    private let feedbackAnalyzer: FeedbackAnalyzing
    private let entitlementProvider: (() async -> ProEntitlement)?
    private let historyRepository: WorkoutHistoryRepository?
    private let clock: () -> Date
    private let logger: (String) -> Void

    init(
        localComposer: LocalWorkoutPlanComposer,
        usageLimiter: OpenAIUsageLimiting?,
        exerciseNameNormalizer: ExerciseNameNormalizing? = nil,
        mediaResolver: ExerciseMediaResolving? = nil,
        feedbackAnalyzer: FeedbackAnalyzing = FeedbackAnalyzer(),
        entitlementProvider: (() async -> ProEntitlement)? = nil,
        historyRepository: WorkoutHistoryRepository? = nil,
        clock: @escaping () -> Date = { Date() },
        logger: @escaping (String) -> Void = { print("[DynamicHybrid]", $0) }
    ) {
        self.localComposer = localComposer
        self.usageLimiter = usageLimiter
        self.exerciseNameNormalizer = exerciseNameNormalizer
        self.mediaResolver = mediaResolver
        self.feedbackAnalyzer = feedbackAnalyzer
        self.entitlementProvider = entitlementProvider
        self.historyRepository = historyRepository
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
        
        // Criar cliente e compositor sob demanda
        let client = OpenAIClient(configuration: configuration)

        // 💡 Learn: Usar normalizer se disponível, senão usa fallback que retorna nome original
        let normalizer = exerciseNameNormalizer ?? NoOpExerciseNameNormalizer()

        let remoteComposer = OpenAIWorkoutPlanComposer(
            client: client,
            localComposer: localComposer,
            exerciseNameNormalizer: normalizer,
            mediaResolver: mediaResolver,
            historyRepository: historyRepository,
            feedbackAnalyzer: feedbackAnalyzer,
            logger: logger
        )
        
        do {
            logger("PRO: Usando OpenAI para gerar treino (blueprint + variação + histórico)")
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

