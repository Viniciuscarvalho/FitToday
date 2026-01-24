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

        // Track used exercise IDs to prevent duplicates across phases
        var usedExerciseIds = Set<String>()

        // 1) Aquecimento: mescla atividade guiada + alguns exercícios leves (opcional)
        let warmupPhase = buildWarmupPhase(
            from: blocks,
            profile: profile,
            checkIn: checkIn,
            domsAdjustment: domsAdjustment,
            usedExerciseIds: &usedExerciseIds
        )

        // 2) Fase de força/principal: primeiros blocos
        let mainBlocks = Array(blocks.prefix(2))
        let mainItems: [WorkoutPlanItem] = mainBlocks
            .flatMap { block in
                prescriptions(
                    from: block,
                    basePrescription: mainPrescription,
                    profile: profile,
                    checkIn: checkIn,
                    domsAdjustment: domsAdjustment,
                    usedExerciseIds: &usedExerciseIds
                )
            }
            .map { .exercise($0) }

        let strengthPhase = WorkoutPlanPhase(
            kind: .strength,
            title: "Força",
            rpeTarget: mainPrescription.rpeTarget,
            items: mainItems
        )

        // 3) Acessórios: blocos restantes
        let accessoryBlocks = Array(blocks.dropFirst(min(2, blocks.count)))
        let accessoryItems: [WorkoutPlanItem] = accessoryBlocks
            .flatMap { block in
                prescriptions(
                    from: block,
                    basePrescription: accessoryPrescription,
                    profile: profile,
                    checkIn: checkIn,
                    domsAdjustment: domsAdjustment,
                    usedExerciseIds: &usedExerciseIds
                )
            }
            .map { .exercise($0) }

        let accessoryPhase = WorkoutPlanPhase(
            kind: .accessory,
            title: "Acessórios",
            rpeTarget: accessoryPrescription.rpeTarget,
            items: accessoryItems
        )

        // 4) Aeróbio guiado (sempre disponível como opção)
        let aerobicPhase = buildAerobicPhase(
            sessionType: sessionType,
            estimatedSessionMinutes: defaultSessionMinutes(profile: profile),
            soreness: checkIn.sorenessLevel
        )

        let phases: [WorkoutPlanPhase] = [warmupPhase, strengthPhase, accessoryPhase, aerobicPhase]
            .filter { !$0.items.isEmpty }

        let duration = estimatedDuration(for: phases)
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
            phases: phases
        )
    }
    
    // MARK: - Prescription Generation

    private func prescriptions(
        from block: WorkoutBlock,
        basePrescription: SpecialistSessionRules.PhasePrescription,
        profile: UserProfile,
        checkIn: DailyCheckIn,
        domsAdjustment: SpecialistSessionRules.DOMSAdjustment,
        usedExerciseIds: inout Set<String>
    ) -> [ExercisePrescription] {
        // Filter out already used exercises to prevent duplicates
        let availableExercises = block.exercises.filter { !usedExerciseIds.contains($0.id) }

        return availableExercises.map { exercise in
            // Mark exercise as used
            usedExerciseIds.insert(exercise.id)
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
    
    private func estimatedDuration(for phases: [WorkoutPlanPhase]) -> Int {
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

        // Adicionar transições (~2min). Aquecimento guiado já entra via activityMinutes quando presente.
        let transitionsMinutes = 2
        let totalMinutes = Int(ceil(Double(seconds) / 60.0)) + activityMinutes + transitionsMinutes
        return max(20, totalMinutes)
    }

    // MARK: - Phase Builders

    private func buildWarmupPhase(
        from blocks: [WorkoutBlock],
        profile: UserProfile,
        checkIn: DailyCheckIn,
        domsAdjustment: SpecialistSessionRules.DOMSAdjustment,
        usedExerciseIds: inout Set<String>
    ) -> WorkoutPlanPhase {
        let activity = ActivityPrescription(
            kind: .mobility,
            title: "Mobilidade + ativação",
            durationMinutes: domsAdjustment.intensityReduction ? 8 : 6,
            notes: "Movimentos controlados, sem falhar. Prepare articulações e padrão motor."
        )

        // Seleciona 1-2 exercícios leves do catálogo já presente (sem inventar exercício).
        // Heurística: pegar exercícios únicos do início dos blocos selecionados.
        // Skip exercises already used to prevent duplicates across phases.
        var seen = Set<String>()
        let warmupExercises: [WorkoutExercise] = blocks
            .flatMap(\.exercises)
            .filter { ex in
                if seen.contains(ex.id) || usedExerciseIds.contains(ex.id) { return false }
                seen.insert(ex.id)
                return true
            }
            .prefix(2)
            .map { $0 }

        // Track warmup exercises as used to prevent duplication in later phases
        for ex in warmupExercises {
            usedExerciseIds.insert(ex.id)
        }

        let warmupItems: [WorkoutPlanItem] = warmupExercises.map { ex in
            let prescription = ExercisePrescription(
                exercise: ex,
                sets: 1,
                reps: IntRange(8, 12),
                restInterval: domsAdjustment.intensityReduction ? 40 : 25,
                tip: "Aquecimento: ritmo leve, foco em amplitude e controle."
            )
            return .exercise(prescription)
        }

        return WorkoutPlanPhase(
            kind: .warmup,
            title: "Aquecimento",
            rpeTarget: domsAdjustment.intensityReduction ? 5 : 6,
            items: [.activity(activity)] + warmupItems
        )
    }

    private func buildAerobicPhase(
        sessionType: SpecialistSessionRules.SessionType,
        estimatedSessionMinutes: Int,
        soreness: MuscleSorenessLevel
    ) -> WorkoutPlanPhase {
        // Duração base ajustada ao tempo disponível do usuário.
        let base = min(15, max(8, Int(Double(estimatedSessionMinutes) * 0.25)))
        let minutes = soreness == .strong ? max(8, base - 3) : base

        let activity: ActivityPrescription
        switch sessionType {
        case .weightLoss:
            activity = ActivityPrescription(
                kind: .aerobicIntervals,
                title: "Aeróbio intervalado (leve)",
                durationMinutes: minutes,
                notes: "Intervalos moderados, sem sprint. Mantenha técnica e respiração."
            )
        case .conditioning, .endurance:
            activity = ActivityPrescription(
                kind: .aerobicZone2,
                title: "Aeróbio Zona 2",
                durationMinutes: minutes,
                notes: "Ritmo confortável e constante. Deve ser possível conversar."
            )
        case .performance:
            activity = ActivityPrescription(
                kind: .aerobicIntervals,
                title: "Condicionamento (intervalos curtos)",
                durationMinutes: minutes,
                notes: "Qualidade > quantidade. Recuperação adequada entre esforços."
            )
        case .strength:
            activity = ActivityPrescription(
                kind: .breathing,
                title: "Desaceleração + respiração",
                durationMinutes: min(8, minutes),
                notes: "Reduza a frequência cardíaca e finalize com controle."
            )
        }

        return WorkoutPlanPhase(
            kind: .aerobic,
            title: "Aeróbio",
            rpeTarget: 6,
            items: [.activity(activity)]
        )
    }

    private func defaultSessionMinutes(profile: UserProfile) -> Int {
        // Heurística simples: estrutura/equipamento + nível determinam o “tamanho típico” de sessão.
        let base: Int
        switch profile.availableStructure {
        case .bodyweight: base = 30
        case .homeDumbbells: base = 35
        case .basicGym: base = 45
        case .fullGym: base = 55
        }

        switch profile.level {
        case .beginner: return max(25, base - 5)
        case .intermediate: return base
        case .advanced: return base + 5
        }
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
