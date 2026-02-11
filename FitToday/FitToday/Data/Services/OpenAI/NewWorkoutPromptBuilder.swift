//
//  NewWorkoutPromptBuilder.swift
//  FitToday
//
//  Created by AI on 09/02/26.
//  Part of: Workout Experience Overhaul (Task 3.0)
//

import Foundation

/// Simplified workout prompt builder for OpenAI generation.
///
/// Key features:
/// - Concise prompt construction (<300 lines)
/// - Includes last 3 workout names with "DO NOT REPEAT" instruction
/// - Seed = timestamp + random for uniqueness
/// - Respects user inputs (equipment, muscles, level, feeling)
/// - Goal-specific guidelines
///
/// - Note: Part of FR-002 (OpenAI Generation Enhancement) from PRD
struct NewWorkoutPromptBuilder: Sendable {

    // MARK: - Public API

    /// Builds a complete prompt for OpenAI workout generation.
    ///
    /// - Parameters:
    ///   - blueprint: The workout blueprint with structure and targets
    ///   - blocks: Available exercise blocks to choose from
    ///   - profile: User profile with goals and preferences
    ///   - checkIn: Daily check-in with energy/soreness state
    ///   - previousWorkouts: Last 3 workouts to avoid repetition
    /// - Returns: Complete prompt string ready for OpenAI
    func buildPrompt(
        blueprint: WorkoutBlueprint,
        blocks: [WorkoutBlock],
        profile: UserProfile,
        checkIn: DailyCheckIn,
        previousWorkouts: [WorkoutPlan]
    ) -> String {
        #if DEBUG
        // Log prohibited exercises for debugging
        var prohibitedExercises = Set<String>()
        for workout in previousWorkouts {
            for phase in workout.phases {
                for item in phase.items {
                    if case .exercise(let prescription) = item {
                        prohibitedExercises.insert(prescription.exercise.name)
                    }
                }
            }
        }
        print("[PromptBuilder] 🚫 Prohibited exercises count: \(prohibitedExercises.count)")
        if !prohibitedExercises.isEmpty {
            print("[PromptBuilder] 🚫 Prohibited: \(prohibitedExercises.sorted().joined(separator: ", "))")
        }
        #endif

        let systemMessage = buildSystemMessage(goal: profile.mainGoal, blueprint: blueprint)
        let userMessage = buildUserMessage(
            blueprint: blueprint,
            blocks: blocks,
            profile: profile,
            checkIn: checkIn,
            previousWorkouts: previousWorkouts
        )

        return """
        SYSTEM:
        \(systemMessage)

        USER:
        \(userMessage)
        """
    }

    // MARK: - System Message

    private func buildSystemMessage(goal: FitnessGoal, blueprint: WorkoutBlueprint) -> String {
        let guidelines = goalGuidelines(for: goal)

        return """
        You are an expert personal trainer specializing in \(goalDescription(for: goal)).

        ## PRIMARY GOAL
        \(goal.rawValue.uppercased())
        \(guidelines)

        ## TASK
        Generate a complete workout using ONLY exercises from the provided catalog.

        ## MANDATORY RULES
        1. Use ONLY exercise names from the catalog (do NOT invent names)
        2. Use ONLY allowed equipment: \(blueprint.equipmentConstraints.allowedEquipment.map(\.rawValue).joined(separator: ", "))
        3. Respect the blueprint: each phase must have the EXACT number of exercises and correct kind
        4. Prioritize safety: avoid exercises that aggravate health limitations
        5. Avoid repetition based on workout history (when provided)
        6. EACH EXERCISE appears ONLY ONCE in the entire workout (no duplicates across phases)
        7. Use EXACT exercise names in English as provided in the catalog

        ## JSON FORMAT (respond with valid JSON only)
        {
          "phases": [
            {
              "kind": "warmup|strength|accessory|conditioning|aerobic",
              "exercises": [{"name":"...", "muscleGroup":"...", "equipment":"...", "sets":3, "reps":"8-12", "restSeconds":60, "notes":"..."}],
              "activity": {"kind":"mobility|aerobicZone2|aerobicIntervals|breathing", "title":"...", "durationMinutes":10}
            }
          ],
          "title": "Workout title",
          "notes": "Optional notes"
        }
        """
    }

    // MARK: - User Message

