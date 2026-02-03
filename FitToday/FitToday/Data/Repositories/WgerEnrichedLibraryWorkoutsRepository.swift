//
//  WgerEnrichedLibraryWorkoutsRepository.swift
//  FitToday
//
//  Wraps BundleLibraryWorkoutsRepository and enriches exercises with Wger API media.
//

import Foundation

/// Repository that enriches library workouts with Wger API images.
/// Wraps the base bundle repository and fetches media from Wger API.
actor WgerEnrichedLibraryWorkoutsRepository: LibraryWorkoutsRepository {
    private let baseRepository: BundleLibraryWorkoutsRepository
    private let wgerService: WgerAPIService
    private var cachedWorkouts: [LibraryWorkout]?
    private var wgerExerciseCache: [String: WgerExerciseInfo] = [:]

    init(
        baseRepository: BundleLibraryWorkoutsRepository = BundleLibraryWorkoutsRepository(),
        wgerService: WgerAPIService
    ) {
        self.baseRepository = baseRepository
        self.wgerService = wgerService
    }

    func loadWorkouts() async throws -> [LibraryWorkout] {
        // Return cached if available
        if let cached = cachedWorkouts {
            #if DEBUG
            print("[WgerEnrichedRepo] Returning \(cached.count) cached enriched workouts")
            #endif
            return cached
        }

        // Load base workouts
        let baseWorkouts = try await baseRepository.loadWorkouts()
        #if DEBUG
        print("[WgerEnrichedRepo] Loaded \(baseWorkouts.count) base workouts")
        #endif

        // Enrich exercises with Wger API media in parallel
        var enrichedWorkouts: [LibraryWorkout] = []

        for workout in baseWorkouts {
            let enrichedExercises = await enrichExercises(workout.exercises)
            let enrichedWorkout = LibraryWorkout(
                id: workout.id,
                title: workout.title,
                subtitle: workout.subtitle,
                goal: workout.goal,
                structure: workout.structure,
                estimatedDurationMinutes: workout.estimatedDurationMinutes,
                intensity: workout.intensity,
                exercises: enrichedExercises
            )
            enrichedWorkouts.append(enrichedWorkout)
        }

        cachedWorkouts = enrichedWorkouts
        #if DEBUG
        print("[WgerEnrichedRepo] Cached \(enrichedWorkouts.count) enriched workouts")
        #endif

        return enrichedWorkouts
    }

    // MARK: - Private Methods

    private func enrichExercises(_ prescriptions: [ExercisePrescription]) async -> [ExercisePrescription] {
        var enriched: [ExercisePrescription] = []

        for prescription in prescriptions {
            if let enrichedExercise = await enrichExercise(prescription.exercise) {
                let enrichedPrescription = ExercisePrescription(
                    exercise: enrichedExercise,
                    sets: prescription.sets,
                    reps: prescription.reps,
                    restInterval: prescription.restInterval,
                    tip: prescription.tip
                )
                enriched.append(enrichedPrescription)
            } else {
                enriched.append(prescription)
            }
        }

        return enriched
    }

    private func enrichExercise(_ exercise: WorkoutExercise) async -> WorkoutExercise? {
        // If exercise already has media, skip enrichment
        if exercise.media?.imageURL != nil || exercise.media?.gifURL != nil {
            return exercise
        }

        // Search for exercise in Wger API by name
        do {
            let searchResults = try await wgerService.searchExercises(
                query: exercise.name,
                language: .portuguese,
                limit: 5
            )

            // Find best match
            guard let bestMatch = findBestMatch(for: exercise.name, in: searchResults) else {
                #if DEBUG
                print("[WgerEnrichedRepo] No match found for: \(exercise.name)")
                #endif
                return nil
            }

            // Fetch images for this exercise
            let images = try await wgerService.fetchExerciseImages(
                exerciseBaseId: bestMatch.exerciseBaseId ?? bestMatch.id
            )

            // Get the main image or first available
            let imageURL = images.first(where: { $0.isMain })?.imageURL ?? images.first?.imageURL

            guard let imageURL else {
                #if DEBUG
                print("[WgerEnrichedRepo] No images for: \(exercise.name)")
                #endif
                return nil
            }

            #if DEBUG
            print("[WgerEnrichedRepo] ✅ Enriched \(exercise.name) with image: \(imageURL.absoluteString)")
            #endif

            // Create enriched exercise with media
            return WorkoutExercise(
                id: exercise.id,
                name: exercise.name,
                mainMuscle: exercise.mainMuscle,
                equipment: exercise.equipment,
                instructions: exercise.instructions,
                media: ExerciseMedia(
                    imageURL: imageURL,
                    gifURL: nil,
                    source: "wger"
                )
            )
        } catch {
            #if DEBUG
            print("[WgerEnrichedRepo] ❌ Error enriching \(exercise.name): \(error.localizedDescription)")
            #endif
            return nil
        }
    }

    private func findBestMatch(for name: String, in results: [WgerExercise]) -> WgerExercise? {
        let normalizedName = name.lowercased()
            .replacingOccurrences(of: " ", with: "")
            .folding(options: .diacriticInsensitive, locale: .current)

        // Exact match
        if let exact = results.first(where: {
            $0.name.lowercased()
                .replacingOccurrences(of: " ", with: "")
                .folding(options: .diacriticInsensitive, locale: .current) == normalizedName
        }) {
            return exact
        }

        // Contains match
        if let contains = results.first(where: {
            let resultName = $0.name.lowercased()
                .replacingOccurrences(of: " ", with: "")
                .folding(options: .diacriticInsensitive, locale: .current)
            return resultName.contains(normalizedName) || normalizedName.contains(resultName)
        }) {
            return contains
        }

        // Return first result as fallback
        return results.first
    }
}
