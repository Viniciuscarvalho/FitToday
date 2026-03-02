//
//  ChatSystemPromptBuilder.swift
//  FitToday
//

import Foundation

struct ChatSystemPromptBuilder: Sendable {

    func buildSystemPrompt(
        profile: UserProfile?,
        stats: UserStats?,
        recentWorkouts: [WorkoutHistoryEntry]
    ) -> String {
        var sections: [String] = []

        sections.append(basePersonality())

        if let profile {
            sections.append(userProfileSection(profile))
        }

        if let stats {
            sections.append(userStatsSection(stats))
        }

        if !recentWorkouts.isEmpty {
            sections.append(recentWorkoutsSection(recentWorkouts))
        }

        sections.append(responseGuidelines())

        return sections.joined(separator: "\n\n")
    }

    // MARK: - Private Sections

    private func basePersonality() -> String {
        """
        You are FitOrb, an AI fitness assistant inside the FitToday app. \
        You act as a personal trainer and nutritionist. \
        Be friendly, motivating, direct, and science-based. \
        Always encourage the user and celebrate their progress. \
        Never recommend anything dangerous or unsupported by evidence.
        """
    }

    private func userProfileSection(_ profile: UserProfile) -> String {
        var lines: [String] = ["## User Profile"]
        lines.append("- Main goal: \(goalDescription(profile.mainGoal))")
        lines.append("- Level: \(levelDescription(profile.level))")
        lines.append("- Equipment: \(structureDescription(profile.availableStructure))")
        lines.append("- Preferred method: \(methodDescription(profile.preferredMethod))")
        lines.append("- Weekly frequency: \(profile.weeklyFrequency)x per week")

        let conditions = profile.healthConditions.filter { $0 != .none }
        if !conditions.isEmpty {
            let conditionText = conditions.map(conditionDescription).joined(separator: ", ")
            lines.append("- Health conditions: \(conditionText)")
            lines.append(
                "IMPORTANT: Always consider these health conditions when suggesting exercises. "
                + "Avoid movements that could aggravate them."
            )
        }

        return lines.joined(separator: "\n")
    }

    private func userStatsSection(_ stats: UserStats) -> String {
        var lines: [String] = ["## Current Progress"]
        lines.append("- Current streak: \(stats.currentStreak) consecutive days")
        lines.append(
            "- This week: \(stats.weekWorkoutsCount) workouts, "
            + "\(stats.weekTotalMinutes) min, \(stats.weekTotalCalories) cal"
        )

        if let lastDate = stats.lastWorkoutDate {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            let relative = formatter.localizedString(for: lastDate, relativeTo: Date())
            lines.append("- Last workout: \(relative)")
        }

        if stats.currentStreak >= 7 {
            lines.append(
                "The user has a strong streak going — acknowledge and motivate them to keep it up!"
            )
        } else if stats.currentStreak == 0 {
            lines.append(
                "The user hasn't been active recently — be extra encouraging without being judgmental."
            )
        }

        return lines.joined(separator: "\n")
    }

    private func recentWorkoutsSection(_ workouts: [WorkoutHistoryEntry]) -> String {
        var lines: [String] = ["## Recent Workouts (last \(workouts.count))"]

        for (index, workout) in workouts.prefix(3).enumerated() {
            var detail = "\(index + 1). \(workout.title) (\(workout.focus.rawValue))"
            if let duration = workout.durationMinutes {
                detail += " — \(duration) min"
            }
            if let calories = workout.caloriesBurned {
                detail += ", \(calories) cal"
            }
            lines.append(detail)
        }

        lines.append("Use this history to avoid repetition and suggest complementary workouts.")
        return lines.joined(separator: "\n")
    }

    private func responseGuidelines() -> String {
        """
        ## Response Guidelines
        - Keep responses concise (under 300 words unless the user asks for detail)
        - Use markdown formatting for structure (bold, lists, headers)
        - Respond in the same language the user writes in
        - When suggesting exercises, include sets, reps, and rest time
        - When discussing nutrition, give practical and accessible advice
        - If unsure about something medical, recommend consulting a healthcare professional
        """
    }

    // MARK: - Description Helpers

    private func goalDescription(_ goal: FitnessGoal) -> String {
        switch goal {
        case .hypertrophy: "muscle gain (hypertrophy)"
        case .conditioning: "general conditioning"
        case .endurance: "endurance improvement"
        case .weightLoss: "weight loss"
        case .performance: "athletic performance"
        }
    }

    private func levelDescription(_ level: TrainingLevel) -> String {
        switch level {
        case .beginner: "beginner"
        case .intermediate: "intermediate"
        case .advanced: "advanced"
        }
    }

    private func structureDescription(_ structure: TrainingStructure) -> String {
        switch structure {
        case .fullGym: "full gym with all equipment"
        case .basicGym: "basic gym with limited equipment"
        case .homeDumbbells: "home with dumbbells"
        case .bodyweight: "bodyweight only (no equipment)"
        }
    }

    private func methodDescription(_ method: TrainingMethod) -> String {
        switch method {
        case .traditional: "traditional (sets/reps)"
        case .circuit: "circuit training"
        case .hiit: "HIIT"
        case .mixed: "mixed methods"
        }
    }

    private func conditionDescription(_ condition: HealthCondition) -> String {
        switch condition {
        case .none: "none"
        case .lowerBackPain: "lower back pain"
        case .knee: "knee issues"
        case .shoulder: "shoulder issues"
        case .other: "other condition"
        }
    }
}
