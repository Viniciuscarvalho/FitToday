//
//  UserStatsTests.swift
//  FitTodayTests
//
//  Created by Claude on 18/01/26.
//

import XCTest
@testable import FitToday

final class UserStatsTests: XCTestCase {

    // MARK: - Computed Properties Tests

    func test_weekAverageDuration_withWorkouts_calculatesCorrectly() {
        // Given
        let stats = UserStats(
            currentStreak: 5,
            longestStreak: 10,
            lastWorkoutDate: Date(),
            weekStartDate: Date().startOfWeek,
            weekWorkoutsCount: 4,
            weekTotalMinutes: 200,
            weekTotalCalories: 800,
            monthStartDate: Date().startOfMonth,
            monthWorkoutsCount: 10,
            monthTotalMinutes: 500,
            monthTotalCalories: 2000,
            lastUpdatedAt: Date()
        )

        // Then
        XCTAssertEqual(stats.weekAverageDuration, 50) // 200 / 4
    }

    func test_weekAverageDuration_noWorkouts_returnsZero() {
        // Given
        let stats = UserStats(
            currentStreak: 0,
            longestStreak: 0,
            lastWorkoutDate: nil,
            weekStartDate: Date().startOfWeek,
            weekWorkoutsCount: 0,
            weekTotalMinutes: 0,
            weekTotalCalories: 0,
            monthStartDate: Date().startOfMonth,
            monthWorkoutsCount: 0,
            monthTotalMinutes: 0,
            monthTotalCalories: 0,
            lastUpdatedAt: Date()
        )

        // Then
        XCTAssertEqual(stats.weekAverageDuration, 0)
    }

    func test_monthAverageDuration_withWorkouts_calculatesCorrectly() {
        // Given
        let stats = UserStats(
            currentStreak: 5,
            longestStreak: 10,
            lastWorkoutDate: Date(),
            weekStartDate: Date().startOfWeek,
            weekWorkoutsCount: 4,
            weekTotalMinutes: 200,
            weekTotalCalories: 800,
            monthStartDate: Date().startOfMonth,
            monthWorkoutsCount: 10,
            monthTotalMinutes: 500,
            monthTotalCalories: 2000,
            lastUpdatedAt: Date()
        )

        // Then
        XCTAssertEqual(stats.monthAverageDuration, 50) // 500 / 10
    }

    func test_weekAverageCalories_withWorkouts_calculatesCorrectly() {
        // Given
        let stats = UserStats(
            currentStreak: 5,
            longestStreak: 10,
            lastWorkoutDate: Date(),
            weekStartDate: Date().startOfWeek,
            weekWorkoutsCount: 4,
            weekTotalMinutes: 200,
            weekTotalCalories: 800,
            monthStartDate: Date().startOfMonth,
            monthWorkoutsCount: 10,
            monthTotalMinutes: 500,
            monthTotalCalories: 2000,
            lastUpdatedAt: Date()
        )

        // Then
        XCTAssertEqual(stats.weekAverageCalories, 200) // 800 / 4
    }

    func test_monthAverageCalories_withWorkouts_calculatesCorrectly() {
        // Given
        let stats = UserStats(
            currentStreak: 5,
            longestStreak: 10,
            lastWorkoutDate: Date(),
            weekStartDate: Date().startOfWeek,
            weekWorkoutsCount: 4,
            weekTotalMinutes: 200,
            weekTotalCalories: 800,
            monthStartDate: Date().startOfMonth,
            monthWorkoutsCount: 10,
            monthTotalMinutes: 500,
            monthTotalCalories: 2000,
            lastUpdatedAt: Date()
        )

        // Then
        XCTAssertEqual(stats.monthAverageCalories, 200) // 2000 / 10
    }

    // MARK: - Empty Factory Tests

