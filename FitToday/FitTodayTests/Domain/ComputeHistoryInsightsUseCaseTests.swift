//
//  ComputeHistoryInsightsUseCaseTests.swift
//  FitTodayTests
//
//  Created by AI on 12/01/26.
//

import XCTest
@testable import FitToday

final class ComputeHistoryInsightsUseCaseTests: XCTestCase {
    func testCurrentStreakCountsConsecutiveDaysEndingTodayOrYesterday() {
        let cal = Calendar(identifier: .iso8601)
        let now = Date()
        let today = cal.startOfDay(for: now)
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = cal.date(byAdding: .day, value: -2, to: today)!
        
        let useCase = ComputeHistoryInsightsUseCase(calendar: cal, now: { now })
        
        let entries: [WorkoutHistoryEntry] = [
            .init(date: today, planId: UUID(), title: "A", focus: .upper, status: .completed, durationMinutes: 30),
            .init(date: yesterday, planId: UUID(), title: "B", focus: .upper, status: .completed, durationMinutes: 25),
            .init(date: twoDaysAgo, planId: UUID(), title: "C", focus: .upper, status: .completed, durationMinutes: 20)
        ]
        
        let insights = useCase.execute(entries: entries)
        XCTAssertEqual(insights.currentStreak, 3)
        XCTAssertGreaterThanOrEqual(insights.bestStreak, 3)
    }
    
    func testWeeklyBucketsAreStableCount() {
        let cal = Calendar(identifier: .iso8601)
        let now = Date()
        let useCase = ComputeHistoryInsightsUseCase(calendar: cal, now: { now })
        
        let insights = useCase.execute(entries: [])
        XCTAssertEqual(insights.weekly.count, 8)
    }
}

