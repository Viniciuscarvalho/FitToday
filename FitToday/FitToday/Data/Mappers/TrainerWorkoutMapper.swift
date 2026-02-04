//
//  TrainerWorkoutMapper.swift
//  FitToday
//
//  Created by Claude on 04/02/26.
//

import Foundation
import FirebaseFirestore

// MARK: - Trainer Workout Mapper

/// Maps between Firebase DTOs and domain models for trainer workout entities.
struct TrainerWorkoutMapper {

    // MARK: - To Domain

    /// Converts a Firebase trainer workout DTO to a domain model.
    ///
    /// - Parameters:
    ///   - fb: The Firebase DTO to convert.
    ///   - id: The document ID from Firestore.
    /// - Returns: A domain `TrainerWorkout` model.
    static func toDomain(_ fb: FBTrainerWorkout, id: String) -> TrainerWorkout {
        TrainerWorkout(
            id: id,
            trainerId: fb.trainerId,
            title: fb.title,
            description: fb.description,
            focus: mapFocus(fb.focus),
            estimatedDurationMinutes: fb.estimatedDurationMinutes,
            intensity: mapIntensity(fb.intensity),
            phases: fb.phases.map { mapPhase($0) },
            schedule: mapSchedule(fb.schedule),
            isActive: fb.isActive,
            createdAt: fb.createdAt?.dateValue() ?? Date(),
            version: fb.version
        )
    }

    /// Converts a trainer workout domain model to a WorkoutPlan for execution.
    ///
    /// - Parameter trainerWorkout: The trainer workout to convert.
    /// - Returns: A `WorkoutPlan` suitable for workout execution.
    static func toWorkoutPlan(_ trainerWorkout: TrainerWorkout) -> WorkoutPlan {
        WorkoutPlan(
            id: UUID(),
            title: trainerWorkout.title,
            focus: trainerWorkout.focus,
            estimatedDurationMinutes: trainerWorkout.estimatedDurationMinutes,
            intensity: trainerWorkout.intensity,
            phases: trainerWorkout.phases.map { mapToWorkoutPlanPhase($0) },
            createdAt: trainerWorkout.createdAt
        )
    }

    // MARK: - Private Mapping Helpers

    /// Maps a focus string to the DailyFocus enum.
    private static func mapFocus(_ focus: String) -> DailyFocus {
        let normalizedFocus = focus.lowercased().trimmingCharacters(in: .whitespaces)

        switch normalizedFocus {
        case "fullbody", "full_body", "full body":
            return .fullBody
        case "upper", "upper_body", "upper body":
            return .upper
        case "lower", "lower_body", "lower body":
            return .lower
        case "cardio":
            return .cardio
        case "core", "abs":
            return .core
        case "surprise", "random":
            return .surprise
        default:
            // Default to fullBody if unknown focus
            return .fullBody
        }
    }

    /// Maps an intensity string to the WorkoutIntensity enum.
    private static func mapIntensity(_ intensity: String) -> WorkoutIntensity {
        let normalizedIntensity = intensity.lowercased().trimmingCharacters(in: .whitespaces)

        switch normalizedIntensity {
        case "low", "light", "easy":
            return .low
        case "moderate", "medium", "normal":
            return .moderate
        case "high", "hard", "intense":
            return .high
        default:
            return .moderate
        }
    }

    /// Maps a Firebase workout phase to a domain phase.
    private static func mapPhase(_ fb: FBWorkoutPhase) -> TrainerWorkoutPhase {
        TrainerWorkoutPhase(
            name: fb.name,
            items: fb.items.map { mapItem($0) }
        )
    }

    /// Maps a Firebase workout item to a domain item.
    private static func mapItem(_ fb: FBWorkoutItem) -> TrainerWorkoutItem {
        TrainerWorkoutItem(
            exerciseId: fb.exerciseId,
            exerciseName: fb.exerciseName,
            sets: fb.sets,
            reps: parseReps(fb.reps),
            restSeconds: fb.restSeconds,
            notes: fb.notes
        )
    }

