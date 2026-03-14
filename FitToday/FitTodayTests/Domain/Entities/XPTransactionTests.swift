//
//  XPTransactionTests.swift
//  FitTodayTests
//

import XCTest
@testable import FitToday

final class XPTransactionTests: XCTestCase {

    func test_xpAmount_workoutCompleted() {
        XCTAssertEqual(XPTransaction.xpAmount(for: .workoutCompleted), 100)
    }

    func test_xpAmount_streakBonus7() {
        XCTAssertEqual(XPTransaction.xpAmount(for: .streakBonus7), 200)
    }

    func test_xpAmount_streakBonus30() {
        XCTAssertEqual(XPTransaction.xpAmount(for: .streakBonus30), 500)
    }

    func test_xpAmount_challengeCompleted() {
        XCTAssertEqual(XPTransaction.xpAmount(for: .challengeCompleted), 500)
    }
}
