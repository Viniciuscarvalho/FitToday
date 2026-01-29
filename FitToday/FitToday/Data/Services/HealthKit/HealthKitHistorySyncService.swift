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
        // BUG FIX #1: 20% duration tolerance to avoid matching wrong workouts
        let durationTolerancePercent = 0.20

        let scored = sameDay.compactMap { w -> (ImportedSessionMetric, TimeInterval)? in
            let delta = abs(w.endDate.timeIntervalSince(entry.date))
            guard delta <= maxDelta else { return nil }

            // BUG FIX #1: Validate duration is within tolerance
            if let entryDuration = entry.durationMinutes {
                let hkDurationMinutes = w.durationMinutes
                let tolerance = Double(entryDuration) * durationTolerancePercent
                let durationDiff = abs(Double(hkDurationMinutes - entryDuration))
                guard durationDiff <= tolerance else {
                    logger("Duration mismatch: entry=\(entryDuration)min, HK=\(hkDurationMinutes)min, diff=\(durationDiff)min > tolerance=\(tolerance)min")
                    return nil
                }
            }

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
    /// Constant UUID used to identify all Apple Health imported workouts
    /// BUG FIX #5: Use constant instead of random UUID for imported workout planId
    private static let appleHealthImportPlanId = UUID(uuidString: "00000000-0000-0000-0000-APPLEHEALTH")
        ?? UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    func importExternalWorkouts(days: Int = 7) async throws -> Int {
        let now = Date()
        let start = calendar.date(byAdding: .day, value: -max(1, days), to: now) ?? now
        let range = DateInterval(start: start, end: now)

        // 1. Buscar todos workouts do HealthKit no período
        let hkWorkouts = try await healthKit.fetchWorkouts(in: range)

        // 2. Buscar entries existentes para evitar duplicatas
        let existingEntries = try await historyRepository.listEntries()
        let existingUUIDs = Set(existingEntries.compactMap { $0.healthKitWorkoutUUID })

        // 3. Filtrar workouts que ainda não foram importados por UUID
        var newWorkouts = hkWorkouts.filter { !existingUUIDs.contains($0.workoutUUID) }

        // BUG FIX #4: Additional deduplication by date+duration
        // Prevents importing duplicate workouts that might have different UUIDs
        newWorkouts = newWorkouts.filter { workout in
            !isDuplicateByDateAndDuration(workout, existingEntries: existingEntries)
        }

        logger("Encontrados \(newWorkouts.count) workouts novos do Apple Health para importar")

        var importedCount = 0

        for workout in newWorkouts {
            // Criar WorkoutHistoryEntry para o workout do Apple Health
            // Workouts externos não têm planId, title nem focus - usamos placeholders
            // BUG FIX #5: Use constant planId for all Apple Health imports
            let entry = WorkoutHistoryEntry(
                id: UUID(),
                date: workout.endDate,
                planId: Self.appleHealthImportPlanId,
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

    // MARK: - BUG FIX #4: Duplicate Detection by Date and Duration

    /// Checks if a HealthKit workout is a duplicate of an existing entry based on date and duration.
    /// This prevents importing the same workout that might have a different UUID.
    /// - Parameters:
    ///   - workout: The HealthKit workout to check
    ///   - existingEntries: Existing history entries to compare against
    /// - Returns: True if a duplicate is found
    private func isDuplicateByDateAndDuration(
        _ workout: ImportedSessionMetric,
        existingEntries: [WorkoutHistoryEntry]
    ) -> Bool {
        let workoutDate = calendar.startOfDay(for: workout.endDate)
        let workoutDuration = workout.durationMinutes

        return existingEntries.contains { entry in
            let entryDate = calendar.startOfDay(for: entry.date)
            guard entryDate == workoutDate else { return false }

            // Check if duration matches within 5 minutes tolerance
            if let entryDuration = entry.durationMinutes {
                let durationDiff = abs(entryDuration - workoutDuration)
                return durationDiff <= 5
            }
            return false
        }
    }

    // MARK: - BUG FIX #6: Stale UUID Cleanup

    /// Removes stale HealthKit UUIDs from entries where the UUID no longer exists in HealthKit.
    /// This allows the entry to be re-matched with a valid HealthKit workout.
    /// - Parameter days: Number of days to check (default: 30)
    /// - Returns: Number of entries cleaned
    func cleanupStaleUUIDs(days: Int = 30) async throws -> Int {
        let now = Date()
        let start = calendar.date(byAdding: .day, value: -max(1, days), to: now) ?? now
        let range = DateInterval(start: start, end: now)

        // Get current HealthKit workouts
        let hkWorkouts = try await healthKit.fetchWorkouts(in: range)
        let validUUIDs = Set(hkWorkouts.map { $0.workoutUUID })

        // Get entries with HealthKit UUIDs
        let entries = try await historyRepository.listEntries()
        let entriesWithUUID = entries.filter {
            $0.healthKitWorkoutUUID != nil &&
            $0.date >= start && $0.date <= now
        }

        var cleanedCount = 0

        for entry in entriesWithUUID {
            guard let uuid = entry.healthKitWorkoutUUID else { continue }

            // If UUID no longer exists in HealthKit, clear it
            if !validUUIDs.contains(uuid) {
                var updated = entry
                updated.healthKitWorkoutUUID = nil
                do {
                    try await historyRepository.saveEntry(updated)
                    cleanedCount += 1
                    logger("🧹 Cleaned stale UUID for entry \(entry.id)")
                } catch {
                    logger("❌ Failed to clean stale UUID: \(error.localizedDescription)")
                }
            }
        }

        if cleanedCount > 0 {
            logger("Cleanup complete: \(cleanedCount) stale UUIDs removed")
        }
        return cleanedCount
    }
}

