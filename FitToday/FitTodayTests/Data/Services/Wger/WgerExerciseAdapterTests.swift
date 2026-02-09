//
//  WgerExerciseAdapterTests.swift
//  FitTodayTests
//
//  Unit tests for WgerExerciseAdapter media resolution priority.
//

import XCTest
@testable import FitToday

final class WgerExerciseAdapterTests: XCTestCase {

    // MARK: - Media Resolution Priority Tests

    func testMediaResolution_WithVideo_PrioritizesVideo() {
        // Given: Exercise with all media types (this is theoretical as Wger doesn't provide videos yet)
        let images = [
            makeImage(id: 1, url: "https://example.com/image.jpg", isMain: true),
            makeImage(id: 2, url: "https://example.com/animation.gif", isMain: false)
        ]
        let exercise = makeExercise(id: 1, name: "Bench Press", category: 11, images: images)

        // When: Converting to WorkoutExercise
        let result = WgerExerciseAdapter.toWorkoutExercise(from: exercise, images: images)

        // Then: Should use image (since Wger doesn't provide videos)
        XCTAssertNotNil(result.media)
        XCTAssertEqual(result.media?.imageURL?.absoluteString, "https://example.com/image.jpg")
        XCTAssertNil(result.media?.videoURL)
        XCTAssertEqual(result.media?.source, "Wger")
    }

    func testMediaResolution_WithGIF_PrioritizesGIFOverStaticImage() {
        // Given: Exercise with GIF and static image
        let images = [
            makeImage(id: 1, url: "https://example.com/image.jpg", isMain: true),
            makeImage(id: 2, url: "https://example.com/animation.gif", isMain: false)
        ]
        let exercise = makeExercise(id: 1, name: "Squat", category: 9, images: images)

        // When: Converting to WorkoutExercise
        let result = WgerExerciseAdapter.toWorkoutExercise(from: exercise, images: images)

        // Then: Should prioritize GIF
        XCTAssertNotNil(result.media)
        XCTAssertEqual(result.media?.gifURL?.absoluteString, "https://example.com/animation.gif")
        XCTAssertNil(result.media?.imageURL)
        XCTAssertNil(result.media?.videoURL)
        XCTAssertEqual(result.media?.source, "Wger")
    }

    func testMediaResolution_WithOnlyStaticImage_UsesImage() {
        // Given: Exercise with only static image
        let images = [
            makeImage(id: 1, url: "https://example.com/image.jpg", isMain: true)
        ]
        let exercise = makeExercise(id: 1, name: "Deadlift", category: 12, images: images)

        // When: Converting to WorkoutExercise
        let result = WgerExerciseAdapter.toWorkoutExercise(from: exercise, images: images)

        // Then: Should use static image
        XCTAssertNotNil(result.media)
        XCTAssertEqual(result.media?.imageURL?.absoluteString, "https://example.com/image.jpg")
        XCTAssertNil(result.media?.gifURL)
        XCTAssertNil(result.media?.videoURL)
        XCTAssertEqual(result.media?.source, "Wger")
    }

    func testMediaResolution_WithNoMedia_UsesPlaceholder() {
        // Given: Exercise with no images
        let exercise = makeExercise(id: 1, name: "Pull Up", category: 12, images: [])

        // When: Converting to WorkoutExercise
        let result = WgerExerciseAdapter.toWorkoutExercise(from: exercise, images: [])

        // Then: Should use placeholder with muscle group
        XCTAssertNotNil(result.media)
        XCTAssertNil(result.media?.imageURL)
        XCTAssertNil(result.media?.gifURL)
        XCTAssertNil(result.media?.videoURL)
        XCTAssertEqual(result.media?.placeholderMuscleGroup, .back)
        XCTAssertEqual(result.media?.source, "Placeholder")
    }

    func testMediaResolution_SelectsMainImage_WhenMultipleImagesAvailable() {
        // Given: Multiple images with one marked as main
        let images = [
            makeImage(id: 1, url: "https://example.com/image1.jpg", isMain: false),
            makeImage(id: 2, url: "https://example.com/main-image.jpg", isMain: true),
            makeImage(id: 3, url: "https://example.com/image3.jpg", isMain: false)
        ]
        let exercise = makeExercise(id: 1, name: "Shoulder Press", category: 13, images: images)

        // When: Converting to WorkoutExercise
        let result = WgerExerciseAdapter.toWorkoutExercise(from: exercise, images: images)

        // Then: Should select the main image
        XCTAssertNotNil(result.media)
        XCTAssertEqual(result.media?.imageURL?.absoluteString, "https://example.com/main-image.jpg")
        XCTAssertEqual(result.media?.source, "Wger")
    }

