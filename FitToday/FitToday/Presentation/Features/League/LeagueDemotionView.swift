//
//  LeagueDemotionView.swift
//  FitToday
//

import SwiftUI

/// Full-screen demotion notice with subtle shake animation.
struct LeagueDemotionView: View {
    let tier: LeagueTier
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showContent = false
    @State private var shakeOffset: CGFloat = 0

    var body: some View {
        ZStack {
            FitTodayColor.background.ignoresSafeArea()

            VStack(spacing: FitTodaySpacing.lg) {
                Spacer()

                LeagueTierBadge(tier: tier, size: .large)
                    .offset(x: shakeOffset)
                    .opacity(showContent ? 1 : 0)

                Text("league.demoted.title".localized)
                    .font(FitTodayFont.ui(size: 28, weight: .bold))
                    .foregroundStyle(FitTodayColor.error)
                    .opacity(showContent ? 1 : 0)

                Text(tier.displayName)
                    .font(FitTodayFont.ui(size: 20, weight: .semiBold))
                    .foregroundStyle(FitTodayColor.textPrimary)
                    .opacity(showContent ? 1 : 0)

                Text("league.demoted.message".localized)
                    .font(FitTodayFont.ui(size: 14, weight: .medium))
                    .foregroundStyle(FitTodayColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .opacity(showContent ? 1 : 0)

                Spacer()

                Button("league.demoted.dismiss".localized) { onDismiss() }
                    .fitSecondaryStyle()
                    .padding(.horizontal, FitTodaySpacing.xl)
                    .opacity(showContent ? 1 : 0)
            }
            .padding()
        }
        .onAppear {
            guard !reduceMotion else {
                showContent = true
                return
            }
            withAnimation(.easeOut(duration: 0.4)) {
                showContent = true
            }
            triggerShake()
        }
        .task {
            try? await Task.sleep(for: .seconds(5))
            onDismiss()
        }
    }

    private func triggerShake() {
        withAnimation(.default.repeatCount(5, autoreverses: true).speed(4)) {
            shakeOffset = 8
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.2)) {
                shakeOffset = 0
            }
        }
    }
}
