//
//  ExercisePlaceholderView.swift
//  FitToday
//
//  Placeholder view for exercises without images.
//

import SwiftUI

/// A placeholder view displayed when exercise image is unavailable.
struct ExercisePlaceholderView: View {
    let muscleGroup: MuscleGroup
    let size: PlaceholderSize

    enum PlaceholderSize {
        case small   // 40x40 - for list rows
        case medium  // 80x80 - for cards
        case large   // 120x120 - for detail views

        var dimension: CGFloat {
            switch self {
            case .small: return 40
            case .medium: return 80
            case .large: return 120
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .small: return 20
            case .medium: return 36
            case .large: return 56
            }
        }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: FitTodayRadius.sm)
                .fill(FitTodayColor.surfaceElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: FitTodayRadius.sm)
                        .stroke(FitTodayColor.outline.opacity(0.3), lineWidth: 1)
                )

            Image(systemName: iconName)
                .font(.system(size: size.iconSize, weight: .medium))
                .foregroundStyle(iconColor)
        }
        .frame(width: size.dimension, height: size.dimension)
    }

    private var iconName: String {
        switch muscleGroup {
        case .chest:
            return "figure.strengthtraining.traditional"
        case .back, .lats, .lowerBack:
            return "figure.rowing"
        case .shoulders:
            return "figure.arms.open"
        case .arms, .biceps, .triceps, .forearms:
            return "figure.boxing"
        case .core:
            return "figure.core.training"
        case .glutes:
            return "figure.run"
        case .quads, .quadriceps, .hamstrings, .calves:
            return "figure.walk"
        case .cardioSystem:
            return "heart.fill"
        case .fullBody:
            return "dumbbell.fill"
        }
    }

    private var iconColor: Color {
        switch muscleGroup {
        case .chest:
            return FitTodayColor.brandPrimary
        case .back, .lats, .lowerBack:
            return FitTodayColor.info
        case .shoulders:
            return FitTodayColor.warning
        case .arms, .biceps, .triceps, .forearms:
            return FitTodayColor.neonCyan
        case .core:
            return FitTodayColor.success
        case .glutes, .quads, .quadriceps, .hamstrings, .calves:
            return FitTodayColor.brandSecondary
        case .cardioSystem:
            return FitTodayColor.error
        case .fullBody:
            return FitTodayColor.neonPurple
        }
    }
}

// MARK: - Loading Placeholder

/// A loading placeholder with shimmer effect.
struct ExerciseLoadingPlaceholder: View {
    let size: ExercisePlaceholderView.PlaceholderSize
    @State private var isAnimating = false

    var body: some View {
        RoundedRectangle(cornerRadius: FitTodayRadius.sm)
            .fill(FitTodayColor.surfaceElevated)
            .overlay(
                RoundedRectangle(cornerRadius: FitTodayRadius.sm)
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                FitTodayColor.brandPrimary.opacity(0.1),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: isAnimating ? size.dimension * 2 : -size.dimension * 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.sm))
            .frame(width: size.dimension, height: size.dimension)
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Error Placeholder

/// A placeholder shown when image loading fails.
struct ExerciseErrorPlaceholder: View {
    let size: ExercisePlaceholderView.PlaceholderSize
    var onRetry: (() -> Void)?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: FitTodayRadius.sm)
                .fill(FitTodayColor.surfaceElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: FitTodayRadius.sm)
                        .stroke(FitTodayColor.error.opacity(0.3), lineWidth: 1)
                )

            VStack(spacing: FitTodaySpacing.xs) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: size.iconSize * 0.6, weight: .medium))
                    .foregroundStyle(FitTodayColor.error.opacity(0.7))

                if size != .small, let onRetry {
                    Button {
                        onRetry()
                    } label: {
                        Text("Retry")
                            .font(FitTodayFont.ui(size: 10, weight: .medium))
                            .foregroundStyle(FitTodayColor.textSecondary)
                    }
                }
            }
        }
        .frame(width: size.dimension, height: size.dimension)
    }
}

// MARK: - Preview

#Preview("Exercise Placeholders") {
    ScrollView {
        VStack(spacing: FitTodaySpacing.lg) {
            // Size variations
            HStack(spacing: FitTodaySpacing.md) {
                ExercisePlaceholderView(muscleGroup: .chest, size: .small)
                ExercisePlaceholderView(muscleGroup: .chest, size: .medium)
                ExercisePlaceholderView(muscleGroup: .chest, size: .large)
            }

            Divider()

            // Muscle group variations
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: FitTodaySpacing.md) {
                ForEach(MuscleGroup.allCases, id: \.self) { muscle in
                    VStack(spacing: FitTodaySpacing.xs) {
                        ExercisePlaceholderView(muscleGroup: muscle, size: .medium)
                        Text(muscle.rawValue)
                            .font(FitTodayFont.ui(size: 10, weight: .medium))
                            .foregroundStyle(FitTodayColor.textSecondary)
                    }
                }
            }

            Divider()

            // Loading state
            HStack(spacing: FitTodaySpacing.md) {
                ExerciseLoadingPlaceholder(size: .small)
                ExerciseLoadingPlaceholder(size: .medium)
                ExerciseLoadingPlaceholder(size: .large)
            }

            Divider()

            // Error state
            HStack(spacing: FitTodaySpacing.md) {
                ExerciseErrorPlaceholder(size: .small)
                ExerciseErrorPlaceholder(size: .medium) { print("Retry tapped") }
                ExerciseErrorPlaceholder(size: .large) { print("Retry tapped") }
            }
        }
        .padding()
    }
    .background(FitTodayColor.background)
    .preferredColorScheme(.dark)
}
