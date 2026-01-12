//
//  HealthKitService.swift
//  FitToday
//
//  Created by AI on 12/01/26.
//

import Foundation
import HealthKit

enum HealthKitAuthorizationState: Sendable, Equatable {
    case notAvailable
    case notDetermined
    case denied
    case authorized
}

struct ImportedSessionMetric: Sendable, Hashable {
    let workoutUUID: UUID
    let startDate: Date
    let endDate: Date
    let durationMinutes: Int
    let caloriesBurned: Int?
}

struct ExportedWorkoutReceipt: Sendable, Hashable {
    let workoutUUID: UUID
    let exportedAt: Date
}

protocol HealthKitServicing: Sendable {
    func authorizationState() async -> HealthKitAuthorizationState
    func requestAuthorization() async throws
    func fetchWorkouts(in range: DateInterval) async throws -> [ImportedSessionMetric]
    func exportWorkout(plan: WorkoutPlan, completedAt: Date) async throws -> ExportedWorkoutReceipt
}

actor HealthKitService: HealthKitServicing {
    private let healthStore = HKHealthStore()
    
    func authorizationState() async -> HealthKitAuthorizationState {
        guard HKHealthStore.isHealthDataAvailable() else { return .notAvailable }
        
        // Heurística: verificar autorização para workouts
        let status = healthStore.authorizationStatus(for: HKObjectType.workoutType())
        switch status {
        case .notDetermined:
            return .notDetermined
        case .sharingDenied:
            return .denied
        case .sharingAuthorized:
            return .authorized
        @unknown default:
            return .notDetermined
        }
    }
    
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let workoutType = HKObjectType.workoutType()
        let energy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)
        
        var readTypes: Set<HKObjectType> = [workoutType]
        var shareTypes: Set<HKSampleType> = [workoutType]
        if let energy {
            readTypes.insert(energy)
            shareTypes.insert(energy)
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.requestAuthorization(toShare: shareTypes, read: readTypes) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                if success {
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(throwing: NSError(domain: "HealthKit", code: 1, userInfo: [
                        NSLocalizedDescriptionKey: "Permissão do HealthKit não concedida."
                    ]))
                }
            }
        }
    }
    
    func fetchWorkouts(in range: DateInterval) async throws -> [ImportedSessionMetric] {
        guard HKHealthStore.isHealthDataAvailable() else { return [] }
        
        let type = HKObjectType.workoutType()
        let predicate = HKQuery.predicateForSamples(withStart: range.start, end: range.end, options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let workouts = (samples as? [HKWorkout]) ?? []
                let mapped: [ImportedSessionMetric] = workouts.map { workout in
                    let minutes = Int((workout.duration / 60.0).rounded())
                    let calories: Int?
                    if let total = workout.totalEnergyBurned {
                        calories = Int(total.doubleValue(for: .kilocalorie()).rounded())
                    } else {
                        calories = nil
                    }
                    return ImportedSessionMetric(
                        workoutUUID: workout.uuid,
                        startDate: workout.startDate,
                        endDate: workout.endDate,
                        durationMinutes: max(0, minutes),
                        caloriesBurned: calories
                    )
                }
                
                continuation.resume(returning: mapped)
            }
            self.healthStore.execute(query)
        }
    }
    
    func exportWorkout(plan: WorkoutPlan, completedAt: Date) async throws -> ExportedWorkoutReceipt {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw NSError(domain: "HealthKit", code: 2, userInfo: [NSLocalizedDescriptionKey: "HealthKit não disponível."])
        }
        
        let end = completedAt
        let start = end.addingTimeInterval(TimeInterval(-max(1, plan.estimatedDurationMinutes) * 60))
        
        let activityType = mapActivityType(from: plan.focus)
        let workout = HKWorkout(
            activityType: activityType,
            start: start,
            end: end,
            workoutEvents: nil,
            totalEnergyBurned: nil,
            totalDistance: nil,
            metadata: [
                HKMetadataKeyWorkoutBrandName: "FitToday"
                // Note: HKMetadataKeyWorkoutRoutineName não existe no HealthKit moderno
                // O título do treino é capturado como parte do HKWorkout.uuid
            ]
        )
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.healthStore.save(workout) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard success else {
                    continuation.resume(throwing: NSError(domain: "HealthKit", code: 3, userInfo: [
                        NSLocalizedDescriptionKey: "Falha ao exportar treino para o HealthKit."
                    ]))
                    return
                }
                continuation.resume(returning: ())
            }
        }
        
        return ExportedWorkoutReceipt(workoutUUID: workout.uuid, exportedAt: Date())
    }
    
    private func mapActivityType(from focus: DailyFocus) -> HKWorkoutActivityType {
        switch focus {
        case .cardio:
            return .mixedCardio
        case .core:
            return .coreTraining
        case .upper, .lower, .fullBody, .surprise:
            return .traditionalStrengthTraining
        }
    }
}

