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
                    .retroGridOverlay(spacing: 30)  // Grid overlay
                    .overlay(
                        RoundedRectangle(cornerRadius: FitTodayRadius.md)
                            .stroke(
                                isHighlighted ? FitTodayColor.neonCyan.opacity(0.6) : FitTodayColor.outline.opacity(0.3),  // Neon cyan when highlighted
                                lineWidth: isHighlighted ? 2 : 1
                            )
                    )
            )
            .techCornerBorders(color: isHighlighted ? FitTodayColor.neonCyan : FitTodayColor.techBorder)  // Tech corners
            .fitCardShadow()
            .scanlineOverlay()  // VHS scanline effect
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
                .font(FitTodayFont.ui(size: 17, weight: .semiBold))  // Retro font
                .foregroundStyle(FitTodayColor.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(FitTodayFont.ui(size: 13, weight: .medium))  // Retro font
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
                        .stroke(isSelected ? FitTodayColor.neonCyan : FitTodayColor.outline.opacity(0.4), lineWidth: isSelected ? 2 : 1)  // Neon cyan border
                )
        )
        .overlay(  // Diagonal accent on selection
            Group {
                if isSelected {
                    RoundedRectangle(cornerRadius: FitTodayRadius.md)
                        .fill(Color.clear)
                        .diagonalStripes(color: FitTodayColor.neonCyan, spacing: 12, opacity: 0.08)
                }
            }
        )
        .techCornerBorders(color: isSelected ? FitTodayColor.neonCyan.opacity(0.6) : FitTodayColor.techBorder.opacity(0.3), length: 12, thickness: 1.5)  // Tech corners
        .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: isSelected)
        .contentShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
        .fitGlowEffect(color: isSelected ? FitTodayColor.neonCyan.opacity(0.3) : Color.clear.opacity(0))  // Glow when selected
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
            .font(FitTodayFont.accent(size: 11))  // Bungee retro font
            .tracking(0.8)
            .padding(.horizontal, FitTodaySpacing.sm + 2)
            .padding(.vertical, FitTodaySpacing.xs + 2)
            .background(
                Capsule()
                    .fill(style.colors.background)
                    .diagonalStripes(color: style.colors.foreground, spacing: 6, opacity: 0.1)  // Diagonal stripes
            )
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
                .font(FitTodayFont.ui(size: 20, weight: .bold))  // Retro font
                .tracking(0.8)
                .foregroundStyle(FitTodayColor.textPrimary)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(FitTodayFont.ui(size: 16, weight: .medium))  // Retro font
                    .foregroundStyle(FitTodayColor.neonCyan)  // Neon cyan action
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
                .foregroundStyle(FitTodayColor.neonCyan.opacity(0.7))  // Neon cyan icon
                .fitGlowEffect(color: FitTodayColor.neonCyan.opacity(0.3))  // Neon glow

            VStack(spacing: FitTodaySpacing.sm) {
                Text(title)
                    .font(FitTodayFont.display(size: 20, weight: .bold))  // Retro display font
                    .foregroundStyle(FitTodayColor.textPrimary)
                Text(message)
                    .font(FitTodayFont.ui(size: 17, weight: .medium))  // Retro UI font
                    .foregroundStyle(FitTodayColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding()
        .background(
            Color.clear.retroGridOverlay(lineColor: FitTodayColor.gridLine.opacity(0.5), spacing: 40)  // Grid background
        )
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
                .fitGlowEffect(color: color.opacity(0.5))  // Icon glow

            Text(value)
                .font(FitTodayFont.display(size: 22, weight: .bold))  // Retro display font
                .foregroundStyle(FitTodayColor.textPrimary)

            Text(label)
                .font(FitTodayFont.ui(size: 12, weight: .medium))  // Retro UI font
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(FitTodaySpacing.md)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .fill(FitTodayColor.surface)
                .retroGridOverlay(spacing: 25)  // Grid overlay
                .overlay(
                    RoundedRectangle(cornerRadius: FitTodayRadius.md)
                        .stroke(FitTodayColor.outline.opacity(0.3), lineWidth: 1)
                )
        )
        .techCornerBorders()  // Tech corner borders
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

