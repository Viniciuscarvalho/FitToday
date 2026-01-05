//
//  LocalWorkoutPlanComposer.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import Foundation

/// Compositor local de planos de treino com regras de especialista
/// Baseado nos guias de `personal-active/` para estrutura completa e ajuste por DOMS
struct LocalWorkoutPlanComposer: WorkoutPlanComposing, Sendable {
    
    private let validator = WorkoutPlanValidator()
    
    // MARK: - WorkoutPlanComposing
    
    func composePlan(
        blocks: [WorkoutBlock],
        profile: UserProfile,
        checkIn: DailyCheckIn
    ) async throws -> WorkoutPlan {
        let sessionType = SpecialistSessionRules.sessionType(for: profile.mainGoal)
        let domsAdjustment = SpecialistSessionRules.DOMSAdjustment.adjustment(for: checkIn.sorenessLevel)
        let phases = SpecialistSessionRules.phases(for: sessionType)
        
        // 1. Filtrar e priorizar blocos por foco e objetivo
        let filteredBlocks = filterBlocks(
            blocks,
            profile: profile,
            checkIn: checkIn,
            domsAdjustment: domsAdjustment
        )
        
        // 2. Selecionar blocos para cada fase da sessão
        let selectedBlocks = selectBlocksForPhases(
            from: filteredBlocks,
            phases: phases,
            checkIn: checkIn,
            profile: profile
        )
        
        // 3. Se não conseguiu blocos suficientes, usar fallback
        guard !selectedBlocks.isEmpty else {
            return try fallbackPlan(allBlocks: blocks, profile: profile, checkIn: checkIn)
        }
        
        // 4. Montar plano com prescrições ajustadas por objetivo e DOMS
        var plan = assemblePlan(
            selectedBlocks,
            profile: profile,
            checkIn: checkIn,
            sessionType: sessionType,
            domsAdjustment: domsAdjustment
        )
        
        // 5. Validar e sanitizar se necessário
        if !validator.isValid(plan: plan, for: profile.mainGoal) {
            plan = validator.sanitize(plan: plan, for: profile.mainGoal)
        }
        
        return plan
    }
    
    // MARK: - Block Filtering
    
    private func filterBlocks(
        _ blocks: [WorkoutBlock],
        profile: UserProfile,
        checkIn: DailyCheckIn,
        domsAdjustment: SpecialistSessionRules.DOMSAdjustment
    ) -> [(block: WorkoutBlock, score: Int)] {
        let musclePriority = SpecialistSessionRules.musclePriority(for: checkIn.focus, goal: profile.mainGoal)
        let soreMuscles = Set(checkIn.sorenessAreas)
        let focusTargets = targets(for: checkIn.focus)
        
        return blocks
            .filter { focusTargets.contains($0.group) }
            .filter { $0.matches(profile: profile, checkIn: checkIn, soreMuscles: soreMuscles) }
            .filter { block in
                // Se DOMS alto, evitar exercícios de alto impacto
                if domsAdjustment.avoidPlyometrics {
                    return !block.isHighImpact
                }
                return true
            }
            .map { block in
                let score = compatibilityScore(
                    for: block,
                    profile: profile,
                    checkIn: checkIn,
                    musclePriority: musclePriority
                )
                return (block, score)
            }
            .sorted { $0.score > $1.score }
    }
    
    private func selectBlocksForPhases(
        from candidates: [(block: WorkoutBlock, score: Int)],
        phases: SpecialistSessionRules.SessionPhases,
        checkIn: DailyCheckIn,
        profile: UserProfile
    ) -> [WorkoutBlock] {
        let targetCount = min(
            phases.mainExercises + phases.accessoryExercises,
            max(2, candidates.count)
        )
        
        // Selecionar os melhores blocos
        return Array(candidates.prefix(targetCount).map(\.block))
    }
    
    // MARK: - Plan Assembly
    
    private func assemblePlan(
        _ blocks: [WorkoutBlock],
        profile: UserProfile,
        checkIn: DailyCheckIn,
        sessionType: SpecialistSessionRules.SessionType,
        domsAdjustment: SpecialistSessionRules.DOMSAdjustment
    ) -> WorkoutPlan {
        let appliedFocus = checkIn.focus == .surprise ? (blocks.first?.group ?? .fullBody) : checkIn.focus
        
        // Separar exercícios principais e acessórios
        let mainPrescription = SpecialistSessionRules.mainPrescription(for: sessionType)
        let accessoryPrescription = SpecialistSessionRules.accessoryPrescription(for: sessionType)
        
        var allPrescriptions: [ExercisePrescription] = []
        
        for (index, block) in blocks.enumerated() {
            let isMainBlock = index < 2
            let basePrescription = isMainBlock ? mainPrescription : accessoryPrescription
            
            let blockPrescriptions = prescriptions(
                from: block,
                basePrescription: basePrescription,
                profile: profile,
                checkIn: checkIn,
                domsAdjustment: domsAdjustment
            )
            
            allPrescriptions.append(contentsOf: blockPrescriptions)
        }
        
        let duration = estimatedDuration(for: allPrescriptions)
        let intensity = SpecialistSessionRules.intensity(
            for: profile.level,
            soreness: checkIn.sorenessLevel,
            goal: profile.mainGoal
        )
        
        let title = SpecialistSessionRules.sessionTitle(
            focus: appliedFocus,
            goal: profile.mainGoal,
            soreness: checkIn.sorenessLevel
        )
        
        return WorkoutPlan(
            title: title,
            focus: appliedFocus,
            estimatedDurationMinutes: duration,
            intensity: intensity,
            exercises: allPrescriptions
        )
    }
    
