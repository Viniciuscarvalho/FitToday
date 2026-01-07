//
//  WorkoutModels.swift
//  FitToday
//
//  Created by AI on 03/01/26.
//

import Foundation

// MARK: - Image URL Extraction

extension WorkoutPlan {
  /// Extrai todas as URLs de imagens de exercícios do treino
  var imageURLs: [URL] {
    var urls: [URL] = []
    
    for phase in phases {
      for item in phase.items {
        if case .exercise(let prescription) = item {
          if let imageURL = prescription.exercise.media?.imageURL {
            urls.append(imageURL)
          }
          if let gifURL = prescription.exercise.media?.gifURL {
            urls.append(gifURL)
          }
        }
      }
    }
    
    return urls
  }
}

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

// MARK: - Phased Workout Plan (Session Structure)

/// Item de um plano de treino, podendo ser um exercício do catálogo ou uma atividade guiada (ex.: Aeróbio Z2).
enum WorkoutPlanItem: Codable, Hashable, Sendable {
    case exercise(ExercisePrescription)
    case activity(ActivityPrescription)

    private enum CodingKeys: String, CodingKey { case type, exercise, activity }
    private enum ItemType: String, Codable { case exercise, activity }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ItemType.self, forKey: .type)
        switch type {
        case .exercise:
            self = .exercise(try container.decode(ExercisePrescription.self, forKey: .exercise))
        case .activity:
            self = .activity(try container.decode(ActivityPrescription.self, forKey: .activity))
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .exercise(let exercise):
            try container.encode(ItemType.exercise, forKey: .type)
            try container.encode(exercise, forKey: .exercise)
        case .activity(let activity):
            try container.encode(ItemType.activity, forKey: .type)
            try container.encode(activity, forKey: .activity)
        }
    }
}

/// Atividade guiada (sem lista de exercícios), como Aeróbio Zona 2, mobilidade guiada, intervalado leve, etc.
struct ActivityPrescription: Codable, Hashable, Sendable {
    enum Kind: String, Codable, CaseIterable, Sendable {
        case mobility
        case aerobicZone2
        case aerobicIntervals
        case breathing
        case cooldown
    }

    var kind: Kind
    var title: String
    var durationMinutes: Int
    var notes: String?

    init(kind: Kind, title: String, durationMinutes: Int, notes: String? = nil) {
        self.kind = kind
        self.title = title
        self.durationMinutes = durationMinutes
        self.notes = notes
    }
}

/// Fase de uma sessão (aquecimento, força, acessórios, aeróbio, etc).
struct WorkoutPlanPhase: Identifiable, Codable, Hashable, Sendable {
    enum Kind: String, Codable, CaseIterable, Sendable {
        case warmup
        case strength
        case accessory
        case conditioning
        case aerobic
        case finisher
        case cooldown
    }

    var id: UUID
    var kind: Kind
    var title: String
    var rpeTarget: Int?
    var items: [WorkoutPlanItem]

    init(
        id: UUID = .init(),
        kind: Kind,
        title: String,
        rpeTarget: Int? = nil,
        items: [WorkoutPlanItem]
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.rpeTarget = rpeTarget
        self.items = items
    }

    var exercises: [ExercisePrescription] {
        items.compactMap {
            if case .exercise(let prescription) = $0 { return prescription }
            return nil
        }
    }
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
    var phases: [WorkoutPlanPhase]
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
        // Compatibilidade: versões anteriores geram lista plana de exercícios.
        // A evolução do app passará a produzir fases reais (warmup/strength/aerobic etc).
        self.phases = [
            WorkoutPlanPhase(
                kind: .strength,
                title: "Treino",
                rpeTarget: nil,
                items: exercises.map { .exercise($0) }
            )
        ]
        self.createdAt = createdAt
    }

    init(
        id: UUID = .init(),
        title: String,
        focus: DailyFocus,
        estimatedDurationMinutes: Int,
        intensity: WorkoutIntensity,
        phases: [WorkoutPlanPhase],
        createdAt: Date = .init()
    ) {
        self.id = id
        self.title = title
        self.focus = focus
        self.estimatedDurationMinutes = estimatedDurationMinutes
        self.intensity = intensity
        self.phases = phases
        self.createdAt = createdAt
    }

    /// Lista plana de exercícios (compatibilidade com telas/fluxos antigos).
    var exercises: [ExercisePrescription] {
        phases.flatMap(\.exercises)
    }
}

