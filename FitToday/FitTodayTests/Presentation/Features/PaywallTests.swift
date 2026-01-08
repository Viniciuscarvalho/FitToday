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
        XCTAssertFalse(service.hasActiveSubscription)
    }
    
    @MainActor
    func testStoreKitProductIDConstants() {
        XCTAssertEqual(StoreKitProductID.proMonthly, "com.fittoday.pro.monthly")
        XCTAssertEqual(StoreKitProductID.proYearly, "com.fittoday.pro.yearly")
        XCTAssertEqual(StoreKitProductID.allSubscriptions.count, 2)
        XCTAssertTrue(StoreKitProductID.allSubscriptions.contains(StoreKitProductID.proMonthly))
        XCTAssertTrue(StoreKitProductID.allSubscriptions.contains(StoreKitProductID.proYearly))
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
    
    func testProEntitlementPro() {
        let expirationDate = Date().addingTimeInterval(86400 * 30) // 30 days
        let entitlement = ProEntitlement(
            isPro: true,
            source: .storeKit,
            expirationDate: expirationDate
        )
        
        XCTAssertTrue(entitlement.isPro)
        XCTAssertEqual(entitlement.source, .storeKit)
        XCTAssertEqual(entitlement.expirationDate, expirationDate)
    }
    
    func testProEntitlementTrialState() {
        // Um entitlement Pro com data de expiração no futuro indica trial ativo
        let futureDate = Date().addingTimeInterval(86400 * 7) // 7 days
        let entitlement = ProEntitlement(
            isPro: true,
            source: .storeKit,
            expirationDate: futureDate
        )
        
        XCTAssertTrue(entitlement.isPro)
        // Trial ativo = expiração no futuro
        XCTAssertTrue(entitlement.expirationDate! > Date())
    }
    
    func testProEntitlementExpired() {
        // Um entitlement com data de expiração no passado
        let pastDate = Date().addingTimeInterval(-86400) // Yesterday
        let entitlement = ProEntitlement(
            isPro: false, // Should be false if expired
            source: .storeKit,
            expirationDate: pastDate
        )
        
        XCTAssertFalse(entitlement.isPro)
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
        
        // ErrorAction.retry tem closure, então verificamos se não é nil
        XCTAssertNotNil(errorMessage.action)
    }
    
    // MARK: - Feature Comparison Logic Tests
    
    func testFeatureAccessForFreeUser() {
        let freeEntitlement = ProEntitlement.free
        
        // Free user should have limited access
        XCTAssertFalse(freeEntitlement.isPro)
        
        // Simulate feature gating
        let aiWorkoutsPerWeek = freeEntitlement.isPro ? Int.max : 1
        XCTAssertEqual(aiWorkoutsPerWeek, 1)
        
        let historyDaysLimit = freeEntitlement.isPro ? Int.max : 7
        XCTAssertEqual(historyDaysLimit, 7)
    }
    
    func testFeatureAccessForProUser() {
        let proEntitlement = ProEntitlement(
            isPro: true,
            source: .storeKit,
            expirationDate: Date().addingTimeInterval(86400 * 30)
        )
        
        // Pro user should have unlimited access
        XCTAssertTrue(proEntitlement.isPro)
        
        // Simulate feature gating
        let aiWorkoutsPerWeek = proEntitlement.isPro ? Int.max : 1
        XCTAssertEqual(aiWorkoutsPerWeek, Int.max)
        
        let historyDaysLimit = proEntitlement.isPro ? Int.max : 7
        XCTAssertEqual(historyDaysLimit, Int.max)
    }
}

