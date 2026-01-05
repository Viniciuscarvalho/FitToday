//
//  CardsAndBadges.swift
//  FitToday
//
//  Design System - Cards & Badges
//  Dark Theme (Gym App UI Kit Style)
//

import SwiftUI

struct FitCard<Content: View>: View {
    let content: Content
    var isHighlighted: Bool = false

    init(isHighlighted: Bool = false, @ViewBuilder content: () -> Content) {
        self.isHighlighted = isHighlighted
        self.content = content()
    }

    var body: some View {
        content
            .padding(FitTodaySpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: FitTodayRadius.md)
                    .fill(FitTodayColor.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: FitTodayRadius.md)
                            .stroke(
                                isHighlighted ? FitTodayColor.brandPrimary.opacity(0.5) : FitTodayColor.outline.opacity(0.3),
                                lineWidth: isHighlighted ? 2 : 1
                            )
                    )
            )
            .fitCardShadow()
    }
}

struct OptionCard: View {
    let title: String
    let subtitle: String?
    let isSelected: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(FitTodayColor.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(FitTodayColor.textSecondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .fill(isSelected ? FitTodayColor.brandPrimary.opacity(0.12) : FitTodayColor.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: FitTodayRadius.md)
                        .stroke(isSelected ? FitTodayColor.brandPrimary : FitTodayColor.outline.opacity(0.4), lineWidth: isSelected ? 2 : 1)
                )
        )
        .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: isSelected)
        .contentShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
    }
}

struct FitBadge: View {
    let text: String
    let style: Style

    enum Style {
        case info, success, warning, pro, error

        var colors: (background: Color, foreground: Color) {
            switch self {
            case .info:
                return (FitTodayColor.brandPrimary.opacity(0.2), FitTodayColor.brandPrimary)
            case .success:
                return (FitTodayColor.success.opacity(0.2), FitTodayColor.success)
            case .warning:
                return (FitTodayColor.warning.opacity(0.2), FitTodayColor.warning)
            case .pro:
                return (Color(hex: "#FFD700").opacity(0.2), Color(hex: "#FFD700"))
            case .error:
                return (FitTodayColor.error.opacity(0.2), FitTodayColor.error)
            }
        }
    }

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .tracking(0.5)
            .padding(.horizontal, FitTodaySpacing.sm + 2)
            .padding(.vertical, FitTodaySpacing.xs + 2)
            .background(style.colors.background)
            .foregroundColor(style.colors.foreground)
            .clipShape(Capsule())
    }
}

struct SectionHeader: View {
    let title: String
    let actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(FitTodayColor.textPrimary)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(FitTodayColor.brandPrimary)
            }
        }
        .padding(.horizontal)
        .padding(.top, FitTodaySpacing.md)
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    var systemIcon: String = "figure.run.circle"

    var body: some View {
        VStack(spacing: FitTodaySpacing.lg) {
            Image(systemName: systemIcon)
                .font(.system(size: 64))
                .foregroundStyle(FitTodayColor.brandPrimary.opacity(0.6))
            
            VStack(spacing: FitTodaySpacing.sm) {
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(FitTodayColor.textPrimary)
                Text(message)
                    .font(.system(size: 17))
                    .foregroundStyle(FitTodayColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding()
    }
}

// MARK: - Stat Card (para métricas)

struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    var color: Color = FitTodayColor.brandPrimary
    
    var body: some View {
        VStack(spacing: FitTodaySpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(color)
            
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(FitTodayColor.textPrimary)
            
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(FitTodaySpacing.md)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .fill(FitTodayColor.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: FitTodayRadius.md)
                        .stroke(FitTodayColor.outline.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview("Cards & Badges") {
    ScrollView {
        VStack(spacing: 16) {
            FitCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Treino de hoje")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(FitTodayColor.textPrimary)
                    Text("45 minutos • Hipertrofia")
                        .foregroundStyle(FitTodayColor.textSecondary)
                    Button("Começar treino") {}
                        .fitPrimaryStyle()
                }
            }

            OptionCard(title: "Superior", subtitle: "Empurre/puxe", isSelected: true)
            OptionCard(title: "Inferior", subtitle: "Força e mobilidade", isSelected: false)

            HStack {
                FitBadge(text: "Pro", style: .pro)
                FitBadge(text: "Novo", style: .success)
                FitBadge(text: "Atenção", style: .warning)
            }
            
            HStack(spacing: FitTodaySpacing.md) {
                StatCard(value: "45", label: "minutos", icon: "clock.fill")
                StatCard(value: "12", label: "exercícios", icon: "dumbbell.fill", color: FitTodayColor.brandSecondary)
            }
            
            EmptyStateView(
                title: "Nenhum treino",
                message: "Complete o questionário para gerar seu treino de hoje."
            )
            .frame(height: 200)
        }
        .padding()
    }
    .background(FitTodayColor.background)
    .preferredColorScheme(.dark)
}

