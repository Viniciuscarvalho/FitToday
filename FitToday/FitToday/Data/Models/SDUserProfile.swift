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
    
    /// Indica se perfil foi preenchido completamente.
    /// Usa Optional para permitir migração de dados existentes sem valor.
    private var _isProfileComplete: Bool?
    
    /// Getter/Setter que trata nil como true (dados existentes assumem perfil completo)
    var isProfileComplete: Bool {
        get { _isProfileComplete ?? true }
        set { _isProfileComplete = newValue }
    }

    init(
        id: UUID,
        mainGoalRaw: String,
        availableStructureRaw: String,
        preferredMethodRaw: String,
        levelRaw: String,
        healthConditionsRaw: [String],
        weeklyFrequency: Int,
        createdAt: Date,
        isProfileComplete: Bool = true
    ) {
        self.id = id
        self.mainGoalRaw = mainGoalRaw
        self.availableStructureRaw = availableStructureRaw
        self.preferredMethodRaw = preferredMethodRaw
        self.levelRaw = levelRaw
        self.healthConditionsRaw = healthConditionsRaw
        self.weeklyFrequency = weeklyFrequency
        self.createdAt = createdAt
        self._isProfileComplete = isProfileComplete
    }
}


