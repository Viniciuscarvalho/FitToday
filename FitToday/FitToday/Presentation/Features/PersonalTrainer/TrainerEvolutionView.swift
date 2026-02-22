//
//  TrainerEvolutionView.swift
//  FitToday
//
//  Evolution/progress view with metrics and weight progression chart.
//

import Charts
import SwiftUI

struct TrainerEvolutionView: View {
    let workouts: [TrainerWorkout]

    private var totalWorkouts: Int {
        workouts.count
    }

    private var loadChange: Double {
        let sorted = workouts.sorted { $0.createdAt < $1.createdAt }
        guard sorted.count >= 2 else { return 0 }
        let recentCount = max(1, sorted.count / 2)
        let olderSlice = sorted.prefix(sorted.count - recentCount)
        let recentSlice = sorted.suffix(recentCount)
        let olderAvg = averageExerciseCount(Array(olderSlice))
        let recentAvg = averageExerciseCount(Array(recentSlice))
        guard olderAvg > 0 else { return 0 }
        return ((recentAvg - olderAvg) / olderAvg) * 100
    }

    private var frequencyPercent: Int {
        let calendar = Calendar.current
        guard let oldest = workouts.min(by: { $0.createdAt < $1.createdAt })?.createdAt else { return 0 }
        let weeks = max(1, calendar.dateComponents([.weekOfYear], from: oldest, to: Date()).weekOfYear ?? 1)
        let targetPerWeek = 3.0
        let actual = Double(workouts.count) / Double(weeks)
        return min(100, Int((actual / targetPerWeek) * 100))
    }

    private var chartData: [ChartDataPoint] {
        let sorted = workouts.sorted { $0.createdAt < $1.createdAt }
        return sorted.map { workout in
            let totalSets = workout.phases.flatMap(\.items).reduce(0) { $0 + $1.sets }
            return ChartDataPoint(date: workout.createdAt, value: Double(totalSets))
        }
    }

    var body: some View {
        ScrollView {
            if workouts.isEmpty {
                emptyView
            } else {
                VStack(alignment: .leading, spacing: FitTodaySpacing.lg) {
                    metricsRow
                    chartSection
                }
                .padding(.horizontal, FitTodaySpacing.md)
                .padding(.vertical, FitTodaySpacing.sm)
            }
        }
        .scrollIndicators(.hidden)
        .background(FitTodayColor.background)
    }

    // MARK: - Metrics Row

    private var metricsRow: some View {
        HStack(spacing: FitTodaySpacing.sm) {
            EvolutionMetricCard(
                icon: "arrow.up.right",
                value: String(format: "%+.0f%%", loadChange),
                label: "trainer.evolution.load".localized,
                color: FitTodayColor.success
            )

            EvolutionMetricCard(
                icon: "flame.fill",
                value: "\(totalWorkouts)",
                label: "trainer.evolution.workouts".localized,
                color: FitTodayColor.brandPrimary
            )

            EvolutionMetricCard(
                icon: "calendar.badge.checkmark",
                value: "\(frequencyPercent)%",
                label: "trainer.evolution.frequency".localized,
                color: FitTodayColor.info
            )
        }
    }

    // MARK: - Chart Section

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            Text("trainer.evolution.chart_title".localized)
                .font(FitTodayFont.ui(size: 16, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)

            if chartData.count >= 2 {
                Chart(chartData) { point in
                    LineMark(
                        x: .value("trainer.evolution.date".localized, point.date),
                        y: .value("trainer.evolution.sets".localized, point.value)
                    )
                    .foregroundStyle(FitTodayColor.brandPrimary)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("trainer.evolution.date".localized, point.date),
                        y: .value("trainer.evolution.sets".localized, point.value)
                    )
                    .foregroundStyle(
                        .linearGradient(
                            colors: [FitTodayColor.brandPrimary.opacity(0.3), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(FitTodayColor.outline)
                        AxisValueLabel()
                            .foregroundStyle(FitTodayColor.textTertiary)
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(FitTodayColor.outline)
                        AxisValueLabel()
                            .foregroundStyle(FitTodayColor.textTertiary)
                    }
                }
                .frame(height: 200)
                .padding(FitTodaySpacing.md)
                .background(FitTodayColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
            } else {
                Text("trainer.evolution.not_enough_data".localized)
                    .font(FitTodayFont.ui(size: 14, weight: .medium))
                    .foregroundStyle(FitTodayColor.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, FitTodaySpacing.xl)
            }
        }
    }

    // MARK: - Empty View

    private var emptyView: some View {
        VStack(spacing: FitTodaySpacing.md) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundStyle(FitTodayColor.textTertiary)

            Text("trainer.evolution.empty".localized)
                .font(FitTodayFont.ui(size: 16, weight: .semiBold))
                .foregroundStyle(FitTodayColor.textPrimary)

            Text("trainer.evolution.empty_message".localized)
                .font(FitTodayFont.ui(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, FitTodaySpacing.xxl)
    }

    // MARK: - Helpers

    private func averageExerciseCount(_ workouts: [TrainerWorkout]) -> Double {
        guard !workouts.isEmpty else { return 0 }
        let total = workouts.reduce(0) { sum, workout in
            sum + workout.phases.flatMap(\.items).reduce(0) { $0 + $1.sets }
        }
        return Double(total) / Double(workouts.count)
    }
}

// MARK: - Chart Data

private struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}
