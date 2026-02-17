//
//  StoreKitConstants.swift
//  FitToday
//

import Foundation

enum StoreKitProductID {
    /// One-time purchase (primary product)
    static let proLifetime = "com.fittoday.pro.lifetime"

    /// All product IDs that grant Pro access
    static let allProducts: Set<String> = [proLifetime]
}
