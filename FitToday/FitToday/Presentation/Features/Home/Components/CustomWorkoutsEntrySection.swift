//
//  CustomWorkoutsEntrySection.swift
//  FitToday
//
//  Created by Claude on 28/01/26.
//

import SwiftUI

/// Entry point section for Custom Workouts feature on the Home screen
struct CustomWorkoutsEntrySection: View {
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            SectionHeader(
                title: "My Workouts",
                actionTitle: nil,
                action: nil
            )
            .padding(.horizontal)

            Button(action: onTap) {
                HStack(spacing: FitTodaySpacing.md) {
                    // Icon
                    Image(systemName: "dumbbell.fill")
                        .font(.title2)
                        .foregroundStyle(FitTodayColor.brandPrimary)
                        .frame(width: 50, height: 50)
                        .background(FitTodayColor.brandPrimary.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Custom Workouts")
                            .font(.headline)
                            .foregroundStyle(FitTodayColor.textPrimary)

                        Text("Create and manage your own workout templates")
                            .font(.subheadline)
                            .foregroundStyle(FitTodayColor.textSecondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                        .foregroundStyle(FitTodayColor.textSecondary)
                }
                .padding(FitTodaySpacing.md)
                .background(FitTodayColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
        }
    }
}

// MARK: - Preview

#Preview {
    CustomWorkoutsEntrySection {
        print("Tapped")
    }
    .background(FitTodayColor.background)
}
