//
//  HistoryView.swift
//  FitToday
//
//  Redesigned on 23/01/26 - Added Challenges feature (GymRats-like)
//

import SwiftUI
import Swinject

// MARK: - History Tab Selection

enum HistoryTabSelection: String, CaseIterable {
    case history = "History"
    case challenges = "Challenges"
}

struct HistoryView: View {
    @Environment(\.dependencyResolver) private var resolver
    @Environment(AppRouter.self) private var router
    @State private var viewModel: HistoryViewModel?
    @Environment(WorkoutSessionStore.self) private var sessionStore
    @State private var dependencyError: String?
    @State private var selectedTab: HistoryTabSelection = .history

    init(resolver: Resolver) {
        if let repository = resolver.resolve(WorkoutHistoryRepository.self) {
            _viewModel = State(initialValue: HistoryViewModel(repository: repository))
        } else {
            _dependencyError = State(initialValue: "Erro de configuração: repositório de histórico não encontrado")
        }
    }

    var body: some View {
        Group {
            if let errorMessage = dependencyError {
                DependencyErrorView(message: errorMessage)
            } else if let vm = viewModel {
                mainContent(vm: vm)
            } else {
                ProgressView("Carregando...")
            }
        }
        .background(FitTodayColor.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private func mainContent(vm: HistoryViewModel) -> some View {
        ScrollView {
            VStack(spacing: FitTodaySpacing.lg) {
                headerSection
                tabSelector

                switch selectedTab {
                case .history:
                    historyContent(vm: vm)
                case .challenges:
                    challengesContent
                }
            }
            .padding(.bottom, FitTodaySpacing.xxl)
        }
        .task {
            vm.loadHistory()
        }
        .refreshable {
            await vm.refresh()
        }
        .errorToast(errorMessage: Binding(
            get: { vm.errorMessage },
            set: { vm.errorMessage = $0 }
        ))
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Activity")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)
            Text("Track your progress and join challenges")
                .font(.system(size: 14))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.top, FitTodaySpacing.md)
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(HistoryTabSelection.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(selectedTab == tab ? .white : FitTodayColor.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            selectedTab == tab
                            ? FitTodayColor.brandPrimary
                            : Color.clear
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .background(FitTodayColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    // MARK: - History Content

    @ViewBuilder
    private func historyContent(vm: HistoryViewModel) -> some View {
        if vm.sections.isEmpty && !vm.isLoading {
            emptyHistoryState
        } else {
            VStack(spacing: 0) {
                // Insights header
                if let insights = vm.insights {
                    HistoryInsightsHeader(insights: insights)
                        .padding(.horizontal)
                        .padding(.bottom, FitTodaySpacing.lg)
                }

                // History sections
                ForEach(vm.sections) { section in
                    VStack(alignment: .leading, spacing: 0) {
                        Text(section.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(FitTodayColor.textSecondary)
                            .padding(.horizontal)
                            .padding(.top, FitTodaySpacing.lg)
                            .padding(.bottom, FitTodaySpacing.sm)

                        VStack(spacing: 0) {
                            ForEach(section.entries) { entry in
                                HistoryRow(entry: entry)
                                    .padding(.horizontal)
                                    .padding(.vertical, FitTodaySpacing.sm)
                                    .onAppear {
                                        if entry.id == vm.sections.last?.entries.last?.id {
                                            vm.loadMoreIfNeeded()
                                        }
                                    }

                                if entry.id != section.entries.last?.id {
                                    Divider()
                                        .padding(.leading)
                                }
                            }
                        }
                        .background(FitTodayColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                    }
                }

                // Loading more indicator
                if vm.isLoadingMore {
                    HStack {
                        Spacer()
                        ProgressView()
                            .tint(FitTodayColor.brandPrimary)
                        Text("Loading more...")
                            .font(.footnote)
                            .foregroundStyle(FitTodayColor.textSecondary)
                        Spacer()
                    }
                    .padding()
                }
            }
        }
    }

    private var emptyHistoryState: some View {
        VStack(spacing: FitTodaySpacing.md) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(FitTodayColor.brandPrimary)
            Text("No workouts yet")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)
            Text("Complete a workout to see your progress here")
                .font(.system(size: 14))
                .foregroundStyle(FitTodayColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, FitTodaySpacing.xxl)
    }

    // MARK: - Challenges Content

    private var challengesContent: some View {
        VStack(spacing: FitTodaySpacing.lg) {
            // Active Challenge Card
            ActiveChallengeCard()

            // Join Challenge Card
            JoinChallengeCard {
                // Navigate to authentication or group creation
                router.push(.authentication(inviteContext: nil), on: .history)
            }

            // Past challenges section
            VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
                Text("Past Challenges")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(FitTodayColor.textPrimary)
                    .padding(.horizontal)

                Text("Complete your first challenge to see your history here")
                    .font(.system(size: 14))
                    .foregroundStyle(FitTodayColor.textSecondary)
                    .padding(.horizontal)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Active Challenge Card

struct ActiveChallengeCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Active Challenge")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(FitTodayColor.success)
                .clipShape(Capsule())

                Spacer()

                Text("3 days left")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(FitTodayColor.textSecondary)
            }

            // Challenge info
            Text("New Year Challenge")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)

            Text("Complete 20 workouts in January")
                .font(.system(size: 14))
                .foregroundStyle(FitTodayColor.textSecondary)

            // Progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Your Progress")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(FitTodayColor.textSecondary)
                    Spacer()
                    Text("15/20 workouts")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(FitTodayColor.brandPrimary)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(FitTodayColor.surfaceElevated)
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(FitTodayColor.gradientPrimary)
                            .frame(width: geo.size.width * 0.75, height: 8)
                    }
                }
                .frame(height: 8)
            }

            // Leaderboard preview
            HStack(spacing: -8) {
                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .fill(FitTodayColor.surfaceElevated)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text("\(index + 1)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(FitTodayColor.textPrimary)
                        )
                        .overlay(
                            Circle()
                                .stroke(FitTodayColor.surface, lineWidth: 2)
                        )
                }

                Text("+8 more")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(FitTodayColor.textSecondary)
                    .padding(.leading, 16)
            }
            .padding(.top, 4)

            // View Leaderboard button
            Button {
                // Navigate to leaderboard
            } label: {
                HStack {
                    Spacer()
                    Text("View Leaderboard")
                        .font(.system(size: 14, weight: .semibold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                    Spacer()
                }
                .foregroundStyle(.white)
                .padding(.vertical, 12)
                .background(FitTodayColor.gradientPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(FitTodaySpacing.lg)
        .background(FitTodayColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Join Challenge Card

struct JoinChallengeCard: View {
    let onJoin: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            HStack {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(FitTodayColor.brandPrimary)
                Spacer()
            }

            Text("Join a Challenge")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)

            Text("Compete with friends and stay motivated together")
                .font(.system(size: 14))
                .foregroundStyle(FitTodayColor.textSecondary)

            Button(action: onJoin) {
                HStack {
                    Spacer()
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Create or Join")
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                }
                .foregroundStyle(FitTodayColor.brandPrimary)
                .padding(.vertical, 12)
                .background(FitTodayColor.brandPrimary.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(FitTodaySpacing.lg)
        .background(FitTodayColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - History Row

private struct HistoryRow: View {
    let entry: WorkoutHistoryEntry

    private var statusText: String {
        switch entry.status {
        case .completed: return "Completed"
        case .skipped: return "Skipped"
        }
    }

    private var statusStyle: FitBadge.Style {
        entry.status == .completed ? .success : .warning
    }

    private var hourString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: entry.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            HStack(spacing: FitTodaySpacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(FitTodayColor.textPrimary)
                    Text("\(entry.focusTitle) • \(hourString)")
                        .font(.system(size: 13))
                        .foregroundStyle(FitTodayColor.textSecondary)
                }
                Spacer()
                FitBadge(text: statusText, style: statusStyle)
            }

            if let programName = entry.programName {
                HStack(spacing: FitTodaySpacing.xs) {
                    Image(systemName: "rectangle.stack.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(FitTodayColor.brandPrimary)
                    Text(programName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(FitTodayColor.brandPrimary)
                }
            }

            if entry.status == .completed && (entry.durationMinutes != nil || entry.caloriesBurned != nil) {
                HStack(spacing: FitTodaySpacing.md) {
                    if let duration = entry.durationMinutes {
                        Label("\(duration) min", systemImage: "clock")
                    }
                    if let calories = entry.caloriesBurned {
                        Label("\(calories) kcal", systemImage: "flame")
                    }
                }
                .font(.system(size: 12))
                .foregroundStyle(FitTodayColor.textSecondary)
            }
        }
    }
}

// MARK: - History Insights Header

private struct HistoryInsightsHeader: View {
    let insights: HistoryInsights

    var body: some View {
        VStack(spacing: FitTodaySpacing.md) {
            // Stats row
            HStack(spacing: 12) {
                StatCard(
                    label: "Current Streak",
                    value: "\(insights.currentStreak)",
                    unit: "days",
                    color: FitTodayColor.success
                )
                StatCard(
                    label: "Best Streak",
                    value: "\(insights.bestStreak)",
                    unit: "days",
                    color: FitTodayColor.brandPrimary
                )
            }

            // Sparkline card
            VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
                Text("Weekly Minutes")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(FitTodayColor.textPrimary)

                WeeklyMinutesSparkline(weeks: insights.weekly.map { $0.minutes })
                    .frame(height: 44)

                let totalSessions = insights.weekly.reduce(0) { $0 + $1.sessions }
                let totalMinutes = insights.weekly.reduce(0) { $0 + $1.minutes }
                Text("Last \(insights.weekly.count) weeks • \(totalSessions) sessions • \(totalMinutes) min")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(FitTodayColor.textSecondary)
            }
            .padding(FitTodaySpacing.md)
            .background(FitTodayColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private struct StatCard: View {
        let label: String
        let value: String
        let unit: String
        let color: Color

        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(FitTodayColor.textSecondary)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(color)
                    Text(unit)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(FitTodayColor.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(FitTodaySpacing.md)
            .background(FitTodayColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private struct WeeklyMinutesSparkline: View {
        let weeks: [Int]

        var body: some View {
            GeometryReader { proxy in
                let w = proxy.size.width
                let h = proxy.size.height
                let maxValue = max(1, weeks.max() ?? 1)
                let stepX = weeks.count > 1 ? w / CGFloat(weeks.count - 1) : 0

                Path { path in
                    for (idx, value) in weeks.enumerated() {
                        let x = CGFloat(idx) * stepX
                        let y = h - (CGFloat(value) / CGFloat(maxValue)) * h
                        if idx == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(FitTodayColor.brandPrimary, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .background(
                    Path { path in
                        for (idx, value) in weeks.enumerated() {
                            let x = CGFloat(idx) * stepX
                            let y = h - (CGFloat(value) / CGFloat(maxValue)) * h
                            if idx == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                        path.addLine(to: CGPoint(x: w, y: h))
                        path.addLine(to: CGPoint(x: 0, y: h))
                        path.closeSubpath()
                    }
                    .fill(FitTodayColor.brandPrimary.opacity(0.12))
                )
            }
        }
    }
}

private extension WorkoutHistoryEntry {
    var focusTitle: String {
        switch focus {
        case .upper: return "Upper"
        case .lower: return "Lower"
        case .cardio: return "Cardio"
        case .core: return "Core"
        case .fullBody: return "Full Body"
        case .surprise: return "Surprise"
        }
    }
}
