//
//  Hashing.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import CryptoKit
import Foundation

enum Hashing {
    static func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}




