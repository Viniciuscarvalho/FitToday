//
//  RestTimerModal.swift
//  FitToday
//
//  Modal view for rest timer between sets.
//

import SwiftUI

/// Modal view displaying the rest timer between sets.
struct RestTimerModal: View {
    @Environment(RestTimerStore.self) private var timerStore
    let nextExerciseName: String?
    let onSkip: () -> Void
    let onComplete: () -> Void

    @State private var animationProgress: CGFloat = 0

    var body: some View {
        VStack(spacing: FitTodaySpacing.xl) {
            // Title
            Text("rest_timer.title".localized)
                .font(FitTodayFont.display(size: 28, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)

            // Circular Timer
            circularTimer

            // Next Exercise Info
            if let nextExercise = nextExerciseName {
                nextExerciseSection(nextExercise)
            }

            // Action Buttons
            actionButtons

            Spacer()
        }
        .padding(FitTodaySpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FitTodayColor.background)
        .onChange(of: timerStore.isFinished) { _, finished in
            if finished {
                onComplete()
            }
        }
        .onAppear {
            withAnimation(.linear(duration: Double(timerStore.totalSeconds))) {
                animationProgress = 1
            }
        }
    }

    // MARK: - Circular Timer

    private var circularTimer: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(FitTodayColor.outline, lineWidth: 12)
                .frame(width: 200, height: 200)

            // Progress circle
            Circle()
                .trim(from: 0, to: 1 - timerStore.progressPercentage)
                .stroke(
                    LinearGradient(
                        colors: [FitTodayColor.brandPrimary, FitTodayColor.brandSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: timerStore.progressPercentage)

            // Time display
            VStack(spacing: FitTodaySpacing.xs) {
                Text(timerStore.formattedTime)
                    .font(FitTodayFont.display(size: 56, weight: .bold))
                    .foregroundStyle(FitTodayColor.textPrimary)
                    .contentTransition(.numericText())

                Text("\(timerStore.remainingSeconds) seg")
                    .font(FitTodayFont.ui(size: 14, weight: .medium))
                    .foregroundStyle(FitTodayColor.textSecondary)
            }
        }
        .padding(.vertical, FitTodaySpacing.lg)
    }

    // MARK: - Next Exercise Section

    private func nextExerciseSection(_ name: String) -> some View {
        VStack(spacing: FitTodaySpacing.sm) {
            Text("rest_timer.next_exercise".localized)
                .font(FitTodayFont.ui(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)

            Text(name)
                .font(FitTodayFont.ui(size: 18, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)
                .multilineTextAlignment(.center)
        }
        .padding(FitTodaySpacing.md)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .fill(FitTodayColor.surface)
        )
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: FitTodaySpacing.md) {
            // Skip button
            Button {
                timerStore.skip()
                onSkip()
            } label: {
                Text("rest_timer.skip".localized)
                    .font(FitTodayFont.ui(size: 16, weight: .bold))
                    .foregroundStyle(FitTodayColor.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, FitTodaySpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: FitTodayRadius.md)
                            .fill(FitTodayColor.surface)
                    )
            }
            .buttonStyle(.plain)

            // Add time button
            Button {
                timerStore.addTime(30)
            } label: {
                Text("rest_timer.add_time".localized)
                    .font(FitTodayFont.ui(size: 16, weight: .bold))
                    .foregroundStyle(FitTodayColor.textInverse)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, FitTodaySpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: FitTodayRadius.md)
                            .fill(FitTodayColor.brandPrimary)
                    )
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Preview

#Preview {
    let timerStore = RestTimerStore()
    timerStore.start(duration: 60)

    return RestTimerModal(
        nextExerciseName: "Supino Inclinado com Halteres",
        onSkip: {},
        onComplete: {}
    )
    .environment(timerStore)
    .preferredColorScheme(.dark)
}
