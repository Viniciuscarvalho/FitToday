//
//  WorkoutModels.swift
//  FitToday
//
//  Created by AI on 03/01/26.
//

import Foundation

enum EquipmentType: String, Codable, CaseIterable, Sendable {
    case barbell
    case dumbbell
    case machine
    case kettlebell
    case bodyweight
    case resistanceBand
    case cardioMachine
    case cable
    case pullupBar
}

struct ExerciseMedia: Codable, Hashable, Sendable {
    var imageURL: URL?
    var gifURL: URL?
    var source: String? // e.g. "ExerciseDB"

    public init(imageURL: URL?, gifURL: URL?, source: String? = nil) {
        self.imageURL = imageURL
        self.gifURL = gifURL
        self.source = source
    }
}

struct WorkoutExercise: Codable, Hashable, Sendable {
    var id: String
    var name: String
    var mainMuscle: MuscleGroup
    var equipment: EquipmentType
    var instructions: [String]
    var media: ExerciseMedia?
}

struct WorkoutBlock: Codable, Hashable, Sendable {
    var id: String
    var group: DailyFocus
    var level: TrainingLevel
    var compatibleStructures: [TrainingStructure]
    var equipmentOptions: [EquipmentType]
    var exercises: [WorkoutExercise]
    var suggestedSets: IntRange
    var suggestedReps: IntRange
    var restInterval: TimeInterval

    func matches(profile: UserProfile, checkIn: DailyCheckIn, soreMuscles: Set<MuscleGroup> = []) -> Bool {
        guard compatibleStructures.contains(profile.availableStructure) else { return false }
        guard levelCompatibility(profileLevel: profile.level) else { return false }

        if checkIn.sorenessLevel == .strong && !soreMuscles.isEmpty {
            let hitsSoreArea = exercises.contains { soreMuscles.contains($0.mainMuscle) }
            if hitsSoreArea { return false }
        }

        return true
    }

    private func levelCompatibility(profileLevel: TrainingLevel) -> Bool {
        switch (profileLevel, level) {
        case (.beginner, .advanced):
            return false
        case (.beginner, .intermediate):
            return false
        default:
            return true
        }
    }
}

struct IntRange: Codable, Hashable, Sendable {
    var lowerBound: Int
    var upperBound: Int

    init(_ lower: Int, _ upper: Int) {
        self.lowerBound = min(lower, upper)
        self.upperBound = max(lower, upper)
    }

    var average: Int {
        (lowerBound + upperBound) / 2
    }

    var display: String {
        lowerBound == upperBound ? "\(lowerBound)" : "\(lowerBound)-\(upperBound)"
    }
}

struct ExercisePrescription: Codable, Hashable, Sendable {
    var exercise: WorkoutExercise
    var sets: Int
    var reps: IntRange
    var restInterval: TimeInterval
    var tip: String?
}

enum WorkoutIntensity: String, Codable, CaseIterable, Sendable {
    case low
    case moderate
    case high
}

struct WorkoutPlan: Codable, Hashable, Sendable {
    var id: UUID
    var title: String
    var focus: DailyFocus
    var estimatedDurationMinutes: Int
    var intensity: WorkoutIntensity
    var exercises: [ExercisePrescription]
    var createdAt: Date

    init(
        id: UUID = .init(),
        title: String,
        focus: DailyFocus,
        estimatedDurationMinutes: Int,
        intensity: WorkoutIntensity,
        exercises: [ExercisePrescription],
        createdAt: Date = .init()
    ) {
        self.id = id
        self.title = title
        self.focus = focus
        self.estimatedDurationMinutes = estimatedDurationMinutes
        self.intensity = intensity
        self.exercises = exercises
        self.createdAt = createdAt
    }
}

