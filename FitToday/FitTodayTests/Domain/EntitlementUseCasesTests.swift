//
//  EntitlementUseCasesTests.swift
//  FitTodayTests
//
//  Created by AI on 15/01/26.
//

import XCTest
@testable import FitToday

// 💡 Learn: Testes para os UseCases de entitlement (monetização)
// Validam recuperação e observação do status Pro do usuário
final class EntitlementUseCasesTests: XCTestCase {

    func testGetProEntitlement_whenUserIsPro_returnsPro() async throws {
        // Given
        let proEntitlement = ProEntitlement(isPro: true, source: .storeKit, expirationDate: nil)
        let mockRepo = MockEntitlementRepository(entitlement: proEntitlement)
        let sut = GetProEntitlementUseCase(repository: mockRepo)

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertTrue(result.isPro)
        XCTAssertTrue(mockRepo.currentEntitlementCalled)
    }

    func testGetProEntitlement_whenUserIsFree_returnsFree() async throws {
        // Given
        let mockRepo = MockEntitlementRepository(entitlement: .free)
        let sut = GetProEntitlementUseCase(repository: mockRepo)

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertFalse(result.isPro)
        XCTAssertTrue(mockRepo.currentEntitlementCalled)
    }

    func testObserveEntitlement_receivesStreamOfChanges() async {
        // Given
        let freeEntitlement = ProEntitlement.free
        let mockRepo = MockEntitlementRepository(entitlement: freeEntitlement)
        let sut = GetProEntitlementUseCase(repository: mockRepo)

        // When
        let stream = sut.observe()
        var receivedValues: [ProEntitlement] = []

        for await value in stream {
            receivedValues.append(value)
            if receivedValues.count >= 2 {
                break
            }
        }

        // Then
        XCTAssertEqual(receivedValues.count, 2)
        XCTAssertFalse(receivedValues[0].isPro) // First value is free
        XCTAssertTrue(receivedValues[1].isPro)  // Second value is pro
    }
}

// MARK: - Mock Repository

private final class MockEntitlementRepository: EntitlementRepository, @unchecked Sendable {
    var entitlement: ProEntitlement
    var currentEntitlementCalled = false

    init(entitlement: ProEntitlement) {
        self.entitlement = entitlement
    }

    func currentEntitlement() async throws -> ProEntitlement {
        currentEntitlementCalled = true
        return entitlement
    }

    func entitlementStream() -> AsyncStream<ProEntitlement> {
        AsyncStream { continuation in
            continuation.yield(ProEntitlement.free)
            continuation.yield(ProEntitlement(isPro: true, source: .storeKit, expirationDate: nil))
            continuation.finish()
        }
    }
}
