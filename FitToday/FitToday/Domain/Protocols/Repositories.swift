//
//  Repositories.swift
//  FitToday
//
//  Created by AI on 03/01/26.
//

import Foundation

protocol UserProfileRepository: Sendable {
    func loadProfile() async throws -> UserProfile?
    func saveProfile(_ profile: UserProfile) async throws
}

protocol WorkoutBlocksRepository: Sendable {
    func loadBlocks() async throws -> [WorkoutBlock]
}

protocol WorkoutHistoryRepository: Sendable {
    func listEntries() async throws -> [WorkoutHistoryEntry]
    func saveEntry(_ entry: WorkoutHistoryEntry) async throws
}

protocol EntitlementRepository: Sendable {
    func currentEntitlement() async throws -> ProEntitlement
    func entitlementStream() -> AsyncStream<ProEntitlement>
}

protocol LibraryWorkoutsRepository: Sendable {
    func loadWorkouts() async throws -> [LibraryWorkout]
}

protocol ProgramRepository: Sendable {
    func listPrograms() async throws -> [Program]
    func getProgram(id: String) async throws -> Program?
}