    func testMediaResolution_SelectsFirstImage_WhenNoMainImageMarked() {
        // Given: Multiple images without main marker
        let images = [
            makeImage(id: 1, url: "https://example.com/first.jpg", isMain: false),
            makeImage(id: 2, url: "https://example.com/second.jpg", isMain: false)
        ]
        let exercise = makeExercise(id: 1, name: "Bicep Curl", category: 8, images: images)

        // When: Converting to WorkoutExercise
        let result = WgerExerciseAdapter.toWorkoutExercise(from: exercise, images: images)

        // Then: Should select the first image
        XCTAssertNotNil(result.media)
        XCTAssertEqual(result.media?.imageURL?.absoluteString, "https://example.com/first.jpg")
        XCTAssertEqual(result.media?.source, "Wger")
    }

    func testMediaResolution_GIFDetection_CaseInsensitive() {
        // Given: GIF with uppercase extension
        let images = [
            makeImage(id: 1, url: "https://example.com/animation.GIF", isMain: false),
            makeImage(id: 2, url: "https://example.com/image.jpg", isMain: true)
        ]
        let exercise = makeExercise(id: 1, name: "Plank", category: 10, images: images)

        // When: Converting to WorkoutExercise
        let result = WgerExerciseAdapter.toWorkoutExercise(from: exercise, images: images)

        // Then: Should detect GIF regardless of case
        XCTAssertNotNil(result.media)
        XCTAssertEqual(result.media?.gifURL?.absoluteString, "https://example.com/animation.GIF")
        XCTAssertNil(result.media?.imageURL)
        XCTAssertEqual(result.media?.source, "Wger")
    }

    // MARK: - Muscle Group Placeholder Mapping Tests

    func testPlaceholder_ChestExercise_UsesChestMuscleGroup() {
        let exercise = makeExercise(id: 1, name: "Bench Press", category: 11, images: [])
        let result = WgerExerciseAdapter.toWorkoutExercise(from: exercise, images: [])

        XCTAssertEqual(result.media?.placeholderMuscleGroup, .chest)
        XCTAssertEqual(result.mainMuscle, .chest)
    }

    func testPlaceholder_BackExercise_UsesBackMuscleGroup() {
        let exercise = makeExercise(id: 1, name: "Barbell Row", category: 12, images: [])
        let result = WgerExerciseAdapter.toWorkoutExercise(from: exercise, images: [])

        XCTAssertEqual(result.media?.placeholderMuscleGroup, .back)
        XCTAssertEqual(result.mainMuscle, .back)
    }

    func testPlaceholder_ShouldersExercise_UsesShouldersMuscleGroup() {
        let exercise = makeExercise(id: 1, name: "Overhead Press", category: 13, images: [])
        let result = WgerExerciseAdapter.toWorkoutExercise(from: exercise, images: [])

        XCTAssertEqual(result.media?.placeholderMuscleGroup, .shoulders)
        XCTAssertEqual(result.mainMuscle, .shoulders)
    }

    func testPlaceholder_ArmsExercise_UsesArmsMuscleGroup() {
        let exercise = makeExercise(id: 1, name: "Hammer Curl", category: 8, images: [])
        let result = WgerExerciseAdapter.toWorkoutExercise(from: exercise, images: [])

        XCTAssertEqual(result.media?.placeholderMuscleGroup, .arms)
        XCTAssertEqual(result.mainMuscle, .arms)
    }

    func testPlaceholder_LegsExercise_UsesQuadricepsMuscleGroup() {
        let exercise = makeExercise(id: 1, name: "Leg Press", category: 9, images: [])
        let result = WgerExerciseAdapter.toWorkoutExercise(from: exercise, images: [])

        XCTAssertEqual(result.media?.placeholderMuscleGroup, .quadriceps)
        XCTAssertEqual(result.mainMuscle, .quadriceps)
    }

    func testPlaceholder_AbsExercise_UsesCoreMuscleGroup() {
        let exercise = makeExercise(id: 1, name: "Crunches", category: 10, images: [])
        let result = WgerExerciseAdapter.toWorkoutExercise(from: exercise, images: [])

        XCTAssertEqual(result.media?.placeholderMuscleGroup, .core)
        XCTAssertEqual(result.mainMuscle, .core)
    }