    private func buildUserMessage(
        blueprint: WorkoutBlueprint,
        blocks: [WorkoutBlock],
        profile: UserProfile,
        checkIn: DailyCheckIn,
        previousWorkouts: [WorkoutPlan]
    ) -> String {
        let blueprintSection = formatBlueprint(blueprint)
        let catalogSection = formatCatalog(blocks: blocks, blueprint: blueprint)
        let prohibitedSection = formatProhibitedWorkouts(previousWorkouts)

        return """
        ## USER PROFILE
        **PRIMARY GOAL: \(profile.mainGoal.rawValue.uppercased())**
        Level: \(profile.level.rawValue) | Equipment: \(profile.availableStructure.rawValue) | Frequency: \(profile.weeklyFrequency)x/week
        Health conditions: \(formatHealthConditions(profile.healthConditions))

        ## TODAY'S STATE
        Focus: \(checkIn.focus.rawValue) | DOMS: \(checkIn.sorenessLevel.rawValue) | Energy: \(checkIn.energyLevel)/10
        \(checkIn.sorenessAreas.isEmpty ? "" : "Sore areas: \(checkIn.sorenessAreas.map(\.rawValue).joined(separator: ", "))")

        Adaptation rules:
        - If energy <= 3 OR DOMS == strong: keep workout conservative, prioritize technique and safety

        ## WORKOUT STRUCTURE (MANDATORY)
        \(blueprintSection)

        \(prohibitedSection)

        ## AVAILABLE EXERCISES (use ONLY these)
        \(catalogSection)

        Return ONLY the JSON workout.
        """
    }

    // MARK: - Blueprint Formatting