    // MARK: - Prescription Generation
    
    private func prescriptions(
        from block: WorkoutBlock,
        basePrescription: SpecialistSessionRules.PhasePrescription,
        profile: UserProfile,
        checkIn: DailyCheckIn,
        domsAdjustment: SpecialistSessionRules.DOMSAdjustment
    ) -> [ExercisePrescription] {
        
        return block.exercises.map { exercise in
            // Calcular sets ajustados por DOMS
            let baseSets = basePrescription.setsRange.average
            let adjustedSets = Int(Double(baseSets) * domsAdjustment.volumeMultiplier)
            let finalSets = max(basePrescription.setsRange.lowerBound, adjustedSets)
            
            // Calcular reps ajustados por objetivo e nível
            let reps = adjustedReps(
                baseRange: basePrescription.repsRange,
                profile: profile,
                domsAdjustment: domsAdjustment
            )
            
            // Calcular descanso ajustado por DOMS
            let baseRest = TimeInterval(basePrescription.restSeconds)
            let adjustedRest = baseRest + TimeInterval(domsAdjustment.extraRestSeconds)
            
            // Gerar dica contextual
            let tip = generateTip(
                for: exercise,
                domsAdjustment: domsAdjustment,
                sessionType: SpecialistSessionRules.sessionType(for: profile.mainGoal)
            )
            
            return ExercisePrescription(
                exercise: exercise,
                sets: finalSets,
                reps: reps,
                restInterval: adjustedRest,
                tip: tip
            )
        }
    }
    
    private func adjustedReps(
        baseRange: ClosedRange<Int>,
        profile: UserProfile,
        domsAdjustment: SpecialistSessionRules.DOMSAdjustment
    ) -> IntRange {
        var lower = baseRange.lowerBound
        var upper = baseRange.upperBound
        
        // Ajustar por nível
        if profile.level == .beginner {
            lower = max(baseRange.lowerBound, 8)
            upper = min(baseRange.upperBound + 2, 20)
        } else if profile.level == .advanced && !domsAdjustment.intensityReduction {
            // Avançados podem ir mais pesado (menos reps)
            lower = max(baseRange.lowerBound - 2, 1)
        }
        
        // Se DOMS alto, aumentar reps para reduzir carga
        if domsAdjustment.intensityReduction {
            lower = lower + 2
            upper = upper + 2
        }
        
        return IntRange(lower, upper)
    }
    
    private func generateTip(
        for exercise: WorkoutExercise,
        domsAdjustment: SpecialistSessionRules.DOMSAdjustment,
        sessionType: SpecialistSessionRules.SessionType
    ) -> String? {
        // Dicas contextuais baseadas em DOMS e tipo de sessão
        if domsAdjustment.avoidMuscleFailure {
            return "Evite falha muscular. Priorize técnica e controle."
        }
        
        if domsAdjustment.intensityReduction {
            return "Reduza a carga se necessário. Foco em qualidade do movimento."
        }
        
        // Dicas por tipo de sessão
        switch sessionType {
        case .strength:
            return exercise.instructions.first ?? "Movimento controlado. Descanso completo entre séries."
        case .performance:
            return exercise.instructions.first ?? "Foco em velocidade e explosão. Qualidade > quantidade."
        case .weightLoss:
            return exercise.instructions.first ?? "Mantenha o ritmo. Intervalos curtos para manter a frequência cardíaca."
        case .conditioning:
            return exercise.instructions.first ?? "Respiração controlada. Mantenha a intensidade moderada."
        case .endurance:
            return exercise.instructions.first ?? "Ritmo constante. Não acelere demais no início."
        }
    }
    
    // MARK: - Helper Methods
    
    private func targets(for focus: DailyFocus) -> [DailyFocus] {
        switch focus {
        case .surprise:
            return [.fullBody, .upper, .lower, .cardio, .core]
        default:
            return [focus]
        }
    }
    
    private func estimatedDuration(for exercises: [ExercisePrescription]) -> Int {
        let seconds = exercises.reduce(0) { acc, prescription in
            let workTime = Double(prescription.reps.average) * 3.0 * Double(prescription.sets)
            let restTime = Double(prescription.restInterval) * Double(max(0, prescription.sets - 1))
            return acc + Int(workTime + restTime)
        }
        // Adicionar tempo de aquecimento (~5min) e transições (~2min)
        let warmupAndTransitions = 7 * 60
        return max(20, Int(ceil(Double(seconds + warmupAndTransitions) / 60.0)))
    }
    
