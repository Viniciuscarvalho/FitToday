//
//  GroupDashboardView.swift
//  FitToday
//
//  Created by Claude on 16/01/26.
//

import SwiftUI
import Swinject

// MARK: - GroupTab

enum GroupTab: String, CaseIterable {
    case feed = "Feed"
    case leaderboard = "Ranking"

    var icon: String {
        switch self {
        case .feed: return "photo.stack"
        case .leaderboard: return "trophy"
        }
    }
}

// MARK: - GroupDashboardView

struct GroupDashboardView: View {
    let group: SocialGroup
    let members: [GroupMember]
    let isAdmin: Bool
    let currentUserId: String?
    let resolver: Resolver
    let onInviteTapped: () -> Void
    let onLeaveTapped: () -> Void
    var onManageGroupTapped: (() -> Void)?

    @State private var showLeaveConfirmation = false
    @State private var selectedTab: GroupTab = .feed
    @State private var feedViewModel: CheckInFeedViewModel?
    @State private var streakViewModel: GroupStreakViewModel?
    @State private var showStreakDetail = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Group Header
                GroupHeaderView(group: group, membersCount: members.count)

                // Group Streak Card
                if let streakVM = streakViewModel, let status = streakVM.streakStatus {
                    GroupStreakCardView(status: status) {
                        showStreakDetail = true
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                // Tab selector
            HStack(spacing: 0) {
                ForEach(GroupTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 20))
                            Text(tab.rawValue)
                                .font(.caption)
                        }
                        .foregroundStyle(selectedTab == tab ? FitTodayColor.brandPrimary : FitTodayColor.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                }
            }
            .background(FitTodayColor.surface)

            // Content
            TabView(selection: $selectedTab) {
                // Feed tab
                Group {
                    if let feedVM = feedViewModel {
                        CheckInFeedView(viewModel: feedVM)
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .tag(GroupTab.feed)

                // Leaderboard tab
                LeaderboardView(
                    groupId: group.id,
                    currentUserId: currentUserId,
                    resolver: resolver
                )
                .tag(GroupTab.leaderboard)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Action buttons
                GroupActionsBar(
                    isAdmin: isAdmin,
                    onInviteTapped: onInviteTapped,
                    onManageTapped: onManageGroupTapped,
                    onLeaveTapped: { showLeaveConfirmation = true }
                )
            }

            // Milestone Overlay
            if let streakVM = streakViewModel, streakVM.showMilestoneOverlay,
               let milestone = streakVM.reachedMilestone,
               let status = streakVM.streakStatus {
                MilestoneOverlayView(
                    milestone: milestone,
                    groupName: status.groupName,
                    topPerformers: status.topPerformers,
                    onShare: {
                        // Share functionality
                    },
                    onDismiss: {
                        streakVM.dismissMilestoneOverlay()
                    }
                )
            }
        }
        .task {
            initializeFeedViewModel()
            initializeStreakViewModel()
        }
        .sheet(isPresented: $showStreakDetail) {
            if let streakVM = streakViewModel {
                NavigationStack {
                    GroupStreakDetailView(viewModel: streakVM)
                }
            }
        }
        .onDisappear {
            streakViewModel?.stopObserving()
        }
        .confirmationDialog(
            "Sair do Grupo",
            isPresented: $showLeaveConfirmation,
            titleVisibility: .visible
        ) {
            Button("Sair", role: .destructive) {
                onLeaveTapped()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Tem certeza? Suas estatísticas serão removidas dos placares.")
        }
    }

    private func initializeFeedViewModel() {
        guard let checkInRepo = resolver.resolve(CheckInRepository.self) else { return }
        feedViewModel = CheckInFeedViewModel(
            checkInRepository: checkInRepo,
            groupId: group.id
        )
    }

    private func initializeStreakViewModel() {
        streakViewModel = GroupStreakViewModel(resolver: resolver)
        streakViewModel?.startObserving(groupId: group.id)
    }
}

// MARK: - GroupHeaderView

private struct GroupHeaderView: View {
    let group: SocialGroup
    let membersCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
            Text(group.name)
                .font(.title2.bold())

            Text("\(membersCount) \(membersCount == 1 ? "membro" : "membros")")
                .font(.subheadline)
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(FitTodayColor.surface)
    }
}

// MARK: - GroupActionsBar

private struct GroupActionsBar: View {
    let isAdmin: Bool
    let onInviteTapped: () -> Void
    var onManageTapped: (() -> Void)?
    let onLeaveTapped: () -> Void

    var body: some View {
        HStack(spacing: FitTodaySpacing.md) {
            Button {
                onInviteTapped()
            } label: {
                Label("Convidar", systemImage: "person.badge.plus")
                    .font(.caption)
            }
            .fitSecondaryStyle()

            if isAdmin {
                Button {
                    onManageTapped?()
                } label: {
                    Label("Gerenciar", systemImage: "gearshape")
                        .font(.caption)
                }
                .fitSecondaryStyle()
            }

            Button {
                onLeaveTapped()
            } label: {
                Label("Sair", systemImage: "rectangle.portrait.and.arrow.right")
                    .font(.caption)
            }
            .fitDestructiveStyle()
        }
        .padding()
        .background(FitTodayColor.surface)
    }
}

// MARK: - MemberRowView

private struct MemberRowView: View {
    let member: GroupMember

    var body: some View {
        HStack(spacing: 12) {
            // Avatar or initials
            if let photoURL = member.photoURL {
                AsyncImage(url: photoURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    initialsView
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            } else {
                initialsView
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(member.displayName)
                        .font(.body)

                    if member.role == .admin {
                        Text("Admin")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor)
                            .clipShape(Capsule())
                    }
                }

                Text("Entrou em \(member.joinedAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private var initialsView: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.2))

            Text(member.initials)
                .font(.headline)
                .foregroundStyle(Color.accentColor)
        }
        .frame(width: 40, height: 40)
    }
}

// MARK: - GroupMember Extension

private extension GroupMember {
    var initials: String {
        let components = displayName.split(separator: " ")
        let firstInitial = components.first?.first.map(String.init) ?? ""
        let lastInitial = components.count > 1 ? components.last?.first.map(String.init) ?? "" : ""
        return (firstInitial + lastInitial).uppercased()
    }
}

// MARK: - Preview

#Preview {
    let sampleMembers = [
        GroupMember(id: "1", displayName: "João Silva", photoURL: nil, joinedAt: Date(), role: .admin, isActive: true),
        GroupMember(id: "2", displayName: "Maria Santos", photoURL: nil, joinedAt: Date().addingTimeInterval(-86400), role: .member, isActive: true),
        GroupMember(id: "3", displayName: "Pedro Oliveira", photoURL: nil, joinedAt: Date().addingTimeInterval(-172800), role: .member, isActive: true)
    ]

    let sampleGroup = SocialGroup(
        id: "test",
        name: "Galera da Academia",
        createdAt: Date(),
        createdBy: "1",
        memberCount: 3,
        isActive: true
    )

    return NavigationStack {
        GroupDashboardView(
            group: sampleGroup,
            members: sampleMembers,
            isAdmin: true,
            currentUserId: "1",
            resolver: Container().synchronize(),
            onInviteTapped: { print("Invite tapped") },
            onLeaveTapped: { print("Leave tapped") },
            onManageGroupTapped: { print("Manage tapped") }
        )
        .navigationTitle("Grupos")
    }
}
