//
//  OpenAIWorkoutResponse.swift
//  FitToday
//
//  Created by AI on 09/02/26.
//  Shared response models for OpenAI workout generation
//

import Foundation

/// Schema of the response expected from OpenAI for workout generation
/// Uses resilient decoding with fallbacks for missing fields
struct OpenAIWorkoutResponse: Codable, Sendable {
    let phases: [OpenAIPhaseResponse]
    let title: String?
    let notes: String?

    private enum CodingKeys: String, CodingKey {
        case phases, title, notes
    }

    init(phases: [OpenAIPhaseResponse], title: String? = nil, notes: String? = nil) {
        self.phases = phases
        self.title = title
        self.notes = notes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Fallback to empty array if phases is missing or malformed
        self.phases = (try? container.decode([OpenAIPhaseResponse].self, forKey: .phases)) ?? []
        self.title = try? container.decodeIfPresent(String.self, forKey: .title)
        self.notes = try? container.decodeIfPresent(String.self, forKey: .notes)
    }
}

struct OpenAIPhaseResponse: Codable, Sendable {
    let kind: String // "warmup", "strength", "accessory", "aerobic"
    let exercises: [OpenAIExerciseResponse]?
    let activity: OpenAIActivityResponse?

    private enum CodingKeys: String, CodingKey {
        case kind, exercises, activity
    }

    init(kind: String, exercises: [OpenAIExerciseResponse]? = nil, activity: OpenAIActivityResponse? = nil) {
        self.kind = kind
        self.exercises = exercises
        self.activity = activity
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Fallback to "strength" if kind is missing
        self.kind = (try? container.decode(String.self, forKey: .kind)) ?? "strength"
        self.exercises = try? container.decodeIfPresent([OpenAIExerciseResponse].self, forKey: .exercises)
        self.activity = try? container.decodeIfPresent(OpenAIActivityResponse.self, forKey: .activity)
    }
}

struct OpenAIExerciseResponse: Codable, Sendable {
    let name: String
    let muscleGroup: String
    let equipment: String
    let sets: Int
    let reps: String // "8-12" or "10"
    let restSeconds: Int
    let notes: String?

    private enum CodingKeys: String, CodingKey {
        case name, muscleGroup, equipment, sets, reps, restSeconds, notes
    }

    init(
        name: String,
        muscleGroup: String,
        equipment: String,
        sets: Int,
        reps: String,
        restSeconds: Int,
        notes: String? = nil
    ) {
        self.name = name
        self.muscleGroup = muscleGroup
        self.equipment = equipment
        self.sets = sets
        self.reps = reps
        self.restSeconds = restSeconds
        self.notes = notes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Required fields with sensible defaults
        self.name = (try? container.decode(String.self, forKey: .name)) ?? "Unknown Exercise"
        self.muscleGroup = (try? container.decode(String.self, forKey: .muscleGroup)) ?? "fullBody"
        self.equipment = (try? container.decode(String.self, forKey: .equipment)) ?? "bodyweight"
        self.sets = (try? container.decode(Int.self, forKey: .sets)) ?? 3
        self.reps = (try? container.decode(String.self, forKey: .reps)) ?? "10-12"
        self.restSeconds = (try? container.decode(Int.self, forKey: .restSeconds)) ?? 60
        self.notes = try? container.decodeIfPresent(String.self, forKey: .notes)
    }
}

struct OpenAIActivityResponse: Codable, Sendable {
    let kind: String // "mobility", "aerobicZone2", "aerobicIntervals", "breathing"
    let title: String
    let durationMinutes: Int
    let notes: String?

    private enum CodingKeys: String, CodingKey {
        case kind, title, durationMinutes, notes
    }

    init(kind: String, title: String, durationMinutes: Int, notes: String? = nil) {
        self.kind = kind
        self.title = title
        self.durationMinutes = durationMinutes
        self.notes = notes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Required fields with sensible defaults
        self.kind = (try? container.decode(String.self, forKey: .kind)) ?? "mobility"
        self.title = (try? container.decode(String.self, forKey: .title)) ?? "Activity"
        self.durationMinutes = (try? container.decode(Int.self, forKey: .durationMinutes)) ?? 5
        self.notes = try? container.decodeIfPresent(String.self, forKey: .notes)
    }
}
