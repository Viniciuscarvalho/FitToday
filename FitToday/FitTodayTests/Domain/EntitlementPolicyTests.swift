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
    
    func testProUserHasAccessToAllFeatures() {
        let proEntitlement = ProEntitlement(
            isPro: true,
            source: .storeKit,
            expirationDate: Date().addingTimeInterval(86400 * 30)
        )
        
        for feature in ProFeature.allCases {
            let result = EntitlementPolicy.canAccess(feature, entitlement: proEntitlement)
            XCTAssertTrue(result.isAllowed, "Pro user should have access to \(feature)")
        }
    }
    
    func testTrialUserHasAccessToAllFeatures() {
        let trialEntitlement = ProEntitlement(
            isPro: true,
            source: .storeKit,
            expirationDate: Date().addingTimeInterval(86400 * 7) // 7 days trial
        )
        
        for feature in ProFeature.allCases {
            let result = EntitlementPolicy.canAccess(feature, entitlement: trialEntitlement)
            XCTAssertTrue(result.isAllowed, "Trial user should have access to \(feature)")
        }
    }
    
    func testExpiredTrialDoesNotHaveAccess() {
        let expiredTrialEntitlement = ProEntitlement(
            isPro: true,
            source: .storeKit,
            expirationDate: Date().addingTimeInterval(-86400) // Expired yesterday
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
        
        // First usage should be allowed
        let result1 = EntitlementPolicy.canAccess(.aiWorkoutGeneration, entitlement: freeEntitlement, usageCount: 0)
        XCTAssertTrue(result1.isAllowed)
        
        // After limit reached, should not be allowed
        let result2 = EntitlementPolicy.canAccess(.aiWorkoutGeneration, entitlement: freeEntitlement, usageCount: 1)
        if case .limitReached = result2 {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected limitReached result")
        }
    }
    
    func testFreeUserCannotAccessProOnlyFeatures() {
        let freeEntitlement = ProEntitlement.free
        
        let proOnlyFeatures: [ProFeature] = [
            .aiExerciseSubstitution,
            .unlimitedHistory,
            .advancedDOMSAdjustment,
            .premiumPrograms,
            .customizableSettings
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
        XCTAssertTrue(limitResult.message.contains("Upgrade"))
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
        // aiExerciseSubstitution, unlimitedHistory, advancedDOMSAdjustment, premiumPrograms, customizableSettings
        XCTAssertEqual(proOnlyFeatures.count, 5)
    }
    
    func testLimitedFreeFeaturesCount() {
        let limitedFeatures = EntitlementPolicy.limitedFreeFeatures
        // Only aiWorkoutGeneration has a limit for free users
        XCTAssertEqual(limitedFeatures.count, 1)
        XCTAssertEqual(limitedFeatures.first?.feature, .aiWorkoutGeneration)
        XCTAssertEqual(limitedFeatures.first?.limit, 1)
    }
    
    // MARK: - Weekly Limit Tests
    
    func testWeeklyLimitForFreeUser() {
        let freeEntitlement = ProEntitlement.free
        
        let limit = EntitlementPolicy.weeklyLimit(for: .aiWorkoutGeneration, entitlement: freeEntitlement)
        XCTAssertEqual(limit, 1)
    }
    
    func testWeeklyLimitForProUser() {
        let proEntitlement = ProEntitlement(isPro: true, source: .storeKit, expirationDate: nil)
        
        let limit = EntitlementPolicy.weeklyLimit(for: .aiWorkoutGeneration, entitlement: proEntitlement)
        XCTAssertNil(limit) // Pro has no limit
    }
    
    // MARK: - Convenience Extension Tests
    
    func testProEntitlementConvenienceExtension() {
        let proEntitlement = ProEntitlement(isPro: true, source: .storeKit, expirationDate: nil)
        
        XCTAssertTrue(proEntitlement.hasAccess(to: .aiWorkoutGeneration))
        XCTAssertTrue(proEntitlement.hasAccess(to: .aiExerciseSubstitution))
        XCTAssertTrue(proEntitlement.hasAccess(to: .unlimitedHistory))
    }
    
    func testFreeEntitlementConvenienceExtension() {
        let freeEntitlement = ProEntitlement.free
        
        XCTAssertTrue(freeEntitlement.hasAccess(to: .aiWorkoutGeneration)) // First use allowed
        XCTAssertFalse(freeEntitlement.hasAccess(to: .aiExerciseSubstitution))
        XCTAssertFalse(freeEntitlement.hasAccess(to: .unlimitedHistory))
    }
}

