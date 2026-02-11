//
//  WgerExerciseAdapter.swift
//  FitToday
//
//  Converts Wger API models to app domain models.
//

import Foundation

// MARK: - Exercise Adapter

/// Converts Wger API exercises to app's WorkoutExercise model.
struct WgerExerciseAdapter {

    /// Converts a Wger exercise to WorkoutExercise.
    /// - Parameters:
    ///   - wgerExercise: The Wger exercise to convert.
    ///   - images: Optional images for the exercise.
    ///   - language: Language code for localization.
    /// - Returns: A WorkoutExercise ready for use in the app.
    static func toWorkoutExercise(
        from wgerExercise: WgerExercise,
        images: [WgerExerciseImage] = [],
        language: WgerLanguageCode = .portuguese
    ) -> WorkoutExercise {
        // Determine muscle group from category
        let muscleGroup = wgerExercise.category
            .flatMap { WgerCategoryMapping.from(id: $0)?.muscleGroup }
            ?? .fullBody

        // Determine equipment type
        let equipmentType = wgerExercise.equipment.first
            .flatMap { WgerEquipmentMapping.from(id: $0)?.toEquipmentType }
            ?? .bodyweight

        // Clean HTML from description
        let instructions = cleanDescription(wgerExercise.description)

        // Get media URLs from images with priority resolution
        let media = createMedia(from: images, muscleGroup: muscleGroup)

        return WorkoutExercise(
            id: String(wgerExercise.id),
            name: wgerExercise.name,
            mainMuscle: muscleGroup,
            equipment: equipmentType,
            instructions: instructions,
            media: media
        )
    }

    /// Converts multiple Wger exercises to WorkoutExercises.
    static func toWorkoutExercises(
        from wgerExercises: [WgerExercise],
        imagesByExercise: [Int: [WgerExerciseImage]] = [:],
        language: WgerLanguageCode = .portuguese
    ) -> [WorkoutExercise] {
        wgerExercises.map { exercise in
            let images = imagesByExercise[exercise.exerciseBaseId ?? exercise.id] ?? []
            return toWorkoutExercise(from: exercise, images: images, language: language)
        }
    }

    // MARK: - Private Helpers

    private static func cleanDescription(_ description: String?) -> [String] {
        guard let description, !description.isEmpty else {
            return []
        }

        // Remove HTML tags
        let cleaned = description
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Split into sentences for instructions
        let sentences = cleaned.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return sentences
    }

    /// Resolves exercise media with priority: video > GIF > image > placeholder.
    /// - Parameters:
    ///   - images: Array of exercise images from Wger API.
    ///   - videos: Optional array of exercise videos (not currently provided by Wger).
    ///   - muscleGroup: The primary muscle group for placeholder fallback.
    /// - Returns: ExerciseMedia with best available media or placeholder.
    private static func createMedia(
        from images: [WgerExerciseImage],
        videos: [URL]? = nil,
        muscleGroup: MuscleGroup
    ) -> ExerciseMedia {
        // Priority 1: Video (if available)
        if let videoURL = videos?.first {
            return ExerciseMedia(
                videoURL: videoURL,
                imageURL: nil,
                gifURL: nil,
                placeholderMuscleGroup: nil,
                source: "Wger"
            )
        }

        // Priority 2: GIF (Wger doesn't currently provide GIFs, but check imageURLs for .gif extension)
        if let gifImage = images.first(where: { $0.image.lowercased().hasSuffix(".gif") }) {
            return ExerciseMedia(
                videoURL: nil,
                imageURL: nil,
                gifURL: gifImage.imageURL,
                placeholderMuscleGroup: nil,
                source: "Wger"
            )
        }

        // Priority 3: Image (static image)
        let mainImage = images.first { $0.isMain } ?? images.first
        if let imageURL = mainImage?.imageURL {
            return ExerciseMedia(
                videoURL: nil,
                imageURL: imageURL,
                gifURL: nil,
                placeholderMuscleGroup: nil,
                source: "Wger"
            )
        }

        // Priority 4: Placeholder (no media available)
        return ExerciseMedia(
            videoURL: nil,
            imageURL: nil,
            gifURL: nil,
            placeholderMuscleGroup: muscleGroup,
            source: "Placeholder"
        )
    }
}

// MARK: - Category Localization

extension WgerExerciseAdapter {
    /// Returns localized category name.
    static func localizedCategoryName(for categoryId: Int, language: WgerLanguageCode = .portuguese) -> String {
        let languageCode = language == .portuguese ? "pt" : "en"
        return WgerCategoryMapping.localizedName(for: categoryId, language: languageCode)
    }

    /// Returns localized equipment name.
    static func localizedEquipmentName(for equipmentId: Int, language: WgerLanguageCode = .portuguese) -> String {
        let languageCode = language == .portuguese ? "pt" : "en"
        return WgerEquipmentMapping.localizedName(for: equipmentId, language: languageCode)
    }

    /// Returns all categories with localized names.
    static func allCategories(language: WgerLanguageCode = .portuguese) -> [(id: Int, name: String, icon: String)] {
        WgerCategoryMapping.allCases.map { category in
            let name = language == .portuguese ? category.portugueseName : category.englishName
            return (id: category.rawValue, name: name, icon: category.icon)
        }
    }

    /// Returns all equipment types with localized names.
    static func allEquipment(language: WgerLanguageCode = .portuguese) -> [(id: Int, name: String)] {
        WgerEquipmentMapping.allCases.map { equipment in
            let name = language == .portuguese ? equipment.portugueseName : equipment.englishName
            return (id: equipment.rawValue, name: name)
        }
    }
}

// MARK: - Search Helpers

extension WgerExerciseAdapter {
    /// Filters exercises by muscle group.
    static func filterByMuscleGroup(
        _ exercises: [WgerExercise],
        muscleGroup: MuscleGroup
    ) -> [WgerExercise] {
        exercises.filter { exercise in
            guard let categoryId = exercise.category,
                  let mapping = WgerCategoryMapping.from(id: categoryId) else {
                return false
            }
            return mapping.muscleGroup == muscleGroup
        }
    }

    /// Filters exercises by equipment type.
    static func filterByEquipment(
        _ exercises: [WgerExercise],
        equipmentType: EquipmentType
    ) -> [WgerExercise] {
        exercises.filter { exercise in
            for eqId in exercise.equipment {
                if let mapping = WgerEquipmentMapping.from(id: eqId),
                   mapping.toEquipmentType == equipmentType {
                    return true
                }
            }
            return false
        }
    }
}
