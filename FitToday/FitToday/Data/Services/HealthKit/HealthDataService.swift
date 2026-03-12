//
//  HealthDataService.swift
//  FitToday
//
//  Foundation service for reading health metrics (body mass, etc.) from HealthKit.
//  PRO-72: HealthDataService Foundation
//

import Foundation
import HealthKit

// MARK: - Weight Entry

struct WeightEntry: Identifiable, Sendable, Hashable {
    let id: UUID
    let date: Date
    let weightKg: Double

    var weightFormatted: String {
        String(format: "%.1f kg", weightKg)
    }
}

// MARK: - Protocol

protocol HealthDataServicing: Sendable {
    func requestBodyMassAuthorization() async throws
    func fetchWeightEntries(days: Int) async throws -> [WeightEntry]
    func isBodyMassAvailable() -> Bool
}

// MARK: - Implementation

actor HealthDataService: HealthDataServicing {
    private let healthStore = HKHealthStore()

    func isBodyMassAvailable() -> Bool {
        HKHealthStore.isHealthDataAvailable()
            && HKObjectType.quantityType(forIdentifier: .bodyMass) != nil
    }

    func requestBodyMassAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        guard let bodyMassType = HKObjectType.quantityType(forIdentifier: .bodyMass) else { return }

        try await healthStore.requestAuthorization(toShare: [], read: [bodyMassType])
    }

    func fetchWeightEntries(days: Int) async throws -> [WeightEntry] {
        guard HKHealthStore.isHealthDataAvailable() else { return [] }
        guard let bodyMassType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return [] }

        let calendar = Calendar.current
        let end = Date()
        guard let start = calendar.date(byAdding: .day, value: -days, to: end) else { return [] }

        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: end,
            options: .strictStartDate
        )
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: bodyMassType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let entries = (samples as? [HKQuantitySample] ?? []).map { sample in
                    WeightEntry(
                        id: sample.uuid,
                        date: sample.startDate,
                        weightKg: sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                    )
                }
                continuation.resume(returning: entries)
            }
            healthStore.execute(query)
        }
    }
}
