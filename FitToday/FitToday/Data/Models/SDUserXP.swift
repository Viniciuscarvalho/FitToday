//
//  SDUserXP.swift
//  FitToday
//

import Foundation
import SwiftData

@Model
final class SDUserXP {
    @Attribute(.unique) var id: String
    var totalXP: Int
    var lastAwardDate: Date?

    init(totalXP: Int = 0) {
        self.id = "current"
        self.totalXP = totalXP
    }

    func toDomain() -> UserXP {
        UserXP(totalXP: totalXP, lastAwardDate: lastAwardDate)
    }
}
