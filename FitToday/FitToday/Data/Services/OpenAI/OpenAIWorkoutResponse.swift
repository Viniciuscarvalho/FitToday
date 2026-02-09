//
//  OpenAIWorkoutResponse.swift
//  FitToday
//
//  Created by AI on 09/02/26.
//  Shared response models for OpenAI workout generation
//

import Foundation

/// Schema of the response expected from OpenAI for workout generation
struct OpenAIWorkoutResponse: Codable, Sendable {
    let phases: [OpenAIPhaseResponse]
    let title: String?
    let notes: String?
}

struct OpenAIPhaseResponse: Codable, Sendable {
    let kind: String // "warmup", "strength", "accessory", "aerobic"
    let exercises: [OpenAIExerciseResponse]?
    let activity: OpenAIActivityResponse?
}

struct OpenAIExerciseResponse: Codable, Sendable {
    let name: String
    let muscleGroup: String
    let equipment: String
    let sets: Int
    let reps: String // "8-12" or "10"
    let restSeconds: Int
    let notes: String?
}

struct OpenAIActivityResponse: Codable, Sendable {
    let kind: String // "mobility", "aerobicZone2", "aerobicIntervals", "breathing"
    let title: String
    let durationMinutes: Int
    let notes: String?
}
