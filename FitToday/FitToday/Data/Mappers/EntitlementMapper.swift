//
//  EntitlementMapper.swift
//  FitToday
//

import Foundation

struct EntitlementMapper {
    static func toDomain(_ snapshot: SDProEntitlementSnapshot) -> ProEntitlement {
        // Prefer tierRaw (subscriptions); fall back to isPro for migrated records
        let tier: SubscriptionTier
        if let parsed = SubscriptionTier(rawValue: snapshot.tierRaw) {
            tier = parsed
        } else {
            tier = snapshot.isPro ? .pro : .free
        }
        return ProEntitlement(
            tier: tier,
            source: EntitlementSource(rawValue: snapshot.sourceRaw) ?? .none,
            expirationDate: snapshot.expirationDate
        )
    }

    static func toSnapshot(_ entitlement: ProEntitlement) -> SDProEntitlementSnapshot {
        SDProEntitlementSnapshot(
            isPro: entitlement.isPro,
            tierRaw: entitlement.tier.rawValue,
            sourceRaw: entitlement.source.rawValue,
            expirationDate: entitlement.expirationDate
        )
    }
}
