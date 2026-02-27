//
//  RecommendedProgramsSection.swift
//  FitToday
//

import SwiftUI

/// Horizontal scroll section showing recommended workout programs.
struct RecommendedProgramsSection: View {
    let programs: [Program]
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            Text("programs.recommended".localized)
                .font(FitTodayFont.ui(size: 18, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)
                .padding(.horizontal, FitTodaySpacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: FitTodaySpacing.md) {
                    ForEach(programs) { program in
                        programCard(program)
                            .onTapGesture {
                                onSelect(program.id)
                            }
                    }
                }
                .padding(.horizontal, FitTodaySpacing.md)
            }
        }
    }

    // MARK: - Card

    private func programCard(_ program: Program) -> some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            // Level badge
            Text(program.level.displayName)
                .font(FitTodayFont.ui(size: 10, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, FitTodaySpacing.sm)
                .padding(.vertical, 3)
                .background(levelColor(program.level))
                .clipShape(Capsule())

            Spacer()

            Text(program.shortName)
                .font(FitTodayFont.ui(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(2)

            HStack(spacing: FitTodaySpacing.xs) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 11))
                Text("\(program.totalWorkouts) workouts")
                    .font(FitTodayFont.ui(size: 12, weight: .medium))
            }
            .foregroundStyle(.white.opacity(0.8))
        }
        .padding(FitTodaySpacing.md)
        .frame(width: 160, height: 130, alignment: .bottomLeading)
        .background(gradientForGoal(program.goalTag))
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
    }

    // MARK: - Helpers

    private func levelColor(_ level: ProgramLevel) -> Color {
        switch level {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }

    private func gradientForGoal(_ goal: ProgramGoalTag) -> LinearGradient {
        switch goal {
        case .strength:
            return FitTodayColor.gradientPrimary
        case .conditioning:
            return LinearGradient(colors: [.orange, .red.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .aerobic:
            return LinearGradient(colors: [.cyan, .blue.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .core:
            return LinearGradient(colors: [.green, .teal.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .endurance:
            return LinearGradient(colors: [.purple, .indigo.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

// MARK: - Preview

#Preview {
    RecommendedProgramsSection(
        programs: [
            Program(
                id: "1", name: "Push Pull Legs", subtitle: "Classic split",
                goalTag: .strength, level: .intermediate, durationWeeks: 8,
                heroImageName: "ppl", workoutTemplateIds: ["a", "b", "c", "d", "e", "f"],
                estimatedMinutesPerSession: 60, sessionsPerWeek: 6
            ),
            Program(
                id: "2", name: "HIIT Cardio", subtitle: "High intensity",
                goalTag: .conditioning, level: .beginner, durationWeeks: 4,
                heroImageName: "hiit", workoutTemplateIds: ["a", "b", "c", "d"],
                estimatedMinutesPerSession: 30, sessionsPerWeek: 4
            )
        ],
        onSelect: { _ in }
    )
    .padding(.vertical)
    .background(FitTodayColor.background)
    .preferredColorScheme(.dark)
}
