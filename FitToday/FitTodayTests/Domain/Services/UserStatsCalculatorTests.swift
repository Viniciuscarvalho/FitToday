//
//  UserStatsCalculatorTests.swift
//  FitTodayTests
//
//  Created by Claude on 20/01/26.
//

import XCTest
@testable import FitToday

final class UserStatsCalculatorTests: XCTestCase {

    private var sut: UserStatsCalculator!
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday
        sut = UserStatsCalculator(calendar: calendar)
    }

    override func tearDown() {
        sut = nil
        calendar = nil
        super.tearDown()
    }

    // MARK: - Streak Tests

    func testCalculateCurrentStreak_whenNoHistory_shouldReturnZero() {
        // Given
        let history: [WorkoutHistoryEntry] = []

        // When
        let streak = sut.calculateCurrentStreak(from: history)

        // Then
        XCTAssertEqual(streak, 0)
    }

    func testCalculateCurrentStreak_whenWorkoutToday_shouldReturnOne() {
        // Given
        let today = Date()
        let history = [makeEntry(date: today)]

        // When
        let streak = sut.calculateCurrentStreak(from: history)

        // Then
        XCTAssertEqual(streak, 1)
    }

    func testCalculateCurrentStreak_whenWorkoutYesterday_shouldReturnOne() {
        // Given
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        let history = [makeEntry(date: yesterday)]

        // When
        let streak = sut.calculateCurrentStreak(from: history)

        // Then
        XCTAssertEqual(streak, 1)
    }

    func testCalculateCurrentStreak_whenThreeConsecutiveDays_shouldReturnThree() {
        // Given
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        let history = [
            makeEntry(date: today),
            makeEntry(date: yesterday),
            makeEntry(date: twoDaysAgo)
        ]

        // When
        let streak = sut.calculateCurrentStreak(from: history)

        // Then
        XCTAssertEqual(streak, 3)
    }

    func testCalculateCurrentStreak_whenGapInHistory_shouldStopAtGap() {
        // Given - today, yesterday, skip a day, then 3 days ago
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today)!
        let history = [
            makeEntry(date: today),
            makeEntry(date: yesterday),
            makeEntry(date: threeDaysAgo) // Gap - 2 days ago missing
        ]

        // When
        let streak = sut.calculateCurrentStreak(from: history)

        // Then
        XCTAssertEqual(streak, 2) // Only today and yesterday count
    }

    func testCalculateCurrentStreak_whenLastWorkoutMoreThanOneDayAgo_shouldReturnZero() {
        // Given
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: Date())!
        let history = [makeEntry(date: twoDaysAgo)]

        // When
        let streak = sut.calculateCurrentStreak(from: history)

        // Then
        XCTAssertEqual(streak, 0)
    }

    func testCalculateCurrentStreak_whenMultipleWorkoutsSameDay_shouldCountAsOne() {
        // Given
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let history = [
            makeEntry(date: today),
            makeEntry(date: today.addingTimeInterval(-3600)), // Same day, 1 hour earlier
            makeEntry(date: yesterday)
        ]

        // When
        let streak = sut.calculateCurrentStreak(from: history)

        // Then
        XCTAssertEqual(streak, 2) // Today + yesterday
    }

    func testCalculateCurrentStreak_whenSkippedWorkoutsIncluded_shouldOnlyCountCompleted() {
        // Given
        let today = Date()
        let history = [
            makeEntry(date: today, status: .completed),
            makeEntry(date: today, status: .skipped) // Should be ignored
        ]

        // When
        let streak = sut.calculateCurrentStreak(from: history)

        // Then
        XCTAssertEqual(streak, 1)
    }

    // MARK: - Weekly Stats Tests

    func testCalculateWeeklyStats_whenNoHistory_shouldReturnEmpty() {
        // Given
        let history: [WorkoutHistoryEntry] = []

        // When
        let stats = sut.calculateWeeklyStats(from: history)

        // Then
        XCTAssertEqual(stats.workoutsCompleted, 0)
        XCTAssertEqual(stats.totalDurationMinutes, 0)
        XCTAssertEqual(stats.totalCaloriesBurned, 0)
        XCTAssertNil(stats.averageRating)
    }

    func testCalculateWeeklyStats_shouldAggregateCurrentWeek() {
        // Given
        let today = Date()
        let history = [
            makeEntry(date: today, duration: 45, calories: 300, userRating: .adequate),
            makeEntry(date: today.addingTimeInterval(-3600), duration: 30, calories: 200, userRating: .adequate)
        ]

        // When
        let stats = sut.calculateWeeklyStats(from: history)

        // Then
        XCTAssertEqual(stats.workoutsCompleted, 2)
        XCTAssertEqual(stats.totalDurationMinutes, 75)
        XCTAssertEqual(stats.totalCaloriesBurned, 500)
        XCTAssertEqual(stats.averageRating, 1.0) // All adequate = 100%
    }

    func testCalculateWeeklyStats_shouldExcludeEntriesFromPreviousWeek() {
        // Given
        let today = Date()
        let lastWeek = calendar.date(byAdding: .day, value: -8, to: today)!
        let history = [
            makeEntry(date: today, duration: 45),
            makeEntry(date: lastWeek, duration: 60) // Should be excluded
        ]

        // When
        let stats = sut.calculateWeeklyStats(from: history)

        // Then
        XCTAssertEqual(stats.workoutsCompleted, 1)
        XCTAssertEqual(stats.totalDurationMinutes, 45)
    }

    // MARK: - Monthly Stats Tests

    func testCalculateMonthlyStats_whenNoHistory_shouldReturnEmpty() {
        // Given
        let history: [WorkoutHistoryEntry] = []

        // When
        let stats = sut.calculateMonthlyStats(from: history)

        // Then
        XCTAssertEqual(stats.workoutsCompleted, 0)
        XCTAssertEqual(stats.totalDurationMinutes, 0)
        XCTAssertEqual(stats.totalCaloriesBurned, 0)
        XCTAssertNil(stats.averageRating)
    }

    func testCalculateMonthlyStats_shouldAggregateCurrentMonth() {
        // Given
        let today = Date()
        let history = [
            makeEntry(date: today, duration: 45, calories: 300),
            makeEntry(date: today.addingTimeInterval(-86400), duration: 30, calories: 200)
        ]

        // When
        let stats = sut.calculateMonthlyStats(from: history)

        // Then
        XCTAssertEqual(stats.workoutsCompleted, 2)
        XCTAssertEqual(stats.totalDurationMinutes, 75)
        XCTAssertEqual(stats.totalCaloriesBurned, 500)
    }

    // MARK: - Full Stats Computation Tests

    func testComputeStats_shouldTrackLongestStreak() {
        // Given
        let today = Date()
        let history = [makeEntry(date: today)]
        let previousStats = UserStats(
            currentStreak: 0,
            longestStreak: 5, // Previous longest
            lastWorkoutDate: nil,
            weekStartDate: today.startOfWeek,
            weekWorkoutsCount: 0,
            weekTotalMinutes: 0,
            weekTotalCalories: 0,
            monthStartDate: today.startOfMonth,
            monthWorkoutsCount: 0,
            monthTotalMinutes: 0,
            monthTotalCalories: 0,
            lastUpdatedAt: Date()
        )

        // When
        let stats = sut.computeStats(from: history, currentStats: previousStats)

        // Then
        XCTAssertEqual(stats.currentStreak, 1)
        XCTAssertEqual(stats.longestStreak, 5) // Previous longest preserved
    }

    func testComputeStats_shouldUpdateLongestStreakWhenNewRecordSet() {
        // Given
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        let history = [
            makeEntry(date: today),
            makeEntry(date: yesterday),
            makeEntry(date: twoDaysAgo)
        ]
        let previousStats = UserStats(
            currentStreak: 0,
            longestStreak: 2, // Previous longest
            lastWorkoutDate: nil,
            weekStartDate: today.startOfWeek,
            weekWorkoutsCount: 0,
            weekTotalMinutes: 0,
            weekTotalCalories: 0,
            monthStartDate: today.startOfMonth,
            monthWorkoutsCount: 0,
            monthTotalMinutes: 0,
            monthTotalCalories: 0,
            lastUpdatedAt: Date()
        )

        // When
        let stats = sut.computeStats(from: history, currentStats: previousStats)

        // Then
        XCTAssertEqual(stats.currentStreak, 3)
        XCTAssertEqual(stats.longestStreak, 3) // New record!
    }

    // MARK: - Helpers

    private func makeEntry(
        date: Date = Date(),
        status: WorkoutStatus = .completed,
        duration: Int? = nil,
        calories: Int? = nil,
        userRating: WorkoutRating? = nil
    ) -> WorkoutHistoryEntry {
        let plan: WorkoutPlan? = duration.map { dur in
            WorkoutPlan(
                title: "Test",
                focus: .fullBody,
                estimatedDurationMinutes: dur,
                intensity: .moderate,
                phases: []
            )
        }

        return WorkoutHistoryEntry(
            id: UUID(),
            date: date,
            planId: plan?.id ?? UUID(),
            title: plan?.title ?? "Test Workout",
            focus: .fullBody,
            status: status,
            durationMinutes: duration,
            caloriesBurned: calories,
            workoutPlan: plan,
            userRating: userRating
        )
    }
}

