//
//  BadgesGridView.swift
//  FitToday
//

import SwiftUI

struct BadgesGridView: View {
    let badges: [Badge]
    let newlyUnlockedIds: Set<String>
    var onBadgeTap: (Badge) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            Text("badge.section.title".localized)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(FitTodayColor.textSecondary)
                .padding(.leading, 4)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(badges) { badge in
                    BadgeCardView(
                        badge: badge,
                        isNewlyUnlocked: newlyUnlockedIds.contains(badge.id)
                    )
                    .onTapGesture { onBadgeTap(badge) }
                }
            }
        }
    }
}
