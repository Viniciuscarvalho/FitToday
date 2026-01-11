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
            #if DEBUG
            if storage[key] != nil {
                print("[OpenAICache] ⏰ Entrada expirada para key: \(key.prefix(20))...")
            }
            #endif
            return nil
        }
        #if DEBUG
        let remaining = entry.expiry.timeIntervalSince(Date())
        print("[OpenAICache] ✅ HIT: key=\(key.prefix(20))... TTL=\(Int(remaining))s")
        #endif
        return entry.payload
    }

    func insert(_ data: Data, for key: String) {
        storage[key] = CachedEntry(payload: data, expiry: Date().addingTimeInterval(ttl))
        #if DEBUG
        print("[OpenAICache] 💾 Salvando: key=\(key.prefix(20))... TTL=\(Int(ttl))s")
        #endif
    }
    
    /// Limpa todo o cache (DEBUG)
    func clearAll() {
        let count = storage.count
        storage.removeAll()
        #if DEBUG
        print("[OpenAICache] 🗑️ Cache limpo: \(count) entradas removidas")
        #endif
    }
}




