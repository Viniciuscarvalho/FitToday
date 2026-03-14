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

// MARK: - Color Hex Init

private extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        guard hexSanitized.count == 6,
              let hexNumber = UInt64(hexSanitized, radix: 16) else { return nil }
        let red = Double((hexNumber & 0xFF0000) >> 16) / 255.0
        let green = Double((hexNumber & 0x00FF00) >> 8) / 255.0
        let blue = Double(hexNumber & 0x0000FF) / 255.0
        self.init(red: red, green: green, blue: blue)
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
