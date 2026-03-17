//
//  LeagueTierBadge.swift
//  FitToday
//

import SwiftUI

/// Displays the league tier icon with optional name label.
struct LeagueTierBadge: View {
    let tier: LeagueTier
    var size: BadgeSize = .small

    enum BadgeSize {
        case small
        case large

        var iconSize: CGFloat {
            switch self {
            case .small: return 24
            case .large: return 44
            }
        }
    }

    var body: some View {
        HStack(spacing: FitTodaySpacing.xs) {
            Image(systemName: tier.icon)
                .font(.system(size: size.iconSize * 0.5))
                .frame(width: size.iconSize, height: size.iconSize)
                .foregroundStyle(tierColor)

            if size == .large {
                Text(tier.displayName)
                    .font(FitTodayFont.ui(size: 14, weight: .semiBold))
                    .foregroundStyle(tierColor)
            }
        }
    }

    private var tierColor: Color {
        Color(hex: tier.color) ?? FitTodayColor.textPrimary
    }
}


#Preview {
    VStack(spacing: 16) {
        ForEach(LeagueTier.allCases, id: \.self) { tier in
            HStack(spacing: 20) {
                LeagueTierBadge(tier: tier, size: .small)
                LeagueTierBadge(tier: tier, size: .large)
            }
        }
    }
    .padding()
    .background(FitTodayColor.background)
}
