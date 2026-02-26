//
//  WeekStreakRow.swift
//  FitToday
//
//  Shows 7 day circles for the current week with streak count.
//

import SwiftUI

struct WeekStreakRow: View {
    let completedDays: Set<Int>
    let currentStreak: Int

    private let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]
    private let circleSize: CGFloat = 36

    private var todayWeekday: Int {
        Calendar.current.component(.weekday, from: Date()) - 1 // 0=Sunday
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            // Streak label
            HStack(spacing: FitTodaySpacing.xs) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(FitTodayColor.brandPrimary)
                Text("\(currentStreak) day streak")
                    .font(FitTodayFont.ui(size: 14, weight: .semiBold))
                    .foregroundStyle(FitTodayColor.textPrimary)
            }

            // Day circles
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { index in
                    dayCircle(for: index)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(FitTodaySpacing.md)
        .background(FitTodayColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
    }

    @ViewBuilder
    private func dayCircle(for index: Int) -> some View {
        let isCompleted = completedDays.contains(index)
        let isToday = index == todayWeekday

        VStack(spacing: FitTodaySpacing.xs) {
            ZStack {
                Circle()
                    .fill(isCompleted ? FitTodayColor.brandPrimary : FitTodayColor.surfaceElevated)
                    .frame(width: circleSize, height: circleSize)

                if isToday {
                    Circle()
                        .stroke(FitTodayColor.brandSecondary, lineWidth: 2)
                        .frame(width: circleSize, height: circleSize)
                }

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(FitTodayColor.textPrimary)
                }
            }

            Text(dayLabels[index])
                .font(FitTodayFont.ui(size: 12, weight: .medium))
                .foregroundStyle(isToday ? FitTodayColor.textPrimary : FitTodayColor.textSecondary)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        WeekStreakRow(completedDays: [1, 2, 3], currentStreak: 3)
        WeekStreakRow(completedDays: [0, 1, 2, 3, 4, 5, 6], currentStreak: 7)
        WeekStreakRow(completedDays: [], currentStreak: 0)
    }
    .padding()
    .background(FitTodayColor.background)
    .preferredColorScheme(.dark)
}
