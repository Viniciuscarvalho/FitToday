//
//  SavedRoutine.swift
//  FitToday
//
//  Represents a user-saved routine (program saved for quick access).
//  Users can save up to 5 routines in "Minhas Rotinas" section.
//

import Foundation

/// A saved routine represents a program that the user has saved for quick access.
/// Users can save up to 5 routines in the "Minhas Rotinas" section.
public struct SavedRoutine: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public let programId: String
    public let name: String
    public let subtitle: String
    public let goalTag: ProgramGoalTag
    public let level: ProgramLevel
    public let equipment: ProgramEquipment
    public let workoutCount: Int
    public let sessionsPerWeek: Int
    public let durationWeeks: Int
    public let savedAt: Date

    /// Maximum number of routines a user can save.
    public static let maxSavedRoutines = 5

    public init(
        id: UUID = UUID(),
        programId: String,
        name: String,
        subtitle: String,
        goalTag: ProgramGoalTag,
        level: ProgramLevel,
        equipment: ProgramEquipment,
        workoutCount: Int,
        sessionsPerWeek: Int,
        durationWeeks: Int,
        savedAt: Date = Date()
    ) {
        self.id = id
        self.programId = programId
        self.name = name
        self.subtitle = subtitle
        self.goalTag = goalTag
        self.level = level
        self.equipment = equipment
        self.workoutCount = workoutCount
        self.sessionsPerWeek = sessionsPerWeek
        self.durationWeeks = durationWeeks
        self.savedAt = savedAt
    }

    /// Creates a SavedRoutine from a Program entity.
    public init(from program: Program) {
        self.id = UUID()
        self.programId = program.id
        self.name = program.name
        self.subtitle = program.subtitle
        self.goalTag = program.goalTag
        self.level = program.level
        self.equipment = program.equipment
        self.workoutCount = program.totalWorkouts
        self.sessionsPerWeek = program.sessionsPerWeek
        self.durationWeeks = program.durationWeeks
        self.savedAt = Date()
    }
}

// MARK: - Display Helpers

extension SavedRoutine {
    /// Duration description for display.
    public var durationDescription: String {
        if durationWeeks == 1 {
            return "1 semana"
        }
        return "\(durationWeeks) semanas"
    }

    /// Sessions description for display.
    public var sessionsDescription: String {
        "\(sessionsPerWeek)x por semana"
    }

    /// Formatted saved date for display.
    public var savedAtFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: savedAt, relativeTo: Date())
    }
}

// MARK: - Errors

/// Errors related to SavedRoutine operations.
public enum SavedRoutineError: LocalizedError, Sendable {
    case limitReached
    case alreadySaved
    case notFound

    public var errorDescription: String? {
        switch self {
        case .limitReached:
            return String(localized: "routine.error.limit_reached")
        case .alreadySaved:
            return String(localized: "routine.error.already_saved")
        case .notFound:
            return String(localized: "routine.error.not_found")
        }
    }
}
