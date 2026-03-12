//
//  ConsistencyHeatmapView.swift
//  FitToday
//
//  Heatmap calendar showing workout consistency over the last 3 months.
//  PRO-74: Consistency Calendar Chart
//

import SwiftUI

struct ConsistencyHeatmapView: View {
    let workoutDates: [Date: Int] // date → workout count that day

    @State private var appeared = false

    private let calendar: Calendar = {
        var cal = Calendar.current
        cal.firstWeekday = 2 // Monday
        return cal
    }()

    private let columns = 13 // ~13 weeks in 3 months
    private let rows = 7    // 7 days per week

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            // Header
            VStack(alignment: .leading, spacing: 2) {
                Text("Consistência")
                    .font(FitTodayFont.ui(size: 17, weight: .bold))
                    .foregroundStyle(FitTodayColor.textPrimary)

                Text("Últimos 3 meses")
                    .font(FitTodayFont.ui(size: 12, weight: .medium))
                    .foregroundStyle(FitTodayColor.textTertiary)
            }

            // Heatmap grid
            VStack(spacing: 3) {
                // Day labels
                HStack(spacing: 3) {
                    dayLabel("")
                    ForEach(monthLabels, id: \.offset) { item in
                        if item.show {
                            Text(item.label)
                                .font(FitTodayFont.ui(size: 9, weight: .medium))
                                .foregroundStyle(FitTodayColor.textTertiary)
                                .frame(width: cellSize, alignment: .leading)
                        } else {
                            Color.clear.frame(width: cellSize, height: 1)
                        }
                    }
                }

                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: 3) {
                        dayLabel(weekdayLabel(for: row))

                        ForEach(0..<columns, id: \.self) { col in
                            let date = dateFor(week: col, dayOfWeek: row)
                            let count = date.flatMap { workoutDates[calendar.startOfDay(for: $0)] } ?? 0

                            RoundedRectangle(cornerRadius: 2)
                                .fill(heatColor(for: count))
                                .frame(width: cellSize, height: cellSize)
                                .opacity(appeared ? 1 : 0)
                                .animation(
                                    .easeOut(duration: 0.3)
                                        .delay(Double(col) * 0.02 + Double(row) * 0.01),
                                    value: appeared
                                )
                        }
                    }
                }
            }
            .padding(FitTodaySpacing.md)
            .background(
                RoundedRectangle(cornerRadius: FitTodayRadius.md)
                    .fill(FitTodayColor.surface)
            )

            // Legend
            HStack(spacing: FitTodaySpacing.sm) {
                Spacer()
                Text("Menos")
                    .font(FitTodayFont.ui(size: 10, weight: .medium))
                    .foregroundStyle(FitTodayColor.textTertiary)

                ForEach([0, 1, 2, 3], id: \.self) { level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(heatColor(for: level))
                        .frame(width: 12, height: 12)
                }

                Text("Mais")
                    .font(FitTodayFont.ui(size: 10, weight: .medium))
                    .foregroundStyle(FitTodayColor.textTertiary)
            }
        }
        .onAppear { appeared = true }
    }

    // MARK: - Layout

    private var cellSize: CGFloat { 18 }

    private func dayLabel(_ text: String) -> some View {
        Text(text)
            .font(FitTodayFont.ui(size: 9, weight: .medium))
            .foregroundStyle(FitTodayColor.textTertiary)
            .frame(width: 16, alignment: .trailing)
    }

    private func weekdayLabel(for row: Int) -> String {
        // row 0 = Mon, 1 = Tue, ..., 6 = Sun
        switch row {
        case 0: return "S"
        case 2: return "Q"
        case 4: return "S"
        default: return ""
        }
    }

    // MARK: - Date Mapping

    private var gridStartDate: Date {
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let mondayOffset = (weekday - 2 + 7) % 7
        let thisMonday = calendar.date(byAdding: .day, value: -mondayOffset, to: today)!
        return calendar.date(byAdding: .weekOfYear, value: -(columns - 1), to: thisMonday)!
    }

    private func dateFor(week: Int, dayOfWeek: Int) -> Date? {
        let base = gridStartDate
        guard let date = calendar.date(byAdding: .day, value: week * 7 + dayOfWeek, to: base) else {
            return nil
        }
        return date <= Date() ? date : nil
    }

    private struct MonthLabel: Identifiable {
        let offset: Int
        let label: String
        let show: Bool
        var id: Int { offset }
    }

    private var monthLabels: [MonthLabel] {
        (0..<columns).map { col in
            let date = dateFor(week: col, dayOfWeek: 0) ?? Date()
            let day = calendar.component(.day, from: date)
            let show = day <= 7 // Show label at start of month
            let label = date.formatted(.dateTime.month(.abbreviated))
            return MonthLabel(offset: col, label: label, show: show)
        }
    }

    // MARK: - Color

    private func heatColor(for count: Int) -> Color {
        switch count {
        case 0: return FitTodayColor.heatmapNone
        case 1: return FitTodayColor.heatmapLow
        case 2: return FitTodayColor.heatmapMedium
        default: return FitTodayColor.heatmapHigh
        }
    }
}
