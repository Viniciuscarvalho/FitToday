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
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .frame(maxWidth: .infinity)
            .padding(.vertical, verticalPadding)
            .background(backgroundColor(configuration: configuration))
            .foregroundStyle(FitTodayColor.textInverse)  // Texto escuro em fundo lime
            .clipShape(Capsule())
            .opacity(isEnabled ? 1 : 0.4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .contentShape(Capsule())
            .fitGlowEffect(color: FitTodayColor.brandPrimary.opacity(isEnabled && !configuration.isPressed ? 0.3 : 0))
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
            .font(.system(size: 17, weight: .semibold, design: .rounded))
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
            .foregroundStyle(FitTodayColor.brandPrimary)
            .opacity(isEnabled ? (configuration.isPressed ? 0.7 : 1) : 0.4)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .contentShape(Capsule())
    }
}

struct FitDestructiveButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @ScaledMetric private var verticalPadding: CGFloat = 14

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .frame(maxWidth: .infinity)
            .padding(.vertical, verticalPadding)
            .background(
                Capsule()
                    .fill(configuration.isPressed ? FitTodayColor.error.opacity(0.8) : FitTodayColor.error)
            )
            .foregroundStyle(Color.white)
            .opacity(isEnabled ? 1 : 0.4)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .contentShape(Capsule())
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

