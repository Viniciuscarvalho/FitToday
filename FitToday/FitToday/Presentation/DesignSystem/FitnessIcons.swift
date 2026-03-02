//
//  FitnessIcons.swift
//  FitToday
//
//  Custom fitness-focused icons for the Home screen and stats cards.
//  Following the Retro-Futuristic / Purple Design System.
//

import SwiftUI

/// A collection of reusable fitness icons with the app's design system style.
struct FitnessIcon: View {
    let type: IconType
    var color: Color = FitTodayColor.brandPrimary
    var size: CGFloat = 24
    var showGlow: Bool = true

    enum IconType {
        case strength    // For Volume / Weight
        case intensity   // For Heart Rate / Effort
        case endurance   // For Duration / Time
        case consistency // For Streaks / Frequency
        case performance // For PRs / Trophies
    }

    var body: some View {
        ZStack {
            if showGlow {
                iconImage
                    .font(.system(size: size, weight: .bold))
                    .foregroundStyle(color.opacity(0.3))
                    .blur(radius: 6)
            }

            iconImage
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .frame(width: size * 1.5, height: size * 1.5)
    }

    @ViewBuilder
    private var iconImage: some View {
        switch type {
        case .strength:
            Image(systemName: "dumbbell.fill")
        case .intensity:
            Image(systemName: "bolt.fill")
        case .endurance:
            Image(systemName: "stopwatch.fill")
        case .consistency:
            Image(systemName: "calendar.badge.checkmark")
        case .performance:
            Image(systemName: "trophy.fill")
        }
    }
}

// MARK: - Reusable Metric Card Icon Container

struct MetricIconContainer: View {
    let type: FitnessIcon.IconType
    var color: Color = FitTodayColor.brandPrimary
    
    var body: some View {
        ZStack {
            // Background hex or square with grid
            RoundedRectangle(cornerRadius: 12)
                .fill(FitTodayColor.surfaceElevated)
                .frame(width: 48, height: 48)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
                .retroGridOverlay(lineColor: color.opacity(0.1), spacing: 12)
            
            FitnessIcon(type: type, color: color, size: 22)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            MetricIconContainer(type: .strength, color: FitTodayColor.brandPrimary)
            MetricIconContainer(type: .intensity, color: FitTodayColor.neonMagenta)
            MetricIconContainer(type: .endurance, color: FitTodayColor.neonCyan)
            MetricIconContainer(type: .consistency, color: FitTodayColor.neonYellow)
            MetricIconContainer(type: .performance, color: FitTodayColor.success)
        }
        
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                FitnessIcon(type: .strength)
                Text("Volume de Treino")
            }
            HStack {
                FitnessIcon(type: .intensity, color: FitTodayColor.neonMagenta)
                Text("Intensidade")
            }
            HStack {
                FitnessIcon(type: .endurance, color: FitTodayColor.neonCyan)
                Text("Duração")
            }
        }
        .padding()
        .background(FitTodayColor.surface)
        .preferredColorScheme(.dark)
    }
    .padding()
    .background(FitTodayColor.background)
}
