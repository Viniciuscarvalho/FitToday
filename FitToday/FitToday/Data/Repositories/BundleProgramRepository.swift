//
//  BundleProgramRepository.swift
//  FitToday
//
//  Repositório de Programas que carrega dados do bundle (seed JSON).
//

import Foundation

/// Error types for BundleProgramRepository
enum BundleProgramRepositoryError: LocalizedError {
    case fileNotFound
    case decodingFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "ProgramsSeed.json not found in bundle. Ensure file is added to Copy Bundle Resources."
        case .decodingFailed(let error):
            return "Failed to decode programs: \(error.localizedDescription)"
        }
    }
}

/// Implementação do repositório de programas usando seed no bundle.
/// Converted to actor for proper Swift 6 concurrency without NSLock.
actor BundleProgramRepository: ProgramRepository {

    private var cachedPrograms: [Program]?

    func listPrograms() async throws -> [Program] {
        if let cached = cachedPrograms {
            return cached
        }

        let programs = try loadFromBundle()
        cachedPrograms = programs
        return programs
    }

    func getProgram(id: String) async throws -> Program? {
        #if DEBUG
        print("[BundleProgramRepository] 🔍 getProgram(id: '\(id)')")
        #endif

        let programs = try await listPrograms()

        #if DEBUG
        print("[BundleProgramRepository] 📋 Total programs loaded: \(programs.count)")
        #endif

        let found = programs.first { $0.id == id }

        #if DEBUG
        if let found {
            print("[BundleProgramRepository] ✅ Found: '\(found.name)'")
        } else {
            print("[BundleProgramRepository] ❌ NOT FOUND - searching for '\(id)'")
            print("[BundleProgramRepository] 📋 Available IDs: \(programs.map { $0.id })")
        }
        #endif

        return found
    }

    // MARK: - Private

    private func loadFromBundle() throws -> [Program] {
        #if DEBUG
        print("[BundleProgramRepository] 📂 Loading from bundle...")
        print("[BundleProgramRepository] 📂 Bundle path: \(Bundle.main.bundlePath)")
        #endif

        guard let url = Bundle.main.url(forResource: "ProgramsSeed", withExtension: "json") else {
            #if DEBUG
            print("[BundleProgramRepository] ❌ ProgramsSeed.json NOT FOUND in bundle")
            print("[BundleProgramRepository] 💡 Check if file is added to target in Xcode > Build Phases > Copy Bundle Resources")
            // List all JSON files in bundle for debugging
            if let resourcePath = Bundle.main.resourcePath {
                let fileManager = FileManager.default
                if let files = try? fileManager.contentsOfDirectory(atPath: resourcePath) {
                    let jsonFiles = files.filter { $0.hasSuffix(".json") }
                    print("[BundleProgramRepository] 📂 JSON files in bundle: \(jsonFiles)")
                }
            }
            #endif
            throw BundleProgramRepositoryError.fileNotFound
        }

        #if DEBUG
        print("[BundleProgramRepository] ✅ Found ProgramsSeed.json at: \(url.path)")
        #endif

        let data = try Data(contentsOf: url)

        #if DEBUG
        print("[BundleProgramRepository] 📊 Loaded \(data.count) bytes")
        #endif

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            let dtos = try decoder.decode([ProgramDTO].self, from: data)
            #if DEBUG
            print("[BundleProgramRepository] ✅ Decoded \(dtos.count) programs")
            for dto in dtos.prefix(3) {
                print("[BundleProgramRepository]   - id: '\(dto.id)' name: '\(dto.name)'")
            }
            #endif
            return dtos.map { $0.toDomain() }
        } catch {
            #if DEBUG
            print("[BundleProgramRepository] ❌ Decode error: \(error)")
            #endif
            throw BundleProgramRepositoryError.decodingFailed(underlying: error)
        }
    }
}

// MARK: - DTO para parsing do JSON

private struct ProgramDTO: Decodable {
    let id: String
    let name: String
    let subtitle: String
    let goalTag: String
    let level: String
    let equipment: String?
    let durationWeeks: Int
    let heroImageName: String
    let workoutTemplateIds: [String]
    let estimatedMinutesPerSession: Int
    let sessionsPerWeek: Int

    func toDomain() -> Program {
        // Infer equipment from ID if not explicitly provided
        let inferredEquipment = inferEquipmentFromId(id)

        return Program(
            id: id,
            name: name,
            subtitle: subtitle,
            goalTag: ProgramGoalTag(rawValue: goalTag) ?? .conditioning,
            level: ProgramLevel(rawValue: level) ?? .intermediate,
            equipment: ProgramEquipment(rawValue: equipment ?? "") ?? inferredEquipment,
            durationWeeks: durationWeeks,
            heroImageName: heroImageName,
            workoutTemplateIds: workoutTemplateIds,
            estimatedMinutesPerSession: estimatedMinutesPerSession,
            sessionsPerWeek: sessionsPerWeek
        )
    }

    /// Infers equipment from program ID naming convention.
    private func inferEquipmentFromId(_ id: String) -> ProgramEquipment {
        let lowerId = id.lowercased()
        if lowerId.contains("bodyweight") || lowerId.contains("calistenia") {
            return .bodyweight
        } else if lowerId.contains("dumbbell") || lowerId.contains("halteres") {
            return .dumbbell
        } else if lowerId.contains("home") || lowerId.contains("casa") {
            return .home
        } else if lowerId.contains("kettlebell") {
            return .kettlebell
        } else if lowerId.contains("bands") || lowerId.contains("elastico") {
            return .bands
        } else {
            return .gym
        }
    }
}


