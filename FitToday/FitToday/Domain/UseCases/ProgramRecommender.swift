//
//  ProgramRecommender.swift
//  FitToday
//
//  Recomendador de programas e treinos baseado em:
//  - Objetivo do usuário (perfil)
//  - Histórico recente (evitar repetir tipo se treinou ontem)
//

import Foundation

/// Protocolo para recomendação de programas.
protocol ProgramRecommending: Sendable {
    /// Recomenda programas ordenados por relevância.
    func recommend(
        programs: [Program],
        profile: UserProfile?,
        history: [WorkoutHistoryEntry],
        limit: Int
    ) -> [Program]
    
    /// Recomenda treinos ordenados por relevância.
    func recommendWorkouts(
        workouts: [LibraryWorkout],
        profile: UserProfile?,
        history: [WorkoutHistoryEntry],
        limit: Int
    ) -> [LibraryWorkout]
}

/// Implementação do recomendador de programas.
struct ProgramRecommender: ProgramRecommending {
    
    init() {}
    
    func recommend(
        programs: [Program],
        profile: UserProfile?,
        history: [WorkoutHistoryEntry],
        limit: Int
    ) -> [Program] {
        guard !programs.isEmpty else { return [] }
        
        // Sem perfil: retorna os primeiros (ordem do seed)
        guard let profile = profile else {
            return Array(programs.prefix(limit))
        }
        
        let preferredTag = mapGoalToTag(profile.mainGoal)
        let trainedYesterday = didTrainYesterday(history: history)
        let yesterdayGoalTag = lastTrainingGoalTag(history: history)
        
        // Score para cada programa
        let scored = programs.map { program -> (Program, Int) in
            var score = 0
            
            // +10 pontos se o objetivo combina
            if program.goalTag == preferredTag {
                score += 10
            }
            
            // -5 pontos se treinou ontem com mesmo tipo (evitar repetir)
            if trainedYesterday, let yesterdayTag = yesterdayGoalTag, program.goalTag == yesterdayTag {
                score -= 5
            }
            
            // +3 pontos se nível combina
            if program.level == mapLevelToProgram(profile.level) {
                score += 3
            }
            
            return (program, score)
        }
        
        // Ordenar por score (maior primeiro), manter ordem estável para scores iguais
        let sorted = scored.sorted { $0.1 > $1.1 }
        return Array(sorted.prefix(limit).map { $0.0 })
    }
    
    func recommendWorkouts(
        workouts: [LibraryWorkout],
        profile: UserProfile?,
        history: [WorkoutHistoryEntry],
        limit: Int
    ) -> [LibraryWorkout] {
        guard !workouts.isEmpty else { return [] }
        
        guard let profile = profile else {
            return Array(workouts.prefix(limit))
        }
        
        let trainedYesterday = didTrainYesterday(history: history)
        let yesterdayGoal = lastTrainingGoal(history: history)
        
        // Score para cada treino
        let scored = workouts.map { workout -> (LibraryWorkout, Int) in
            var score = 0
            
            // +10 pontos se o objetivo combina
            if workout.goal == profile.mainGoal {
                score += 10
            }
            
            // +5 pontos se a estrutura combina
            if workout.structure == profile.availableStructure {
                score += 5
            }
            
            // -8 pontos se treinou ontem com mesmo objetivo (evitar repetir - aumentado para garantir variedade)
            if trainedYesterday, let yesterdayGoal = yesterdayGoal {
                let yesterdayGoalConverted = convertFocusToGoal(yesterdayGoal)
                if workout.goal == yesterdayGoalConverted {
                    score -= 8
                }
            }
            
            // -3 pontos se o treino foi já feito recentemente (últimos 3 dias)
            let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
            let recentlyDone = history.contains { entry in
                entry.status == .completed &&
                entry.date >= threeDaysAgo &&
                entry.focus == convertGoalToFocus(workout.goal)
            }
            if recentlyDone {
                score -= 3
            }
            
            return (workout, score)
        }
        
        let sorted = scored.sorted { $0.1 > $1.1 }
        
        // Se retorna menos de `limit` resultados, retorna todos ordenados
        // Se retorna mais, garante diversidade pegando resultados espalhados por score
        if sorted.count <= limit {
            return sorted.map { $0.0 }
        }
        
        // Estratégia de diversidade: pega o melhor, depois salta alguns, depois o próximo melhor, etc.
        var selected: [LibraryWorkout] = []
        var selectedIds: Set<String> = []
        let step = max(1, sorted.count / limit)
        
        for i in stride(from: 0, to: sorted.count, by: step) {
            if selected.count >= limit { break }
            let candidate = sorted[i].0
            // Evitar duplicatas
            if !selectedIds.contains(candidate.id) {
                selected.append(candidate)
                selectedIds.insert(candidate.id)
            }
        }
        
        // Se ainda não tem suficientes (edge case), adicionar os próximos melhores
        for (workout, _) in sorted {
            if selected.count >= limit { break }
            if !selectedIds.contains(workout.id) {
                selected.append(workout)
                selectedIds.insert(workout.id)
            }
        }
        
        return Array(selected.prefix(limit))
    }
    
    // MARK: - Helpers
    
    private func didTrainYesterday(history: [WorkoutHistoryEntry]) -> Bool {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return history.contains { entry in
            Calendar.current.isDate(entry.date, inSameDayAs: yesterday) && entry.status == .completed
        }
    }
    
    private func lastTrainingGoalTag(history: [WorkoutHistoryEntry]) -> ProgramGoalTag? {
        guard let lastCompleted = history
            .filter({ $0.status == .completed })
            .sorted(by: { $0.date > $1.date })
            .first else {
            return nil
        }
        
        // Converter focus do histórico para tag
        return convertFocusToProgramTag(lastCompleted.focus)
    }
    
    private func lastTrainingGoal(history: [WorkoutHistoryEntry]) -> DailyFocus? {
        return history
            .filter { $0.status == .completed }
            .sorted { $0.date > $1.date }
            .first?.focus
    }
    
    private func convertFocusToProgramTag(_ focus: DailyFocus) -> ProgramGoalTag {
        switch focus {
        case .cardio:
            return .aerobic
        case .upper, .lower, .fullBody:
            return .strength
        case .core:
            return .core
        case .surprise:
            return .conditioning
        }
    }
    
    private func convertFocusToGoal(_ focus: DailyFocus) -> FitnessGoal {
        switch focus {
        case .cardio:
            return .conditioning
        case .upper, .lower, .fullBody:
            return .hypertrophy
        case .core:
            return .endurance
        case .surprise:
            return .performance
        }
    }
    
    private func convertGoalToFocus(_ goal: FitnessGoal) -> DailyFocus {
        switch goal {
        case .hypertrophy:
            return .fullBody
        case .conditioning, .weightLoss:
            return .cardio
        case .endurance:
            return .core
        case .performance:
            return .surprise
        }
    }
    
    private func mapGoalToTag(_ goal: FitnessGoal) -> ProgramGoalTag {
        switch goal {
        case .weightLoss:
            return .aerobic
        case .conditioning:
            return .conditioning
        case .hypertrophy, .performance:
            return .strength
        case .endurance:
            return .endurance
        }
    }
    
    private func mapLevelToProgram(_ level: TrainingLevel) -> ProgramLevel {
        switch level {
        case .beginner:
            return .beginner
        case .intermediate:
            return .intermediate
        case .advanced:
            return .advanced
        }
    }
}

