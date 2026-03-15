//
//  RevenueCatEntitlementRepository.swift
//  FitToday
//

import Foundation
import RevenueCat

// MARK: - Provider Protocol (enables testing without Purchases singleton)

protocol RevenueCatProviding: Sendable {
    func customerInfo() async throws -> CustomerInfo
}

// MARK: - Production Provider

final class DefaultRevenueCatProvider: RevenueCatProviding {
    func customerInfo() async throws -> CustomerInfo {
        try await Purchases.shared.customerInfo()
    }
}

// MARK: - Repository

final class RevenueCatEntitlementRepository: EntitlementRepository {

    private let provider: RevenueCatProviding

    init(provider: RevenueCatProviding = DefaultRevenueCatProvider()) {
        self.provider = provider
    }

    func currentEntitlement() async throws -> ProEntitlement {
        let info = try await provider.customerInfo()
        return map(info)
    }

    func entitlementStream() -> AsyncStream<ProEntitlement> {
        AsyncStream { continuation in
            Task {
                while !Task.isCancelled {
                    if let info = try? await provider.customerInfo() {
                        continuation.yield(map(info))
                    }
                    try? await Task.sleep(for: .seconds(60))
                }
                continuation.finish()
            }
        }
    }

    // MARK: - Internal (visible for testing)

    func map(_ info: CustomerInfo) -> ProEntitlement {
        if info.entitlements["FitToday Elite"]?.isActive == true {
            return ProEntitlement(
                tier: .elite,
                source: .storeKit,
                expirationDate: info.entitlements["FitToday Elite"]?.expirationDate
            )
        }
        if info.entitlements["FitToday Pro"]?.isActive == true {
            return ProEntitlement(
                tier: .pro,
                source: .storeKit,
                expirationDate: info.entitlements["FitToday Pro"]?.expirationDate
            )
        }
        return .free
    }
}
