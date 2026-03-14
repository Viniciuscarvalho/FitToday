//
//  XPTransaction.swift
//  FitToday
//

import Foundation

enum XPTransactionType: String, Codable, Sendable {
    case workoutCompleted
    case streakBonus7
    case streakBonus30
    case challengeCompleted
}

struct XPTransaction: Codable, Sendable {
    let type: XPTransactionType
    let amount: Int
    let date: Date

    static func xpAmount(for type: XPTransactionType) -> Int {
        switch type {
        case .workoutCompleted: return 100
        case .streakBonus7: return 200
        case .streakBonus30: return 500
        case .challengeCompleted: return 500
        }
    }
}
