//
//  DailyCheckIn.swift
//  FitToday
//
//  Created by AI on 03/01/26.
//

import Foundation

enum DailyFocus: String, Codable, CaseIterable, Sendable {
    case fullBody
    case upper
    case lower
    case cardio
    case core
    case surprise
}

enum MuscleSorenessLevel: String, Codable, CaseIterable, Sendable {
    case none
    case light
    case moderate
    case strong
}

enum MuscleGroup: String, Codable, CaseIterable, Sendable {
    case chest
    case back
    case shoulders
    case arms
    case biceps
    case triceps
    case core
    case glutes
    case quads
    case quadriceps
    case hamstrings
    case calves
    case cardioSystem
    case fullBody
}

struct DailyCheckIn: Codable, Hashable, Sendable {
    var focus: DailyFocus
    var sorenessLevel: MuscleSorenessLevel
    var sorenessAreas: [MuscleGroup]
    var createdAt: Date

    init(
        focus: DailyFocus,
        sorenessLevel: MuscleSorenessLevel,
        sorenessAreas: [MuscleGroup] = [],
        createdAt: Date = .init()
    ) {
        self.focus = focus
        self.sorenessLevel = sorenessLevel
        self.sorenessAreas = sorenessAreas
        self.createdAt = createdAt
    }
}

