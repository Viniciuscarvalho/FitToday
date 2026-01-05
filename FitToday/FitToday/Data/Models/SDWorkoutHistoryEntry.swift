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

    init(
        id: UUID,
        date: Date,
        planId: UUID,
        title: String,
        focusRaw: String,
        statusRaw: String
    ) {
        self.id = id
        self.date = date
        self.planId = planId
        self.title = title
        self.focusRaw = focusRaw
        self.statusRaw = statusRaw
    }
}


