//
//  BundleProgramRepository.swift
//  FitToday
//
//  Repositório de Programas que carrega dados do bundle (seed JSON).
//

import Foundation

/// Implementação do repositório de programas usando seed no bundle.
final class BundleProgramRepository: ProgramRepository, @unchecked Sendable {
    
    private var cachedPrograms: [Program]?
    private let lock = NSLock()
    
    func listPrograms() async throws -> [Program] {
        lock.lock()
        defer { lock.unlock() }
        
        if let cached = cachedPrograms {
            return cached
        }
        
        let programs = try loadFromBundle()
        cachedPrograms = programs
        return programs
    }
    
    func getProgram(id: String) async throws -> Program? {
        let programs = try await listPrograms()
        return programs.first { $0.id == id }
    }
    
    // MARK: - Private
    
    private func loadFromBundle() throws -> [Program] {
        guard let url = Bundle.main.url(forResource: "ProgramsSeed", withExtension: "json") else {
            #if DEBUG
            print("[ProgramRepository] ⚠️ ProgramsSeed.json não encontrado no bundle")
            #endif
            return []
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let dtos = try decoder.decode([ProgramDTO].self, from: data)
        return dtos.map { $0.toDomain() }
    }
}

// MARK: - DTO para parsing do JSON

private struct ProgramDTO: Decodable {
    let id: String
    let name: String
    let subtitle: String
    let goalTag: String
    let level: String
    let durationWeeks: Int
    let heroImageName: String
    let workoutTemplateIds: [String]
    let estimatedMinutesPerSession: Int
    let sessionsPerWeek: Int
    
    func toDomain() -> Program {
        Program(
            id: id,
            name: name,
            subtitle: subtitle,
            goalTag: ProgramGoalTag(rawValue: goalTag) ?? .conditioning,
            level: ProgramLevel(rawValue: level) ?? .intermediate,
            durationWeeks: durationWeeks,
            heroImageName: heroImageName,
            workoutTemplateIds: workoutTemplateIds,
            estimatedMinutesPerSession: estimatedMinutesPerSession,
            sessionsPerWeek: sessionsPerWeek
        )
    }
}


