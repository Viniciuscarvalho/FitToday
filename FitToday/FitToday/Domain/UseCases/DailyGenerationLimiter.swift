//
//  DailyGenerationLimiter.swift
//  FitToday
//
//  Controla o limite de gerações de treino por dia (máximo 2).
//

import Foundation

/// Controla o limite de gerações de treino por dia.
/// Máximo: 2 gerações por dia (reset à meia-noite local).
struct DailyGenerationLimiter {
    private static let key = "dailyWorkoutGenerationCount"
    private let maxPerDay = 2
    private let userDefaults: UserDefaults
    private let dateProvider: () -> Date

    init(
        userDefaults: UserDefaults = .standard,
        dateProvider: @escaping () -> Date = { Date() }
    ) {
        self.userDefaults = userDefaults
        self.dateProvider = dateProvider
    }

    /// Verifica se o usuário pode gerar mais treinos hoje.
    func canGenerate() -> Bool {
        let counter = getCurrentCounter()
        return counter.count < maxPerDay
    }

    /// Incrementa o contador de gerações.
    func incrementCount() {
        var counter = getCurrentCounter()
        counter.count += 1
        saveCounter(counter)

        #if DEBUG
        print("[GenerationLimiter] Incremented to \(counter.count)/\(maxPerDay)")
        #endif
    }

    /// Retorna quantas gerações restam hoje.
    func remainingGenerations() -> Int {
        let counter = getCurrentCounter()
        return max(0, maxPerDay - counter.count)
    }

    /// Retorna o número de gerações já feitas hoje.
    func currentGenerationsCount() -> Int {
        getCurrentCounter().count
    }

    // MARK: - Private Helpers

    private func getCurrentCounter() -> GenerationCounter {
        let today = todayString()

        guard let data = userDefaults.data(forKey: Self.key),
              let counter = try? JSONDecoder().decode(GenerationCounter.self, from: data),
              counter.date == today else {
            // Novo dia ou sem dados - retorna contador zerado
            return GenerationCounter(date: today, count: 0)
        }

        return counter
    }

    private func saveCounter(_ counter: GenerationCounter) {
        if let data = try? JSONEncoder().encode(counter) {
            userDefaults.set(data, forKey: Self.key)
        }
    }

    private func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: dateProvider())
    }
}

// MARK: - Internal Types

private struct GenerationCounter: Codable {
    let date: String
    var count: Int
}
