//
//  StoreKitConstants.swift
//  FitToday
//

import Foundation

enum StoreKitProductID {
    // MARK: - Pro Tier
    static let proMonthly = "com.fittoday.pro.monthly"
    static let proAnnual = "com.fittoday.pro.annual"

    // MARK: - Elite Tier
    static let eliteMonthly = "com.fittoday.elite.monthly"
    static let eliteAnnual = "com.fittoday.elite.annual"

    // MARK: - Sets
    static let proProducts: Set<String> = [proMonthly, proAnnual]
    static let eliteProducts: Set<String> = [eliteMonthly, eliteAnnual]
    static let allProducts: Set<String> = proProducts.union(eliteProducts)

    // MARK: - Tier Resolution
    static func tier(for productID: String) -> SubscriptionTier {
        if eliteProducts.contains(productID) { return .elite }
        if proProducts.contains(productID) { return .pro }
        return .free
    }

    static func isAnnual(_ productID: String) -> Bool {
        productID == proAnnual || productID == eliteAnnual
    }
}
