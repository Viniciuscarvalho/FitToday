//
//  SwiftDataWorkoutCompositionCacheRepository.swift
//  FitToday
//
//  Created by AI on 09/01/26.
//

import Foundation
import SwiftData

/// SwiftData implementation of WorkoutCompositionCacheRepository (F7)
/// Provides 24h TTL caching for workout compositions
@MainActor
final class SwiftDataWorkoutCompositionCacheRepository: WorkoutCompositionCacheRepository, @unchecked Sendable {
    
    private let modelContainer: ModelContainer
    
    /// Toggle to disable cache (DEBUG only)
    static var isCacheDisabled: Bool = false
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
    
    private func context() -> ModelContext {
        ModelContext(modelContainer)
    }
    
    // MARK: - WorkoutCompositionCacheRepository
    
    func getCachedWorkout(for inputsHash: String) async throws -> CachedWorkoutEntry? {
        #if DEBUG
        if Self.isCacheDisabled {
            print("[CompositionCache] 🚫 Cache DISABLED (toggle)")
            return nil
        }
        #endif
        
        let ctx = context()
        let hashToFind = inputsHash
        var descriptor = FetchDescriptor<SDCachedWorkout>(
            predicate: #Predicate<SDCachedWorkout> { workout in
                workout.inputsHash == hashToFind
            }
        )
        descriptor.fetchLimit = 1
        
        guard let cached = try ctx.fetch(descriptor).first else {
            #if DEBUG
            print("[CompositionCache] ❌ MISS for hash: \(inputsHash.prefix(16))...")
            #endif
            return nil
        }
        
        // Verificar expiração
        if cached.isExpired {
            #if DEBUG
            print("[CompositionCache] ⏰ EXPIRED for hash: \(inputsHash.prefix(16))... (expired \(Int(-cached.timeToLive))s ago)")
            #endif
            // Cleanup silencioso do item expirado
            ctx.delete(cached)
            try? ctx.save()
            return nil
        }
        
        // Decodificar WorkoutPlan
        guard let workoutPlan = try? JSONDecoder().decode(WorkoutPlan.self, from: cached.workoutPlanJSON) else {
            #if DEBUG
            print("[CompositionCache] ⚠️ Failed to decode cached workout for hash: \(inputsHash.prefix(16))...")
            #endif
            ctx.delete(cached)
            try? ctx.save()
            return nil
        }
        
        let entry = CachedWorkoutEntry(
            inputsHash: cached.inputsHash,
            workoutPlan: workoutPlan,
            createdAt: cached.createdAt,
            expiresAt: cached.expiresAt,
            goal: FitnessGoal(rawValue: cached.goalRaw) ?? .hypertrophy,
            structure: TrainingStructure(rawValue: cached.structureRaw) ?? .fullGym,
            focus: DailyFocus(rawValue: cached.focusRaw) ?? .fullBody,
            blueprintVersion: cached.blueprintVersion,
            variationSeed: cached.variationSeed
        )
        
        #if DEBUG
        print("[CompositionCache] ✅ HIT for hash: \(inputsHash.prefix(16))... (TTL: \(Int(cached.timeToLive))s remaining)")
        #endif
        
        return entry
    }
    
    func saveCachedWorkout(_ entry: CachedWorkoutEntry) async throws {
        #if DEBUG
        if Self.isCacheDisabled {
            print("[CompositionCache] 🚫 Cache DISABLED - skipping save")
            return
        }
        #endif
        
        guard let workoutPlanJSON = try? JSONEncoder().encode(entry.workoutPlan) else {
            #if DEBUG
            print("[CompositionCache] ⚠️ Failed to encode workout plan")
            #endif
            return
        }
        
        let ctx = context()
        
        // Verificar se já existe (update)
        let hashToFind = entry.inputsHash
        var descriptor = FetchDescriptor<SDCachedWorkout>(
            predicate: #Predicate<SDCachedWorkout> { workout in
                workout.inputsHash == hashToFind
            }
        )
        descriptor.fetchLimit = 1
        
        if let existing = try ctx.fetch(descriptor).first {
            // Update existing
            existing.workoutPlanJSON = workoutPlanJSON
            existing.createdAt = entry.createdAt
            existing.expiresAt = entry.expiresAt
            existing.goalRaw = entry.goal.rawValue
            existing.structureRaw = entry.structure.rawValue
            existing.focusRaw = entry.focus.rawValue
            existing.blueprintVersion = entry.blueprintVersion
            existing.variationSeed = entry.variationSeed
            
            #if DEBUG
            print("[CompositionCache] 🔄 UPDATE for hash: \(entry.inputsHash.prefix(16))... (TTL: 24h)")
            #endif
        } else {
            // Insert new
            let model = SDCachedWorkout(
                inputsHash: entry.inputsHash,
                workoutPlanJSON: workoutPlanJSON,
                createdAt: entry.createdAt,
                expiresAt: entry.expiresAt,
                goalRaw: entry.goal.rawValue,
                structureRaw: entry.structure.rawValue,
                focusRaw: entry.focus.rawValue,
                blueprintVersion: entry.blueprintVersion,
                variationSeed: entry.variationSeed
            )
            ctx.insert(model)
            
            #if DEBUG
            print("[CompositionCache] 💾 SAVE for hash: \(entry.inputsHash.prefix(16))... (TTL: 24h)")
            #endif
        }
        
        try ctx.save()
    }
    
    func cleanupExpired() async throws -> Int {
        let ctx = context()
        let now = Date()
        
        let descriptor = FetchDescriptor<SDCachedWorkout>(
            predicate: #Predicate<SDCachedWorkout> { workout in
                workout.expiresAt < now
            }
        )
        
        let expired = try ctx.fetch(descriptor)
        let count = expired.count
        
        for item in expired {
            ctx.delete(item)
        }
        
        if count > 0 {
            try ctx.save()
            #if DEBUG
            print("[CompositionCache] 🧹 CLEANUP: removed \(count) expired entries")
            #endif
        }
        
        return count
    }
    
    func clearAll() async throws {
        let ctx = context()
        let descriptor = FetchDescriptor<SDCachedWorkout>()
        let all = try ctx.fetch(descriptor)
        let count = all.count
        
        for item in all {
            ctx.delete(item)
        }
        
        try ctx.save()
        
        #if DEBUG
        print("[CompositionCache] 🗑️ CLEAR ALL: removed \(count) entries")
        #endif
    }
    
    func getStats() async throws -> (total: Int, expired: Int, validCount: Int) {
        let ctx = context()
        let now = Date()
        
        let totalDescriptor = FetchDescriptor<SDCachedWorkout>()
        let total = try ctx.fetchCount(totalDescriptor)
        
        let expiredDescriptor = FetchDescriptor<SDCachedWorkout>(
            predicate: #Predicate<SDCachedWorkout> { workout in
                workout.expiresAt < now
            }
        )
        let expired = try ctx.fetchCount(expiredDescriptor)
        
        let valid = total - expired
        
        #if DEBUG
        print("[CompositionCache] 📊 STATS: total=\(total), expired=\(expired), valid=\(valid)")
        #endif
        
        return (total, expired, valid)
    }
}
