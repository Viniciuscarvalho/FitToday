//
//  RecommendedProgramsSection.swift
//  FitToday
//

import SwiftUI

/// Horizontal scroll section showing recommended workout programs.
struct RecommendedProgramsSection: View {
    let programs: [RecommendedProgram]
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            Text("Recommended for You")
                .font(FitTodayFont.ui(size: 18, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)
                .padding(.horizontal, FitTodaySpacing.lg)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: FitTodaySpacing.md) {
                    ForEach(programs) { program in
                        programCard(program)
                            .onTapGesture {
                                onSelect(program.id)
                            }
                    }
                }
                .padding(.horizontal, FitTodaySpacing.lg)
            }
        }
    }

    // MARK: - Card

    private func programCard(_ program: RecommendedProgram) -> some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            Spacer()

            Text(program.name)
                .font(FitTodayFont.ui(size: 15, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)
                .lineLimit(2)

            HStack(spacing: FitTodaySpacing.xs) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 11))
                Text("\(program.workoutCount) workouts")
                    .font(FitTodayFont.ui(size: 12, weight: .medium))
            }
            .foregroundStyle(FitTodayColor.textPrimary.opacity(0.8))
        }
        .padding(FitTodaySpacing.md)
        .frame(width: 160, height: 120, alignment: .bottomLeading)
        .background(gradientForCategory(program.category))
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
    }

    // MARK: - Category Gradient

    private func gradientForCategory(_ category: String) -> LinearGradient {
        switch category.lowercased() {
        case "strength":
            return FitTodayColor.gradientStrength
        case "conditioning":
            return FitTodayColor.gradientConditioning
        case "aerobic":
            return FitTodayColor.gradientAerobic
        case "endurance":
            return FitTodayColor.gradientEndurance
        case "wellness":
            return FitTodayColor.gradientWellness
        default:
            return FitTodayColor.gradientPrimary
        }
    }
}

// MARK: - Data Model

struct RecommendedProgram: Identifiable {
    let id: String
    let name: String
    let category: String
    let workoutCount: Int
}

// MARK: - Preview

#Preview {
    RecommendedProgramsSection(
        programs: [
            RecommendedProgram(id: "1", name: "Push Pull Legs", category: "Strength", workoutCount: 6),
            RecommendedProgram(id: "2", name: "HIIT Cardio", category: "Conditioning", workoutCount: 4),
            RecommendedProgram(id: "3", name: "Flexibility Flow", category: "Wellness", workoutCount: 3)
        ],
        onSelect: { _ in }
    )
    .padding(.vertical)
    .background(FitTodayColor.background)
    .preferredColorScheme(.dark)
}
