//
//  XPRepository.swift
//  FitToday
//

import Foundation

protocol XPRepository: Sendable {
    func getUserXP() async throws -> UserXP
    func awardXP(transaction: XPTransaction) async throws -> UserXP
    func syncFromRemote() async throws
}
