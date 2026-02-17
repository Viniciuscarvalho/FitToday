//
//  EntitlementPolicyTests.swift
//  FitTodayTests
//
//  Testes para a política de acesso a features.
//

import XCTest
@testable import FitToday

final class EntitlementPolicyTests: XCTestCase {

    // MARK: - Pro Access Tests

    func testProUserHasAccessToNonLimitedFeatures() {
        let proEntitlement = ProEntitlement(isPro: true, source: .storeKit, expirationDate: nil)

        let nonLimitedFeatures = ProFeature.allCases.filter { $0 != .aiWorkoutGeneration }
        for feature in nonLimitedFeatures {
            let result = EntitlementPolicy.canAccess(feature, entitlement: proEntitlement)
            XCTAssertTrue(result.isAllowed, "Pro user should have access to \(feature)")
        }
    }

    func testProUserAIDailyLimit() {
        let proEntitlement = ProEntitlement(isPro: true, source: .storeKit, expirationDate: nil)

        // Under limit
        let result0 = EntitlementPolicy.canAccess(.aiWorkoutGeneration, entitlement: proEntitlement, usageCount: 0)
        XCTAssertTrue(result0.isAllowed)

        let result1 = EntitlementPolicy.canAccess(.aiWorkoutGeneration, entitlement: proEntitlement, usageCount: 1)
        XCTAssertTrue(result1.isAllowed)

        // At limit
        let result2 = EntitlementPolicy.canAccess(.aiWorkoutGeneration, entitlement: proEntitlement, usageCount: 2)
        if case .limitReached(let remaining, let limit) = result2 {
            XCTAssertEqual(remaining, 0)
            XCTAssertEqual(limit, 2)
        } else {
            XCTFail("Expected limitReached result for Pro at daily limit")
        }
    }

    func testExpiredTrialDoesNotHaveAccess() {
        let expiredTrialEntitlement = ProEntitlement(
            isPro: true,
            source: .storeKit,
            expirationDate: Date().addingTimeInterval(-86400)
        )

        let result = EntitlementPolicy.canAccess(.aiWorkoutGeneration, entitlement: expiredTrialEntitlement)

        if case .trialExpired = result {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected trialExpired result")
        }
    }

    // MARK: - Free User Tests

    func testFreeUserHasLimitedAIAccess() {
        let freeEntitlement = ProEntitlement.free

        let result1 = EntitlementPolicy.canAccess(.aiWorkoutGeneration, entitlement: freeEntitlement, usageCount: 0)
        XCTAssertTrue(result1.isAllowed)

        let result2 = EntitlementPolicy.canAccess(.aiWorkoutGeneration, entitlement: freeEntitlement, usageCount: 1)
        if case .limitReached = result2 {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected limitReached result")
        }
    }

    func testFreeUserHasLimitedChallengeAccess() {
        let freeEntitlement = ProEntitlement.free

        // Under limit
        let result4 = EntitlementPolicy.canAccess(.simultaneousChallenges, entitlement: freeEntitlement, usageCount: 4)
        XCTAssertTrue(result4.isAllowed)

        // At limit
        let result5 = EntitlementPolicy.canAccess(.simultaneousChallenges, entitlement: freeEntitlement, usageCount: 5)
        if case .limitReached(let remaining, let limit) = result5 {
            XCTAssertEqual(remaining, 0)
            XCTAssertEqual(limit, 5)
        } else {
            XCTFail("Expected limitReached for challenges at limit")
        }
    }

    func testProUserHasUnlimitedChallenges() {
        let proEntitlement = ProEntitlement(isPro: true, source: .storeKit, expirationDate: nil)

        let result = EntitlementPolicy.canAccess(.simultaneousChallenges, entitlement: proEntitlement, usageCount: 100)
        XCTAssertTrue(result.isAllowed)
    }

    func testFreeUserCannotAccessProOnlyFeatures() {
        let freeEntitlement = ProEntitlement.free

        let proOnlyFeatures: [ProFeature] = [
            .aiExerciseSubstitution,
            .unlimitedHistory,
            .advancedDOMSAdjustment,
            .premiumPrograms,
            .customizableSettings,
            .personalTrainer,
            .trainerWorkouts
        ]

        for feature in proOnlyFeatures {
            let result = EntitlementPolicy.canAccess(feature, entitlement: freeEntitlement)
            if case .requiresPro = result {
                XCTAssertTrue(true)
            } else {
                XCTFail("Free user should not have access to \(feature)")
            }
        }
    }

    // MARK: - Feature Access Result Tests

