//
//  ActivityTabView.swift
//  FitToday
//
//  Main tab view for activity tracking, history, and challenges.
//

import SwiftUI
import Charts
import Swinject

/// Segments available in the Activity tab.
enum ActivitySegment: String, CaseIterable {
    case history = "Histórico"
    case challenges = "Desafios"
    case stats = "Stats"
}

/// Main view for the Activity tab.
struct ActivityTabView: View {
    let resolver: Resolver

    @State private var selectedSegment: ActivitySegment = .history

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented Control
                segmentedControl
                    .padding(.horizontal, FitTodaySpacing.md)
                    .padding(.vertical, FitTodaySpacing.sm)

                // Content
                TabView(selection: $selectedSegment) {
                    WorkoutHistoryView(resolver: resolver)
                        .tag(ActivitySegment.history)

                    ChallengesFullListView(resolver: resolver)
                        .tag(ActivitySegment.challenges)

                    ActivityStatsView(resolver: resolver)
                        .tag(ActivitySegment.stats)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .background(FitTodayColor.background)
            .navigationTitle("Atividade")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Segmented Control

    private var segmentedControl: some View {
        HStack(spacing: FitTodaySpacing.xs) {
            ForEach(ActivitySegment.allCases, id: \.self) { segment in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedSegment = segment
                    }
                } label: {
                    Text(segment.rawValue)
                        .font(FitTodayFont.ui(size: 14, weight: selectedSegment == segment ? .bold : .medium))
                        .foregroundStyle(selectedSegment == segment ? FitTodayColor.textPrimary : FitTodayColor.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, FitTodaySpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: FitTodayRadius.sm)
                                .fill(selectedSegment == segment ? FitTodayColor.brandPrimary.opacity(0.2) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(FitTodaySpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .fill(FitTodayColor.surface)
        )
    }
}

// MARK: - Workout History View

struct WorkoutHistoryView: View {
    let resolver: Resolver

    @State private var selectedDate = Date()
    @State private var workouts: [WorkoutHistoryEntry] = []
    @State private var isLoading = true

    private var repository: WorkoutHistoryRepository? {
        resolver.resolve(WorkoutHistoryRepository.self)
    }

    private var workoutDays: Set<DateComponents> {
        let calendar = Calendar.current
        return Set(workouts.compactMap { entry in
            calendar.dateComponents([.year, .month, .day], from: entry.date)
        })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: FitTodaySpacing.lg) {
                // Calendar
                calendarSection

                // Workout List
                workoutListSection
            }
            .padding(FitTodaySpacing.md)
        }
        .scrollIndicators(.hidden)
        .task {
            await loadWorkouts()
        }
    }

    // MARK: - Calendar Section

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            Text("Calendário")
                .font(FitTodayFont.ui(size: 17, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)

            // Simple month calendar
            MonthCalendarView(
                selectedDate: $selectedDate,
                highlightedDays: workoutDays
            )
        }
    }

    // MARK: - Workout List Section

