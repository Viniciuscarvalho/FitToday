//
//  HistoryModels.swift
//  FitToday
//
//  Created by AI on 03/01/26.
//

import Foundation

enum WorkoutStatus: String, Codable, CaseIterable, Sendable {
    case completed
    case skipped
}

struct WorkoutHistoryEntry: Codable, Hashable, Sendable, Identifiable {
    var id: UUID
    var date: Date
    var planId: UUID
    var title: String
    var focus: DailyFocus
    var status: WorkoutStatus

    init(
        id: UUID = .init(),
        date: Date = .init(),
        planId: UUID,
        title: String,
        focus: DailyFocus,
        status: WorkoutStatus
    ) {
        self.id = id
        self.date = date
        self.planId = planId
        self.title = title
        self.focus = focus
        self.status = status
    }
}

struct WorkoutSession: Codable, Hashable, Sendable {
    var id: UUID
    var plan: WorkoutPlan
    var startedAt: Date

    init(id: UUID = .init(), plan: WorkoutPlan, startedAt: Date = .init()) {
        self.id = id
        self.plan = plan
        self.startedAt = startedAt
    }
}


