//
//  WorkoutPlanComposer.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import Foundation

protocol WorkoutPlanComposing {
    func composePlan(
        blocks: [WorkoutBlock],
        profile: UserProfile,
        checkIn: DailyCheckIn
    ) async throws -> WorkoutPlan
}

