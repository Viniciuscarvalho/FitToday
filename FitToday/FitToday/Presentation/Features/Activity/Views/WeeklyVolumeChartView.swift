//
//  WeeklyVolumeChartView.swift
//  FitToday
//
//  Bar chart with trend line showing weekly workout volume (total minutes).
//  PRO-75: Weekly Workout Volume Chart
//

import SwiftUI
import Charts

struct WeeklyVolumeEntry: Identifiable, Sendable {
    let id = UUID()
    let weekLabel: String
    let totalMinutes: Int
    let workoutCount: Int
}

struct WeeklyVolumeChartView: View {
    let entries: [WeeklyVolumeEntry]
    let animated: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            // Header
            VStack(alignment: .leading, spacing: 2) {
                Text("Volume Semanal")
                    .font(FitTodayFont.ui(size: 17, weight: .bold))
                    .foregroundStyle(FitTodayColor.textPrimary)

                Text("Minutos de treino por semana")
                    .font(FitTodayFont.ui(size: 12, weight: .medium))
                    .foregroundStyle(FitTodayColor.textTertiary)
            }

            if entries.isEmpty {
                emptyState
            } else {
                chart
                    .frame(height: 200)
                    .padding(FitTodaySpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: FitTodayRadius.md)
                            .fill(FitTodayColor.surface)
                    )

                // Summary row
                summaryRow
            }
        }
    }

    // MARK: - Chart

    private var chart: some View {
        Chart {
            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                BarMark(
                    x: .value("Semana", entry.weekLabel),
                    y: .value("Minutos", animated ? entry.totalMinutes : 0)
                )
                .foregroundStyle(FitTodayColor.chartVolume.gradient)
                .cornerRadius(4)
            }

            // Trend line
            if entries.count >= 2 {
                let trendPoints = computeTrend()
                ForEach(Array(trendPoints.enumerated()), id: \.offset) { index, point in
                    LineMark(
                        x: .value("Semana", point.label),
                        y: .value("Tendência", animated ? point.value : 0)
                    )
                    .foregroundStyle(FitTodayColor.chartTrend)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
                    .interpolationMethod(.catmullRom)
                }
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let intVal = value.as(Int.self) {
                        Text("\(intVal)m")
                            .font(FitTodayFont.ui(size: 10, weight: .medium))
                            .foregroundStyle(FitTodayColor.textTertiary)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let label = value.as(String.self) {
                        Text(label)
                            .font(FitTodayFont.ui(size: 10, weight: .medium))
                            .foregroundStyle(FitTodayColor.textSecondary)
                    }
                }
            }
        }
        .animation(.easeOut(duration: 0.8), value: animated)
    }

    // MARK: - Trend Computation

    private struct TrendPoint {
        let label: String
        let value: Int
    }

    private func computeTrend() -> [TrendPoint] {
        guard entries.count >= 2 else { return [] }
        let values = entries.map { Double($0.totalMinutes) }
        let n = Double(values.count)
        let sumX = (0..<values.count).reduce(0.0) { $0 + Double($1) }
        let sumY = values.reduce(0, +)
        let sumXY = (0..<values.count).reduce(0.0) { $0 + Double($1) * values[$1] }
        let sumX2 = (0..<values.count).reduce(0.0) { $0 + Double($1) * Double($1) }

        let denom = n * sumX2 - sumX * sumX
        guard denom != 0 else { return [] }
        let slope = (n * sumXY - sumX * sumY) / denom
        let intercept = (sumY - slope * sumX) / n

        return entries.enumerated().map { index, entry in
            TrendPoint(
                label: entry.weekLabel,
                value: max(0, Int((slope * Double(index) + intercept).rounded()))
            )
        }
    }

    // MARK: - Summary

    private var summaryRow: some View {
        HStack(spacing: FitTodaySpacing.md) {
            let avg = entries.isEmpty ? 0 : entries.map(\.totalMinutes).reduce(0, +) / entries.count
            let trend = trendDirection

            summaryItem(title: "Média", value: "\(avg)m", icon: "chart.bar")
            summaryItem(title: "Tendência", value: trend.label, icon: trend.icon)
            summaryItem(title: "Total Treinos", value: "\(entries.map(\.workoutCount).reduce(0, +))", icon: "dumbbell")
        }
    }

    private var trendDirection: (label: String, icon: String) {
        guard entries.count >= 2 else { return ("—", "minus") }
        let first = entries.first!.totalMinutes
        let last = entries.last!.totalMinutes
        if last > first { return ("Subindo", "arrow.up.right") }
        if last < first { return ("Descendo", "arrow.down.right") }
        return ("Estável", "minus")
    }

    private func summaryItem(title: String, value: String, icon: String) -> some View {
        VStack(spacing: FitTodaySpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(FitTodayColor.chartVolume)
            Text(value)
                .font(FitTodayFont.ui(size: 14, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)
            Text(title)
                .font(FitTodayFont.ui(size: 11, weight: .medium))
                .foregroundStyle(FitTodayColor.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(FitTodaySpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.sm)
                .fill(FitTodayColor.surface)
        )
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: FitTodaySpacing.md) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 32))
                .foregroundStyle(FitTodayColor.textTertiary)
            Text("Sem dados de volume ainda")
                .font(FitTodayFont.ui(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(FitTodaySpacing.xl)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .fill(FitTodayColor.surface)
        )
    }
}
