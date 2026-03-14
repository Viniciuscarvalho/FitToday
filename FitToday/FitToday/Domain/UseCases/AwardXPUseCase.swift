//
//  AwardXPUseCase.swift
//  FitToday
//

import Foundation

struct XPAwardResult: Sendable {
    let previousLevel: Int
    let newLevel: Int
    let xpAwarded: Int
    let totalXP: Int
    let didLevelUp: Bool
}

final class AwardXPUseCase: Sendable {
    private let xpRepository: XPRepository

    init(xpRepository: XPRepository) {
        self.xpRepository = xpRepository
    }

    func execute(type: XPTransactionType, currentStreak: Int) async throws -> XPAwardResult {
        let currentXP = try await xpRepository.getUserXP()
        let previousLevel = currentXP.level

        var totalAwarded = 0

        // Base XP for the action
        let baseAmount = XPTransaction.xpAmount(for: type)
        let baseTransaction = XPTransaction(type: type, amount: baseAmount, date: Date())
        _ = try await xpRepository.awardXP(transaction: baseTransaction)
        totalAwarded += baseAmount

        // Streak bonuses (only for workout completion)
        if type == .workoutCompleted {
            if currentStreak >= 30 {
                let bonus30 = XPTransaction(type: .streakBonus30, amount: XPTransaction.xpAmount(for: .streakBonus30), date: Date())
                _ = try await xpRepository.awardXP(transaction: bonus30)
                totalAwarded += bonus30.amount
            } else if currentStreak >= 7 {
                let bonus7 = XPTransaction(type: .streakBonus7, amount: XPTransaction.xpAmount(for: .streakBonus7), date: Date())
                _ = try await xpRepository.awardXP(transaction: bonus7)
                totalAwarded += bonus7.amount
            }
        }

        let updatedXP = try await xpRepository.getUserXP()
        let newLevel = updatedXP.level

        return XPAwardResult(
            previousLevel: previousLevel,
            newLevel: newLevel,
            xpAwarded: totalAwarded,
            totalXP: updatedXP.totalXP,
            didLevelUp: newLevel > previousLevel
        )
    }
}
