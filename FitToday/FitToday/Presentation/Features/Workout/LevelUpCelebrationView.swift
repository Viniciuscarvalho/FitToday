//
//  LevelUpCelebrationView.swift
//  FitToday
//

import SwiftUI

struct LevelUpCelebrationView: View {
    let level: Int
    let levelTitle: XPLevel
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showContent = false
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            if !reduceMotion {
                ConfettiView(isAnimating: $isAnimating)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            VStack(spacing: FitTodaySpacing.lg) {
                Image(systemName: levelTitle.icon)
                    .font(.system(size: 64))
                    .foregroundStyle(FitTodayColor.brandPrimary)

                Text("gamification.level_up.title".localized)
                    .font(.system(.largeTitle, weight: .bold))
                    .foregroundStyle(FitTodayColor.textPrimary)

                Text("gamification.level_up.level_format".localized(with: level))
                    .font(.system(.title, weight: .bold))
                    .foregroundStyle(FitTodayColor.brandPrimary)

                Text(levelTitle.localizationKey.localized)
                    .font(.system(.title2, weight: .semibold))
                    .foregroundStyle(FitTodayColor.textSecondary)
            }
            .scaleEffect(showContent ? 1 : 0.5)
            .opacity(showContent ? 1 : 0)
        }
        .onAppear {
            isAnimating = true
            withAnimation(reduceMotion ? .none : .spring(response: 0.5, dampingFraction: 0.6)) {
                showContent = true
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(5))
            onDismiss()
        }
    }
}
