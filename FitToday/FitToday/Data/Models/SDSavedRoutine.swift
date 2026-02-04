//
//  SDSavedRoutine.swift
//  FitToday
//
//  SwiftData model for persisting saved routines.
//

import Foundation
import SwiftData

@Model
final class SDSavedRoutine {
    @Attribute(.unique) var id: UUID
    var programId: String
    var name: String
    var subtitle: String
    var goalTagRaw: String
    var levelRaw: String
    var equipmentRaw: String
    var workoutCount: Int
    var sessionsPerWeek: Int
    var durationWeeks: Int
    var savedAt: Date

    init(
        id: UUID,
        programId: String,
        name: String,
        subtitle: String,
        goalTagRaw: String,
        levelRaw: String,
        equipmentRaw: String,
        workoutCount: Int,
        sessionsPerWeek: Int,
        durationWeeks: Int,
        savedAt: Date
    ) {
        self.id = id
        self.programId = programId
        self.name = name
        self.subtitle = subtitle
        self.goalTagRaw = goalTagRaw
        self.levelRaw = levelRaw
        self.equipmentRaw = equipmentRaw
        self.workoutCount = workoutCount
        self.sessionsPerWeek = sessionsPerWeek
        self.durationWeeks = durationWeeks
        self.savedAt = savedAt
    }

    /// Creates a SwiftData model from a domain entity.
    convenience init(from routine: SavedRoutine) {
        self.init(
            id: routine.id,
            programId: routine.programId,
            name: routine.name,
            subtitle: routine.subtitle,
            goalTagRaw: routine.goalTag.rawValue,
            levelRaw: routine.level.rawValue,
            equipmentRaw: routine.equipment.rawValue,
            workoutCount: routine.workoutCount,
            sessionsPerWeek: routine.sessionsPerWeek,
            durationWeeks: routine.durationWeeks,
            savedAt: routine.savedAt
        )
    }

    /// Converts to domain entity.
    func toDomain() -> SavedRoutine {
        SavedRoutine(
            id: id,
            programId: programId,
            name: name,
            subtitle: subtitle,
            goalTag: ProgramGoalTag(rawValue: goalTagRaw) ?? .strength,
            level: ProgramLevel(rawValue: levelRaw) ?? .beginner,
            equipment: ProgramEquipment(rawValue: equipmentRaw) ?? .gym,
            workoutCount: workoutCount,
            sessionsPerWeek: sessionsPerWeek,
            durationWeeks: durationWeeks,
            savedAt: savedAt
        )
    }
}
