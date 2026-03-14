//
//  LeagueHomeCard.swift
//  FitToday
//

import SwiftUI

/// Compact league card for the Home screen showing tier, rank, and countdown.
struct LeagueHomeCard: View {
    let tier: LeagueTier
    let rank: Int
    let countdown: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: FitTodaySpacing.sm) {
                LeagueTierBadge(tier: tier, size: .small)

                VStack(alignment: .leading, spacing: 2) {
                    Text("league.home_card.your_rank".localized(with: rank))
                        .font(FitTodayFont.ui(size: 14, weight: .semiBold))
                        .foregroundStyle(FitTodayColor.textPrimary)

                    if !countdown.isEmpty {
                        Text(countdown)
                            .font(FitTodayFont.ui(size: 12, weight: .medium))
                            .foregroundStyle(FitTodayColor.textSecondary)
                    }
                }

                Spacer()

                HStack(spacing: FitTodaySpacing.xs) {
                    Text("league.home_card.view".localized)
                        .font(FitTodayFont.ui(size: 13, weight: .medium))
                        .foregroundStyle(FitTodayColor.brandPrimary)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(FitTodayColor.brandPrimary)
                }
            }
            .padding(FitTodaySpacing.md)
            .background(FitTodayColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 16) {
        LeagueHomeCard(tier: .gold, rank: 2, countdown: "3d 12h") {}
        LeagueHomeCard(tier: .bronze, rank: 15, countdown: "1h") {}
        LeagueHomeCard(tier: .legend, rank: 1, countdown: "") {}
    }
    .padding()
    .background(FitTodayColor.background)
    .preferredColorScheme(.dark)
}
