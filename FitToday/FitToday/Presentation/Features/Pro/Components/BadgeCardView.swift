//
//  BadgeCardView.swift
//  FitToday
//

import SwiftUI

struct BadgeCardView: View {
    let badge: Badge
    let isNewlyUnlocked: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(badge.isUnlocked
                        ? Color(hex: badge.rarity.color).opacity(0.15)
                        : FitTodayColor.backgroundElevated)
                    .frame(width: 56, height: 56)

                Image(systemName: badge.type.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(badge.isUnlocked
                        ? Color(hex: badge.rarity.color)
                        : FitTodayColor.textTertiary)

                if !badge.isUnlocked {
                    Circle()
                        .fill(.black.opacity(0.4))
                        .frame(width: 56, height: 56)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }

            Text(badge.type.displayName)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(badge.isUnlocked ? FitTodayColor.textPrimary : FitTodayColor.textTertiary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(FitTodayColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(badge.isUnlocked ? Color(hex: badge.rarity.color).opacity(0.4) : .clear, lineWidth: 1.5)
        )
        .scaleEffect(isNewlyUnlocked ? 1.0 : 1.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isNewlyUnlocked)
    }
}
