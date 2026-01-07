//
//  ButtonStyles.swift
//  FitToday
//
//  Design System - Button Styles
//  Dark Theme (Gym App UI Kit Style)
//

import SwiftUI

struct FitPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @ScaledMetric private var verticalPadding: CGFloat = 16

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(FitTodayFont.ui(size: 17, weight: .bold))  // Retro font
            .textCase(.uppercase)  // Uppercase retro style
            .tracking(1.0)  // Letter spacing
            .frame(maxWidth: .infinity)
            .padding(.vertical, verticalPadding)
            .background(backgroundColor(configuration: configuration))
            .foregroundStyle(FitTodayColor.textInverse)
            .clipShape(Capsule())
            .overlay(  // Diagonal stripes on press
                Group {
                    if configuration.isPressed {
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .diagonalStripes(color: .white, spacing: 6, opacity: 0.15)
                    }
                }
            )
            .techCornerBorders(length: 16, thickness: 1.5)  // Tech corners
            .opacity(isEnabled ? 1 : 0.4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .contentShape(Capsule())
            .fitGlowEffect(color: FitTodayColor.neonCyan.opacity(isEnabled && !configuration.isPressed ? 0.3 : 0))  // Neon cyan glow
    }

    private func backgroundColor(configuration: Configuration) -> Color {
        configuration.isPressed ? FitTodayColor.brandPrimary.opacity(0.85) : FitTodayColor.brandPrimary
    }
}

struct FitSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @ScaledMetric private var verticalPadding: CGFloat = 14

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(FitTodayFont.ui(size: 17, weight: .semiBold))  // Retro font
            .textCase(.uppercase)  // Uppercase retro style
            .tracking(1.0)  // Letter spacing
            .frame(maxWidth: .infinity)
            .padding(.vertical, verticalPadding)
            .background(
                Capsule()
                    .fill(FitTodayColor.surface)
                    .overlay(
                        Capsule()
                            .stroke(FitTodayColor.brandPrimary, lineWidth: 1.5)
                    )
            )
            .overlay(  // Diagonal accent on press
                Group {
                    if configuration.isPressed {
                        Capsule()
                            .fill(FitTodayColor.brandPrimary.opacity(0.1))
                            .diagonalStripes(color: FitTodayColor.brandPrimary, spacing: 8, opacity: 0.15)
                    }
                }
            )
            .techCornerBorders(color: FitTodayColor.brandPrimary.opacity(0.6), length: 14, thickness: 1.5)  // Tech corners
            .foregroundStyle(FitTodayColor.brandPrimary)
            .opacity(isEnabled ? (configuration.isPressed ? 0.7 : 1) : 0.4)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .contentShape(Capsule())
            .fitGlowEffect(color: FitTodayColor.neonCyan.opacity(isEnabled && !configuration.isPressed ? 0.2 : 0))  // Subtle glow
    }
}

struct FitDestructiveButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @ScaledMetric private var verticalPadding: CGFloat = 14

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(FitTodayFont.ui(size: 17, weight: .semiBold))  // Retro font
            .textCase(.uppercase)  // Uppercase retro style
            .tracking(1.0)  // Letter spacing
            .frame(maxWidth: .infinity)
            .padding(.vertical, verticalPadding)
            .background(
                Capsule()
                    .fill(configuration.isPressed ? FitTodayColor.error.opacity(0.8) : FitTodayColor.error)
            )
            .overlay(  // Glitch effect on press
                Group {
                    if configuration.isPressed {
                        Capsule()
                            .fill(FitTodayColor.glitchRed.opacity(0.2))
                            .diagonalStripes(color: .white, spacing: 6, opacity: 0.15)
                    }
                }
            )
            .techCornerBorders(color: FitTodayColor.glitchRed.opacity(0.6), length: 14, thickness: 1.5)  // Tech corners
            .foregroundStyle(Color.white)
            .opacity(isEnabled ? 1 : 0.4)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .contentShape(Capsule())
            .fitGlowEffect(color: FitTodayColor.error.opacity(isEnabled && !configuration.isPressed ? 0.2 : 0))  // Error glow
    }
}

extension Button {
    func fitPrimaryStyle() -> some View {
        buttonStyle(FitPrimaryButtonStyle())
            .buttonBorderShape(.capsule)
    }

    func fitSecondaryStyle() -> some View {
        buttonStyle(FitSecondaryButtonStyle())
            .buttonBorderShape(.capsule)
    }
    
    func fitDestructiveStyle() -> some View {
        buttonStyle(FitDestructiveButtonStyle())
            .buttonBorderShape(.capsule)
    }
}

#Preview("Buttons") {
    VStack(spacing: 16) {
        Button("Começar treino") {}
            .fitPrimaryStyle()
        Button("Ver treinos básicos") {}
            .fitSecondaryStyle()
        Button("Cancelar treino") {}
            .fitDestructiveStyle()
        Button("Desabilitado") {}
            .fitPrimaryStyle()
            .disabled(true)
    }
    .padding()
    .background(FitTodayColor.background)
    .preferredColorScheme(.dark)
}

