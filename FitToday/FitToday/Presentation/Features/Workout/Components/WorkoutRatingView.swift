//
//  WorkoutRatingView.swift
//  FitToday
//
//  Created by Claude on 18/01/26.
//

import SwiftUI

/// View for collecting user feedback after completing a workout.
/// Displays three rating options: Muito Fácil, Adequado, Muito Difícil.
struct WorkoutRatingView: View {
    @Binding var selectedRating: WorkoutRating?
    let onRatingSelected: (WorkoutRating?) -> Void
    let onSkip: () -> Void

    @State private var hasAnimated = false

    var body: some View {
        VStack(spacing: FitTodaySpacing.lg) {
            // Title
            Text("Como foi o treino de hoje?")
                .font(.system(.headline, weight: .semibold))
                .foregroundStyle(FitTodayColor.textPrimary)

            // Rating buttons
            HStack(spacing: FitTodaySpacing.md) {
                ForEach(WorkoutRating.allCases, id: \.self) { rating in
                    RatingButton(
                        rating: rating,
                        isSelected: selectedRating == rating,
                        onTap: {
                            selectRating(rating)
                        }
                    )
                }
            }

            // Skip button
            Button(action: onSkip) {
                Text("Pular esta vez")
                    .font(.system(.subheadline))
                    .foregroundStyle(FitTodayColor.textSecondary)
            }
            .padding(.top, FitTodaySpacing.xs)
        }
        .padding(FitTodaySpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.lg)
                .fill(FitTodayColor.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: FitTodayRadius.lg)
                        .stroke(FitTodayColor.outline, lineWidth: 1)
                )
        )
        .opacity(hasAnimated ? 1 : 0)
        .offset(y: hasAnimated ? 0 : 20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
                hasAnimated = true
            }
        }
    }

    private func selectRating(_ rating: WorkoutRating) {
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedRating = rating
        }

        // Delay before calling completion to show selection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onRatingSelected(rating)
        }
    }
}

// MARK: - Rating Button

private struct RatingButton: View {
    let rating: WorkoutRating
    let isSelected: Bool
    let onTap: () -> Void

    private var backgroundColor: Color {
        if isSelected {
            return ratingColor.opacity(0.2)
        }
        return FitTodayColor.surface
    }

    private var borderColor: Color {
        if isSelected {
            return ratingColor
        }
        return FitTodayColor.outline
    }

    private var ratingColor: Color {
        switch rating {
        case .tooEasy:
            return .green
        case .adequate:
            return FitTodayColor.brandPrimary
        case .tooHard:
            return .orange
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: FitTodaySpacing.sm) {
                Text(rating.emoji)
                    .font(.system(size: 32))
                    .scaleEffect(isSelected ? 1.2 : 1.0)

                Text(rating.displayName)
                    .font(.system(.caption, weight: .medium))
                    .foregroundStyle(isSelected ? ratingColor : FitTodayColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, FitTodaySpacing.md)
            .padding(.horizontal, FitTodaySpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: FitTodayRadius.md)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: FitTodayRadius.md)
                            .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(rating.displayName), \(rating.emoji)")
        .accessibilityHint("Toque para avaliar o treino como \(rating.displayName)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        FitTodayColor.background.ignoresSafeArea()

        VStack {
            WorkoutRatingView(
                selectedRating: .constant(nil),
                onRatingSelected: { _ in },
                onSkip: {}
            )
            .padding()

            WorkoutRatingView(
                selectedRating: .constant(.adequate),
                onRatingSelected: { _ in },
                onSkip: {}
            )
            .padding()
        }
    }
}
