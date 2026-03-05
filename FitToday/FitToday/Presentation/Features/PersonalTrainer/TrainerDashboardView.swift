//
//  TrainerDashboardView.swift
//  FitToday
//
//  Dashboard view with trainer header and segmented tabs.
//

import SwiftUI
import Swinject

struct TrainerDashboardView: View {
    let trainer: PersonalTrainer
    let workouts: [TrainerWorkout]
    let isChatEnabled: Bool
    let onDisconnect: () -> Void
    let initialTab: TrainerDashboardTab
    let currentUserId: String
    let resolver: Resolver

    @State private var selectedTab: TrainerDashboardTab

    init(
        trainer: PersonalTrainer,
        workouts: [TrainerWorkout],
        isChatEnabled: Bool,
        onDisconnect: @escaping () -> Void,
        currentUserId: String,
        resolver: Resolver,
        initialTab: TrainerDashboardTab = .today
    ) {
        self.trainer = trainer
        self.workouts = workouts
        self.isChatEnabled = isChatEnabled
        self.onDisconnect = onDisconnect
        self.currentUserId = currentUserId
        self.resolver = resolver
        self.initialTab = initialTab
        self._selectedTab = State(wrappedValue: initialTab)
    }

    var body: some View {
        VStack(spacing: 0) {
            trainerHeader
            tabPicker
            tabContent
        }
        .background(FitTodayColor.background)
    }

    // MARK: - Trainer Header

    private var trainerHeader: some View {
        HStack(spacing: FitTodaySpacing.md) {
            trainerAvatar

            VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                Text(trainer.displayName)
                    .font(FitTodayFont.ui(size: 18, weight: .bold))
                    .foregroundStyle(FitTodayColor.textPrimary)
                    .lineLimit(1)

                HStack(spacing: FitTodaySpacing.xs) {
                    Circle()
                        .fill(FitTodayColor.success)
                        .frame(width: 8, height: 8)

                    Text("trainer.dashboard.online".localized)
                        .font(FitTodayFont.ui(size: 13, weight: .medium))
                        .foregroundStyle(FitTodayColor.textSecondary)
                }
            }

            Spacer()

            Menu {
                Button(role: .destructive) {
                    onDisconnect()
                } label: {
                    Label("trainer.dashboard.disconnect".localized, systemImage: "person.badge.minus")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(FitTodayColor.textSecondary)
                    .frame(width: 32, height: 32)
            }
        }
        .padding(.horizontal, FitTodaySpacing.md)
        .padding(.vertical, FitTodaySpacing.sm)
        .background(FitTodayColor.backgroundElevated)
    }

    private var trainerAvatar: some View {
        Group {
            if let photoURL = trainer.photoURL {
                AsyncImage(url: photoURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    avatarPlaceholder
                }
            } else {
                avatarPlaceholder
            }
        }
        .frame(width: 48, height: 48)
        .clipShape(Circle())
    }

    private var avatarPlaceholder: some View {
        Circle()
            .fill(FitTodayColor.brandPrimary.opacity(0.2))
            .overlay(
                Text(String(trainer.displayName.prefix(1)).uppercased())
                    .font(FitTodayFont.ui(size: 18, weight: .bold))
                    .foregroundStyle(FitTodayColor.brandPrimary)
            )
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(availableTabs, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: FitTodaySpacing.sm) {
                        Text(tab.title)
                            .font(FitTodayFont.ui(size: 14, weight: selectedTab == tab ? .bold : .medium))
                            .foregroundStyle(selectedTab == tab ? FitTodayColor.brandPrimary : FitTodayColor.textSecondary)

                        Rectangle()
                            .fill(selectedTab == tab ? FitTodayColor.brandPrimary : Color.clear)
                            .frame(height: 2)
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, FitTodaySpacing.md)
        .padding(.top, FitTodaySpacing.sm)
        .background(FitTodayColor.backgroundElevated)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .today:
            TodayWorkoutTabView(
                workouts: workouts,
                onViewHistory: { selectedTab = .history }
            )
        case .chat:
            TrainerChatView(
                trainerId: trainer.id,
                trainerName: trainer.displayName,
                currentUserId: currentUserId,
                resolver: resolver
            )
        case .history:
            TrainerHistoryView(workouts: workouts)
        case .evolution:
            TrainerEvolutionView(workouts: workouts)
        }
    }

    // MARK: - Helpers

    private var availableTabs: [TrainerDashboardTab] {
        var tabs: [TrainerDashboardTab] = [.today]
        if isChatEnabled {
            tabs.append(.chat)
        }
        tabs.append(contentsOf: [.history, .evolution])
        return tabs
    }
}

// MARK: - Dashboard Tab

enum TrainerDashboardTab: CaseIterable, Hashable {
    case today
    case chat
    case history
    case evolution

    var title: String {
        switch self {
        case .today: return "Hoje"
        case .chat: return "trainer.dashboard.tab.chat".localized
        case .history: return "trainer.dashboard.tab.history".localized
        case .evolution: return "trainer.dashboard.tab.evolution".localized
        }
    }

    var icon: String {
        switch self {
        case .today: return "doc.fill"
        case .chat: return "message.fill"
        case .history: return "clock.fill"
        case .evolution: return "chart.line.uptrend.xyaxis"
        }
    }
}