    private func compatibilityScore(
        for block: WorkoutBlock,
        profile: UserProfile,
        checkIn: DailyCheckIn,
        musclePriority: SpecialistSessionRules.MuscleGroupPriority
    ) -> Int {
        var score = 0
        
        // Compatibilidade com foco do dia (prioridade alta)
        if block.group == checkIn.focus {
            score += 10
        }
        
        // Full body é sempre compatível
        if block.group == .fullBody {
            score += 5
        }
        
        // Compatibilidade com focos relacionados
        let relatedFocuses = relatedFocuses(for: checkIn.focus)
        if relatedFocuses.contains(block.group) {
            score += 3
        }
        
        // Compatibilidade com nível
        if block.level == profile.level {
            score += 3
        } else if profile.level == .advanced && block.level == .intermediate {
            score += 2
        }
        
        // Equipamento disponível
        if block.equipmentOptions.contains(where: { preferredEquipments(for: profile.availableStructure).contains($0) }) {
            score += 2
        }
        
        // Boost para objetivo específico
        switch profile.mainGoal {
        case .hypertrophy:
            if block.suggestedSets.average >= 3 {
                score += 2
            }
        case .weightLoss, .conditioning:
            if block.suggestedReps.average >= 12 {
                score += 2
            }
        default:
            break
        }
        
        return score
    }
    
    private func relatedFocuses(for focus: DailyFocus) -> [DailyFocus] {
        switch focus {
        case .upper:
            return [.fullBody]
        case .lower:
            return [.fullBody, .cardio]
        case .fullBody:
            return [.upper, .lower]
        case .cardio:
            return [.fullBody, .lower]
        case .core:
            return [.fullBody]
        case .surprise:
            return DailyFocus.allCases
        }
    }
    
    private func preferredEquipments(for structure: TrainingStructure) -> [EquipmentType] {
        switch structure {
        case .bodyweight:
            return [.bodyweight]
        case .homeDumbbells:
            return [.dumbbell, .bodyweight, .kettlebell]
        case .basicGym:
            return [.machine, .dumbbell, .cable, .bodyweight]
        case .fullGym:
            return [.barbell, .machine, .dumbbell, .cable, .bodyweight, .pullupBar]
        }
    }
    
    // MARK: - Fallback
    
    private func fallbackPlan(
        allBlocks: [WorkoutBlock],
        profile: UserProfile,
        checkIn: DailyCheckIn
    ) throws -> WorkoutPlan {
        // Tentar blocos fullBody primeiro
        let fullBodyBlocks = allBlocks
            .filter { $0.group == .fullBody }
            .filter { $0.matches(profile: profile, checkIn: checkIn, soreMuscles: Set()) }
        
        if let block = fullBodyBlocks.first {
            let sessionType = SpecialistSessionRules.sessionType(for: profile.mainGoal)
            let domsAdjustment = SpecialistSessionRules.DOMSAdjustment.adjustment(for: checkIn.sorenessLevel)
            
            return assemblePlan(
                [block],
                profile: profile,
                checkIn: checkIn,
                sessionType: sessionType,
                domsAdjustment: domsAdjustment
            )
        }
        
        // Último recurso: pegar qualquer bloco disponível do nível mais baixo
        let compatibleBlocks = allBlocks
            .filter { block in
                block.matches(profile: profile, checkIn: checkIn, soreMuscles: Set())
            }
            .sorted { $0.level.rawValue < $1.level.rawValue }
        
        guard let lightBlock = compatibleBlocks.first else {
            throw DomainError.noCompatibleBlocks
        }
        
        let sessionType = SpecialistSessionRules.sessionType(for: profile.mainGoal)
        let domsAdjustment = SpecialistSessionRules.DOMSAdjustment.adjustment(for: checkIn.sorenessLevel)
        
        return assemblePlan(
            [lightBlock],
            profile: profile,
            checkIn: checkIn,
            sessionType: sessionType,
            domsAdjustment: domsAdjustment
        )
    }
}

// MARK: - Helper Extensions

private extension ClosedRange where Bound == Int {
    var average: Int {
        (lowerBound + upperBound) / 2
    }
}

extension WorkoutBlock {
    /// Indica se o bloco contém exercícios de alto impacto (pliometria, saltos)
    var isHighImpact: Bool {
        // Heurística simples: verificar pelo nome ou grupo
        exercises.contains { exercise in
            let name = exercise.name.lowercased()
            return name.contains("jump") ||
                   name.contains("salto") ||
                   name.contains("plio") ||
                   name.contains("burpee") ||
                   name.contains("box jump") ||
                   name.contains("squat jump")
        }
    }
}
