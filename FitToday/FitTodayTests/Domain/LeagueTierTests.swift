//
//  LeagueTierTests.swift
//  FitTodayTests
//

import XCTest
@testable import FitToday

final class LeagueTierTests: XCTestCase {

    // MARK: - Raw Values

    func test_allTiersExist_withCorrectRawValues() {
        XCTAssertEqual(LeagueTier.bronze.rawValue, "bronze")
        XCTAssertEqual(LeagueTier.silver.rawValue, "silver")
        XCTAssertEqual(LeagueTier.gold.rawValue, "gold")
        XCTAssertEqual(LeagueTier.diamond.rawValue, "diamond")
        XCTAssertEqual(LeagueTier.legend.rawValue, "legend")
    }

    func test_allCases_containsFiveTiers() {
        XCTAssertEqual(LeagueTier.allCases.count, 5)
    }

    // MARK: - Comparable Ordering

    func test_bronze_isLessThanSilver() {
        XCTAssertTrue(LeagueTier.bronze < .silver)
    }

    func test_silver_isLessThanGold() {
        XCTAssertTrue(LeagueTier.silver < .gold)
    }

    func test_gold_isLessThanDiamond() {
        XCTAssertTrue(LeagueTier.gold < .diamond)
    }

    func test_diamond_isLessThanLegend() {
        XCTAssertTrue(LeagueTier.diamond < .legend)
    }

    func test_legend_isNotLessThanBronze() {
        XCTAssertFalse(LeagueTier.legend < .bronze)
    }

    func test_allTiers_sortedAscending_matchesExpectedOrder() {
        let sorted = [LeagueTier.legend, .bronze, .diamond, .silver, .gold].sorted()
        XCTAssertEqual(sorted, [.bronze, .silver, .gold, .diamond, .legend])
    }

    // MARK: - Display Name

    func test_displayName_isNotEmpty_forAllTiers() {
        for tier in LeagueTier.allCases {
            XCTAssertFalse(tier.displayName.isEmpty, "\(tier.rawValue) displayName should not be empty")
        }
    }

    // MARK: - Icon

    func test_icon_returnsValidSFSymbolName_forAllTiers() {
        let expectedIcons: [LeagueTier: String] = [
            .bronze: "shield",
            .silver: "shield.fill",
            .gold: "star.circle.fill",
            .diamond: "diamond.fill",
            .legend: "crown.fill"
        ]

        for (tier, expectedIcon) in expectedIcons {
            XCTAssertEqual(tier.icon, expectedIcon, "\(tier.rawValue) icon mismatch")
        }
    }

    func test_icon_isNotEmpty_forAllTiers() {
        for tier in LeagueTier.allCases {
            XCTAssertFalse(tier.icon.isEmpty, "\(tier.rawValue) icon should not be empty")
        }
    }

    // MARK: - Required Tier

    func test_bronze_requiresFreeTier() {
        XCTAssertEqual(LeagueTier.bronze.requiredTier, .free)
    }

    func test_silver_requiresProTier() {
        XCTAssertEqual(LeagueTier.silver.requiredTier, .pro)
    }

    func test_gold_requiresProTier() {
        XCTAssertEqual(LeagueTier.gold.requiredTier, .pro)
    }

    func test_diamond_requiresProTier() {
        XCTAssertEqual(LeagueTier.diamond.requiredTier, .pro)
    }

    func test_legend_requiresEliteTier() {
        XCTAssertEqual(LeagueTier.legend.requiredTier, .elite)
    }

    // MARK: - Sort Order

    func test_sortOrder_isMonotonicallyIncreasing() {
        let orders = LeagueTier.allCases.map(\.sortOrder)
        for i in 0..<orders.count - 1 {
            XCTAssertLessThan(orders[i], orders[i + 1])
        }
    }

    // MARK: - Color

    func test_color_isNotEmpty_forAllTiers() {
        for tier in LeagueTier.allCases {
            XCTAssertFalse(tier.color.isEmpty, "\(tier.rawValue) color should not be empty")
        }
    }
}
