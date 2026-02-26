//
//  FitOrbView.swift
//  FitToday
//
//  Animated orb branding for the FitOrb AI assistant.
//

import SwiftUI

struct FitOrbView: View {

    @State private var isPulsing = false

    var body: some View {
        VStack(spacing: FitTodaySpacing.md) {
            // Animated orb
            Circle()
                .fill(
                    LinearGradient(
                        colors: [FitTodayColor.brandPrimary, FitTodayColor.brandSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
                .shadow(color: FitTodayColor.brandPrimary.opacity(0.5), radius: isPulsing ? 24 : 12)
                .scaleEffect(isPulsing ? 1.05 : 1.0)
                .animation(
                    .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                    value: isPulsing
                )
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.system(size: 40))
                        .foregroundStyle(.white)
                )

            // Title
            Text("fitorb.title".localized)
                .font(FitTodayFont.display(size: 24, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)

            // Subtitle
            Text("fitorb.subtitle".localized)
                .font(FitTodayFont.ui(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .onAppear {
            isPulsing = true
        }
    }
}

#Preview {
    FitOrbView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FitTodayColor.background)
}
