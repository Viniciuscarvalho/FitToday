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
    case history
    case challenges

    var displayName: String {
        switch self {
        case .history: return "history.tab.history".localized
        case .challenges: return "history.tab.challenges".localized
        }
    }
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
            Text("history.header.title".localized)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)
            Text("history.header.subtitle".localized)
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
                    Text(tab.displayName)
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
                        Text("history.loading_more".localized)
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
            Text("history.empty".localized)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)
            Text("history.empty.subtitle".localized)
                .font(.system(size: 14))
                .foregroundStyle(FitTodayColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, FitTodaySpacing.xxl)
    }

    // MARK: - Challenges Content

    @ViewBuilder
    private var challengesContent: some View {
        // Check if user is authenticated
        let isAuthenticated = UserDefaults.standard.string(forKey: "socialUserId") != nil

        if isAuthenticated {
            // Show the actual groups view when authenticated
            GroupsContentView(resolver: resolver)
        } else {
            // Show authentication prompt when not logged in
            VStack(spacing: FitTodaySpacing.lg) {
                JoinChallengeCard {
                    // Navigate to authentication
                    router.push(.authentication(inviteContext: "Entre para criar ou participar de desafios com amigos"), on: .activity)
                }

                // Info section
                VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
                    Text("challenges.info.title".localized)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(FitTodayColor.textPrimary)
                        .padding(.horizontal)

                    Text("challenges.info.subtitle".localized)
                        .font(.system(size: 14))
                        .foregroundStyle(FitTodayColor.textSecondary)
                        .padding(.horizontal)
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Groups Content View (Embedded)

private struct GroupsContentView: View {
    @State private var viewModel: GroupsViewModel
    @State private var showingCreateGroup = false
    @State private var showingNotifications = false
    @State private var showingManageGroup = false
    let resolver: Resolver

    init(resolver: Resolver) {
        self.resolver = resolver
        _viewModel = State(initialValue: GroupsViewModel(resolver: resolver))
    }

    var body: some View {
        VStack(spacing: FitTodaySpacing.lg) {
            if viewModel.isLoading && viewModel.currentGroup == nil {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else if let group = viewModel.currentGroup {
                // User has a group - show dashboard
                GroupDashboardCard(
                    group: group,
                    members: viewModel.members,
                    isAdmin: viewModel.isAdmin,
                    unreadCount: viewModel.unreadNotificationsCount,
                    onNotificationsTapped: { showingNotifications = true },
                    onManageTapped: { showingManageGroup = true }
                )

                // Leaderboard preview
                if !viewModel.members.isEmpty {
                    LeaderboardPreviewCard(members: viewModel.members)
                }
            } else {
                // No group - show create/join options
                EmptyGroupCard {
                    showingCreateGroup = true
                }
            }
        }
        .padding(.horizontal)
        .task {
            await viewModel.onAppear()
        }
        .refreshable {
            await viewModel.loadCurrentGroup()
            await viewModel.loadUnreadNotificationsCount()
        }
        .sheet(isPresented: $showingCreateGroup) {
            CreateGroupView(resolver: resolver) { _ in
                Task {
                    await viewModel.loadCurrentGroup()
                }
            }
        }
        .sheet(isPresented: $showingNotifications) {
            NavigationStack {
                NotificationFeedView(
                    viewModel: NotificationFeedViewModel(resolver: resolver)
                )
            }
            .onDisappear {
                viewModel.clearUnreadCount()
                Task {
                    await viewModel.loadUnreadNotificationsCount()
                }
            }
        }
        .sheet(isPresented: $showingManageGroup) {
            if let group = viewModel.currentGroup {
                ManageGroupView(
                    group: group,
                    members: viewModel.members,
                    currentUserId: viewModel.currentUserId,
                    onRemoveMember: { userId in
                        Task {
                            await viewModel.removeMember(userId: userId)
                        }
                    },
                    onDeleteGroup: {
                        Task {
                            await viewModel.deleteGroup()
                        }
                    }
                )
            }
        }
        .showErrorAlert(errorMessage: $viewModel.errorMessage)
    }
}

// MARK: - Group Dashboard Card

private struct GroupDashboardCard: View {
    let group: SocialGroup
    let members: [GroupMember]
    let isAdmin: Bool
    let unreadCount: Int
    let onNotificationsTapped: () -> Void
    let onManageTapped: () -> Void

    // Generate invite links for sharing
    private var inviteLinks: InviteLinks {
        GenerateInviteLinkUseCase().execute(groupId: group.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text("groups.active".localized)
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(FitTodayColor.success)
                .clipShape(Capsule())

                Spacer()

                // Share/Invite button
                ShareLink(
                    item: inviteLinks.shareURL,
                    subject: Text("groups.invite.subject".localized),
                    message: Text(String(format: "groups.invite.message".localized, group.name))
                ) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16))
                        .foregroundStyle(FitTodayColor.brandPrimary)
                }
                .padding(.trailing, FitTodaySpacing.sm)

                // Notifications button
                Button(action: onNotificationsTapped) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(FitTodayColor.textSecondary)

                        if unreadCount > 0 {
                            Text("\(min(unreadCount, 99))")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(3)
                                .background(Color.red)
                                .clipShape(Circle())
                                .offset(x: 6, y: -6)
                        }
                    }
                }
            }

            // Group name
            Text(group.name)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)

            // Members count - use actual members array count instead of stored memberCount
            Text("\(members.count) " + "groups.members".localized)
                .font(.system(size: 14))
                .foregroundStyle(FitTodayColor.textSecondary)

            // Members preview
            if !members.isEmpty {
                HStack(spacing: -8) {
                    ForEach(members.prefix(5), id: \.id) { member in
                        Circle()
                            .fill(FitTodayColor.surfaceElevated)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Text(member.displayName.prefix(1).uppercased())
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(FitTodayColor.textPrimary)
                            )
                            .overlay(
                                Circle()
                                    .stroke(FitTodayColor.surface, lineWidth: 2)
                            )
                    }

                    if members.count > 5 {
                        Text("+\(members.count - 5)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(FitTodayColor.textSecondary)
                            .padding(.leading, 16)
                    }
                }
            }

            // Manage button (admin only)
            if isAdmin {
                Button(action: onManageTapped) {
                    HStack {
                        Spacer()
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 12))
                        Text("groups.manage".localized)
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
        }
        .padding(FitTodaySpacing.lg)
        .background(FitTodayColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Leaderboard Preview Card

private struct LeaderboardPreviewCard: View {
    let members: [GroupMember]

    // Sort members by workout count descending
    private var rankedMembers: [GroupMember] {
        members.sorted { $0.weeklyWorkoutCount > $1.weeklyWorkoutCount }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            HStack {
                Text("groups.leaderboard".localized)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(FitTodayColor.textPrimary)
                Spacer()
                Text("groups.this_week".localized)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(FitTodayColor.textSecondary)
            }

            ForEach(Array(rankedMembers.prefix(5).enumerated()), id: \.element.id) { index, member in
                HStack(spacing: FitTodaySpacing.md) {
                    // Rank
                    Text("\(index + 1)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(index == 0 ? FitTodayColor.brandPrimary : FitTodayColor.textSecondary)
                        .frame(width: 24)

                    // Avatar
                    Circle()
                        .fill(FitTodayColor.surfaceElevated)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text(member.displayName.prefix(1).uppercased())
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(FitTodayColor.textPrimary)
                        )

                    // Name
                    VStack(alignment: .leading, spacing: 2) {
                        Text(member.displayName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(FitTodayColor.textPrimary)
                        Text("leaderboard.minutes".localized(with: member.weeklyWorkoutMinutes))
                            .font(.system(size: 11))
                            .foregroundStyle(FitTodayColor.textTertiary)
                    }

                    Spacer()

                    // Workout count
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(member.weeklyWorkoutCount)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(index == 0 ? FitTodayColor.brandPrimary : FitTodayColor.textPrimary)
                        Text("leaderboard.workouts".localized)
                            .font(.system(size: 10))
                            .foregroundStyle(FitTodayColor.textTertiary)
                    }

                    // Badge for top 3
                    if index < 3 {
                        Image(systemName: index == 0 ? "crown.fill" : "medal.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(index == 0 ? .yellow : (index == 1 ? .gray : .orange))
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(FitTodaySpacing.lg)
        .background(FitTodayColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Empty Group Card

private struct EmptyGroupCard: View {
    let onCreateTapped: () -> Void

    var body: some View {
        VStack(spacing: FitTodaySpacing.lg) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 48))
                .foregroundStyle(FitTodayColor.brandPrimary)

            Text("groups.empty.title".localized)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)

            Text("groups.empty.subtitle".localized)
                .font(.system(size: 14))
                .foregroundStyle(FitTodayColor.textSecondary)
                .multilineTextAlignment(.center)

            Button(action: onCreateTapped) {
                HStack {
                    Spacer()
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                    Text("groups.create".localized)
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                }
                .foregroundStyle(.white)
                .padding(.vertical, 12)
                .background(FitTodayColor.gradientPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(FitTodaySpacing.xl)
        .background(FitTodayColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
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

            Text("challenges.join.title".localized)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)

            Text("challenges.join.subtitle".localized)
                .font(.system(size: 14))
                .foregroundStyle(FitTodayColor.textSecondary)

            Button(action: onJoin) {
                HStack {
                    Spacer()
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                    Text("challenges.join.button".localized)
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
        case .completed: return "history.completed".localized
        case .skipped: return "history.skipped".localized
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
                    label: "history.streak.current".localized,
                    value: "\(insights.currentStreak)",
                    unit: "history.streak.days".localized,
                    color: FitTodayColor.success
                )
                StatCard(
                    label: "history.streak.best".localized,
                    value: "\(insights.bestStreak)",
                    unit: "history.streak.days".localized,
                    color: FitTodayColor.brandPrimary
                )
            }

            // Sparkline card
            VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
                Text("history.weekly_minutes".localized)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(FitTodayColor.textPrimary)

                WeeklyMinutesSparkline(weeks: insights.weekly.map { $0.minutes })
                    .frame(height: 44)

                let totalSessions = insights.weekly.reduce(0) { $0 + $1.sessions }
                let totalMinutes = insights.weekly.reduce(0) { $0 + $1.minutes }
                Text(String(format: "history.weekly_summary".localized, insights.weekly.count, totalSessions, totalMinutes))
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
        case .upper: return "questionnaire.focus.upper".localized
        case .lower: return "questionnaire.focus.lower".localized
        case .cardio: return "questionnaire.focus.cardio".localized
        case .core: return "questionnaire.focus.core".localized
        case .fullBody: return "questionnaire.focus.fullbody".localized
        case .surprise: return "questionnaire.focus.surprise".localized
        }
    }
}
