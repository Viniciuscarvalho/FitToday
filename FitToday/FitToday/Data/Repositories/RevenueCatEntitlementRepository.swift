//
//  RevenueCatEntitlementRepository.swift
//  FitToday
//

import Foundation
import RevenueCat

final class RevenueCatEntitlementRepository: EntitlementRepository {

    func currentEntitlement() async throws -> ProEntitlement {
        let info = try await Purchases.shared.customerInfo()
        return map(info)
    }

    func entitlementStream() -> AsyncStream<ProEntitlement> {
        AsyncStream { continuation in
            Task {
                while !Task.isCancelled {
                    if let info = try? await Purchases.shared.customerInfo() {
                        continuation.yield(map(info))
                    }
                    try? await Task.sleep(for: .seconds(60))
                }
                continuation.finish()
            }
        }
    }

    // MARK: - Private

    private func map(_ info: CustomerInfo) -> ProEntitlement {
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
