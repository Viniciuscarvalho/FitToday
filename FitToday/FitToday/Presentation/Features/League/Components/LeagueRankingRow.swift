//
//  LeagueRankingRow.swift
//  FitToday
//

import SwiftUI

/// A row displaying a league member's rank, avatar, name, and weekly XP.
struct LeagueRankingRow: View {
    let member: LeagueMember
    let totalMembers: Int

    private var isPromotionZone: Bool { member.rank <= 3 }
    private var isDemotionZone: Bool { member.rank > totalMembers - 3 }

    var body: some View {
        HStack(spacing: FitTodaySpacing.sm) {
            // Rank
            Text("#\(member.rank)")
                .font(FitTodayFont.ui(size: 16, weight: .bold))
                .foregroundStyle(rankColor)
                .frame(width: 36, alignment: .leading)

            // Avatar
            AsyncImage(url: member.avatarURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundStyle(FitTodayColor.textSecondary)
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())

            // Name
            Text(member.displayName)
                .font(FitTodayFont.ui(size: 14, weight: member.isCurrentUser ? .bold : .medium))
                .foregroundStyle(FitTodayColor.textPrimary)
                .lineLimit(1)

            Spacer()

            // Weekly XP
            Text("league.ranking.xp_format".localized(with: member.weeklyXP))
                .font(FitTodayFont.ui(size: 13, weight: .semiBold))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .padding(.horizontal, FitTodaySpacing.md)
        .padding(.vertical, FitTodaySpacing.sm)
        .background(rowBackground)
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.sm))
        .overlay {
            if member.isCurrentUser {
                RoundedRectangle(cornerRadius: FitTodayRadius.sm)
                    .stroke(FitTodayColor.brandPrimary, lineWidth: 1.5)
            }
        }
    }

    @ViewBuilder
    private var rowBackground: some View {
        if isPromotionZone {
            FitTodayColor.success.opacity(0.1)
        } else if isDemotionZone {
            FitTodayColor.error.opacity(0.1)
        } else {
            FitTodayColor.surface
        }
    }

    private var rankColor: Color {
        if isPromotionZone { return FitTodayColor.success }
        if isDemotionZone { return FitTodayColor.error }
        return FitTodayColor.textSecondary
    }
}
