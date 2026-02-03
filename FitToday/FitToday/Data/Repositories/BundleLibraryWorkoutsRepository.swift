//
//  BundleLibraryWorkoutsRepository.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//  Simplified on 29/01/26 - Uses Wger API for exercise data
//

import Foundation

/// Repository for loading library workouts from bundle.
/// Note: Media is loaded directly from JSON, no external resolution.
actor BundleLibraryWorkoutsRepository: LibraryWorkoutsRepository {
    private let loader: LibraryWorkoutsLoader
    private var cachedWorkouts: [LibraryWorkout]?

    init(loader: LibraryWorkoutsLoader = LibraryWorkoutsLoader()) {
        self.loader = loader
    }

    func loadWorkouts() async throws -> [LibraryWorkout] {
        if let cached = cachedWorkouts {
            #if DEBUG
            print("[LibraryWorkoutsRepository] Returning \(cached.count) cached workouts")
            #endif
            return cached
        }

        let dtos = try loader.loadDTOs()
        #if DEBUG
        print("[LibraryWorkoutsRepository] Loaded \(dtos.count) DTOs from JSON")
        #endif

        var workouts: [LibraryWorkout] = []
        for dto in dtos {
            if let workout = dto.toDomain(normalizer: normalizeExerciseId(_:)) {
                workouts.append(workout)
            } else {
                #if DEBUG
                print("[LibraryWorkoutsRepository] Failed to convert DTO: \(dto.id)")
                #endif
            }
        }

        #if DEBUG
        print("[LibraryWorkoutsRepository] Successfully converted \(workouts.count) workouts")
        #endif

        cachedWorkouts = workouts
        return workouts
    }

    // Normaliza IDs removendo espaços e usando lowercase para consistência.
    private func normalizeExerciseId(_ id: String) -> String {
        id
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "_")
            .lowercased()
    }
}

struct LibraryWorkoutsLoader: Sendable {
    private let fileName: String
    private let bundle: Bundle

    nonisolated init(fileName: String = "LibraryWorkoutsSeed", bundle: Bundle = .main) {
        self.fileName = fileName
        self.bundle = bundle
    }

    nonisolated fileprivate func loadDTOs() throws -> [LibraryWorkoutDTO] {
        guard let url = bundle.url(forResource: fileName, withExtension: "json") else {
            throw DomainError.repositoryFailure(reason: "seed \(fileName).json não encontrado no bundle.")
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode([LibraryWorkoutDTO].self, from: data)
    }
}

// MARK: - DTOs

fileprivate struct LibraryWorkoutDTO: Codable {
    let id: String
    let title: String
    let subtitle: String
    let goal: String
    let structure: String
    let estimatedDurationMinutes: Int
    let intensity: String
    let exercises: [LibraryExercisePrescriptionDTO]

    func toDomain(normalizer: (String) -> String) -> LibraryWorkout? {
        guard let goalEnum = FitnessGoal(rawValue: goal) else {
            #if DEBUG
            print("[DTO] Workout \(id): Invalid goal '\(goal)'")
            #endif
            return nil
        }
        guard let structureEnum = TrainingStructure(rawValue: structure) else {
            #if DEBUG
            print("[DTO] Workout \(id): Invalid structure '\(structure)'")
            #endif
            return nil
        }
        guard let intensityEnum = WorkoutIntensity(rawValue: intensity) else {
            #if DEBUG
            print("[DTO] Workout \(id): Invalid intensity '\(intensity)'")
            #endif
            return nil
        }

        var exercisePrescriptions: [ExercisePrescription] = []
        for exercise in exercises {
            if let domain = exercise.toDomain(normalizer: normalizer) {
                exercisePrescriptions.append(domain)
            }
        }

        guard !exercisePrescriptions.isEmpty else {
            #if DEBUG
            print("[DTO] Workout \(id): No valid exercises")
            #endif
            return nil
        }

        return LibraryWorkout(
            id: id,
            title: title,
            subtitle: subtitle,
            goal: goalEnum,
            structure: structureEnum,
            estimatedDurationMinutes: estimatedDurationMinutes,
            intensity: intensityEnum,
            exercises: exercisePrescriptions
        )
    }
}

private struct LibraryExercisePrescriptionDTO: Codable {
    let exercise: LibraryExerciseDTO
    let sets: Int
    let repsLower: Int
    let repsUpper: Int
    let restInterval: TimeInterval
    let tip: String?

    func toDomain(normalizer: (String) -> String) -> ExercisePrescription? {
        guard let exerciseDomain = exercise.toDomain(normalizer: normalizer) else { return nil }
        return ExercisePrescription(
            exercise: exerciseDomain,
            sets: sets,
            reps: IntRange(repsLower, repsUpper),
            restInterval: restInterval,
            tip: tip
        )
    }
}

private struct LibraryExerciseDTO: Codable {
    let id: String
    let name: String
    let mainMuscle: String
    let equipment: String
    let instructions: [String]
    let media: LibraryMediaDTO?

    func toDomain(normalizer: (String) -> String) -> WorkoutExercise? {
        guard let muscle = MuscleGroup(rawValue: mainMuscle) else {
            #if DEBUG
            print("[DTO] Exercise \(id): Invalid mainMuscle '\(mainMuscle)'")
            #endif
            return nil
        }
        guard let equipmentEnum = EquipmentType(rawValue: equipment) else {
            #if DEBUG
            print("[DTO] Exercise \(id): Invalid equipment '\(equipment)'")
            #endif
            return nil
        }

        let normalizedId = normalizer(id)

        return WorkoutExercise(
            id: normalizedId,
            name: name,
            mainMuscle: muscle,
            equipment: equipmentEnum,
            instructions: instructions,
            media: media?.toDomain()
        )
    }
}

private struct LibraryMediaDTO: Codable {
    let imageUrl: String?
    let gifUrl: String?

    func toDomain() -> ExerciseMedia {
        ExerciseMedia(
            imageURL: imageUrl.flatMap(URL.init(string:)),
            gifURL: gifUrl.flatMap(URL.init(string:)),
            source: nil
        )
    }
}
