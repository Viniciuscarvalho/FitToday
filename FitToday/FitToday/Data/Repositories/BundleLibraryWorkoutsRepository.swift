//
//  BundleLibraryWorkoutsRepository.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import Foundation

actor BundleLibraryWorkoutsRepository: LibraryWorkoutsRepository {
    private let loader: LibraryWorkoutsLoader
    private let mediaResolver: ExerciseMediaResolving?
    private var cachedWorkouts: [LibraryWorkout]?

    init(
        loader: LibraryWorkoutsLoader = LibraryWorkoutsLoader(),
        mediaResolver: ExerciseMediaResolving? = nil
    ) {
        self.loader = loader
        self.mediaResolver = mediaResolver
    }

    func loadWorkouts() async throws -> [LibraryWorkout] {
        if let cached = cachedWorkouts {
            return cached
        }

        let dtos = try loader.loadDTOs()
        var workouts: [LibraryWorkout] = []
        for dto in dtos {
            if let workout = await dto.toDomain(mediaResolver: mediaResolver, normalizer: normalizeExerciseId(_:)) {
                workouts.append(workout)
            }
        }
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

    init(fileName: String = "LibraryWorkoutsSeed", bundle: Bundle = .main) {
        self.fileName = fileName
        self.bundle = bundle
    }

    fileprivate func loadDTOs() throws -> [LibraryWorkoutDTO] {
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

    func toDomain(
        mediaResolver: ExerciseMediaResolving?,
        normalizer: (String) -> String
    ) async -> LibraryWorkout? {
        guard
            let goalEnum = FitnessGoal(rawValue: goal),
            let structureEnum = TrainingStructure(rawValue: structure),
            let intensityEnum = WorkoutIntensity(rawValue: intensity)
        else { return nil }

        var exercisePrescriptions: [ExercisePrescription] = []
        for exercise in exercises {
            if let domain = await exercise.toDomain(mediaResolver: mediaResolver, normalizer: normalizer) {
                exercisePrescriptions.append(domain)
            }
        }
        guard !exercisePrescriptions.isEmpty else { return nil }

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

    func toDomain(
        mediaResolver: ExerciseMediaResolving?,
        normalizer: (String) -> String
    ) async -> ExercisePrescription? {
        guard let exerciseDomain = await exercise.toDomain(mediaResolver: mediaResolver, normalizer: normalizer) else { return nil }
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

    func toDomain(
        mediaResolver: ExerciseMediaResolving?,
        normalizer: (String) -> String
    ) async -> WorkoutExercise? {
        guard
            let muscle = MuscleGroup(rawValue: mainMuscle),
            let equipmentEnum = EquipmentType(rawValue: equipment)
        else { return nil }

        let normalizedId = normalizer(id)
        let resolvedMedia = await resolveMedia(using: mediaResolver, normalizedId: normalizedId)

        return WorkoutExercise(
            id: normalizedId,
            name: name,
            mainMuscle: muscle,
            equipment: equipmentEnum,
            instructions: instructions,
            media: resolvedMedia
        )
    }

    private func resolveMedia(
        using mediaResolver: ExerciseMediaResolving?,
        normalizedId: String
    ) async -> ExerciseMedia? {
        let domainMedia = media?.toDomain()

        // Se já houver mídia, retorna sem resolver.
        if let media = domainMedia, (media.imageURL != nil || media.gifURL != nil) {
            return media
        }

        // Tenta resolver via serviço (prioriza GIF)
        if let resolver = mediaResolver {
            let resolved = await resolver.resolveMedia(for: normalizedId, existingMedia: domainMedia)
            if resolved.hasMedia {
                return ExerciseMedia(
                    imageURL: resolved.imageURL ?? resolved.gifURL,
                    gifURL: resolved.gifURL ?? resolved.imageURL,
                    source: resolved.source.rawValue
                )
            }
        }

        // Fallback para URL estática do ExerciseDB (sem auth)
        if let fallbackURL = URL(string: "https://v2.exercisedb.io/image/\(normalizedId)") {
            return ExerciseMedia(
                imageURL: fallbackURL,
                gifURL: fallbackURL,
                source: "ExerciseDB"
            )
        }

        return domainMedia
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

