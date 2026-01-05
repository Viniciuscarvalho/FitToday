//
//  WorkoutHistoryMapper.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import Foundation

struct WorkoutHistoryMapper {
    static func toDomain(_ model: SDWorkoutHistoryEntry) -> WorkoutHistoryEntry? {
        guard
            let focus = DailyFocus(rawValue: model.focusRaw),
            let status = WorkoutStatus(rawValue: model.statusRaw)
        else { return nil }

        return WorkoutHistoryEntry(
            id: model.id,
            date: model.date,
            planId: model.planId,
            title: model.title,
            focus: focus,
            status: status,
            programId: model.programId,
            programName: model.programName,
            durationMinutes: model.durationMinutes,
            caloriesBurned: model.caloriesBurned
        )
    }

    static func toModel(_ entry: WorkoutHistoryEntry) -> SDWorkoutHistoryEntry {
        SDWorkoutHistoryEntry(
            id: entry.id,
            date: entry.date,
            planId: entry.planId,
            title: entry.title,
            focusRaw: entry.focus.rawValue,
            statusRaw: entry.status.rawValue,
            programId: entry.programId,
            programName: entry.programName,
            durationMinutes: entry.durationMinutes,
            caloriesBurned: entry.caloriesBurned
        )
    }
}