    func test_empty_returnsDefaultValues() {
        // Given/When
        let stats = UserStats.empty

        // Then
        XCTAssertEqual(stats.currentStreak, 0)
        XCTAssertEqual(stats.longestStreak, 0)
        XCTAssertNil(stats.lastWorkoutDate)
        XCTAssertEqual(stats.weekWorkoutsCount, 0)
        XCTAssertEqual(stats.weekTotalMinutes, 0)
        XCTAssertEqual(stats.weekTotalCalories, 0)
        XCTAssertEqual(stats.monthWorkoutsCount, 0)
        XCTAssertEqual(stats.monthTotalMinutes, 0)
        XCTAssertEqual(stats.monthTotalCalories, 0)
    }

    // MARK: - Equatable Tests

    func test_equatable_sameValues_areEqual() {
        // Given
        let date = Date()
        let weekStart = date.startOfWeek
        let monthStart = date.startOfMonth

        let stats1 = UserStats(
            currentStreak: 5,
            longestStreak: 10,
            lastWorkoutDate: date,
            weekStartDate: weekStart,
            weekWorkoutsCount: 3,
            weekTotalMinutes: 120,
            weekTotalCalories: 450,
            monthStartDate: monthStart,
            monthWorkoutsCount: 12,
            monthTotalMinutes: 600,
            monthTotalCalories: 2400,
            lastUpdatedAt: date
        )

        let stats2 = UserStats(
            currentStreak: 5,
            longestStreak: 10,
            lastWorkoutDate: date,
            weekStartDate: weekStart,
            weekWorkoutsCount: 3,
            weekTotalMinutes: 120,
            weekTotalCalories: 450,
            monthStartDate: monthStart,
            monthWorkoutsCount: 12,
            monthTotalMinutes: 600,
            monthTotalCalories: 2400,
            lastUpdatedAt: date
        )

        // Then
        XCTAssertEqual(stats1, stats2)
    }

    func test_equatable_differentValues_areNotEqual() {
        // Given
        let date = Date()
        let weekStart = date.startOfWeek
        let monthStart = date.startOfMonth

        let stats1 = UserStats(
            currentStreak: 5,
            longestStreak: 10,
            lastWorkoutDate: date,
            weekStartDate: weekStart,
            weekWorkoutsCount: 3,
            weekTotalMinutes: 120,
            weekTotalCalories: 450,
            monthStartDate: monthStart,
            monthWorkoutsCount: 12,
            monthTotalMinutes: 600,
            monthTotalCalories: 2400,
            lastUpdatedAt: date
        )

        let stats2 = UserStats(
            currentStreak: 7, // Different streak
            longestStreak: 10,
            lastWorkoutDate: date,
            weekStartDate: weekStart,
            weekWorkoutsCount: 3,
            weekTotalMinutes: 120,
            weekTotalCalories: 450,
            monthStartDate: monthStart,
            monthWorkoutsCount: 12,
            monthTotalMinutes: 600,
            monthTotalCalories: 2400,
            lastUpdatedAt: date
        )

        // Then
        XCTAssertNotEqual(stats1, stats2)
    }

    // MARK: - Codable Tests

    func test_codable_encodesAndDecodesCorrectly() throws {
        // Given
        let date = Date()
        let stats = UserStats(
            currentStreak: 5,
            longestStreak: 10,
            lastWorkoutDate: date,
            weekStartDate: date.startOfWeek,
            weekWorkoutsCount: 3,
            weekTotalMinutes: 120,
            weekTotalCalories: 450,
            monthStartDate: date.startOfMonth,
            monthWorkoutsCount: 12,
            monthTotalMinutes: 600,
            monthTotalCalories: 2400,
            lastUpdatedAt: date
        )

        // When
        let encoded = try JSONEncoder().encode(stats)
        let decoded = try JSONDecoder().decode(UserStats.self, from: encoded)

        // Then
        XCTAssertEqual(decoded.currentStreak, stats.currentStreak)
        XCTAssertEqual(decoded.longestStreak, stats.longestStreak)
        XCTAssertEqual(decoded.weekWorkoutsCount, stats.weekWorkoutsCount)
        XCTAssertEqual(decoded.monthWorkoutsCount, stats.monthWorkoutsCount)
    }
}
