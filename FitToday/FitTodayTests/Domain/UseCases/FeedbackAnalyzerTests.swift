//
//  FeedbackAnalyzerTests.swift
//  FitTodayTests
//
//  Created by Claude on 18/01/26.
//

import XCTest
@testable import FitToday

final class FeedbackAnalyzerTests: XCTestCase {

    var sut: FeedbackAnalyzer!

    override func setUp() {
        super.setUp()
        sut = FeedbackAnalyzer()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Empty Ratings Tests

    func test_analyzeRecentFeedback_emptyRatings_returnsNoChange() {
        // Given
        let ratings: [WorkoutRating] = []

        // When
        let result = sut.analyzeRecentFeedback(ratings: ratings, currentIntensity: .moderate)

        // Then
        XCTAssertEqual(result.volumeMultiplier, 1.0)
        XCTAssertEqual(result.rpeAdjustment, 0)
        XCTAssertEqual(result.restAdjustment, 0)
        XCTAssertFalse(result.hasAdjustment)
        XCTAssertEqual(result.direction, .maintain)
    }

    // MARK: - Increase Intensity Tests (3+ too_easy)

    func test_analyzeRecentFeedback_threeOrMoreTooEasy_returnsIncreaseIntensity() {
        // Given - exactly 3 "too_easy" ratings
        let ratings: [WorkoutRating] = [.tooEasy, .tooEasy, .tooEasy]

        // When
        let result = sut.analyzeRecentFeedback(ratings: ratings, currentIntensity: .moderate)

        // Then
        XCTAssertEqual(result.volumeMultiplier, 1.15)
        XCTAssertEqual(result.rpeAdjustment, 1)
        XCTAssertEqual(result.restAdjustment, -15)
        XCTAssertTrue(result.hasAdjustment)
        XCTAssertEqual(result.direction, .increase)
        XCTAssertFalse(result.recommendation.isEmpty)
    }

    func test_analyzeRecentFeedback_fourTooEasy_returnsIncreaseIntensity() {
        // Given - 4 "too_easy" ratings
        let ratings: [WorkoutRating] = [.tooEasy, .tooEasy, .tooEasy, .tooEasy]

        // When
        let result = sut.analyzeRecentFeedback(ratings: ratings, currentIntensity: .low)

        // Then
        XCTAssertEqual(result.volumeMultiplier, 1.15)
        XCTAssertEqual(result.direction, .increase)
    }

    func test_analyzeRecentFeedback_fiveTooEasy_returnsIncreaseIntensity() {
        // Given - 5 "too_easy" ratings (max we consider)
        let ratings: [WorkoutRating] = [.tooEasy, .tooEasy, .tooEasy, .tooEasy, .tooEasy]

        // When
        let result = sut.analyzeRecentFeedback(ratings: ratings, currentIntensity: .high)

        // Then
        XCTAssertEqual(result.volumeMultiplier, 1.15)
        XCTAssertEqual(result.direction, .increase)
    }

    // MARK: - Decrease Intensity Tests (3+ too_hard)

    func test_analyzeRecentFeedback_threeOrMoreTooHard_returnsDecreaseIntensity() {
        // Given - exactly 3 "too_hard" ratings
        let ratings: [WorkoutRating] = [.tooHard, .tooHard, .tooHard]

        // When
        let result = sut.analyzeRecentFeedback(ratings: ratings, currentIntensity: .high)

        // Then
        XCTAssertEqual(result.volumeMultiplier, 0.85)
        XCTAssertEqual(result.rpeAdjustment, -1)
        XCTAssertEqual(result.restAdjustment, 30)
        XCTAssertTrue(result.hasAdjustment)
        XCTAssertEqual(result.direction, .decrease)
        XCTAssertFalse(result.recommendation.isEmpty)
    }

    func test_analyzeRecentFeedback_fourTooHard_returnsDecreaseIntensity() {
        // Given - 4 "too_hard" ratings
        let ratings: [WorkoutRating] = [.tooHard, .tooHard, .tooHard, .tooHard]

        // When
        let result = sut.analyzeRecentFeedback(ratings: ratings, currentIntensity: .moderate)

        // Then
        XCTAssertEqual(result.volumeMultiplier, 0.85)
        XCTAssertEqual(result.direction, .decrease)
    }

    // MARK: - No Change Tests (Mixed/Adequate)

    func test_analyzeRecentFeedback_twoTooEasy_returnsNoChange() {
        // Given - only 2 "too_easy" ratings (below threshold)
        let ratings: [WorkoutRating] = [.tooEasy, .tooEasy]

        // When
        let result = sut.analyzeRecentFeedback(ratings: ratings, currentIntensity: .moderate)

        // Then
        XCTAssertEqual(result.volumeMultiplier, 1.0)
        XCTAssertEqual(result.direction, .maintain)
        XCTAssertFalse(result.hasAdjustment)
    }

    func test_analyzeRecentFeedback_twoTooHard_returnsNoChange() {
        // Given - only 2 "too_hard" ratings (below threshold)
        let ratings: [WorkoutRating] = [.tooHard, .tooHard]

        // When
        let result = sut.analyzeRecentFeedback(ratings: ratings, currentIntensity: .moderate)

        // Then
        XCTAssertEqual(result.volumeMultiplier, 1.0)
        XCTAssertEqual(result.direction, .maintain)
    }

    func test_analyzeRecentFeedback_allAdequate_returnsNoChange() {
        // Given - all "adequate" ratings
        let ratings: [WorkoutRating] = [.adequate, .adequate, .adequate, .adequate, .adequate]

        // When
        let result = sut.analyzeRecentFeedback(ratings: ratings, currentIntensity: .moderate)

        // Then
        XCTAssertEqual(result.volumeMultiplier, 1.0)
        XCTAssertEqual(result.direction, .maintain)
        XCTAssertFalse(result.hasAdjustment)
    }

    func test_analyzeRecentFeedback_mixedRatings_returnsNoChange() {
        // Given - mixed ratings (no clear majority)
        let ratings: [WorkoutRating] = [.tooEasy, .adequate, .tooHard, .adequate, .tooEasy]

        // When
        let result = sut.analyzeRecentFeedback(ratings: ratings, currentIntensity: .moderate)

        // Then
        XCTAssertEqual(result.volumeMultiplier, 1.0)
        XCTAssertEqual(result.direction, .maintain)
    }

    func test_analyzeRecentFeedback_twoEasyTwoHard_returnsNoChange() {
        // Given - balanced extremes
        let ratings: [WorkoutRating] = [.tooEasy, .tooEasy, .tooHard, .tooHard]

        // When
        let result = sut.analyzeRecentFeedback(ratings: ratings, currentIntensity: .moderate)

        // Then
        XCTAssertEqual(result.volumeMultiplier, 1.0)
        XCTAssertEqual(result.direction, .maintain)
    }

    // MARK: - Edge Cases

    func test_analyzeRecentFeedback_singleRating_returnsNoChange() {
        // Given - single rating (below threshold)
        let ratings: [WorkoutRating] = [.tooEasy]

        // When
        let result = sut.analyzeRecentFeedback(ratings: ratings, currentIntensity: .moderate)

        // Then
        XCTAssertEqual(result.volumeMultiplier, 1.0)
        XCTAssertFalse(result.hasAdjustment)
    }

    func test_analyzeRecentFeedback_threeTooEasyWithAdequate_returnsIncreaseIntensity() {
        // Given - 3 "too_easy" + 2 "adequate"
        let ratings: [WorkoutRating] = [.tooEasy, .adequate, .tooEasy, .adequate, .tooEasy]

        // When
        let result = sut.analyzeRecentFeedback(ratings: ratings, currentIntensity: .moderate)

        // Then
        XCTAssertEqual(result.volumeMultiplier, 1.15)
        XCTAssertEqual(result.direction, .increase)
    }

    func test_analyzeRecentFeedback_threeTooHardWithAdequate_returnsDecreaseIntensity() {
        // Given - 3 "too_hard" + 2 "adequate"
        let ratings: [WorkoutRating] = [.tooHard, .adequate, .tooHard, .adequate, .tooHard]

        // When
        let result = sut.analyzeRecentFeedback(ratings: ratings, currentIntensity: .high)

        // Then
        XCTAssertEqual(result.volumeMultiplier, 0.85)
        XCTAssertEqual(result.direction, .decrease)
    }

    // MARK: - IntensityAdjustment Factory Tests

    func test_intensityAdjustment_noChange_hasCorrectValues() {
        // When
        let adjustment = IntensityAdjustment.noChange

        // Then
        XCTAssertEqual(adjustment.volumeMultiplier, 1.0)
        XCTAssertEqual(adjustment.rpeAdjustment, 0)
        XCTAssertEqual(adjustment.restAdjustment, 0)
        XCTAssertTrue(adjustment.recommendation.isEmpty)
        XCTAssertFalse(adjustment.hasAdjustment)
    }

    func test_intensityAdjustment_increaseIntensity_hasCorrectValues() {
        // When
        let adjustment = IntensityAdjustment.increaseIntensity

        // Then
        XCTAssertEqual(adjustment.volumeMultiplier, 1.15)
        XCTAssertEqual(adjustment.rpeAdjustment, 1)
        XCTAssertEqual(adjustment.restAdjustment, -15)
        XCTAssertFalse(adjustment.recommendation.isEmpty)
        XCTAssertTrue(adjustment.hasAdjustment)
    }

    func test_intensityAdjustment_decreaseIntensity_hasCorrectValues() {
        // When
        let adjustment = IntensityAdjustment.decreaseIntensity

        // Then
        XCTAssertEqual(adjustment.volumeMultiplier, 0.85)
        XCTAssertEqual(adjustment.rpeAdjustment, -1)
        XCTAssertEqual(adjustment.restAdjustment, 30)
        XCTAssertFalse(adjustment.recommendation.isEmpty)
        XCTAssertTrue(adjustment.hasAdjustment)
    }
}
