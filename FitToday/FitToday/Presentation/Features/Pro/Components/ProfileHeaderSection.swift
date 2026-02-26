//
//  ProfileHeaderSection.swift
//  FitToday
//

import SwiftUI

/// Profile header displaying a gradient avatar circle with initials and the user's name.
struct ProfileHeaderSection: View {
    var name: String = "Athlete"

    private var initials: String {
        String(name.prefix(2)).uppercased()
    }

    var body: some View {
        VStack(spacing: FitTodaySpacing.md) {
            // Avatar circle
            ZStack {
                Circle()
                    .fill(FitTodayColor.gradientPrimary)
                    .frame(width: 80, height: 80)

                Text(initials)
                    .font(FitTodayFont.display(size: 28, weight: .bold))
                    .foregroundStyle(.white)
            }

            // Name
            Text(name)
                .font(FitTodayFont.ui(size: 20, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 32) {
        ProfileHeaderSection()
        ProfileHeaderSection(name: "Vinicius")
    }
    .padding()
    .background(FitTodayColor.background)
    .preferredColorScheme(.dark)
}
