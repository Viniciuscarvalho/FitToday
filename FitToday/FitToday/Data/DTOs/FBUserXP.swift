//
//  FBUserXP.swift
//  FitToday
//

import Foundation

struct FBUserXP: Codable, Sendable {
    var totalXP: Int
    var lastAwardDate: Date?
    var level: Int
}
