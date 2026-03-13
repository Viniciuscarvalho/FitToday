//
//  XPLevelCard.swift
//  FitToday
//

import SwiftUI

struct XPLevelCard: View {
    let userXP: UserXP

    @State private var animatedProgress: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            // Level header
            HStack(spacing: FitTodaySpacing.xs) {
                Image(systemName: userXP.levelTitle.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(FitTodayColor.brandPrimary)

                Text("Nível \(userXP.level) — \(userXP.levelTitle.rawValue)")
                    .font(FitTodayFont.ui(size: 14, weight: .semiBold))
                    .foregroundStyle(FitTodayColor.textPrimary)

                Spacer()

                Text("\(userXP.currentLevelXP) / 1000 XP")
                    .font(FitTodayFont.ui(size: 12, weight: .medium))
                    .foregroundStyle(FitTodayColor.textSecondary)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(FitTodayColor.surfaceElevated)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(FitTodayColor.brandPrimary)
                        .frame(width: geometry.size.width * animatedProgress, height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(FitTodaySpacing.md)
        .background(FitTodayColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                animatedProgress = userXP.levelProgress
            }
        }
        .onChange(of: userXP.totalXP) {
            withAnimation(.easeOut(duration: 0.4)) {
                animatedProgress = userXP.levelProgress
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        XPLevelCard(userXP: UserXP(totalXP: 750))
        XPLevelCard(userXP: UserXP(totalXP: 4500))
        XPLevelCard(userXP: UserXP(totalXP: 0))
    }
    .padding()
    .background(FitTodayColor.background)
    .preferredColorScheme(.dark)
}
