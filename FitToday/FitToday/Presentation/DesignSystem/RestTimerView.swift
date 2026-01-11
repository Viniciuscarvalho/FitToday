//
//  RestTimerView.swift
//  FitToday
//
//  UI do timer de descanso entre séries.
//

import SwiftUI

struct RestTimerView: View {
    @ObservedObject var timerStore: RestTimerStore
    let defaultDuration: TimeInterval
    let onComplete: () -> Void
    let onSkip: () -> Void
    
    @State private var showTimer = false
    
    var body: some View {
        VStack(spacing: FitTodaySpacing.lg) {
            if showTimer {
                activeTimerView
            } else {
                startTimerButton
            }
        }
        .onChange(of: timerStore.isFinished) { _, finished in
            if finished {
                onComplete()
                showTimer = false
            }
        }
    }
    
    // MARK: - Start Button
    
    private var startTimerButton: some View {
        Button {
            showTimer = true
            timerStore.start(duration: defaultDuration)
        } label: {
            HStack(spacing: FitTodaySpacing.sm) {
                Image(systemName: "timer")
                    .font(.system(size: 18))
                Text("Iniciar descanso (\(Int(defaultDuration))s)")
                    .font(FitTodayFont.ui(size: 15, weight: .semiBold))
            }
            .foregroundStyle(FitTodayColor.brandPrimary)
            .padding(.vertical, FitTodaySpacing.sm)
            .padding(.horizontal, FitTodaySpacing.md)
            .background(
                RoundedRectangle(cornerRadius: FitTodayRadius.md)
                    .fill(FitTodayColor.brandPrimary.opacity(0.15))
            )
            .overlay(
                RoundedRectangle(cornerRadius: FitTodayRadius.md)
                    .stroke(FitTodayColor.brandPrimary.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Active Timer
    
    private var activeTimerView: some View {
        VStack(spacing: FitTodaySpacing.md) {
            // Timer display
            ZStack {
                // Background ring
                Circle()
                    .stroke(FitTodayColor.surface, lineWidth: 8)
                    .frame(width: 140, height: 140)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: timerStore.progressPercentage)
                    .stroke(
                        LinearGradient(
                            colors: [FitTodayColor.brandPrimary, FitTodayColor.brandSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: timerStore.progressPercentage)
                
                // Time display
                VStack(spacing: 4) {
                    Text(timerStore.formattedTime)
                        .font(FitTodayFont.display(size: 40, weight: .bold))
                        .foregroundStyle(FitTodayColor.textPrimary)
                        .monospacedDigit()
                    
                    Text("descanso")
                        .font(FitTodayFont.ui(size: 13, weight: .medium))
                        .foregroundStyle(FitTodayColor.textSecondary)
                }
            }
            .fitGlowEffect(color: FitTodayColor.brandPrimary.opacity(0.2))
            
            // Controls
            HStack(spacing: FitTodaySpacing.md) {
                // Pause/Resume
                Button {
                    timerStore.toggle()
                } label: {
                    Image(systemName: timerStore.isActive ? "pause.fill" : "play.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(FitTodayColor.textPrimary)
                        .frame(width: 48, height: 48)
                        .background(FitTodayColor.surface)
                        .clipShape(Circle())
                }
                
                // +30s
                Button {
                    timerStore.addTime(30)
                } label: {
                    Text("+30s")
                        .font(FitTodayFont.ui(size: 14, weight: .semiBold))
                        .foregroundStyle(FitTodayColor.textPrimary)
                        .frame(width: 56, height: 48)
                        .background(FitTodayColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.sm))
                }
                
                // Skip
                Button {
                    timerStore.skip()
                    showTimer = false
                    onSkip()
                } label: {
                    Text("Pular")
                        .font(FitTodayFont.ui(size: 14, weight: .semiBold))
                        .foregroundStyle(FitTodayColor.brandPrimary)
                        .frame(width: 56, height: 48)
                        .background(FitTodayColor.brandPrimary.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.sm))
                }
            }
        }
        .padding(FitTodaySpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.lg)
                .fill(FitTodayColor.surfaceElevated)
                .retroGridOverlay(spacing: 20)
        )
        .techCornerBorders(length: 12, thickness: 1.5)
    }
}

// MARK: - Compact Timer (para inline)

struct CompactRestTimer: View {
    @ObservedObject var timerStore: RestTimerStore
    
    var body: some View {
        HStack(spacing: FitTodaySpacing.sm) {
            MiniProgressRing(progress: timerStore.progressPercentage, size: 24)
            
            Text(timerStore.formattedTime)
                .font(FitTodayFont.ui(size: 15, weight: .semiBold))
                .monospacedDigit()
                .foregroundStyle(FitTodayColor.brandPrimary)
            
            Button {
                timerStore.skip()
            } label: {
                Text("Pular")
                    .font(FitTodayFont.ui(size: 13, weight: .medium))
                    .foregroundStyle(FitTodayColor.textSecondary)
            }
        }
        .padding(.horizontal, FitTodaySpacing.md)
        .padding(.vertical, FitTodaySpacing.sm)
        .background(
            Capsule()
                .fill(FitTodayColor.brandPrimary.opacity(0.1))
        )
    }
}

// MARK: - Previews

#Preview("Rest Timer") {
    @Previewable @StateObject var timerStore = RestTimerStore()
    
    VStack(spacing: 30) {
        RestTimerView(
            timerStore: timerStore,
            defaultDuration: 60,
            onComplete: { print("Complete!") },
            onSkip: { print("Skipped!") }
        )
    }
    .padding()
    .background(FitTodayColor.background)
}

