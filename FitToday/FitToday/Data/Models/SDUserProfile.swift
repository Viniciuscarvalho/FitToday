//
//  SDUserProfile.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import Foundation
import SwiftData

@Model
final class SDUserProfile {
    @Attribute(.unique) var id: UUID
    var mainGoalRaw: String
    var availableStructureRaw: String
    var preferredMethodRaw: String
    var levelRaw: String
    var healthConditionsRaw: [String]
    var weeklyFrequency: Int
    var createdAt: Date

    init(
        id: UUID,
        mainGoalRaw: String,
        availableStructureRaw: String,
        preferredMethodRaw: String,
        levelRaw: String,
        healthConditionsRaw: [String],
        weeklyFrequency: Int,
        createdAt: Date
    ) {
        self.id = id
        self.mainGoalRaw = mainGoalRaw
        self.availableStructureRaw = availableStructureRaw
        self.preferredMethodRaw = preferredMethodRaw
        self.levelRaw = levelRaw
        self.healthConditionsRaw = healthConditionsRaw
        self.weeklyFrequency = weeklyFrequency
        self.createdAt = createdAt
    }
}


