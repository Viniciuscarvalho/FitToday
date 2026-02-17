//
//  PaywallTests.swift
//  FitTodayTests
//
//  Testes para o paywall otimizado.
//

import XCTest
@testable import FitToday

final class PaywallTests: XCTestCase {

    // MARK: - StoreKitService Tests

    @MainActor
    func testStoreKitServiceInitialState() {
        let service = StoreKitService()

        XCTAssertTrue(service.products.isEmpty)
        XCTAssertEqual(service.purchaseState, .idle)
        XCTAssertFalse(service.hasProAccess)
    }

    @MainActor
    func testStoreKitProductIDConstants() {
        XCTAssertEqual(StoreKitProductID.proLifetime, "com.fittoday.pro.lifetime")
        XCTAssertEqual(StoreKitProductID.allProducts.count, 1)
        XCTAssertTrue(StoreKitProductID.allProducts.contains(StoreKitProductID.proLifetime))
    }

    // MARK: - PurchaseState Tests

    func testPurchaseStateEquatable() {
        XCTAssertEqual(StoreKitService.PurchaseState.idle, .idle)
        XCTAssertEqual(StoreKitService.PurchaseState.loading, .loading)
        XCTAssertEqual(StoreKitService.PurchaseState.purchasing, .purchasing)
        XCTAssertEqual(StoreKitService.PurchaseState.success, .success)
        XCTAssertEqual(StoreKitService.PurchaseState.cancelled, .cancelled)

        // Failed states with same message should be equal
        XCTAssertEqual(
            StoreKitService.PurchaseState.failed("Error"),
            StoreKitService.PurchaseState.failed("Error")
        )

        // Failed states with different messages should not be equal
        XCTAssertNotEqual(
            StoreKitService.PurchaseState.failed("Error 1"),
            StoreKitService.PurchaseState.failed("Error 2")
        )
    }

    // MARK: - ProEntitlement Tests

    func testProEntitlementFree() {
        let entitlement = ProEntitlement.free

        XCTAssertFalse(entitlement.isPro)
        XCTAssertNil(entitlement.expirationDate)
    }

    func testProEntitlementLifetime() {
        let entitlement = ProEntitlement(
            isPro: true,
            source: .storeKit,
            expirationDate: nil
        )

        XCTAssertTrue(entitlement.isPro)
        XCTAssertEqual(entitlement.source, .storeKit)
        XCTAssertNil(entitlement.expirationDate)
    }

    // MARK: - ErrorMessage Tests

    func testErrorMessageCreation() {
        let errorMessage = ErrorMessage(
            title: "Erro",
            message: "Falha ao processar pagamento"
        )

        XCTAssertEqual(errorMessage.title, "Erro")
        XCTAssertEqual(errorMessage.message, "Falha ao processar pagamento")
        XCTAssertNil(errorMessage.action)
    }

    func testErrorMessageWithAction() {
        let errorMessage = ErrorMessage(
            title: "Erro",
            message: "Tente novamente",
            action: .retry({})
        )

        XCTAssertNotNil(errorMessage.action)
    }

    // MARK: - Feature Comparison Logic Tests

    func testFeatureAccessForFreeUser() {
        let freeEntitlement = ProEntitlement.free

        XCTAssertFalse(freeEntitlement.isPro)

        // Free user has 1 AI workout per week
        let aiResult0 = EntitlementPolicy.canAccess(.aiWorkoutGeneration, entitlement: freeEntitlement, usageCount: 0)
        XCTAssertTrue(aiResult0.isAllowed)

        let aiResult1 = EntitlementPolicy.canAccess(.aiWorkoutGeneration, entitlement: freeEntitlement, usageCount: 1)
        XCTAssertFalse(aiResult1.isAllowed)
    }

    func testFeatureAccessForProUser() {
        let proEntitlement = ProEntitlement(isPro: true, source: .storeKit, expirationDate: nil)

        XCTAssertTrue(proEntitlement.isPro)

        // Pro user has 2 AI workouts per day
        let aiResult0 = EntitlementPolicy.canAccess(.aiWorkoutGeneration, entitlement: proEntitlement, usageCount: 0)
        XCTAssertTrue(aiResult0.isAllowed)

        let aiResult1 = EntitlementPolicy.canAccess(.aiWorkoutGeneration, entitlement: proEntitlement, usageCount: 1)
        XCTAssertTrue(aiResult1.isAllowed)

        let aiResult2 = EntitlementPolicy.canAccess(.aiWorkoutGeneration, entitlement: proEntitlement, usageCount: 2)
        XCTAssertFalse(aiResult2.isAllowed)
    }
}
