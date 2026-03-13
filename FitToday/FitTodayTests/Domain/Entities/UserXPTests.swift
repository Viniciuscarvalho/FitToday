//
//  UserXPTests.swift
//  FitTodayTests
//

import XCTest
@testable import FitToday

final class UserXPTests: XCTestCase {

    func test_level_calculatesCorrectly() {
        XCTAssertEqual(UserXP(totalXP: 0).level, 1)
        XCTAssertEqual(UserXP(totalXP: 999).level, 1)
        XCTAssertEqual(UserXP(totalXP: 1000).level, 2)
        XCTAssertEqual(UserXP(totalXP: 4999).level, 5)
        XCTAssertEqual(UserXP(totalXP: 19000).level, 20)
    }

    func test_currentLevelXP_returnsRemainder() {
        XCTAssertEqual(UserXP(totalXP: 0).currentLevelXP, 0)
        XCTAssertEqual(UserXP(totalXP: 750).currentLevelXP, 750)
        XCTAssertEqual(UserXP(totalXP: 1500).currentLevelXP, 500)
    }

    func test_xpToNextLevel_calculatesCorrectly() {
        XCTAssertEqual(UserXP(totalXP: 0).xpToNextLevel, 1000)
        XCTAssertEqual(UserXP(totalXP: 750).xpToNextLevel, 250)
        XCTAssertEqual(UserXP(totalXP: 1000).xpToNextLevel, 1000)
    }

    func test_levelProgress_returnsPercentage() {
        XCTAssertEqual(UserXP(totalXP: 0).levelProgress, 0.0)
        XCTAssertEqual(UserXP(totalXP: 500).levelProgress, 0.5)
        XCTAssertEqual(UserXP(totalXP: 750).levelProgress, 0.75)
    }

    func test_levelTitle_mapsCorrectly() {
        XCTAssertEqual(UserXP(totalXP: 0).levelTitle, .iniciante)       // level 1
        XCTAssertEqual(UserXP(totalXP: 4000).levelTitle, .guerreiro)    // level 5
        XCTAssertEqual(UserXP(totalXP: 9000).levelTitle, .tita)         // level 10
        XCTAssertEqual(UserXP(totalXP: 14000).levelTitle, .lenda)       // level 15
        XCTAssertEqual(UserXP(totalXP: 19000).levelTitle, .imortal)     // level 20
    }

    func test_empty_returnsZeroXP() {
        let empty = UserXP.empty
        XCTAssertEqual(empty.totalXP, 0)
        XCTAssertNil(empty.lastAwardDate)
        XCTAssertEqual(empty.level, 1)
    }
}
