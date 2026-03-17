//
//  RevenueCatEntitlementRepository.swift
//  FitToday
//

import Foundation
import RevenueCat

// MARK: - Entitlement Snapshot (testable, no RevenueCat dependency)

struct RCEntitlementSnapshot: Sendable {
    struct EntitlementInfo: Sendable {
        let isActive: Bool
        let expirationDate: Date?
    }

    let entitlements: [String: EntitlementInfo]

    init(from customerInfo: CustomerInfo) {
        entitlements = customerInfo.entitlements.all.mapValues {
            EntitlementInfo(isActive: $0.isActive, expirationDate: $0.expirationDate)
        }
    }

    // For testing
    init(entitlements: [String: EntitlementInfo]) {
        self.entitlements = entitlements
    }
}

// MARK: - Provider Protocol

protocol RevenueCatProviding: Sendable {
    func customerInfo() async throws -> RCEntitlementSnapshot
}

// MARK: - Production Provider

final class DefaultRevenueCatProvider: RevenueCatProviding, @unchecked Sendable {
    func customerInfo() async throws -> RCEntitlementSnapshot {
        let info = try await Purchases.shared.customerInfo()
        return RCEntitlementSnapshot(from: info)
    }
}

// MARK: - Repository

final class RevenueCatEntitlementRepository: EntitlementRepository, @unchecked Sendable {

    private let provider: RevenueCatProviding

    init(provider: RevenueCatProviding = DefaultRevenueCatProvider()) {
        self.provider = provider
    }

    func currentEntitlement() async throws -> ProEntitlement {
        let snapshot = try await provider.customerInfo()
        return map(snapshot)
    }

    func entitlementStream() -> AsyncStream<ProEntitlement> {
        AsyncStream { continuation in
            let task = Task {
                while !Task.isCancelled {
                    if let snapshot = try? await provider.customerInfo() {
                        continuation.yield(map(snapshot))
                    }
                    try? await Task.sleep(for: .seconds(60))
                }
                continuation.finish()
            }
            continuation.onTermination = { @Sendable _ in task.cancel() }
        }
    }

    // MARK: - Mapping (internal for testing)

    func map(_ snapshot: RCEntitlementSnapshot) -> ProEntitlement {
        if snapshot.entitlements["FitToday Elite"]?.isActive == true {
            return ProEntitlement(
                tier: .elite,
                source: .storeKit,
                expirationDate: snapshot.entitlements["FitToday Elite"]?.expirationDate
            )
        }
        if snapshot.entitlements["FitToday Pro"]?.isActive == true {
            return ProEntitlement(
                tier: .pro,
                source: .storeKit,
                expirationDate: snapshot.entitlements["FitToday Pro"]?.expirationDate
            )
        }
        return .free
    }
}
