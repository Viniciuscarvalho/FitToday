//
//  StreakBanner.swift
//  FitToday
//
//  Simple banner showing current streak days.
//

import SwiftUI

/// Banner displaying the user's current workout streak.
struct StreakBanner: View {
    let streakDays: Int

    var body: some View {
        HStack(spacing: FitTodaySpacing.sm) {
            Image(systemName: "flame.fill")
                .font(.system(size: 16))
                .foregroundStyle(FitTodayColor.brandPrimary)

            Text(String(format: NSLocalizedString("home.streak.banner", comment: "Streak banner"), streakDays))
                .font(FitTodayFont.ui(size: 14, weight: .semiBold))
                .foregroundStyle(FitTodayColor.textPrimary)

            Spacer()
        }
        .padding(.horizontal, FitTodaySpacing.md)
        .padding(.vertical, FitTodaySpacing.sm)
        .background(FitTodayColor.brandPrimary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.sm))
        .overlay(
            RoundedRectangle(cornerRadius: FitTodayRadius.sm)
                .stroke(FitTodayColor.brandPrimary.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        StreakBanner(streakDays: 5)
        StreakBanner(streakDays: 12)
        StreakBanner(streakDays: 0)
    }
    .background(FitTodayColor.background)
    .preferredColorScheme(.dark)
}
