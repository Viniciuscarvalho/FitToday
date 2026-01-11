//
//  FlowComponents.swift
//  FitToday
//
//  Created by AI on 03/01/26.
//

import SwiftUI

struct StepperHeader: View {
    let title: String
    let step: Int
    let totalSteps: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Passo \(step) de \(totalSteps)")
                .font(FitTodayFont.ui(size: 12, weight: .medium))  // Retro font
                .textCase(.uppercase)  // Uppercase retro style
                .tracking(0.8)
                .foregroundStyle(FitTodayColor.textSecondary)
            Text(title)
                .font(FitTodayFont.display(size: 24, weight: .bold))  // Retro font
                .tracking(1.0)
                .foregroundStyle(FitTodayColor.textPrimary)
            ProgressView(value: Double(step), total: Double(totalSteps))
                .tint(FitTodayColor.brandPrimary)
        }
        .padding(.vertical, FitTodaySpacing.sm)
    }
}

struct ProgressPill: View {
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: FitTodaySpacing.sm) {
            Text(label)
                .font(FitTodayFont.ui(size: 12, weight: .medium))  // Retro font
                .foregroundStyle(.secondary)
            Text(value)
                .font(FitTodayFont.ui(size: 17, weight: .semiBold))  // Retro font
                .foregroundStyle(FitTodayColor.textPrimary)
        }
        .padding(.horizontal, FitTodaySpacing.md)
        .padding(.vertical, FitTodaySpacing.sm)
        .background(FitTodayColor.surface)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(FitTodayColor.outline.opacity(0.4), lineWidth: 1)
        )
    }
}

struct PaywallFeatureRow: View {
    let iconName: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: FitTodaySpacing.md) {
            Image(systemName: iconName)
                .font(.title3)
                .foregroundStyle(FitTodayColor.brandPrimary)
                .frame(width: 44, height: 44)
                .background(FitTodayColor.brandPrimary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.sm))
                .fitGlowEffect(color: FitTodayColor.brandPrimary.opacity(0.3))  // Neon glow

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(FitTodayFont.ui(size: 17, weight: .semiBold))  // Retro font
                Text(subtitle)
                    .font(FitTodayFont.ui(size: 15, weight: .medium))  // Retro font
                    .foregroundStyle(FitTodayColor.textSecondary)
            }
            Spacer()
        }
        .padding(.vertical, FitTodaySpacing.sm)
    }
}

#Preview("Flow components") {
    VStack(alignment: .leading, spacing: 20) {
        StepperHeader(title: "Qual é o seu objetivo principal?", step: 2, totalSteps: 6)
        ProgressPill(label: "Foco", value: "Hipertrofia")
        PaywallFeatureRow(
            iconName: "sparkles",
            title: "IA personalizada",
            subtitle: "Treinos combinados com dados da ExerciseDB e bloco curado"
        )
        PaywallFeatureRow(
            iconName: "bolt.heart",
            title: "Ajuste por dor",
            subtitle: "Adaptamos volume e grupos para você recuperar melhor"
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}




