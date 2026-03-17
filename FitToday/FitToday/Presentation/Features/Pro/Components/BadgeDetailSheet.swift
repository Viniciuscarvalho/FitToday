//
//  BadgeDetailSheet.swift
//  FitToday
//

import SwiftUI

struct BadgeDetailSheet: View {
    let badge: Badge
    var onToggleVisibility: (Bool) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isPublic: Bool

    init(badge: Badge, onToggleVisibility: @escaping (Bool) -> Void) {
        self.badge = badge
        self.onToggleVisibility = onToggleVisibility
        self._isPublic = State(initialValue: badge.isPublic)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: FitTodaySpacing.xl) {
                // Icon
                ZStack {
                    Circle()
                        .fill(badge.isUnlocked
                            ? Color(hex: badge.rarity.color).opacity(0.15)
                            : FitTodayColor.backgroundElevated)
                        .frame(width: 96, height: 96)

                    Image(systemName: badge.type.icon)
                        .font(.system(size: 44))
                        .foregroundStyle(badge.isUnlocked
                            ? Color(hex: badge.rarity.color)
                            : FitTodayColor.textTertiary)
                }
                .padding(.top, FitTodaySpacing.xl)

                // Name + Rarity
                VStack(spacing: 6) {
                    Text(badge.type.displayName)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(FitTodayColor.textPrimary)

                    Text(badge.rarity.displayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(hex: badge.rarity.color))
                }

                // Criteria
                VStack(spacing: 4) {
                    Text("badge.criteria.prefix".localized)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(FitTodayColor.textSecondary)
                    Text(badge.type.description)
                        .font(.system(size: 15))
                        .foregroundStyle(FitTodayColor.textPrimary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, FitTodaySpacing.lg)

                // Unlock date
                if let unlockedAt = badge.unlockedAt {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(FitTodayColor.success)
                        Text("\("badge.unlocked_at".localized) \(unlockedAt.formatted(date: .abbreviated, time: .omitted))")
                            .font(.system(size: 13))
                            .foregroundStyle(FitTodayColor.textSecondary)
                    }
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(FitTodayColor.textTertiary)
                        Text("badge.locked".localized)
                            .font(.system(size: 13))
                            .foregroundStyle(FitTodayColor.textTertiary)
                    }
                }

                if badge.isUnlocked {
                    // Privacy toggle
                    Toggle(isOn: $isPublic) {
                        Label("badge.public_toggle".localized, systemImage: "eye")
                            .font(.system(size: 15))
                    }
                    .padding(.horizontal, FitTodaySpacing.lg)
                    .onChange(of: isPublic) { _, newValue in
                        onToggleVisibility(newValue)
                    }

                    // Share button
                    ShareLink(item: shareBadgeText) {
                        Label("badge.share".localized, systemImage: "square.and.arrow.up")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(hex: badge.rarity.color))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, FitTodaySpacing.lg)
                }

                Spacer()
            }
            .background(FitTodayColor.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(FitTodayColor.textTertiary)
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var shareBadgeText: String {
        String(
            format: NSLocalizedString("badge.share.text", comment: ""),
            badge.type.displayName,
            badge.rarity.displayName
        )
    }
}
