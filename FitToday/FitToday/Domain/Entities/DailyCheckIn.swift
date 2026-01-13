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
    case forearms
    case core
    case glutes
    case quads
    case quadriceps
    case hamstrings
    case calves
    case lats
    case lowerBack
    case cardioSystem
    case fullBody
}

struct DailyCheckIn: Codable, Hashable, Sendable {
    var focus: DailyFocus
    var sorenessLevel: MuscleSorenessLevel
    var sorenessAreas: [MuscleGroup]
    /// Energia percebida do usuário no dia (0–10)
    var energyLevel: Int
    var createdAt: Date

    init(
        focus: DailyFocus,
        sorenessLevel: MuscleSorenessLevel,
        sorenessAreas: [MuscleGroup] = [],
        energyLevel: Int = 5,
        createdAt: Date = .init()
    ) {
        self.focus = focus
        self.sorenessLevel = sorenessLevel
        self.sorenessAreas = sorenessAreas
        self.energyLevel = Self.clampEnergyLevel(energyLevel)
        self.createdAt = createdAt
    }
}

// MARK: - Codable Compatibility

extension DailyCheckIn {
    private enum CodingKeys: String, CodingKey {
        case focus
        case sorenessLevel
        case sorenessAreas
        case energyLevel
        case createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        focus = try container.decode(DailyFocus.self, forKey: .focus)
        sorenessLevel = try container.decode(MuscleSorenessLevel.self, forKey: .sorenessLevel)
        sorenessAreas = try container.decodeIfPresent([MuscleGroup].self, forKey: .sorenessAreas) ?? []
        
        // Backward compatible: check-ins antigos não tinham energyLevel
        let decodedEnergy = try container.decodeIfPresent(Int.self, forKey: .energyLevel) ?? 5
        energyLevel = Self.clampEnergyLevel(decodedEnergy)
        
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(focus, forKey: .focus)
        try container.encode(sorenessLevel, forKey: .sorenessLevel)
        try container.encode(sorenessAreas, forKey: .sorenessAreas)
        try container.encode(energyLevel, forKey: .energyLevel)
        try container.encode(createdAt, forKey: .createdAt)
    }
    
    private static func clampEnergyLevel(_ value: Int) -> Int {
        min(10, max(0, value))
    }
}