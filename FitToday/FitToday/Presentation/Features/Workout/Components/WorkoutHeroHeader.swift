//
//  WorkoutHeroHeader.swift
//  FitToday
//

import SwiftUI

/// Hero header for the workout detail screen.
/// Displays a large icon with gradient overlay, title, subtitle, and metadata badges.
struct WorkoutHeroHeader: View {
    let title: String
    let subtitle: String?
    let duration: String
    let level: String
    var imageSystemName: String = "dumbbell.fill"

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background
            FitTodayColor.surfaceElevated
                .overlay(
                    LinearGradient(
                        colors: [
                            FitTodayColor.brandPrimary.opacity(0.3),
                            FitTodayColor.brandAccent.opacity(0.1),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Large semi-transparent icon
            Image(systemName: imageSystemName)
                .font(.system(size: 80, weight: .light))
                .foregroundStyle(FitTodayColor.brandPrimary.opacity(0.15))
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Bottom gradient overlay
            LinearGradient(
                colors: [Color.clear, FitTodayColor.background.opacity(0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 120)
            .frame(maxHeight: .infinity, alignment: .bottom)

            // Content overlay
            VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
                Text(title)
                    .font(FitTodayFont.display(size: 24, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(FitTodayColor.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(FitTodayFont.ui(size: 15, weight: .medium))
                        .foregroundStyle(FitTodayColor.textSecondary)
                }

                HStack(spacing: FitTodaySpacing.sm) {
                    heroBadge(icon: "clock", text: duration)
                    heroBadge(icon: "chart.bar.fill", text: level)
                }
            }
            .padding(FitTodaySpacing.lg)
        }
        .frame(height: 250)
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.lg))
    }

    // MARK: - Badge

    private func heroBadge(icon: String, text: String) -> some View {
        HStack(spacing: FitTodaySpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
            Text(text)
                .font(FitTodayFont.ui(size: 13, weight: .semiBold))
        }
        .foregroundStyle(FitTodayColor.textPrimary)
        .padding(.horizontal, FitTodaySpacing.sm)
        .padding(.vertical, FitTodaySpacing.xs)
        .background(FitTodayColor.surface.opacity(0.8))
        .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview {
    WorkoutHeroHeader(
        title: "Push Day",
        subtitle: "Chest, Shoulders, Triceps",
        duration: "45 min",
        level: "Intermediate"
    )
    .padding()
    .background(FitTodayColor.background)
    .preferredColorScheme(.dark)
}
