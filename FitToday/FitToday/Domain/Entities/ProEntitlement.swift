//
//  ProEntitlement.swift
//  FitToday
//
//  Created by AI on 03/01/26.
//

import Foundation

enum EntitlementSource: String, Codable, Sendable {
    case none
    case storeKit
    case promo
    case enterprise
}

struct ProEntitlement: Codable, Hashable, Sendable {
    var isPro: Bool
    var source: EntitlementSource
    var expirationDate: Date?

    static let free = ProEntitlement(isPro: false, source: .none, expirationDate: nil)
}




