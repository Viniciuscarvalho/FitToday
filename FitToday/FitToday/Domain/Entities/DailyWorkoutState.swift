//
//  DailyWorkoutState.swift
//  FitToday
//
//  Estado do treino diário: sugerido, visualizado, concluído, trocas permitidas.
//

import Foundation

/// Status do treino diário
public enum DailyWorkoutStatus: String, Codable, Sendable {
    case pending       // Ainda não foi gerado/sugerido
    case suggested     // Treino foi sugerido
    case viewed        // Usuário abriu/visualizou o treino
    case started       // Usuário iniciou o treino
    case completed     // Usuário concluiu o treino
    case skipped       // Usuário pulou o treino
}

/// Estado do treino diário (persiste por dia)
public struct DailyWorkoutState: Codable, Sendable {
    public let date: Date
    public var status: DailyWorkoutStatus
    public var swapsUsed: Int
    public var planId: UUID?
    
    public static let maxSwapsPerDay = 1
    
    public init(
        date: Date = Date(),
        status: DailyWorkoutStatus = .pending,
        swapsUsed: Int = 0,
        planId: UUID? = nil
    ) {
        self.date = date
        self.status = status
        self.swapsUsed = swapsUsed
        self.planId = planId
    }
    
    /// Verifica se ainda pode trocar a sugestão
    public var canSwap: Bool {
        swapsUsed < Self.maxSwapsPerDay && status == .suggested
    }
    
    /// Verifica se o treino foi concluído ou pulado
    public var isFinished: Bool {
        status == .completed || status == .skipped
    }
    
    /// Verifica se é o mesmo dia
    public func isSameDay(as otherDate: Date) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: otherDate)
    }
    
    /// Retorna estado atualizado após uma troca
    public func withSwap() -> DailyWorkoutState {
        var copy = self
        copy.swapsUsed += 1
        return copy
    }
    
    /// Retorna estado atualizado com novo status
    public func with(status: DailyWorkoutStatus) -> DailyWorkoutState {
        var copy = self
        copy.status = status
        return copy
    }
    
    /// Retorna estado atualizado com planId
    public func with(planId: UUID) -> DailyWorkoutState {
        var copy = self
        copy.planId = planId
        return copy
    }
}

// MARK: - Persistência via AppStorage

/// Manager para persistir o estado do treino diário
final class DailyWorkoutStateManager: @unchecked Sendable {
    
    static let shared = DailyWorkoutStateManager()
    
    private let key = "daily_workout_state_v1"
    private let defaults = UserDefaults.standard
    
    private init() {}
    
    /// Carrega o estado do dia atual (ou cria um novo se não existir/expirado)
    func loadTodayState() -> DailyWorkoutState {
        guard let data = defaults.data(forKey: key),
              let state = try? JSONDecoder().decode(DailyWorkoutState.self, from: data),
              state.isSameDay(as: Date()) else {
            // Estado expirado ou não existe - criar novo
            return DailyWorkoutState()
        }
        return state
    }
    
    /// Salva o estado atual
    func save(_ state: DailyWorkoutState) {
        if let data = try? JSONEncoder().encode(state) {
            defaults.set(data, forKey: key)
        }
    }
    
    /// Registra que uma sugestão foi feita
    func markSuggested(planId: UUID) {
        var state = loadTodayState()
        state = state.with(planId: planId).with(status: .suggested)
        save(state)
    }
    
    /// Registra que o usuário visualizou o treino
    func markViewed() {
        var state = loadTodayState()
        if state.status == .suggested {
            state = state.with(status: .viewed)
            save(state)
        }
    }
    
    /// Registra que o usuário iniciou o treino
    func markStarted() {
        var state = loadTodayState()
        if state.status == .suggested || state.status == .viewed {
            state = state.with(status: .started)
            save(state)
        }
    }
    
    /// Registra que o usuário concluiu o treino
    func markCompleted() {
        var state = loadTodayState()
        state = state.with(status: .completed)
        save(state)
    }
    
    /// Registra que o usuário pulou o treino
    func markSkipped() {
        var state = loadTodayState()
        state = state.with(status: .skipped)
        save(state)
    }
    
    /// Tenta fazer uma troca (retorna true se conseguiu)
    func trySwap() -> Bool {
        var state = loadTodayState()
        guard state.canSwap else { return false }
        state = state.withSwap().with(status: .pending)
        save(state)
        return true
    }
    
    /// Reseta o estado para um novo dia (chamado automaticamente se data mudou)
    func resetForNewDay() {
        save(DailyWorkoutState())
    }
}


