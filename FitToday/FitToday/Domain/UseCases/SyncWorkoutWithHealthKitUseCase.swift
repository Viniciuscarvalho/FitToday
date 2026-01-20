//
//  SyncWorkoutWithHealthKitUseCase.swift
//  FitToday
//
//  Created by Claude on 20/01/26.
//

import Foundation

/// Result of HealthKit sync operation
struct HealthKitSyncResult: Sendable {
    let workoutUUID: UUID?
    let caloriesBurned: Int?
    let syncedAt: Date
    let status: SyncStatus

    enum SyncStatus: Sendable {
        case success
        case partialSuccess(reason: String)
        case skipped(reason: String)
        case failed(reason: String)
    }

    var succeeded: Bool {
        switch status {
        case .success, .partialSuccess:
            return true
        case .skipped, .failed:
            return false
        }
    }
}

/// Use case for syncing completed workouts with Apple HealthKit.
/// Handles export, calorie import with delay, and history entry update.
struct SyncWorkoutWithHealthKitUseCase: Sendable {
    private let healthKitService: HealthKitServicing
    private let historyRepository: WorkoutHistoryRepository
    private let calorieImportDelay: Duration
    private let maxRetries: Int

    init(
        healthKitService: HealthKitServicing,
        historyRepository: WorkoutHistoryRepository,
        calorieImportDelay: Duration = .seconds(5),
        maxRetries: Int = 2
    ) {
        self.healthKitService = healthKitService
        self.historyRepository = historyRepository
        self.calorieImportDelay = calorieImportDelay
        self.maxRetries = maxRetries
    }

    /// Syncs a completed workout with HealthKit.
    /// - Parameters:
    ///   - entry: The workout history entry to sync
    ///   - plan: The workout plan (needed for export metadata)
    ///   - completedAt: When the workout was completed
    /// - Returns: Result of the sync operation
    @discardableResult
    func execute(
        entry: WorkoutHistoryEntry,
        plan: WorkoutPlan,
        completedAt: Date
    ) async -> HealthKitSyncResult {
        // 1. Check authorization
        let authState = await healthKitService.authorizationState()

        guard authState == .authorized else {
            let reason: String
            switch authState {
            case .notAvailable:
                reason = "HealthKit não disponível neste dispositivo"
            case .denied:
                reason = "Permissão do HealthKit negada"
            case .notDetermined:
                reason = "Permissão do HealthKit não solicitada"
            case .authorized:
                reason = "Erro inesperado"
            }

            #if DEBUG
            print("[HealthKitSync] Skipped: \(reason)")
            #endif

            return HealthKitSyncResult(
                workoutUUID: nil,
                caloriesBurned: nil,
                syncedAt: Date(),
                status: .skipped(reason: reason)
            )
        }

        // 2. Export workout to HealthKit
        let receipt: ExportedWorkoutReceipt
        do {
            receipt = try await healthKitService.exportWorkout(plan: plan, completedAt: completedAt)
            #if DEBUG
            print("[HealthKitSync] Exported workout: \(receipt.workoutUUID)")
            #endif
        } catch {
            #if DEBUG
            print("[HealthKitSync] Export failed: \(error.localizedDescription)")
            #endif

            return HealthKitSyncResult(
                workoutUUID: nil,
                caloriesBurned: nil,
                syncedAt: Date(),
                status: .failed(reason: "Falha ao exportar treino: \(error.localizedDescription)")
            )
        }

        // 3. Update entry with HealthKit UUID
        var updatedEntry = entry
        updatedEntry.healthKitWorkoutUUID = receipt.workoutUUID

        // 4. Wait for Apple Watch data to sync
        #if DEBUG
        print("[HealthKitSync] Waiting \(calorieImportDelay) for calorie sync...")
        #endif

        do {
            try await Task.sleep(for: calorieImportDelay)
        } catch {
            // Cancelled, but still update with UUID
            await updateHistoryEntry(updatedEntry)
            return HealthKitSyncResult(
                workoutUUID: receipt.workoutUUID,
                caloriesBurned: nil,
                syncedAt: Date(),
                status: .partialSuccess(reason: "Sincronização de calorias cancelada")
            )
        }

        // 5. Fetch calories with retry
        var calories: Int?
        for attempt in 1...maxRetries {
            do {
                calories = try await healthKitService.fetchCaloriesForWorkout(
                    workoutUUID: receipt.workoutUUID,
                    around: completedAt
                )

                if calories != nil {
                    #if DEBUG
                    print("[HealthKitSync] Fetched calories: \(calories!) (attempt \(attempt))")
                    #endif
                    break
                }

                // Wait before retry
                if attempt < maxRetries {
                    try await Task.sleep(for: .seconds(2))
                }
            } catch {
                #if DEBUG
                print("[HealthKitSync] Calorie fetch failed (attempt \(attempt)): \(error.localizedDescription)")
                #endif
            }
        }

        // 6. Update entry with calories if available
        if let calories {
            updatedEntry.caloriesBurned = calories
        }

        // 7. Save updated entry to repository
        await updateHistoryEntry(updatedEntry)

        // 8. Return result
        let status: HealthKitSyncResult.SyncStatus
        if calories != nil {
            status = .success
        } else {
            status = .partialSuccess(reason: "Calorias não disponíveis (Apple Watch pode não estar conectado)")
        }

        return HealthKitSyncResult(
            workoutUUID: receipt.workoutUUID,
            caloriesBurned: calories,
            syncedAt: Date(),
            status: status
        )
    }

    private func updateHistoryEntry(_ entry: WorkoutHistoryEntry) async {
        do {
            try await historyRepository.saveEntry(entry)
            #if DEBUG
            print("[HealthKitSync] Updated history entry with HealthKit data")
            #endif
        } catch {
            #if DEBUG
            print("[HealthKitSync] Failed to update history entry: \(error.localizedDescription)")
            #endif
        }
    }
}
