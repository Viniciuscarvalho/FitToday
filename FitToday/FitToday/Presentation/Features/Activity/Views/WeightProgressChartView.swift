//
//  WeightProgressChartView.swift
//  FitToday
//
//  Line chart showing weight progress over time with trend line.
//  PRO-76: Weight Progress Chart
//

import SwiftUI
import Charts

struct WeightProgressChartView: View {
    let entries: [WeightEntry]
    let animated: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            // Header
            VStack(alignment: .leading, spacing: 2) {
                Text("Evolução de Peso")
                    .font(FitTodayFont.ui(size: 17, weight: .bold))
                    .foregroundStyle(FitTodayColor.textPrimary)

                Text("Dados do Apple Health")
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

                summaryRow
            }
        }
    }

    // MARK: - Chart

    private var chart: some View {
        Chart {
            // Actual weight line
            ForEach(entries) { entry in
                LineMark(
                    x: .value("Data", entry.date),
                    y: .value("Peso", animated ? entry.weightKg : entries.first?.weightKg ?? 0)
                )
                .foregroundStyle(FitTodayColor.chartWeight)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .interpolationMethod(.catmullRom)
                .symbol {
                    Circle()
                        .fill(FitTodayColor.chartWeight)
                        .frame(width: 6, height: 6)
                }

                AreaMark(
                    x: .value("Data", entry.date),
                    y: .value("Peso", animated ? entry.weightKg : entries.first?.weightKg ?? 0)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [FitTodayColor.chartWeight.opacity(0.3), FitTodayColor.chartWeight.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }

            // Trend line
            if entries.count >= 2 {
                let trend = computeTrend()
                ForEach(trend, id: \.date) { point in
                    LineMark(
                        x: .value("Data", point.date),
                        y: .value("Tendência", animated ? point.value : entries.first?.weightKg ?? 0)
                    )
                    .foregroundStyle(FitTodayColor.chartTrend)
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                }
            }
        }
        .chartYScale(domain: yDomain)
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let kg = value.as(Double.self) {
                        Text(String(format: "%.0f", kg))
                            .font(FitTodayFont.ui(size: 10, weight: .medium))
                            .foregroundStyle(FitTodayColor.textTertiary)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { value in
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(date.formatted(.dateTime.day().month(.abbreviated)))
                            .font(FitTodayFont.ui(size: 10, weight: .medium))
                            .foregroundStyle(FitTodayColor.textSecondary)
                    }
                }
            }
        }
        .animation(.easeOut(duration: 1.0), value: animated)
    }

    // MARK: - Y Domain

    private var yDomain: ClosedRange<Double> {
        let weights = entries.map(\.weightKg)
        guard let minW = weights.min(), let maxW = weights.max() else { return 0...100 }
        let padding = Swift.max(1, (maxW - minW) * 0.15)
        return (minW - padding)...(maxW + padding)
    }

    // MARK: - Trend Line

    private struct TrendDataPoint: Hashable {
        let date: Date
        let value: Double
    }

    private func computeTrend() -> [TrendDataPoint] {
        guard entries.count >= 2 else { return [] }
        let base = entries.first!.date.timeIntervalSince1970
        let xs = entries.map { ($0.date.timeIntervalSince1970 - base) / 86400.0 }
        let ys = entries.map(\.weightKg)
        let n = Double(xs.count)

        let sumX = xs.reduce(0, +)
        let sumY = ys.reduce(0, +)
        let sumXY = zip(xs, ys).reduce(0.0) { $0 + $1.0 * $1.1 }
        let sumX2 = xs.reduce(0.0) { $0 + $1 * $1 }

        let denom = n * sumX2 - sumX * sumX
        guard denom != 0 else { return [] }
        let slope = (n * sumXY - sumX * sumY) / denom
        let intercept = (sumY - slope * sumX) / n

        return entries.map { entry in
            let x = (entry.date.timeIntervalSince1970 - base) / 86400.0
            return TrendDataPoint(date: entry.date, value: slope * x + intercept)
        }
    }

    // MARK: - Summary

    private var summaryRow: some View {
        HStack(spacing: FitTodaySpacing.md) {
            let first = entries.first?.weightKg ?? 0
            let last = entries.last?.weightKg ?? 0
            let diff = last - first

            summaryItem(
                title: "Atual",
                value: String(format: "%.1f kg", last),
                icon: "scalemass"
            )
            summaryItem(
                title: "Variação",
                value: String(format: "%@%.1f kg", diff >= 0 ? "+" : "", diff),
                icon: diff < 0 ? "arrow.down.right" : diff > 0 ? "arrow.up.right" : "minus"
            )
            summaryItem(
                title: "Registros",
                value: "\(entries.count)",
                icon: "list.bullet"
            )
        }
    }

    private func summaryItem(title: String, value: String, icon: String) -> some View {
        VStack(spacing: FitTodaySpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(FitTodayColor.chartWeight)
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
            Image(systemName: "scalemass")
                .font(.system(size: 32))
                .foregroundStyle(FitTodayColor.textTertiary)
            Text("Sem dados de peso")
                .font(FitTodayFont.ui(size: 14, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)
            Text("Adicione registros de peso no Apple Health para ver sua evolução")
                .font(FitTodayFont.ui(size: 12, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(FitTodaySpacing.xl)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .fill(FitTodayColor.surface)
        )
    }
}
