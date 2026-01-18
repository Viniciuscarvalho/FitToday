//
//  LeaderboardView.swift
//  FitToday
//
//  Created by Claude on 17/01/26.
//

import SwiftUI
import Swinject

// MARK: - LeaderboardView

struct LeaderboardView: View {
    // MARK: - Properties

    let groupId: String
    let currentUserId: String?

    @State private var viewModel: LeaderboardViewModel
    @State private var selectedTab: ChallengeType = .checkIns

    // MARK: - Initialization

    init(groupId: String, currentUserId: String?, resolver: Resolver) {
        self.groupId = groupId
        self.currentUserId = currentUserId
        _viewModel = State(wrappedValue: LeaderboardViewModel(resolver: resolver))
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            Picker("Tipo de Desafio", selection: $selectedTab) {
                Text("Esta Semana").tag(ChallengeType.checkIns)
                Text("Maior Sequência").tag(ChallengeType.streak)
            }
            .pickerStyle(.segmented)
            .padding()

            // Leaderboard content
            if viewModel.isLoading {
                loadingView
            } else if let errorMessage = viewModel.errorMessage {
                errorView(message: errorMessage)
            } else {
                leaderboardList(snapshot: selectedTab == .checkIns ? viewModel.checkInsLeaderboard : viewModel.streakLeaderboard)
            }
        }
        .task {
            viewModel.startListening(groupId: groupId)
        }
        .onDisappear {
            viewModel.stopListening()
        }
    }

    // MARK: - Leaderboard List

    @ViewBuilder
    private func leaderboardList(snapshot: LeaderboardSnapshot?) -> some View {
        if let snapshot = snapshot, !snapshot.entries.isEmpty {
            ScrollView {
                VStack(spacing: 0) {
                    // Challenge period header
                    challengePeriodHeader(challenge: snapshot.challenge)

                    // Entries list
                    ForEach(snapshot.entries) { entry in
                        LeaderboardRowView(
                            entry: entry,
                            isCurrentUser: entry.id == currentUserId,
                            challengeType: selectedTab
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))

                        if entry.id != snapshot.entries.last?.id {
                            Divider()
                                .padding(.leading, 68)
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: snapshot.entries.map { $0.rank })
            }
        } else {
            emptyStateView
        }
    }

    // MARK: - Challenge Period Header

    private func challengePeriodHeader(challenge: Challenge) -> some View {
        VStack(spacing: 4) {
            Text("Semana de")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("\(challenge.weekStartDate.formatted(.dateTime.day().month())) - \(challenge.weekEndDate.formatted(.dateTime.day().month()))")
                .font(.subheadline.bold())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Carregando classificação...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.red)

            Text("Erro")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: selectedTab == .checkIns ? "figure.run" : "flame.fill")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)

            Text(selectedTab == .checkIns ? "Nenhum treino esta semana!" : "Nenhuma sequência ainda!")
                .font(.headline)

            Text("Seja o primeiro a treinar e aparecer no ranking!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - LeaderboardRowView

struct LeaderboardRowView: View {
    // MARK: - Properties

    let entry: LeaderboardEntry
    let isCurrentUser: Bool
    let challengeType: ChallengeType

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            // Rank badge
            rankBadge

            // Avatar or initials
            avatarView

            // Name and value
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.displayName)
                    .font(isCurrentUser ? .headline : .body)
                    .foregroundStyle(isCurrentUser ? .primary : .primary)

                Text(metricText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Trophy for top 3
            if entry.rank <= 3 {
                trophyIcon
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isCurrentUser ? Color.accentColor.opacity(0.1) : Color.clear)
    }

    // MARK: - Rank Badge

    private var rankBadge: some View {
        ZStack {
            Circle()
                .fill(rankColor.opacity(0.15))
                .frame(width: 36, height: 36)

            Text("#\(entry.rank)")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(rankColor)
        }
    }

    // MARK: - Avatar View

    @ViewBuilder
    private var avatarView: some View {
        if let photoURL = entry.photoURL {
            AsyncImage(url: photoURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                initialsView
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())
        } else {
            initialsView
        }
    }

    private var initialsView: some View {
        ZStack {
            Circle()
                .fill(isCurrentUser ? Color.accentColor : Color.accentColor.opacity(0.2))

            Text(initials)
                .font(.headline)
                .foregroundStyle(isCurrentUser ? .white : Color.accentColor)
        }
        .frame(width: 44, height: 44)
    }

    // MARK: - Trophy Icon

    private var trophyIcon: some View {
        Image(systemName: trophyIconName)
            .font(.system(size: 20))
            .foregroundStyle(trophyColor)
    }

    // MARK: - Computed Properties

    private var initials: String {
        let components = entry.displayName.split(separator: " ")
        let firstInitial = components.first?.first.map(String.init) ?? ""
        let lastInitial = components.count > 1 ? components.last?.first.map(String.init) ?? "" : ""
        return (firstInitial + lastInitial).uppercased()
    }

    private var metricText: String {
        switch challengeType {
        case .checkIns:
            return entry.value == 1 ? "1 treino" : "\(entry.value) treinos"
        case .streak:
            return entry.value == 1 ? "1 dia" : "\(entry.value) dias"
        }
    }

    private var rankColor: Color {
        switch entry.rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .secondary
        }
    }

    private var trophyIconName: String {
        switch entry.rank {
        case 1: return "trophy.fill"
        case 2: return "medal.fill"
        case 3: return "medal.fill"
        default: return ""
        }
    }

    private var trophyColor: Color {
        switch entry.rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .clear
        }
    }
}

// MARK: - Preview

#Preview {
    let mockEntries = [
        LeaderboardEntry(id: "1", displayName: "João Silva", photoURL: nil, value: 5, rank: 1, lastUpdated: Date()),
        LeaderboardEntry(id: "2", displayName: "Maria Santos", photoURL: nil, value: 4, rank: 2, lastUpdated: Date()),
        LeaderboardEntry(id: "3", displayName: "Pedro Oliveira", photoURL: nil, value: 3, rank: 3, lastUpdated: Date()),
        LeaderboardEntry(id: "4", displayName: "Ana Costa", photoURL: nil, value: 2, rank: 4, lastUpdated: Date())
    ]

    let mockChallenge = Challenge(
        id: "test",
        groupId: "group1",
        type: .checkIns,
        weekStartDate: Date(),
        weekEndDate: Date().addingTimeInterval(7*24*60*60),
        isActive: true,
        createdAt: Date()
    )

    return LeaderboardView(
        groupId: "test",
        currentUserId: "2",
        resolver: Container().synchronize()
    )
}
