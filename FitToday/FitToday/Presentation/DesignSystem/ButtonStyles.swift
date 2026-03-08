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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric private var verticalPadding: CGFloat = 16

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(FitTodayFont.ui(size: 17, weight: .bold))            .textCase(.uppercase)            .tracking(1.0)  // Letter spacing
            .frame(maxWidth: .infinity)
            .padding(.vertical, verticalPadding)
            .background(backgroundColor(configuration: configuration))
            .foregroundStyle(FitTodayColor.textInverse)
            .clipShape(Capsule())
            .overlay(
                Group {
                    if configuration.isPressed {
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                    }
                }
            )
            .opacity(isEnabled ? 1 : 0.4)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(reduceMotion ? .none : .spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
            .contentShape(Capsule())
            .fitGlowEffect(color: FitTodayColor.brandPrimary.opacity(isEnabled && !configuration.isPressed ? 0.3 : 0))
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
    }

    private func backgroundColor(configuration: Configuration) -> Color {
        configuration.isPressed ? FitTodayColor.brandPrimary.opacity(0.85) : FitTodayColor.brandPrimary
    }
}

struct FitSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric private var verticalPadding: CGFloat = 14

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(FitTodayFont.ui(size: 17, weight: .semiBold))            .textCase(.uppercase)            .tracking(1.0)  // Letter spacing
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
            .overlay(
                Group {
                    if configuration.isPressed {
                        Capsule()
                            .fill(FitTodayColor.brandPrimary.opacity(0.1))
                    }
                }
            )
            .foregroundStyle(FitTodayColor.brandPrimary)
            .opacity(isEnabled ? (configuration.isPressed ? 0.7 : 1) : 0.4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(reduceMotion ? .none : .spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
            .contentShape(Capsule())
            .fitGlowEffect(color: FitTodayColor.brandPrimary.opacity(isEnabled && !configuration.isPressed ? 0.2 : 0))
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
    }
}

struct FitDestructiveButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric private var verticalPadding: CGFloat = 14

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(FitTodayFont.ui(size: 17, weight: .semiBold))            .textCase(.uppercase)            .tracking(1.0)  // Letter spacing
            .frame(maxWidth: .infinity)
            .padding(.vertical, verticalPadding)
            .background(
                Capsule()
                    .fill(configuration.isPressed ? FitTodayColor.error.opacity(0.8) : FitTodayColor.error)
            )
            .overlay(
                Group {
                    if configuration.isPressed {
                        Capsule()
                            .fill(FitTodayColor.error.opacity(0.2))
                    }
                }
            )
            .foregroundStyle(Color.white)
            .opacity(isEnabled ? 1 : 0.4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(reduceMotion ? .none : .spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
            .contentShape(Capsule())
            .fitGlowEffect(color: FitTodayColor.error.opacity(isEnabled && !configuration.isPressed ? 0.2 : 0))
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
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

