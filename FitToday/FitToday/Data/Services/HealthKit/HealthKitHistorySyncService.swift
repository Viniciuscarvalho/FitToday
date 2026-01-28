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
    private let syncWorkoutUseCase: SyncWorkoutCompletionUseCase?
    private let calendar: Calendar
    private let logger: (String) -> Void

    init(
        healthKit: any HealthKitServicing,
        historyRepository: WorkoutHistoryRepository,
        syncWorkoutUseCase: SyncWorkoutCompletionUseCase? = nil,
        calendar: Calendar = Calendar(identifier: .iso8601),
        logger: @escaping (String) -> Void = { print("[HealthKitSync]", $0) }
    ) {
        self.healthKit = healthKit
        self.historyRepository = historyRepository
        self.syncWorkoutUseCase = syncWorkoutUseCase
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

                // Sync to challenges if workout meets 30min minimum
                if let syncUseCase = syncWorkoutUseCase, (updated.durationMinutes ?? 0) >= 30 {
                    await syncUseCase.execute(entry: updated)
                    logger("Synced HealthKit workout to challenges: \(updated.durationMinutes ?? 0) min")
                }
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

    // MARK: - Import External Workouts from Apple Health

    /// Importa workouts do Apple Health que foram feitos FORA do app FitToday.
    /// Cria entries no histórico e conta para desafios se duração >= 30 min.
    ///
    /// - Parameter days: Número de dias para buscar retroativamente (padrão: 7)
    /// - Returns: Número de workouts importados
    func importExternalWorkouts(days: Int = 7) async throws -> Int {
        let now = Date()
        let start = calendar.date(byAdding: .day, value: -max(1, days), to: now) ?? now
        let range = DateInterval(start: start, end: now)

        // 1. Buscar todos workouts do HealthKit no período
        let hkWorkouts = try await healthKit.fetchWorkouts(in: range)

        // 2. Buscar entries existentes para evitar duplicatas
        let existingEntries = try await historyRepository.listEntries()
        let existingUUIDs = Set(existingEntries.compactMap { $0.healthKitWorkoutUUID })

        // 3. Filtrar workouts que ainda não foram importados
        let newWorkouts = hkWorkouts.filter { !existingUUIDs.contains($0.workoutUUID) }

        logger("Encontrados \(newWorkouts.count) workouts novos do Apple Health para importar")

        var importedCount = 0

        for workout in newWorkouts {
            // Criar WorkoutHistoryEntry para o workout do Apple Health
            // Workouts externos não têm planId, title nem focus - usamos placeholders
            let entry = WorkoutHistoryEntry(
                id: UUID(),
                date: workout.endDate,
                planId: UUID(), // Placeholder - não há plano associado
                title: "Apple Health Workout",
                focus: .fullBody, // Default para workouts importados
                status: .completed,
                durationMinutes: workout.durationMinutes,
                caloriesBurned: workout.caloriesBurned,
                healthKitWorkoutUUID: workout.workoutUUID,
                source: .appleHealth
            )

            do {
                try await historyRepository.saveEntry(entry)
                importedCount += 1
                logger("✅ Importado workout de \(workout.durationMinutes) min do Apple Health")

                // Sync para desafios se >= 30 min
                if let syncUseCase = syncWorkoutUseCase, workout.durationMinutes >= 30 {
                    await syncUseCase.execute(entry: entry)
                    logger("🏆 Workout de \(workout.durationMinutes) min contabilizado para desafios")
                }
            } catch {
                logger("❌ Falha ao importar workout: \(error.localizedDescription)")
            }
        }

        logger("Importação concluída: \(importedCount) workouts importados")
        return importedCount
    }
}

