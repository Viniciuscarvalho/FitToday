//
//  UserXP.swift
//  FitToday
//

import Foundation

struct UserXP: Codable, Sendable, Equatable {
    var totalXP: Int
    var lastAwardDate: Date?

    var level: Int { totalXP / 1000 + 1 }
    var currentLevelXP: Int { totalXP % 1000 }
    var xpToNextLevel: Int { 1000 - currentLevelXP }
    var levelProgress: Double { Double(currentLevelXP) / 1000.0 }
    var levelTitle: XPLevel { XPLevel(level: level) }

    static let empty = UserXP(totalXP: 0)
}
