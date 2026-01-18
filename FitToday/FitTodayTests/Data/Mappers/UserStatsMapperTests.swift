//
//  UserStatsMapperTests.swift
//  FitTodayTests
//
//  Created by Claude on 18/01/26.
//

import XCTest
@testable import FitToday

final class UserStatsMapperTests: XCTestCase {

    // MARK: - toDomain Tests

    func test_toDomain_mapsAllFieldsCorrectly() {
        // Given
        let now = Date()
        let weekStart = now.startOfWeek
        let monthStart = now.startOfMonth

        let sdModel = SDUserStats(
            id: "current",
            currentStreak: 7,
            longestStreak: 15,
            lastWorkoutDate: now,
            weekStartDate: weekStart,
            weekWorkoutsCount: 3,
            weekTotalMinutes: 135,
            weekTotalCalories: 540,
            monthStartDate: monthStart,
            monthWorkoutsCount: 12,
            monthTotalMinutes: 600,
            monthTotalCalories: 2400,
            lastUpdatedAt: now
        )

        // When
        let domain = UserStatsMapper.toDomain(sdModel)

        // Then
        XCTAssertEqual(domain.currentStreak, 7)
        XCTAssertEqual(domain.longestStreak, 15)
        XCTAssertEqual(domain.lastWorkoutDate, now)
        XCTAssertEqual(domain.weekStartDate, weekStart)
        XCTAssertEqual(domain.weekWorkoutsCount, 3)
        XCTAssertEqual(domain.weekTotalMinutes, 135)
        XCTAssertEqual(domain.weekTotalCalories, 540)
        XCTAssertEqual(domain.monthStartDate, monthStart)
        XCTAssertEqual(domain.monthWorkoutsCount, 12)
        XCTAssertEqual(domain.monthTotalMinutes, 600)
        XCTAssertEqual(domain.monthTotalCalories, 2400)
        XCTAssertEqual(domain.lastUpdatedAt, now)
    }

    func test_toDomain_withNilLastWorkoutDate_mapsCorrectly() {
        // Given
        let now = Date()
        let sdModel = SDUserStats(
            id: "current",
            currentStreak: 0,
            longestStreak: 0,
            lastWorkoutDate: nil,
            weekStartDate: now.startOfWeek,
            weekWorkoutsCount: 0,
            weekTotalMinutes: 0,
            weekTotalCalories: 0,
            monthStartDate: now.startOfMonth,
            monthWorkoutsCount: 0,
            monthTotalMinutes: 0,
            monthTotalCalories: 0,
            lastUpdatedAt: now
        )

        // When
        let domain = UserStatsMapper.toDomain(sdModel)

        // Then
        XCTAssertNil(domain.lastWorkoutDate)
        XCTAssertEqual(domain.currentStreak, 0)
    }

    // MARK: - toModel Tests

    func test_toModel_mapsAllFieldsCorrectly() {
        // Given
        let now = Date()
        let weekStart = now.startOfWeek
        let monthStart = now.startOfMonth

        let domain = UserStats(
            currentStreak: 5,
            longestStreak: 20,
            lastWorkoutDate: now,
            weekStartDate: weekStart,
            weekWorkoutsCount: 4,
            weekTotalMinutes: 180,
            weekTotalCalories: 720,
            monthStartDate: monthStart,
            monthWorkoutsCount: 16,
            monthTotalMinutes: 800,
            monthTotalCalories: 3200,
            lastUpdatedAt: now
        )

        // When
        let sdModel = UserStatsMapper.toModel(domain)

        // Then
        XCTAssertEqual(sdModel.id, "current")
        XCTAssertEqual(sdModel.currentStreak, 5)
        XCTAssertEqual(sdModel.longestStreak, 20)
        XCTAssertEqual(sdModel.lastWorkoutDate, now)
        XCTAssertEqual(sdModel.weekStartDate, weekStart)
        XCTAssertEqual(sdModel.weekWorkoutsCount, 4)
        XCTAssertEqual(sdModel.weekTotalMinutes, 180)
        XCTAssertEqual(sdModel.weekTotalCalories, 720)
        XCTAssertEqual(sdModel.monthStartDate, monthStart)
        XCTAssertEqual(sdModel.monthWorkoutsCount, 16)
        XCTAssertEqual(sdModel.monthTotalMinutes, 800)
        XCTAssertEqual(sdModel.monthTotalCalories, 3200)
        XCTAssertEqual(sdModel.lastUpdatedAt, now)
    }