    private var workoutListSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            Text("Treinos Recentes")
                .font(FitTodayFont.ui(size: 17, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)

            if isLoading {
                loadingView
            } else if workouts.isEmpty {
                emptyStateView
            } else {
                LazyVStack(spacing: FitTodaySpacing.sm) {
                    ForEach(workouts) { entry in
                        WorkoutEntryCard(entry: entry)
                    }
                }
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: FitTodaySpacing.md) {
            ProgressView()
                .tint(FitTodayColor.brandPrimary)
            Text("Carregando treinos...")
                .font(FitTodayFont.ui(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(FitTodaySpacing.xl)
    }

    private var emptyStateView: some View {
        VStack(spacing: FitTodaySpacing.md) {
            Image(systemName: "figure.run.circle")
                .font(.system(size: 48))
                .foregroundStyle(FitTodayColor.textTertiary)

            Text("Nenhum treino ainda")
                .font(FitTodayFont.ui(size: 17, weight: .semiBold))
                .foregroundStyle(FitTodayColor.textPrimary)

            Text("Complete seu primeiro treino para ver seu histórico")
                .font(FitTodayFont.ui(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(FitTodaySpacing.xl)
    }

    // MARK: - Data Loading

    private func loadWorkouts() async {
        guard let repository else {
            isLoading = false
            return
        }

        do {
            let entries = try await repository.listEntries(limit: 20, offset: 0)
            workouts = entries
        } catch {
            workouts = []
        }
        isLoading = false
    }
}

// MARK: - Month Calendar View

struct MonthCalendarView: View {
    @Binding var selectedDate: Date
    let highlightedDays: Set<DateComponents>

    private let calendar = Calendar.current
    private let daysOfWeek = ["D", "S", "T", "Q", "Q", "S", "S"]

    private var monthDays: [Date?] {
        let interval = calendar.dateInterval(of: .month, for: selectedDate)!
        let firstDay = interval.start
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let daysInMonth = calendar.range(of: .day, in: .month, for: selectedDate)!.count

        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)

        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }

        // Pad to complete last week
        while days.count % 7 != 0 {
            days.append(nil)
        }

        return days
    }

    var body: some View {
        VStack(spacing: FitTodaySpacing.sm) {
            // Month navigation
            HStack {
                Button {
                    withAnimation {
                        selectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate)!
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(FitTodayColor.textSecondary)
                }

                Spacer()

                Text(selectedDate, format: .dateTime.month(.wide).year())
                    .font(FitTodayFont.ui(size: 16, weight: .semiBold))
                    .foregroundStyle(FitTodayColor.textPrimary)

                Spacer()

                Button {
                    withAnimation {
                        selectedDate = calendar.date(byAdding: .month, value: 1, to: selectedDate)!
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(FitTodayColor.textSecondary)
                }
            }
            .padding(.horizontal, FitTodaySpacing.sm)

            // Days of week header
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(FitTodayFont.ui(size: 12, weight: .medium))
                        .foregroundStyle(FitTodayColor.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: FitTodaySpacing.xs) {
                ForEach(Array(monthDays.enumerated()), id: \.offset) { _, date in
                    if let date {
                        DayCell(
                            date: date,
                            isHighlighted: isHighlighted(date),
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date)
                        ) {
                            selectedDate = date
                        }
                    } else {
                        Color.clear
                            .frame(width: 36, height: 36)
                    }
                }
            }
        }
        .padding(FitTodaySpacing.md)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .fill(FitTodayColor.surface)
        )
    }

    private func isHighlighted(_ date: Date) -> Bool {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return highlightedDays.contains(components)
    }
}

// MARK: - Day Cell

struct DayCell: View {
    let date: Date
    let isHighlighted: Bool
    let isSelected: Bool
    let isToday: Bool
    let action: () -> Void

    private let calendar = Calendar.current

    var body: some View {
        Button(action: action) {
            Text("\(calendar.component(.day, from: date))")
                .font(FitTodayFont.ui(size: 14, weight: isSelected || isToday ? .bold : .medium))
                .foregroundStyle(foregroundColor)
                .frame(width: 36, height: 36)
                .background(backgroundColor)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(isToday && !isSelected ? FitTodayColor.brandPrimary : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }

    private var foregroundColor: Color {
        if isSelected {
            return .white
        } else if isHighlighted {
            return FitTodayColor.brandPrimary
        } else {
            return FitTodayColor.textPrimary
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return FitTodayColor.brandPrimary
        } else if isHighlighted {
            return FitTodayColor.brandPrimary.opacity(0.15)
        } else {
            return Color.clear
        }
    }
}

// MARK: - Workout Entry Card

struct WorkoutEntryCard: View {
    let entry: WorkoutHistoryEntry

    private var hourString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: entry.date)
    }

    private var statusText: String {
        switch entry.status {
        case .completed: return "history.completed".localized
        case .skipped: return "history.skipped".localized
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                    Text(entry.title)
                        .font(FitTodayFont.ui(size: 16, weight: .bold))
                        .foregroundStyle(FitTodayColor.textPrimary)

                    Text(entry.date, format: .dateTime.weekday(.wide).day().month())
                        .font(FitTodayFont.ui(size: 13, weight: .medium))
                        .foregroundStyle(FitTodayColor.textSecondary)
                }

                Spacer()

                sourceIcon
            }

            if let programName = entry.programName {
                HStack(spacing: FitTodaySpacing.xs) {
                    Image(systemName: "rectangle.stack.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(FitTodayColor.brandPrimary)
                    Text(programName)
                        .font(FitTodayFont.ui(size: 12, weight: .medium))
                        .foregroundStyle(FitTodayColor.brandPrimary)
                }
            }

            if entry.durationMinutes != nil || entry.caloriesBurned != nil {
                Divider()
                    .background(FitTodayColor.outline)

                HStack(spacing: FitTodaySpacing.lg) {
                    if let duration = entry.durationMinutes {
                        statItem(icon: "clock", value: "\(duration) min", label: "Duração")
                    }
                    if let calories = entry.caloriesBurned {
                        statItem(icon: "flame", value: "\(calories) kcal", label: "Calorias")
                    }
                    statItem(icon: "checkmark.circle", value: statusText, label: hourString)
                }
            }
        }
        .padding(FitTodaySpacing.md)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .fill(FitTodayColor.surface)
        )
    }

    @ViewBuilder
    private var sourceIcon: some View {
        switch entry.source {
        case .app:
            Image(systemName: "iphone")
                .foregroundStyle(FitTodayColor.brandPrimary)
        case .appleHealth:
            Image(systemName: "heart.fill")
                .foregroundStyle(.red)
        case .merged:
            Image(systemName: "arrow.triangle.merge")
                .foregroundStyle(FitTodayColor.brandSecondary)
        }
    }

    private func statItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: FitTodaySpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(FitTodayColor.brandPrimary)

            Text(value)
                .font(FitTodayFont.ui(size: 14, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)

            Text(label)
                .font(FitTodayFont.ui(size: 11, weight: .medium))
                .foregroundStyle(FitTodayColor.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}


// MARK: - Activity Stats View

struct ActivityStatsView: View {
    let resolver: Resolver

    @State private var viewModel: ActivityStatsViewModel?

    var body: some View {
        ScrollView {
            if let viewModel, !viewModel.isLoading {
                VStack(spacing: FitTodaySpacing.lg) {
                    // Summary Cards
                    summarySection(viewModel: viewModel)

                    // Weekly Chart — Workouts per Day
                    if !viewModel.dailyEntries.isEmpty {
                        chartSection(
                            title: "Treinos por Dia",
                            subtitle: "Últimos 7 dias"
                        ) {
                            Chart(viewModel.dailyEntries) { entry in
                                BarMark(
                                    x: .value("Dia", entry.dayLabel),
                                    y: .value("Treinos", entry.workouts)
                                )
                                .foregroundStyle(FitTodayColor.brandPrimary.gradient)
                                .cornerRadius(4)
                            }
                            .chartYAxis {
                                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                                    AxisGridLine()
                                    AxisValueLabel {
                                        if let intVal = value.as(Int.self) {
                                            Text("\(intVal)")
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
                            .frame(height: 180)
                        }
                    }

                    // Weekly Chart — Minutes per Day
                    if !viewModel.dailyEntries.isEmpty {
                        chartSection(
                            title: "Minutos por Dia",
                            subtitle: "Últimos 7 dias"
                        ) {
                            Chart(viewModel.dailyEntries) { entry in
                                BarMark(
                                    x: .value("Dia", entry.dayLabel),
                                    y: .value("Minutos", entry.minutes)
                                )
                                .foregroundStyle(Color.orange.gradient)
                                .cornerRadius(4)
                            }
                            .chartYAxis {
                                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                                    AxisGridLine()
                                    AxisValueLabel {
                                        if let intVal = value.as(Int.self) {
                                            Text("\(intVal)")
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
                            .frame(height: 180)
                        }
                    }

                    // Monthly Chart — Workouts per Week
                    if !viewModel.weeklyEntries.isEmpty {
                        chartSection(
                            title: "Treinos por Semana",
                            subtitle: "Últimas 4 semanas"
                        ) {
                            Chart(viewModel.weeklyEntries) { entry in
                                BarMark(
                                    x: .value("Semana", entry.weekLabel),
                                    y: .value("Treinos", entry.workouts)
                                )
                                .foregroundStyle(Color.green.gradient)
                                .cornerRadius(4)
                            }
                            .chartYAxis {
                                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                                    AxisGridLine()
                                    AxisValueLabel {
                                        if let intVal = value.as(Int.self) {
                                            Text("\(intVal)")
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
                            .frame(height: 180)
                        }
                    }
                }
                .padding(FitTodaySpacing.md)
            } else {
                VStack {
                    Spacer(minLength: 100)
                    ProgressView()
                    Spacer(minLength: 100)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .scrollIndicators(.hidden)
        .task {
            if viewModel == nil {
                viewModel = ActivityStatsViewModel(resolver: resolver)
            }
            await viewModel?.loadStats()
        }
        .refreshable {
            await viewModel?.loadStats()
        }
    }

    // MARK: - Summary Section

    private func summarySection(viewModel: ActivityStatsViewModel) -> some View {
        let stats = viewModel.stats ?? .empty

        return VStack(spacing: FitTodaySpacing.md) {
            // Week row
            VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
                Text("Esta Semana")
                    .font(FitTodayFont.ui(size: 17, weight: .bold))
                    .foregroundStyle(FitTodayColor.textPrimary)

                HStack(spacing: FitTodaySpacing.md) {
                    ActivityStatCard(title: "Treinos", value: "\(stats.weekWorkoutsCount)", icon: "dumbbell")
                    ActivityStatCard(title: "Tempo", value: formatMinutes(stats.weekTotalMinutes), icon: "clock")
                    ActivityStatCard(title: "Calorias", value: "\(stats.weekTotalCalories)", icon: "flame")
                }
            }

            // Month row
            VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
                Text("Este Mês")
                    .font(FitTodayFont.ui(size: 17, weight: .bold))
                    .foregroundStyle(FitTodayColor.textPrimary)

                HStack(spacing: FitTodaySpacing.md) {
                    ActivityStatCard(title: "Treinos", value: "\(stats.monthWorkoutsCount)", icon: "dumbbell")
                    ActivityStatCard(title: "Streak", value: "\(stats.currentStreak) dias", icon: "flame.fill")
                    ActivityStatCard(title: "Tempo", value: formatMinutes(stats.monthTotalMinutes), icon: "clock")
                }
            }
        }
    }

    // MARK: - Chart Section

    private func chartSection<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder chart: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(FitTodayFont.ui(size: 17, weight: .bold))
                    .foregroundStyle(FitTodayColor.textPrimary)

                Text(subtitle)
                    .font(FitTodayFont.ui(size: 12, weight: .medium))
                    .foregroundStyle(FitTodayColor.textTertiary)
            }

            chart()
                .padding(FitTodaySpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: FitTodayRadius.md)
                        .fill(FitTodayColor.surface)
                )
        }
    }

    // MARK: - Helpers

    private func formatMinutes(_ minutes: Int) -> String {
        if minutes >= 60 {
            let h = minutes / 60
            let m = minutes % 60
            return m > 0 ? "\(h)h \(m)m" : "\(h)h"
        }
        return "\(minutes)m"
    }
}

// MARK: - Activity Stat Card

private struct ActivityStatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: FitTodaySpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(FitTodayColor.brandPrimary)

            Text(value)
                .font(FitTodayFont.ui(size: 20, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)

            Text(title)
                .font(FitTodayFont.ui(size: 12, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(FitTodaySpacing.md)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .fill(FitTodayColor.surface)
        )
    }
}

// MARK: - Preview

#Preview {
    let container = Container()
    return ActivityTabView(resolver: container)
        .preferredColorScheme(.dark)
}