    private func formatBlueprint(_ blueprint: WorkoutBlueprint) -> String {
        var lines: [String] = []

        lines.append("Title: \(blueprint.title) | Intensity: \(blueprint.intensity.rawValue) | Duration: ~\(blueprint.estimatedDurationMinutes)min")
        lines.append("Recovery mode: \(blueprint.isRecoveryMode ? "YES (reduce intensity)" : "NO")")
        lines.append("")
        lines.append("Phases (create EXACTLY \(blueprint.blocks.count) phases):")

        for (index, block) in blueprint.blocks.enumerated() {
            lines.append("")
            lines.append("Phase \(index + 1): \(block.title) (kind: \(block.phaseKind.rawValue))")
            lines.append("- EXERCISES: \(block.exerciseCount) (required)")
            lines.append("- Sets: \(block.setsRange.lowerBound)-\(block.setsRange.upperBound) | Reps: \(block.repsRange.lowerBound)-\(block.repsRange.upperBound) | Rest: \(block.restSeconds)s | RPE: \(block.rpeTarget)")
            lines.append("- Target muscles: \(block.targetMuscles.map(\.rawValue).joined(separator: ", "))")

            if !block.avoidMuscles.isEmpty {
                lines.append("- AVOID: \(block.avoidMuscles.map(\.rawValue).joined(separator: ", "))")
            }
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Catalog Formatting

    private func formatCatalog(blocks: [WorkoutBlock], blueprint: WorkoutBlueprint) -> String {
        // Filter compatible blocks
        let allowedEquipment = Set(blueprint.equipmentConstraints.allowedEquipment)
        let compatibleBlocks = blocks.filter { block in
            block.equipmentOptions.contains { allowedEquipment.contains($0) }
        }

        // Seed-based randomization for variety
        var generator = SeededRandomGenerator(seed: blueprint.variationSeed)
        var shuffledBlocks = compatibleBlocks
        for i in (1..<shuffledBlocks.count).reversed() {
            let j = generator.nextInt(in: 0...i)
            shuffledBlocks.swapAt(i, j)
        }

        // Select top blocks (limit to 15 blocks for conciseness)
        let selectedBlocks = shuffledBlocks.prefix(15)

        // Extract exercises grouped by muscle
        var exercisesByMuscle: [MuscleGroup: [WorkoutExercise]] = [:]
        for block in selectedBlocks {
            var shuffledExercises = block.exercises
            for i in (1..<shuffledExercises.count).reversed() {
                let j = generator.nextInt(in: 0...i)
                shuffledExercises.swapAt(i, j)
            }

            for exercise in shuffledExercises.prefix(8) {
                exercisesByMuscle[exercise.mainMuscle, default: []].append(exercise)
            }
        }

        // Format catalog
        var catalogLines: [String] = []
        catalogLines.append("CRITICAL: Use EXACTLY these exercise names (including capitalization).")
        catalogLines.append("Any exercise not in this list will be REJECTED.")
        catalogLines.append("")

        // Sort muscles and output exercises
        let sortedMuscles = exercisesByMuscle.keys.sorted { $0.rawValue < $1.rawValue }
        var totalExercises = 0

        for muscle in sortedMuscles.prefix(10) { // Limit to 10 muscle groups
            guard let exercises = exercisesByMuscle[muscle], !exercises.isEmpty else { continue }

            catalogLines.append("### \(muscle.rawValue.capitalized)")
            for exercise in exercises.prefix(8) { // Max 8 exercises per muscle
                catalogLines.append("- \(exercise.name) (\(exercise.equipment.rawValue))")
                totalExercises += 1
            }
            catalogLines.append("")
        }

        catalogLines.append("Total: \(totalExercises) exercises available")
        catalogLines.append("REMINDER: Use ONLY names from this list. Do NOT invent exercise names.")

        return catalogLines.joined(separator: "\n")
    }

    // MARK: - Prohibited Workouts Formatting

    private func formatProhibitedWorkouts(_ workouts: [WorkoutPlan]) -> String {
        var lines: [String] = []

        // Always include variation instruction
        lines.append("## VARIATION REQUIREMENTS")
        lines.append("")
        lines.append("CRITICAL: Create a UNIQUE workout with MAXIMUM VARIETY.")
        lines.append("- Select DIFFERENT exercises from the catalog each time")
        lines.append("- Prioritize exercises you haven't suggested recently")
        lines.append("- Mix compound and isolation movements")
        lines.append("- Vary exercise order and selection within each muscle group")
        lines.append("")

        // Add prohibited exercises if history exists
        if !workouts.isEmpty {
            let recentWorkouts = Array(workouts.prefix(3))

            // Collect all unique exercise names
            var prohibitedExercises = Set<String>()
            for workout in recentWorkouts {
                for phase in workout.phases {
                    for item in phase.items {
                        if case .exercise(let prescription) = item {
                            prohibitedExercises.insert(prescription.exercise.name)
                        }
                    }
                }
            }

            if !prohibitedExercises.isEmpty {
                lines.append("## PROHIBITED EXERCISES (from last \(recentWorkouts.count) workouts)")
                lines.append("")
                lines.append("⚠️ DO NOT USE any of these exercises - select alternatives:")
                lines.append("")

                let sortedProhibited = prohibitedExercises.sorted()
                for name in sortedProhibited {
                    lines.append("❌ \(name)")
                }
                lines.append("")
                lines.append("Total prohibited: \(sortedProhibited.count) exercises")
                lines.append("")
            }
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Helper Methods

    private func goalDescription(for goal: FitnessGoal) -> String {
        switch goal {
        case .hypertrophy:
            return "muscle hypertrophy and strength development"
        case .weightLoss:
            return "weight loss and fat reduction"
        case .performance:
            return "athletic performance and functional development"
        case .conditioning:
            return "general physical conditioning"
        case .endurance:
            return "cardiovascular endurance"
        }
    }

    private func goalGuidelines(for goal: FitnessGoal) -> String {
        switch goal {
        case .hypertrophy:
            return """
            - Prioritize multi-joint exercises
            - High intensity, low-medium volume
            - Long rest periods (2-5min) for neural recovery
            - Sets: 3-5, Reps: 4-10, RPE: 7-9
            - Progressive overload focus
            """

        case .weightLoss:
            return """
            - Full body circuits with high density
            - Short intervals (30-60s)
            - Moderate volume, RPE 6-8
            - Sets: 3-4, Reps: 10-18
            - Focus on total energy expenditure
            - Include light cardio at the end
            """

        case .performance:
            return """
            - Explosive and functional movements
            - Quality over quantity
            - Adequate recovery between sets
            - Sets: 3-4, Reps: 5-8, RPE: 7
            - Varied stimulus
            """

        case .conditioning:
            return """
            - Balanced strength and endurance
            - Moderate intensity, RPE 6-7
            - Full body preferred
            - Sets: 3-4, Reps: 10-15
            - Rest: 45-90s
            """

        case .endurance:
            return """
            - High volume, controlled intensity
            - Short rest (20-45s)
            - Focus on cardio and technique
            - Sets: 2-4, Reps: 15-25
            - Zone 2 priority for cardio
            """
        }
    }

    private func formatHealthConditions(_ conditions: [HealthCondition]) -> String {
        guard !conditions.isEmpty else { return "none" }

        let filtered = conditions.filter { $0 != .none }
        guard !filtered.isEmpty else { return "none" }

        return filtered.map { condition in
            switch condition {
            case .none: return "none"
            case .lowerBackPain: return "lower back pain"
            case .knee: return "knee"
            case .shoulder: return "shoulder"
            case .other: return "other"
            }
        }
        .joined(separator: ", ")
    }
}