    func test_toModel_alwaysSetsIdToCurrent() {
        // Given
        let domain = UserStats.empty

        // When
        let sdModel = UserStatsMapper.toModel(domain)

        // Then
        XCTAssertEqual(sdModel.id, "current")
    }

    // MARK: - updateModel Tests

    func test_updateModel_updatesAllFields() {
        // Given
        let originalDate = Date().addingTimeInterval(-86400)
        let newDate = Date()

        let sdModel = SDUserStats(
            id: "current",
            currentStreak: 1,
            longestStreak: 1,
            lastWorkoutDate: originalDate,
            weekStartDate: originalDate.startOfWeek,
            weekWorkoutsCount: 1,
            weekTotalMinutes: 45,
            weekTotalCalories: 180,
            monthStartDate: originalDate.startOfMonth,
            monthWorkoutsCount: 1,
            monthTotalMinutes: 45,
            monthTotalCalories: 180,
            lastUpdatedAt: originalDate
        )

        let newStats = UserStats(
            currentStreak: 2,
            longestStreak: 5,
            lastWorkoutDate: newDate,
            weekStartDate: newDate.startOfWeek,
            weekWorkoutsCount: 2,
            weekTotalMinutes: 90,
            weekTotalCalories: 360,
            monthStartDate: newDate.startOfMonth,
            monthWorkoutsCount: 8,
            monthTotalMinutes: 400,
            monthTotalCalories: 1600,
            lastUpdatedAt: newDate
        )

        // When
        UserStatsMapper.updateModel(sdModel, with: newStats)

        // Then
        XCTAssertEqual(sdModel.currentStreak, 2)
        XCTAssertEqual(sdModel.longestStreak, 5)
        XCTAssertEqual(sdModel.lastWorkoutDate, newDate)
        XCTAssertEqual(sdModel.weekWorkoutsCount, 2)
        XCTAssertEqual(sdModel.weekTotalMinutes, 90)
        XCTAssertEqual(sdModel.weekTotalCalories, 360)
        XCTAssertEqual(sdModel.monthWorkoutsCount, 8)
        XCTAssertEqual(sdModel.monthTotalMinutes, 400)
        XCTAssertEqual(sdModel.monthTotalCalories, 1600)
        XCTAssertEqual(sdModel.lastUpdatedAt, newDate)
    }

    // MARK: - Round Trip Tests

    func test_roundTrip_preservesAllFields() {
        // Given
        let now = Date()
        let original = UserStats(
            currentStreak: 10,
            longestStreak: 30,
            lastWorkoutDate: now,
            weekStartDate: now.startOfWeek,
            weekWorkoutsCount: 5,
            weekTotalMinutes: 225,
            weekTotalCalories: 900,
            monthStartDate: now.startOfMonth,
            monthWorkoutsCount: 20,
            monthTotalMinutes: 1000,
            monthTotalCalories: 4000,
            lastUpdatedAt: now
        )

        // When
        let sdModel = UserStatsMapper.toModel(original)
        let restored = UserStatsMapper.toDomain(sdModel)

        // Then
        XCTAssertEqual(restored.currentStreak, original.currentStreak)
        XCTAssertEqual(restored.longestStreak, original.longestStreak)
        XCTAssertEqual(restored.lastWorkoutDate, original.lastWorkoutDate)
        XCTAssertEqual(restored.weekStartDate, original.weekStartDate)
        XCTAssertEqual(restored.weekWorkoutsCount, original.weekWorkoutsCount)
        XCTAssertEqual(restored.weekTotalMinutes, original.weekTotalMinutes)
        XCTAssertEqual(restored.weekTotalCalories, original.weekTotalCalories)
        XCTAssertEqual(restored.monthStartDate, original.monthStartDate)
        XCTAssertEqual(restored.monthWorkoutsCount, original.monthWorkoutsCount)
        XCTAssertEqual(restored.monthTotalMinutes, original.monthTotalMinutes)
        XCTAssertEqual(restored.monthTotalCalories, original.monthTotalCalories)
        XCTAssertEqual(restored.lastUpdatedAt, original.lastUpdatedAt)
    }
}
