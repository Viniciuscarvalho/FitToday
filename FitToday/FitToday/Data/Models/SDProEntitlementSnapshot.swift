//
//  SDProEntitlementSnapshot.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import Foundation
import SwiftData

@Model
final class SDProEntitlementSnapshot {
    @Attribute(.unique) var id: UUID
    var isPro: Bool
    var sourceRaw: String
    var expirationDate: Date?
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        isPro: Bool,
        sourceRaw: String,
        expirationDate: Date?,
        updatedAt: Date = .init()
    ) {
        self.id = id
        self.isPro = isPro
        self.sourceRaw = sourceRaw
        self.expirationDate = expirationDate
        self.updatedAt = updatedAt
    }
}




