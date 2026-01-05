//
//  SDWorkoutHistoryEntry.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import Foundation
import SwiftData

@Model
final class SDWorkoutHistoryEntry {
    @Attribute(.unique) var id: UUID
    var date: Date
    var planId: UUID
    var title: String
    var focusRaw: String
    var statusRaw: String
    
    // Novos campos para evolução e vínculo com programa
    var programId: String?
    var programName: String?
    var durationMinutes: Int?
    var caloriesBurned: Int?

    init(
        id: UUID,
        date: Date,
        planId: UUID,
        title: String,
        focusRaw: String,
        statusRaw: String,
        programId: String? = nil,
        programName: String? = nil,
        durationMinutes: Int? = nil,
        caloriesBurned: Int? = nil
    ) {
        self.id = id
        self.date = date
        self.planId = planId
        self.title = title
        self.focusRaw = focusRaw
        self.statusRaw = statusRaw
        self.programId = programId
        self.programName = programName
        self.durationMinutes = durationMinutes
        self.caloriesBurned = caloriesBurned
    }
}