    func testPlaceholder_CalvesExercise_UsesCalvesMuscleGroup() {
        let exercise = makeExercise(id: 1, name: "Calf Raises", category: 14, images: [])
        let result = WgerExerciseAdapter.toWorkoutExercise(from: exercise, images: [])

        XCTAssertEqual(result.media?.placeholderMuscleGroup, .calves)
        XCTAssertEqual(result.mainMuscle, .calves)
    }

    func testPlaceholder_CardioExercise_UsesCardioSystemMuscleGroup() {
        let exercise = makeExercise(id: 1, name: "Running", category: 15, images: [])
        let result = WgerExerciseAdapter.toWorkoutExercise(from: exercise, images: [])

        XCTAssertEqual(result.media?.placeholderMuscleGroup, .cardioSystem)
        XCTAssertEqual(result.mainMuscle, .cardioSystem)
    }

    func testPlaceholder_UnknownCategory_UsesFullBodyMuscleGroup() {
        let exercise = makeExercise(id: 1, name: "Unknown Exercise", category: nil, images: [])
        let result = WgerExerciseAdapter.toWorkoutExercise(from: exercise, images: [])

        XCTAssertEqual(result.media?.placeholderMuscleGroup, .fullBody)
        XCTAssertEqual(result.mainMuscle, .fullBody)
    }

    // MARK: - ExerciseMedia Helper Tests

    func testExerciseMedia_HasMedia_ReturnsTrueWhenVideoExists() {
        let media = ExerciseMedia(videoURL: URL(string: "https://example.com/video.mp4"))
        XCTAssertTrue(media.hasMedia)
    }

    func testExerciseMedia_HasMedia_ReturnsTrueWhenGIFExists() {
        let media = ExerciseMedia(gifURL: URL(string: "https://example.com/animation.gif"))
        XCTAssertTrue(media.hasMedia)
    }

    func testExerciseMedia_HasMedia_ReturnsTrueWhenImageExists() {
        let media = ExerciseMedia(imageURL: URL(string: "https://example.com/image.jpg"))
        XCTAssertTrue(media.hasMedia)
    }

    func testExerciseMedia_HasMedia_ReturnsFalseWhenOnlyPlaceholder() {
        let media = ExerciseMedia(placeholderMuscleGroup: .chest)
        XCTAssertFalse(media.hasMedia)
    }

    func testExerciseMedia_BestMediaURL_ReturnsVideoFirst() {
        let media = ExerciseMedia(
            videoURL: URL(string: "https://example.com/video.mp4"),
            imageURL: URL(string: "https://example.com/image.jpg"),
            gifURL: URL(string: "https://example.com/animation.gif")
        )
        XCTAssertEqual(media.bestMediaURL?.absoluteString, "https://example.com/video.mp4")
    }

    func testExerciseMedia_BestMediaURL_ReturnsGIFWhenNoVideo() {
        let media = ExerciseMedia(
            imageURL: URL(string: "https://example.com/image.jpg"),
            gifURL: URL(string: "https://example.com/animation.gif")
        )
        XCTAssertEqual(media.bestMediaURL?.absoluteString, "https://example.com/animation.gif")
    }

    func testExerciseMedia_BestMediaURL_ReturnsImageWhenNoVideoOrGIF() {
        let media = ExerciseMedia(imageURL: URL(string: "https://example.com/image.jpg"))
        XCTAssertEqual(media.bestMediaURL?.absoluteString, "https://example.com/image.jpg")
    }

    func testExerciseMedia_BestMediaURL_ReturnsNilWhenNoMedia() {
        let media = ExerciseMedia(placeholderMuscleGroup: .chest)
        XCTAssertNil(media.bestMediaURL)
    }

    // MARK: - Test Helpers

    private func makeExercise(
        id: Int,
        name: String,
        category: Int?,
        images: [WgerExerciseImage]
    ) -> WgerExercise {
        WgerExercise(
            id: id,
            uuid: nil,
            name: name,
            exerciseBaseId: id,
            description: nil,
            category: category,
            muscles: [],
            musclesSecondary: [],
            equipment: [7], // Bodyweight
            language: 4, // Portuguese
            license: nil,
            licenseAuthor: nil,
            mainImageURL: images.first?.image,
            imageURLs: images.map { $0.image }
        )
    }

    private func makeImage(id: Int, url: String, isMain: Bool) -> WgerExerciseImage {
        WgerExerciseImage(from: try! JSONDecoder().decode(
            WgerExerciseImage.self,
            from: """
            {
                "id": \(id),
                "image": "\(url)",
                "is_main": \(isMain)
            }
            """.data(using: .utf8)!
        ))
    }
}
