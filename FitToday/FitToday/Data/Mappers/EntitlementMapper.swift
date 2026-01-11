//
//  EntitlementMapper.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import Foundation

struct EntitlementMapper {
    static func toDomain(_ snapshot: SDProEntitlementSnapshot) -> ProEntitlement {
        ProEntitlement(
            isPro: snapshot.isPro,
            source: EntitlementSource(rawValue: snapshot.sourceRaw) ?? .none,
            expirationDate: snapshot.expirationDate
        )
    }

    static func toSnapshot(_ entitlement: ProEntitlement) -> SDProEntitlementSnapshot {
        SDProEntitlementSnapshot(
            isPro: entitlement.isPro,
            sourceRaw: entitlement.source.rawValue,
            expirationDate: entitlement.expirationDate
        )
    }
}



