//
//  CMSWorkoutMapper.swift
//  FitToday
//
//  Maps CMS API DTOs to domain models.
//

import Foundation

// MARK: - CMS Workout Mapper

/// Converts CMS API DTOs to domain models.
///
/// Handles the transformation of workout data from the CMS REST API
/// format to the app's domain model format.
enum CMSWorkoutMapper {

    // MARK: - CMS to Domain

    /// Converts a CMS workout DTO to a domain TrainerWorkout.
    ///
    /// - Parameter cms: The CMS workout DTO.
    /// - Returns: A domain TrainerWorkout model.
    static func toDomain(_ cms: CMSWorkout) -> TrainerWorkout {
        TrainerWorkout(
            id: cms.id,
            trainerId: cms.trainerId,
            title: cms.title,
            description: cms.description,
            focus: mapFocus(cms.focus),
            estimatedDurationMinutes: cms.estimatedDurationMinutes,
            intensity: mapIntensity(cms.intensity),
            phases: cms.phases.map(mapPhase),
            schedule: mapSchedule(cms.schedule),
            isActive: cms.status == .active,
            createdAt: cms.createdAt,
            version: cms.version,
            pdfUrl: cms.pdfUrl
        )
    }

    /// Converts a CMS workout to an executable WorkoutPlan.
    ///
    /// - Parameter cms: The CMS workout DTO.
    /// - Returns: A WorkoutPlan ready for workout execution.
    static func toWorkoutPlan(_ cms: CMSWorkout) -> WorkoutPlan {
        let trainerWorkout = toDomain(cms)
        return toWorkoutPlan(from: trainerWorkout)
    }

    /// Converts a TrainerWorkout domain model to a WorkoutPlan.
    ///
    /// - Parameter workout: The TrainerWorkout domain model.
    /// - Returns: A WorkoutPlan ready for workout execution.
    static func toWorkoutPlan(from workout: TrainerWorkout) -> WorkoutPlan {
        let phases = workout.phases.map { phase -> WorkoutPlanPhase in
            let items: [WorkoutPlanItem] = phase.items.map { item in
                let exercise = WorkoutExercise(
                    id: item.exerciseId.map { String($0) } ?? UUID().uuidString,
                    name: item.exerciseName,
                    mainMuscle: mapMuscleGroup(from: workout.focus),
                    equipment: .bodyweight,
                    instructions: item.notes.map { [$0] } ?? [],
                    media: nil
                )

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
                kind: mapPhaseKind(phase.name),
                title: phase.name,
                rpeTarget: nil,
                items: items
            )
        }

        return WorkoutPlan(
            id: UUID(),
            title: workout.title,
            focus: workout.focus,
            estimatedDurationMinutes: workout.estimatedDurationMinutes,
            intensity: workout.intensity,
            phases: phases,
            createdAt: workout.createdAt
        )
    }

    // MARK: - Private Helpers

    private static func mapFocus(_ focus: String) -> DailyFocus {
        switch focus.lowercased() {
        case "fullbody", "full_body", "full-body", "corpo todo":
            return .fullBody
        case "upper", "upper_body", "upper-body", "superior":
            return .upper
        case "lower", "lower_body", "lower-body", "inferior":
            return .lower
        case "cardio", "aerobico":
            return .cardio
        case "core", "abdomen":
            return .core
        case "push":
            return .upper
        case "pull":
            return .upper
        case "legs":
            return .lower
        default:
            return .surprise
        }
    }

    private static func mapIntensity(_ intensity: String) -> WorkoutIntensity {
        switch intensity.lowercased() {
        case "low", "baixa", "leve":
            return .low
        case "moderate", "medium", "moderada", "media":
            return .moderate
        case "high", "alta", "intensa":
            return .high
        default:
            return .moderate
        }
    }

    private static func mapPhase(_ phase: CMSWorkoutPhase) -> TrainerWorkoutPhase {
        TrainerWorkoutPhase(
            name: phase.name,
            items: phase.items.map(mapItem)
        )
    }

    private static func mapItem(_ item: CMSWorkoutItem) -> TrainerWorkoutItem {
        TrainerWorkoutItem(
            exerciseId: item.exerciseId,
            exerciseName: item.exerciseName,
            sets: item.sets,
            reps: parseReps(item.reps),
            restSeconds: item.restSeconds,
            notes: item.notes
        )
    }

    private static func parseReps(_ reps: String) -> IntRange {
        let trimmed = reps.trimmingCharacters(in: .whitespaces)

        if trimmed.contains("-") {
            let parts = trimmed.split(separator: "-")
            if parts.count == 2,
               let lower = Int(parts[0].trimmingCharacters(in: .whitespaces)),
               let upper = Int(parts[1].trimmingCharacters(in: .whitespaces)) {
                return IntRange(lower, upper)
            }
        }

        if let single = Int(trimmed) {
            return IntRange(single, single)
        }

        return IntRange(10, 12)
    }

    private static func mapSchedule(_ schedule: CMSWorkoutSchedule?) -> TrainerWorkoutSchedule {
        guard let schedule else {
            return TrainerWorkoutSchedule(type: .once, scheduledDate: nil, dayOfWeek: nil)
        }

        let type: TrainerWorkoutScheduleType
        switch schedule.type.lowercased() {
        case "once", "single":
            type = .once
        case "recurring", "repeat":
            type = .recurring
        case "weekly", "semanal":
            type = .weekly
        default:
            type = .once
        }

        return TrainerWorkoutSchedule(
            type: type,
            scheduledDate: schedule.scheduledDate,
            dayOfWeek: schedule.dayOfWeek
        )
    }

    private static func mapPhaseKind(_ name: String) -> WorkoutPlanPhase.Kind {
        let normalized = name.lowercased()

        if normalized.contains("warmup") || normalized.contains("aquecimento") {
            return .warmup
        }
        if normalized.contains("strength") || normalized.contains("força") || normalized.contains("principal") {
            return .strength
        }
        if normalized.contains("accessory") || normalized.contains("acessório") || normalized.contains("complementar") {
            return .accessory
        }
        if normalized.contains("conditioning") || normalized.contains("condicionamento") {
            return .conditioning
        }
        if normalized.contains("aerobic") || normalized.contains("aeróbico") || normalized.contains("cardio") {
            return .aerobic
        }
        if normalized.contains("finisher") || normalized.contains("finalizador") {
            return .finisher
        }
        if normalized.contains("cooldown") || normalized.contains("volta à calma") || normalized.contains("alongamento") {
            return .cooldown
        }

        return .strength
    }

    private static func mapMuscleGroup(from focus: DailyFocus) -> MuscleGroup {
        switch focus {
        case .fullBody:
            return .fullBody
        case .upper:
            return .chest
        case .lower:
            return .quadriceps
        case .cardio:
            return .fullBody
        case .core:
            return .core
        case .surprise:
            return .fullBody
        }
    }
}
