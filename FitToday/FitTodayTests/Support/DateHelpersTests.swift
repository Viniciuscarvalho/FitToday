//
//  DateHelpersTests.swift
//  FitTodayTests
//
//  Created by Claude on 18/01/26.
//

import XCTest
@testable import FitToday

final class DateHelpersTests: XCTestCase {

    // MARK: - startOfWeek Tests

    func test_startOfWeek_returnsMonday() {
        // Given - A Wednesday
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 15  // Wednesday, January 15, 2026
        let wednesday = calendar.date(from: components)!

        // When
        let weekStart = wednesday.startOfWeek

        // Then - Should be Monday, January 13, 2026
        let weekStartComponents = calendar.dateComponents([.year, .month, .day, .weekday], from: weekStart)
        XCTAssertEqual(weekStartComponents.year, 2026)
        XCTAssertEqual(weekStartComponents.month, 1)
        XCTAssertEqual(weekStartComponents.day, 13)
        XCTAssertEqual(weekStartComponents.weekday, 2) // Monday = 2
    }

    func test_startOfWeek_onMonday_returnsSameDay() {
        // Given - A Monday
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 13  // Monday
        let monday = calendar.date(from: components)!

        // When
        let weekStart = monday.startOfWeek

        // Then - Should be the same Monday
        let weekStartComponents = calendar.dateComponents([.year, .month, .day], from: weekStart)
        XCTAssertEqual(weekStartComponents.day, 13)
    }

    func test_startOfWeek_onSunday_returnsPreviousMonday() {
        // Given - A Sunday
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 19  // Sunday, January 19, 2026
        let sunday = calendar.date(from: components)!

        // When
        let weekStart = sunday.startOfWeek

        // Then - Should be Monday, January 13, 2026
        let weekStartComponents = calendar.dateComponents([.year, .month, .day], from: weekStart)
        XCTAssertEqual(weekStartComponents.day, 13)
    }

    // MARK: - startOfMonth Tests

    func test_startOfMonth_returnsFirstDay() {
        // Given - A mid-month date
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 18
        let midMonth = calendar.date(from: components)!

        // When
        let monthStart = midMonth.startOfMonth

        // Then - Should be January 1, 2026
        let monthStartComponents = calendar.dateComponents([.year, .month, .day], from: monthStart)
        XCTAssertEqual(monthStartComponents.year, 2026)
        XCTAssertEqual(monthStartComponents.month, 1)
        XCTAssertEqual(monthStartComponents.day, 1)
    }

    func test_startOfMonth_onFirstDay_returnsSameDay() {
        // Given - First day of month
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 1
        let firstDay = calendar.date(from: components)!

        // When
        let monthStart = firstDay.startOfMonth

        // Then - Should be the same date
        let monthStartComponents = calendar.dateComponents([.year, .month, .day], from: monthStart)
        XCTAssertEqual(monthStartComponents.day, 1)
    }

    // MARK: - startOfDay Tests

    func test_startOfDay_returnsStartOfDay() {
        // Given - A date with time
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 18
        components.hour = 14
        components.minute = 30
        let dateWithTime = calendar.date(from: components)!

        // When
        let dayStart = dateWithTime.startOfDay

        // Then - Should be same day at 00:00
        let dayStartComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: dayStart)
        XCTAssertEqual(dayStartComponents.year, 2026)
        XCTAssertEqual(dayStartComponents.month, 1)
        XCTAssertEqual(dayStartComponents.day, 18)
        XCTAssertEqual(dayStartComponents.hour, 0)
        XCTAssertEqual(dayStartComponents.minute, 0)
    }

    // MARK: - isSameDay Tests

    func test_isSameDay_sameDay_returnsTrue() {
        // Given
        let calendar = Calendar.current
        var components1 = DateComponents()
        components1.year = 2026
        components1.month = 1
        components1.day = 18
        components1.hour = 10
        let date1 = calendar.date(from: components1)!

        var components2 = DateComponents()
        components2.year = 2026
        components2.month = 1
        components2.day = 18
        components2.hour = 22
        let date2 = calendar.date(from: components2)!

        // Then
        XCTAssertTrue(date1.isSameDay(as: date2))
    }

    func test_isSameDay_differentDay_returnsFalse() {
        // Given
        let calendar = Calendar.current
        var components1 = DateComponents()
        components1.year = 2026
        components1.month = 1
        components1.day = 18
        let date1 = calendar.date(from: components1)!

        var components2 = DateComponents()
        components2.year = 2026
        components2.month = 1
        components2.day = 19
        let date2 = calendar.date(from: components2)!

        // Then
        XCTAssertFalse(date1.isSameDay(as: date2))
    }

    // MARK: - isYesterday Tests

    func test_isYesterday_yesterday_returnsTrue() {
        // Given
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        // Then
        XCTAssertTrue(yesterday.isYesterday(relativeTo: today))
    }

    func test_isYesterday_twoDaysAgo_returnsFalse() {
        // Given
        let calendar = Calendar.current
        let today = Date()
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!

        // Then
        XCTAssertFalse(twoDaysAgo.isYesterday(relativeTo: today))
    }

    // MARK: - daysBetween Tests

    func test_daysBetween_sameDayReturnsZero() {
        // Given
        let date = Date()

        // Then
        XCTAssertEqual(date.daysBetween(date), 0)
    }

    func test_daysBetween_differentDays() {
        // Given
        let calendar = Calendar.current
        var components1 = DateComponents()
        components1.year = 2026
        components1.month = 1
        components1.day = 10
        let date1 = calendar.date(from: components1)!

        var components2 = DateComponents()
        components2.year = 2026
        components2.month = 1
        components2.day = 18
        let date2 = calendar.date(from: components2)!

        // Then
        XCTAssertEqual(date1.daysBetween(date2), 8)
    }
}