    /// Parses a rep string (e.g., "8-12" or "10") into an IntRange.
    private static func parseReps(_ reps: String) -> IntRange {
        let trimmed = reps.trimmingCharacters(in: .whitespaces)

        // Check if it's a range (e.g., "8-12")
        if trimmed.contains("-") {
            let components = trimmed.split(separator: "-")
            if components.count == 2,
               let lower = Int(components[0].trimmingCharacters(in: .whitespaces)),
               let upper = Int(components[1].trimmingCharacters(in: .whitespaces)) {
                return IntRange(lower, upper)
            }
        }

        // Single value (e.g., "10")
        if let value = Int(trimmed) {
            return IntRange(value, value)
        }

        // Default fallback
        return IntRange(10, 10)
    }

    /// Maps a Firebase workout schedule to a domain schedule.
    private static func mapSchedule(_ fb: FBWorkoutSchedule) -> TrainerWorkoutSchedule {
        TrainerWorkoutSchedule(
            type: mapScheduleType(fb.type),
            scheduledDate: fb.scheduledDate?.dateValue(),
            dayOfWeek: fb.dayOfWeek
        )
    }

    /// Maps a schedule type string to the TrainerWorkoutScheduleType enum.
    private static func mapScheduleType(_ type: String) -> TrainerWorkoutScheduleType {
        let normalizedType = type.lowercased().trimmingCharacters(in: .whitespaces)

        switch normalizedType {
        case "once", "single":
            return .once
        case "recurring", "repeat":
            return .recurring
        case "weekly":
            return .weekly
        default:
            return .once
        }
    }

    /// Maps a trainer workout phase to a WorkoutPlanPhase.
    private static func mapToWorkoutPlanPhase(_ phase: TrainerWorkoutPhase) -> WorkoutPlanPhase {
        let phaseKind = inferPhaseKind(from: phase.name)

        let items: [WorkoutPlanItem] = phase.items.map { item in
            let exercise = createWorkoutExercise(from: item)
            let prescription = ExercisePrescription(
                exercise: exercise,
                sets: item.sets,
                reps: item.reps,
                restInterval: TimeInterval(item.restSeconds),
                tip: item.notes
            )
            return .exercise(prescription)
        }

        return WorkoutPlanPhase(
            kind: phaseKind,
            title: phase.name,
            rpeTarget: nil,
            items: items
        )
    }

    /// Infers the phase kind from the phase name.
    private static func inferPhaseKind(from name: String) -> WorkoutPlanPhase.Kind {
        let normalizedName = name.lowercased()

        if normalizedName.contains("warmup") || normalizedName.contains("warm-up") ||
           normalizedName.contains("aquecimento") {
            return .warmup
        } else if normalizedName.contains("strength") || normalizedName.contains("main") ||
                  normalizedName.contains("principal") || normalizedName.contains("forca") {
            return .strength
        } else if normalizedName.contains("accessory") || normalizedName.contains("acessorio") {
            return .accessory
        } else if normalizedName.contains("conditioning") || normalizedName.contains("condicionamento") {
            return .conditioning
        } else if normalizedName.contains("aerobic") || normalizedName.contains("cardio") ||
                  normalizedName.contains("aerobico") {
            return .aerobic
        } else if normalizedName.contains("finisher") || normalizedName.contains("finale") {
            return .finisher
        } else if normalizedName.contains("cooldown") || normalizedName.contains("cool-down") ||
                  normalizedName.contains("desaquecimento") || normalizedName.contains("alongamento") {
            return .cooldown
        }

        // Default to strength for unknown phase names
        return .strength
    }

    /// Creates a WorkoutExercise from a trainer workout item.
    private static func createWorkoutExercise(from item: TrainerWorkoutItem) -> WorkoutExercise {
        WorkoutExercise(
            id: item.exerciseId.map { String($0) } ?? UUID().uuidString,
            name: item.exerciseName,
            mainMuscle: .fullBody, // Default muscle group; can be enriched later
            equipment: .bodyweight, // Default equipment; can be enriched later
            instructions: [],
            media: nil
        )
    }
}
