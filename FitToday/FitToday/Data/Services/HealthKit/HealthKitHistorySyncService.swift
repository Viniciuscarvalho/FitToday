//
//  HealthKitHistorySyncService.swift
//  FitToday
//
//  Created by AI on 12/01/26.
//

import Foundation

actor HealthKitHistorySyncService {
    private let healthKit: any HealthKitServicing
    private let historyRepository: WorkoutHistoryRepository
    private let calendar: Calendar
    private let logger: (String) -> Void
    
    init(
        healthKit: any HealthKitServicing,
        historyRepository: WorkoutHistoryRepository,
        calendar: Calendar = Calendar(identifier: .iso8601),
        logger: @escaping (String) -> Void = { print("[HealthKitSync]", $0) }
    ) {
        self.healthKit = healthKit
        self.historyRepository = historyRepository
        self.calendar = calendar
        self.logger = logger
    }
    
    func syncLastDays(_ days: Int = 30) async throws -> Int {
        let now = Date()
        let start = calendar.date(byAdding: .day, value: -max(1, days), to: now) ?? now
        let range = DateInterval(start: start, end: now)
        
        let hkWorkouts = try await healthKit.fetchWorkouts(in: range)
        let history = try await historyRepository.listEntries()
        
        let candidates = history
            .filter { $0.status == .completed }
            .filter { $0.date >= start && $0.date <= now }
        
        var updatedCount = 0
        
        for entry in candidates {
            // já sincronizado
            if entry.healthKitWorkoutUUID != nil { continue }
            
            guard let match = bestMatch(for: entry, in: hkWorkouts) else { continue }
            
            var updated = entry
            updated.durationMinutes = match.durationMinutes
            updated.caloriesBurned = match.caloriesBurned
            updated.healthKitWorkoutUUID = match.workoutUUID
            
            do {
                try await historyRepository.saveEntry(updated)
                updatedCount += 1
            } catch {
                logger("Falha ao salvar histórico para entry=\(entry.id): \(error.localizedDescription)")
            }
        }
        
        logger("Sync concluído: \(updatedCount) entradas atualizadas")
        return updatedCount
    }
    
    private func bestMatch(for entry: WorkoutHistoryEntry, in workouts: [ImportedSessionMetric]) -> ImportedSessionMetric? {
        // Critério: mesmo dia + menor distância temporal até o momento da entry
        let entryDay = calendar.startOfDay(for: entry.date)
        
        let sameDay = workouts.filter { calendar.startOfDay(for: $0.endDate) == entryDay || calendar.startOfDay(for: $0.startDate) == entryDay }
        guard !sameDay.isEmpty else { return nil }
        
        // Janela de tolerância: 3 horas em relação ao endDate do workout
        let maxDelta: TimeInterval = 3 * 3600
        
        let scored = sameDay.compactMap { w -> (ImportedSessionMetric, TimeInterval)? in
            let delta = abs(w.endDate.timeIntervalSince(entry.date))
            guard delta <= maxDelta else { return nil }
            return (w, delta)
        }
        
        return scored.sorted { $0.1 < $1.1 }.first?.0
    }
}

