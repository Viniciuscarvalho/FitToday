//
//  RevenueCatEntitlementRepositoryTests.swift
//  FitTodayTests
//

import XCTest
@testable import FitToday

final class RevenueCatEntitlementRepositoryTests: XCTestCase {

    // MARK: - currentEntitlement

    func test_currentEntitlement_whenNoActiveEntitlements_returnsFree() async throws {
        let sut = makeSUT(snapshot: .empty)

        let result = try await sut.currentEntitlement()

        XCTAssertEqual(result.tier, .free)
        XCTAssertFalse(result.isPro)
    }

    func test_currentEntitlement_whenProActive_returnsPro() async throws {
        let sut = makeSUT(snapshot: .proActive())

        let result = try await sut.currentEntitlement()

        XCTAssertEqual(result.tier, .pro)
        XCTAssertTrue(result.isPro)
        XCTAssertFalse(result.isElite)
        XCTAssertEqual(result.source, .storeKit)
    }

    func test_currentEntitlement_whenEliteActive_returnsElite() async throws {
        let sut = makeSUT(snapshot: .eliteActive())

        let result = try await sut.currentEntitlement()

        XCTAssertEqual(result.tier, .elite)
        XCTAssertTrue(result.isElite)
        XCTAssertEqual(result.source, .storeKit)
    }

    func test_currentEntitlement_whenBothActive_returnsElite() async throws {
        let sut = makeSUT(snapshot: .bothActive())

        let result = try await sut.currentEntitlement()

        XCTAssertEqual(result.tier, .elite)
    }

    func test_currentEntitlement_whenProInactive_returnsFree() async throws {
        let sut = makeSUT(snapshot: .proInactive())

        let result = try await sut.currentEntitlement()

        XCTAssertEqual(result.tier, .free)
    }

    func test_currentEntitlement_propagatesProviderError() async {
        let sut = makeSUT(shouldThrow: true)

        do {
            _ = try await sut.currentEntitlement()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    func test_currentEntitlement_preservesExpirationDate() async throws {
        let expiry = Date(timeIntervalSince1970: 9_999_999)
        let sut = makeSUT(snapshot: .proActive(expirationDate: expiry))

        let result = try await sut.currentEntitlement()

        XCTAssertEqual(result.expirationDate, expiry)
    }

    // MARK: - Mapping

    func test_map_emptySnapshot_returnsFree() {
        let sut = makeSUT(snapshot: .empty)

        XCTAssertEqual(sut.map(.empty).tier, .free)
    }

    func test_map_proSnapshot_returnsPro() {
        let sut = makeSUT(snapshot: .empty)

        XCTAssertEqual(sut.map(.proActive()).tier, .pro)
    }

    func test_map_eliteSnapshot_returnsElite() {
        let sut = makeSUT(snapshot: .empty)

        XCTAssertEqual(sut.map(.eliteActive()).tier, .elite)
    }

    func test_map_eliteTakesPrecedenceOverPro() {
        let sut = makeSUT(snapshot: .empty)

        XCTAssertEqual(sut.map(.bothActive()).tier, .elite)
    }

    // MARK: - entitlementStream

    func test_entitlementStream_emitsCurrentValue() async {
        let sut = makeSUT(snapshot: .proActive())
        var received: [ProEntitlement] = []

        for await value in sut.entitlementStream() {
            received.append(value)
            break // take first emission only
        }

        XCTAssertEqual(received.count, 1)
        XCTAssertEqual(received.first?.tier, .pro)
    }

    func test_entitlementStream_whenProviderThrows_emitsNothing() async {
        let sut = makeSUT(shouldThrow: true)
        var received: [ProEntitlement] = []

        let stream = sut.entitlementStream()
        let task = Task {
            for await value in stream {
                received.append(value)
            }
        }

        // Give stream a chance to emit
        try? await Task.sleep(for: .milliseconds(100))
        task.cancel()

        XCTAssertTrue(received.isEmpty)
    }
}

// MARK: - Factory

private extension RevenueCatEntitlementRepositoryTests {

    func makeSUT(
        snapshot: RCEntitlementSnapshot = .empty,
        shouldThrow: Bool = false
    ) -> RevenueCatEntitlementRepository {
        let provider = MockRevenueCatProvider(snapshot: snapshot, shouldThrow: shouldThrow)
        return RevenueCatEntitlementRepository(provider: provider)
    }
}

// MARK: - Mock Provider

private final class MockRevenueCatProvider: RevenueCatProviding {
    private let snapshot: RCEntitlementSnapshot
    private let shouldThrow: Bool

    init(snapshot: RCEntitlementSnapshot, shouldThrow: Bool) {
        self.snapshot = snapshot
        self.shouldThrow = shouldThrow
    }

    func customerInfo() async throws -> RCEntitlementSnapshot {
        if shouldThrow { throw URLError(.notConnectedToInternet) }
        return snapshot
    }
}

// MARK: - RCEntitlementSnapshot Test Fixtures

private extension RCEntitlementSnapshot {

    static let empty = RCEntitlementSnapshot(entitlements: [:])

    static func proActive(expirationDate: Date? = nil) -> RCEntitlementSnapshot {
        RCEntitlementSnapshot(entitlements: [
            "FitToday Pro": .init(isActive: true, expirationDate: expirationDate)
        ])
    }

    static func proInactive() -> RCEntitlementSnapshot {
        RCEntitlementSnapshot(entitlements: [
            "FitToday Pro": .init(isActive: false, expirationDate: nil)
        ])
    }

    static func eliteActive() -> RCEntitlementSnapshot {
        RCEntitlementSnapshot(entitlements: [
            "FitToday Elite": .init(isActive: true, expirationDate: nil)
        ])
    }

    static func bothActive() -> RCEntitlementSnapshot {
        RCEntitlementSnapshot(entitlements: [
            "FitToday Pro": .init(isActive: true, expirationDate: nil),
            "FitToday Elite": .init(isActive: true, expirationDate: nil)
        ])
    }
}
