//
//  OpenAIResponseCache.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import Foundation

actor OpenAIResponseCache {
    struct CachedEntry {
        let payload: Data
        let expiry: Date
    }

    private var storage: [String: CachedEntry] = [:]
    private let ttl: TimeInterval

    init(ttl: TimeInterval) {
        self.ttl = ttl
    }

    func value(for key: String) -> Data? {
        guard let entry = storage[key], entry.expiry > Date() else {
            storage.removeValue(forKey: key)
            return nil
        }
        return entry.payload
    }

    func insert(_ data: Data, for key: String) {
        storage[key] = CachedEntry(payload: data, expiry: Date().addingTimeInterval(ttl))
    }
}



