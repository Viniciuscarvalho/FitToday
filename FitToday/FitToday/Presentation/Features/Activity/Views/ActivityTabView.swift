//
//  ActivityTabView.swift
//  FitToday
//
//  Main tab view for activity tracking, history, and challenges.
//

import SwiftUI

/// Segments available in the Activity tab.
enum ActivitySegment: String, CaseIterable {
    case history = "Histórico"
    case challenges = "Desafios"
    case stats = "Stats"
}

/// Main view for the Activity tab.
struct ActivityTabView: View {
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
                    WorkoutHistoryView()
                        .tag(ActivitySegment.history)

                    ChallengesFullListView()
                        .tag(ActivitySegment.challenges)

                    ActivityStatsView()
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
    @State private var selectedDate = Date()
    @State private var workouts: [UnifiedWorkoutSession] = []
    @State private var isLoading = true

    // Mock workout days for calendar highlighting
    private var workoutDays: Set<DateComponents> {
        let calendar = Calendar.current
        return Set(workouts.compactMap { session in
            calendar.dateComponents([.year, .month, .day], from: session.startedAt)
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
                    ForEach(workouts) { workout in
                        WorkoutSessionCard(session: workout)
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
        // Simulate loading
        try? await Task.sleep(for: .milliseconds(500))

        // Mock data for demonstration
        workouts = MockWorkoutData.recentSessions
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

// MARK: - Workout Session Card

struct WorkoutSessionCard: View {
    let session: UnifiedWorkoutSession

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                    Text(session.name)
                        .font(FitTodayFont.ui(size: 16, weight: .bold))
                        .foregroundStyle(FitTodayColor.textPrimary)

                    Text(session.startedAt, format: .dateTime.weekday(.wide).day().month())
                        .font(FitTodayFont.ui(size: 13, weight: .medium))
                        .foregroundStyle(FitTodayColor.textSecondary)
                }

                Spacer()

                sourceIcon
            }

            Divider()
                .background(FitTodayColor.outline)

            // Stats
            HStack(spacing: FitTodaySpacing.lg) {
                statItem(icon: "clock", value: session.formattedDuration, label: "Duração")
                statItem(icon: "scalemass", value: session.formattedVolume, label: "Volume")
                statItem(icon: "number", value: "\(session.totalSets)", label: "Séries")
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
        switch session.source {
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


// MARK: - Activity Stats View (Placeholder)

struct ActivityStatsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: FitTodaySpacing.lg) {
                // Weekly Stats
                VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
                    Text("Esta Semana")
                        .font(FitTodayFont.ui(size: 17, weight: .bold))
                        .foregroundStyle(FitTodayColor.textPrimary)

                    HStack(spacing: FitTodaySpacing.md) {
                        ActivityStatCard(title: "Treinos", value: "3", icon: "dumbbell")
                        ActivityStatCard(title: "Volume", value: "2.5 ton", icon: "scalemass")
                        ActivityStatCard(title: "Tempo", value: "2h 15m", icon: "clock")
                    }
                }

                // Monthly Progress
                VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
                    Text("Este Mês")
                        .font(FitTodayFont.ui(size: 17, weight: .bold))
                        .foregroundStyle(FitTodayColor.textPrimary)

                    HStack(spacing: FitTodaySpacing.md) {
                        ActivityStatCard(title: "Treinos", value: "12", icon: "dumbbell")
                        ActivityStatCard(title: "Streak", value: "5 dias", icon: "flame")
                    }
                }
            }
            .padding(FitTodaySpacing.md)
        }
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

// MARK: - Mock Data

enum MockWorkoutData {
    static let recentSessions: [UnifiedWorkoutSession] = [
        UnifiedWorkoutSession(
            userId: "user1",
            name: "Push Day",
            startedAt: Date().addingTimeInterval(-86400),
            completedAt: Date().addingTimeInterval(-86400 + 3600),
            exercises: []
        ),
        UnifiedWorkoutSession(
            userId: "user1",
            name: "Pull Day",
            startedAt: Date().addingTimeInterval(-172800),
            completedAt: Date().addingTimeInterval(-172800 + 4200),
            exercises: []
        ),
        UnifiedWorkoutSession(
            userId: "user1",
            name: "Leg Day",
            startedAt: Date().addingTimeInterval(-259200),
            completedAt: Date().addingTimeInterval(-259200 + 3900),
            exercises: []
        )
    ]
}

// MARK: - Preview

#Preview {
    ActivityTabView()
        .preferredColorScheme(.dark)
}
