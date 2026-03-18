//
//  BadgeTests.swift
//  FitTodayTests
//

import XCTest
@testable import FitToday

final class BadgeTests: XCTestCase {

    // MARK: - BadgeRarity

    func test_badgeRarity_colorsAreCorrect() {
        XCTAssertEqual(BadgeRarity.common.color, "#6B7280")
        XCTAssertEqual(BadgeRarity.rare.color, "#3B82F6")
        XCTAssertEqual(BadgeRarity.epic.color, "#8B5CF6")
        XCTAssertEqual(BadgeRarity.legendary.color, "#F59E0B")
    }

    func test_badgeRarity_sortOrder() {
        XCTAssertTrue(BadgeRarity.common < BadgeRarity.rare)
        XCTAssertTrue(BadgeRarity.rare < BadgeRarity.epic)
        XCTAssertTrue(BadgeRarity.epic < BadgeRarity.legendary)
    }

    // MARK: - BadgeType

    func test_badgeType_allCasesHas9Types() {
        XCTAssertEqual(BadgeType.allCases.count, 9)
    }

    func test_badgeType_defaultRarities() {
        XCTAssertEqual(BadgeType.firstWorkout.defaultRarity, .common)
        XCTAssertEqual(BadgeType.streak7.defaultRarity, .common)
        XCTAssertEqual(BadgeType.workouts50.defaultRarity, .rare)
        XCTAssertEqual(BadgeType.streak30.defaultRarity, .rare)
        XCTAssertEqual(BadgeType.earlyBird.defaultRarity, .rare)
        XCTAssertEqual(BadgeType.monthlyConsistency.defaultRarity, .rare)
        XCTAssertEqual(BadgeType.workouts100.defaultRarity, .epic)
        XCTAssertEqual(BadgeType.weekWarrior.defaultRarity, .epic)
        XCTAssertEqual(BadgeType.streak100.defaultRarity, .legendary)
    }

    func test_badgeType_eachHasIcon() {
        for type in BadgeType.allCases {
            XCTAssertFalse(type.icon.isEmpty, "\(type) should have an icon")
        }
    }

    // MARK: - Badge

    func test_badge_lockedIsNotUnlocked() {
        let badge = Badge.locked(type: .firstWorkout)
        XCTAssertFalse(badge.isUnlocked)
        XCTAssertNil(badge.unlockedAt)
    }

    func test_badge_unlockedHasDate() {
        let date = Date()
        let badge = Badge.unlocked(type: .workouts50, at: date)
        XCTAssertTrue(badge.isUnlocked)
        XCTAssertEqual(badge.unlockedAt, date)
    }

    func test_badge_idDefaultsToTypeRawValue() {
        let badge = Badge(type: .streak7)
        XCTAssertEqual(badge.id, "streak7")
    }

    func test_badge_rarityDefaultsToTypeDefault() {
        let badge = Badge(type: .streak100)
        XCTAssertEqual(badge.rarity, .legendary)
    }

    func test_badge_equatable() {
        let a = Badge.locked(type: .firstWorkout)
        let b = Badge.locked(type: .firstWorkout)
        XCTAssertEqual(a, b)
    }
}
