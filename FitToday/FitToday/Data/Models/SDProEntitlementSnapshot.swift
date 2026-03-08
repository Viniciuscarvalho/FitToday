//
//  SDProEntitlementSnapshot.swift
//  FitToday
//

import Foundation
import SwiftData

@Model
final class SDProEntitlementSnapshot {
    @Attribute(.unique) var id: UUID
    var isPro: Bool          // kept for lightweight migration compatibility
    var tierRaw: String      // SubscriptionTier.rawValue
    var sourceRaw: String
    var expirationDate: Date?
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        isPro: Bool,
        tierRaw: String = SubscriptionTier.free.rawValue,
        sourceRaw: String,
        expirationDate: Date?,
        updatedAt: Date = .init()
    ) {
        self.id = id
        self.isPro = isPro
        self.tierRaw = tierRaw
        self.sourceRaw = sourceRaw
        self.expirationDate = expirationDate
        self.updatedAt = updatedAt
    }
}