    func testFeatureAccessResultIsAllowed() {
        let allowedResult = FeatureAccessResult.allowed
        XCTAssertTrue(allowedResult.isAllowed)
        XCTAssertEqual(allowedResult.message, "")
    }

    func testFeatureAccessResultLimitReached() {
        let limitResult = FeatureAccessResult.limitReached(remaining: 0, limit: 1)
        XCTAssertFalse(limitResult.isAllowed)
        XCTAssertTrue(limitResult.message.contains("Pro"))
    }

    func testFeatureAccessResultRequiresPro() {
        let proResult = FeatureAccessResult.requiresPro(feature: .aiExerciseSubstitution)
        XCTAssertFalse(proResult.isAllowed)
        XCTAssertTrue(proResult.message.contains("Pro"))
    }

    func testFeatureAccessResultTrialExpired() {
        let expiredResult = FeatureAccessResult.trialExpired
        XCTAssertFalse(expiredResult.isAllowed)
        XCTAssertTrue(expiredResult.message.contains("período de teste"))
    }

    // MARK: - ProFeature Tests

    func testAllFeaturesHaveDisplayName() {
        for feature in ProFeature.allCases {
            XCTAssertFalse(feature.displayName.isEmpty)
        }
    }

    func testProOnlyFeaturesCount() {
        let proOnlyFeatures = EntitlementPolicy.proOnlyFeatures
        // aiExerciseSubstitution, unlimitedHistory, advancedDOMSAdjustment, premiumPrograms, customizableSettings, personalTrainer, trainerWorkouts
        XCTAssertEqual(proOnlyFeatures.count, 7)
    }

    func testLimitedFreeFeaturesCount() {
        let limitedFeatures = EntitlementPolicy.limitedFreeFeatures
        // aiWorkoutGeneration and simultaneousChallenges
        XCTAssertEqual(limitedFeatures.count, 2)
    }

    // MARK: - Usage Limit Tests

    func testUsageLimitForFreeAI() {
        let freeEntitlement = ProEntitlement.free

        let limit = EntitlementPolicy.usageLimit(for: .aiWorkoutGeneration, entitlement: freeEntitlement)
        XCTAssertNotNil(limit)
        XCTAssertEqual(limit?.limit, 1)
        XCTAssertEqual(limit?.period, "semana")
    }

    func testUsageLimitForProAI() {
        let proEntitlement = ProEntitlement(isPro: true, source: .storeKit, expirationDate: nil)

        let limit = EntitlementPolicy.usageLimit(for: .aiWorkoutGeneration, entitlement: proEntitlement)
        XCTAssertNotNil(limit)
        XCTAssertEqual(limit?.limit, 2)
        XCTAssertEqual(limit?.period, "dia")
    }

    func testUsageLimitForFreeChallenges() {
        let freeEntitlement = ProEntitlement.free

        let limit = EntitlementPolicy.usageLimit(for: .simultaneousChallenges, entitlement: freeEntitlement)
        XCTAssertNotNil(limit)
        XCTAssertEqual(limit?.limit, 5)
    }

    func testUsageLimitForProChallenges() {
        let proEntitlement = ProEntitlement(isPro: true, source: .storeKit, expirationDate: nil)

        let limit = EntitlementPolicy.usageLimit(for: .simultaneousChallenges, entitlement: proEntitlement)
        XCTAssertNil(limit) // Unlimited
    }

    // MARK: - Convenience Extension Tests

    func testProEntitlementConvenienceExtension() {
        let proEntitlement = ProEntitlement(isPro: true, source: .storeKit, expirationDate: nil)

        XCTAssertTrue(proEntitlement.hasAccess(to: .aiWorkoutGeneration))
        XCTAssertTrue(proEntitlement.hasAccess(to: .aiExerciseSubstitution))
        XCTAssertTrue(proEntitlement.hasAccess(to: .unlimitedHistory))
        XCTAssertTrue(proEntitlement.hasAccess(to: .simultaneousChallenges))
    }

    func testFreeEntitlementConvenienceExtension() {
        let freeEntitlement = ProEntitlement.free

        XCTAssertTrue(freeEntitlement.hasAccess(to: .aiWorkoutGeneration)) // First use allowed
        XCTAssertFalse(freeEntitlement.hasAccess(to: .aiExerciseSubstitution))
        XCTAssertFalse(freeEntitlement.hasAccess(to: .unlimitedHistory))
        XCTAssertTrue(freeEntitlement.hasAccess(to: .simultaneousChallenges)) // Under limit
    }
}
