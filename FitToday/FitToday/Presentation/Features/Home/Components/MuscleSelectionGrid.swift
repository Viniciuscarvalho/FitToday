//
//  MuscleSelectionGrid.swift
//  FitToday
//
//  Grid component for selecting target muscle groups.
//

import SwiftUI

/// Extension to provide display names and icons for MuscleGroup.
extension MuscleGroup {
    /// Localized display name for the muscle group.
    var displayName: String {
        switch self {
        case .chest: return "Peito"
        case .back: return "Costas"
        case .shoulders: return "Ombros"
        case .arms: return "Braços"
        case .biceps: return "Bíceps"
        case .triceps: return "Tríceps"
        case .forearms: return "Antebraço"
        case .core: return "Core"
        case .glutes: return "Glúteos"
        case .quads: return "Quadríceps"
        case .quadriceps: return "Quadríceps"
        case .hamstrings: return "Posterior"
        case .calves: return "Panturrilha"
        case .lats: return "Dorsal"
        case .lowerBack: return "Lombar"
        case .cardioSystem: return "Cardio"
        case .fullBody: return "Full Body"
        }
    }

    /// SF Symbol icon for the muscle group.
    var icon: String {
        switch self {
        case .chest: return "heart.fill"
        case .back: return "figure.stand"
        case .shoulders: return "figure.arms.open"
        case .arms, .biceps, .triceps, .forearms: return "figure.strengthtraining.traditional"
        case .core: return "figure.core.training"
        case .glutes, .quads, .quadriceps, .hamstrings, .calves: return "figure.run"
        case .lats, .lowerBack: return "figure.flexibility"
        case .cardioSystem: return "heart.circle"
        case .fullBody: return "figure.mixed.cardio"
        }
    }

    /// Primary muscle groups for display in the selection grid.
    static var primaryGroups: [MuscleGroup] {
        [.chest, .back, .shoulders, .biceps, .triceps, .core, .quads, .hamstrings, .glutes, .calves]
    }
}

/// Grid component for selecting multiple muscle groups.
struct MuscleSelectionGrid: View {
    @Binding var selectedMuscles: Set<MuscleGroup>

    private let columns = [
        GridItem(.flexible(), spacing: FitTodaySpacing.sm),
        GridItem(.flexible(), spacing: FitTodaySpacing.sm),
        GridItem(.flexible(), spacing: FitTodaySpacing.sm),
        GridItem(.flexible(), spacing: FitTodaySpacing.sm),
        GridItem(.flexible(), spacing: FitTodaySpacing.sm)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: FitTodaySpacing.sm) {
            ForEach(MuscleGroup.primaryGroups, id: \.self) { muscle in
                MuscleGroupChip(
                    muscle: muscle,
                    isSelected: selectedMuscles.contains(muscle)
                ) {
                    toggleMuscle(muscle)
                }
            }
        }
    }

    private func toggleMuscle(_ muscle: MuscleGroup) {
        if selectedMuscles.contains(muscle) {
            selectedMuscles.remove(muscle)
        } else {
            selectedMuscles.insert(muscle)
        }
    }
}

// MARK: - Muscle Group Chip

/// Individual chip for a muscle group selection in the grid.
private struct MuscleGroupChip: View {
    let muscle: MuscleGroup
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: FitTodaySpacing.xs) {
                Image(systemName: muscle.icon)
                    .font(.system(size: 16))

                Text(muscle.displayName)
                    .font(FitTodayFont.ui(size: 10, weight: isSelected ? .bold : .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, FitTodaySpacing.sm)
            .foregroundStyle(isSelected ? .white : FitTodayColor.textSecondary)
            .background(
                RoundedRectangle(cornerRadius: FitTodayRadius.sm)
                    .fill(isSelected ? FitTodayColor.brandPrimary : FitTodayColor.background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: FitTodayRadius.sm)
                    .stroke(
                        isSelected ? FitTodayColor.brandPrimary : FitTodayColor.outline,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        MuscleSelectionGrid(
            selectedMuscles: .constant([.chest, .back, .biceps])
        )
    }
    .padding()
    .background(FitTodayColor.surface)
    .preferredColorScheme(.dark)
}
