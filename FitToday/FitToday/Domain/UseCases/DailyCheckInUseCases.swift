//
//  DailyCheckInUseCases.swift
//  FitToday
//
//  Created by AI on 03/01/26.
//

import Foundation

struct BuildDailyCheckInUseCase {
    func execute(focus: DailyFocus, sorenessLevel: MuscleSorenessLevel, areas: [MuscleGroup]) throws -> DailyCheckIn {
        if sorenessLevel == .strong && areas.isEmpty {
            throw DomainError.invalidInput(reason: "Selecione ao menos uma área dolorida.")
        }
        return DailyCheckIn(focus: focus, sorenessLevel: sorenessLevel, sorenessAreas: areas)
    }
}



