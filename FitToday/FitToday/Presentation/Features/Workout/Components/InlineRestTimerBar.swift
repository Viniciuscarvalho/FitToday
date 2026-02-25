//
//  InlineRestTimerBar.swift
//  FitToday
//
//  Compact inline rest timer shown between sets during execution.
//

import SwiftUI

struct InlineRestTimerBar: View {
    @Bindable var timerStore: RestTimerStore

    var body: some View {
        HStack(spacing: FitTodaySpacing.md) {
            // Mini progress ring
            MiniProgressRing(progress: timerStore.progressPercentage, size: 32)

            // Time
            Text(timerStore.formattedTime)
                .font(FitTodayFont.ui(size: 18, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(FitTodayColor.textPrimary)

            Spacer()

            // +30s
            Button {
                timerStore.addTime(30)
            } label: {
                Text("+30s")
                    .font(FitTodayFont.ui(size: 13, weight: .semiBold))
                    .foregroundStyle(FitTodayColor.textPrimary)
                    .padding(.horizontal, FitTodaySpacing.sm)
                    .padding(.vertical, 6)
                    .background(FitTodayColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.sm))
            }
            .buttonStyle(.plain)

            // Skip
            Button {
                timerStore.stop()
            } label: {
                Text("execution.skip_rest".localized)
                    .font(FitTodayFont.ui(size: 13, weight: .semiBold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, FitTodaySpacing.sm)
                    .padding(.vertical, 6)
                    .background(FitTodayColor.brandPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.sm))
            }
            .buttonStyle(.plain)
        }
        .padding(FitTodaySpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .fill(FitTodayColor.brandPrimary.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .stroke(FitTodayColor.brandPrimary.opacity(0.3), lineWidth: 1)
        )
    }
}
