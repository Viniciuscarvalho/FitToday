//
//  ChallengesView.swift
//  FitToday
//
//  Full implementation of ChallengesListView and ChallengeDetailView.
//

import SwiftUI
import Swinject

// MARK: - Challenge Display Model

/// View model for displaying a challenge with its progress.
struct ChallengeDisplayModel: Identifiable, Sendable {
    let id: String
    let title: String
    let description: String
    let type: ChallengeType
    let iconName: String
    let progress: Double // 0.0 to 1.0
    let currentValue: Int
    let targetValue: Int
    let unit: String
    let daysRemaining: Int
    let participants: Int
    let isActive: Bool
    let startDate: Date
    let endDate: Date

    var progressPercentage: Int {
        Int(progress * 100)
    }

    var progressColor: Color {
        if progress >= 1.0 {
            return .green
        } else if progress >= 0.5 {
            return FitTodayColor.brandPrimary
        } else {
            return .orange
        }
    }
}

// MARK: - Challenges List View (Full Implementation)

/// Full list view for displaying active and completed challenges.
struct ChallengesFullListView: View {
    @Environment(AppRouter.self) private var router
    let resolver: Resolver

    @State private var viewModel: ChallengesViewModel?
    @State private var selectedFilter: ChallengeFilter = .active
    @State private var selectedChallenge: ChallengeDisplayModel?
    @State private var showCreateGroup = false
    @State private var showJoinGroup = false

    enum ChallengeFilter: String, CaseIterable {
        case active = "Ativos"
        case completed = "Concluídos"
        case all = "Todos"
    }

    private var challenges: [ChallengeDisplayModel] {
        viewModel?.challenges ?? []
    }

    private var isLoading: Bool {
        viewModel?.isLoading ?? true
    }

    private var isInGroup: Bool {
        viewModel?.isInGroup ?? false
    }

    private var filteredChallenges: [ChallengeDisplayModel] {
        switch selectedFilter {
        case .active:
            return challenges.filter { $0.isActive && $0.progress < 1.0 }
        case .completed:
            return challenges.filter { $0.progress >= 1.0 }
        case .all:
            return challenges
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: FitTodaySpacing.lg) {
                // Filter Pills
                filterSection

                // Summary Card
                if !challenges.isEmpty {
                    summaryCard
                }

                // Challenges List
                challengesSection
            }
            .padding(FitTodaySpacing.md)
        }
        .scrollIndicators(.hidden)
        .sheet(item: $selectedChallenge) { challenge in
            ChallengeDetailView(
                challenge: challenge,
                groupId: viewModel?.currentGroupId,
                resolver: resolver,
                onCheckInSubmitted: {
                    Task {
                        await viewModel?.refresh()
                    }
                }
            )
        }
        .task {
            if viewModel == nil {
                viewModel = ChallengesViewModel(resolver: resolver)
            }
            await viewModel?.onAppear()
        }
        .onDisappear {
            viewModel?.stopObserving()
        }
        .refreshable {
            await viewModel?.refresh()
        }
    }

    // MARK: - Filter Section

    private var filterSection: some View {
        HStack(spacing: FitTodaySpacing.sm) {
            ForEach(ChallengeFilter.allCases, id: \.self) { filter in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedFilter = filter
                    }
                } label: {
                    Text(filter.rawValue)
                        .font(FitTodayFont.ui(size: 13, weight: selectedFilter == filter ? .bold : .medium))
                        .foregroundStyle(selectedFilter == filter ? .white : FitTodayColor.textSecondary)
                        .padding(.horizontal, FitTodaySpacing.md)
                        .padding(.vertical, FitTodaySpacing.sm)
                        .background(
                            Capsule()
                                .fill(selectedFilter == filter ? FitTodayColor.brandPrimary : FitTodayColor.surface)
                        )
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        HStack(spacing: FitTodaySpacing.lg) {
            summaryItem(
                value: "\(challenges.filter { $0.isActive }.count)",
                label: "Ativos",
                icon: "flame.fill",
                color: .orange
            )

            summaryItem(
                value: "\(challenges.filter { $0.progress >= 1.0 }.count)",
                label: "Concluídos",
                icon: "checkmark.circle.fill",
                color: .green
            )

            summaryItem(
                value: "\(Int(challenges.reduce(0) { $0 + $1.progress } / Double(max(1, challenges.count)) * 100))%",
                label: "Média",
                icon: "chart.line.uptrend.xyaxis",
                color: FitTodayColor.brandPrimary
            )
        }
        .padding(FitTodaySpacing.md)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .fill(FitTodayColor.surface)
        )
    }

    private func summaryItem(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: FitTodaySpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)

            Text(value)
                .font(FitTodayFont.ui(size: 18, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)

            Text(label)
                .font(FitTodayFont.ui(size: 11, weight: .medium))
                .foregroundStyle(FitTodayColor.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Challenges Section

    private var challengesSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            Text("Desafios")
                .font(FitTodayFont.ui(size: 17, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)

            if isLoading {
                loadingView
            } else if filteredChallenges.isEmpty {
                emptyStateView
            } else {
                LazyVStack(spacing: FitTodaySpacing.sm) {
                    ForEach(filteredChallenges) { challenge in
                        ChallengeCard(challenge: challenge) {
                            selectedChallenge = challenge
                        }
                    }
                }
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: FitTodaySpacing.md) {
            ProgressView()
                .tint(FitTodayColor.brandPrimary)
            Text("Carregando desafios...")
                .font(FitTodayFont.ui(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(FitTodaySpacing.xl)
    }

    private var emptyStateView: some View {
        VStack(spacing: FitTodaySpacing.md) {
            Image(systemName: isInGroup ? "trophy.circle" : "person.2.circle")
                .font(.system(size: 48))
                .foregroundStyle(FitTodayColor.textTertiary)

            Text(isInGroup ? "Nenhum desafio encontrado" : "Entre em um grupo")
                .font(FitTodayFont.ui(size: 17, weight: .semiBold))
                .foregroundStyle(FitTodayColor.textPrimary)

            Text(isInGroup
                 ? "Os desafios semanais serão criados automaticamente"
                 : "Participe de um grupo para acessar desafios e competir com amigos")
                .font(FitTodayFont.ui(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
                .multilineTextAlignment(.center)

            if let errorMessage = viewModel?.errorMessage {
                Text(errorMessage)
                    .font(FitTodayFont.ui(size: 12, weight: .medium))
                    .foregroundStyle(FitTodayColor.error)
                    .multilineTextAlignment(.center)
            }

            // Group creation/join buttons (only when not in a group)
            if !isInGroup {
                VStack(spacing: FitTodaySpacing.sm) {
                    Button {
                        showCreateGroup = true
                    } label: {
                        HStack(spacing: FitTodaySpacing.sm) {
                            Image(systemName: "plus.circle.fill")
                            Text("Criar Grupo")
                        }
                    }
                    .fitPrimaryStyle()

                    Button {
                        showJoinGroup = true
                    } label: {
                        HStack(spacing: FitTodaySpacing.sm) {
                            Image(systemName: "person.badge.plus")
                            Text("Entrar em Grupo")
                        }
                    }
                    .fitSecondaryStyle()
                }
                .padding(.top, FitTodaySpacing.md)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(FitTodaySpacing.xl)
        .sheet(isPresented: $showCreateGroup) {
            CreateGroupView(resolver: resolver) { group in
                Task {
                    await viewModel?.refresh()
                }
            }
        }
        .sheet(isPresented: $showJoinGroup) {
            JoinGroupSheet(resolver: resolver) {
                Task {
                    await viewModel?.refresh()
                }
            }
        }
    }
}

// MARK: - Join Group Sheet

struct JoinGroupSheet: View {
    @Environment(\.dismiss) private var dismiss
    let resolver: Resolver
    let onJoined: () -> Void

    @State private var inviteCode = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Código de convite", text: $inviteCode)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.characters)
                } header: {
                    Text("Código de Convite")
                } footer: {
                    Text("Peça o código de convite para o administrador do grupo")
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(FitTodayColor.error)
                            .font(FitTodayFont.ui(size: 14, weight: .medium))
                    }
                }
            }
            .navigationTitle("Entrar em Grupo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Entrar") {
                        Task {
                            await joinGroup()
                        }
                    }
                    .disabled(inviteCode.isEmpty || isLoading)
                }
            }
            .disabled(isLoading)
        }
    }

    private func joinGroup() async {
        guard !inviteCode.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        guard let joinUseCase = resolver.resolve(JoinGroupUseCase.self) else {
            errorMessage = "Serviço não disponível"
            return
        }

        do {
            try await joinUseCase.execute(groupId: inviteCode)
            dismiss()
            onJoined()
        } catch {
            errorMessage = "Não foi possível entrar no grupo: \(error.localizedDescription)"
        }
    }
}

// MARK: - Challenge Card

struct ChallengeCard: View {
    let challenge: ChallengeDisplayModel
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
                // Header
                HStack {
                    Image(systemName: challenge.iconName)
                        .font(.system(size: 24))
                        .foregroundStyle(challenge.progressColor)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(challenge.title)
                            .font(FitTodayFont.ui(size: 16, weight: .bold))
                            .foregroundStyle(FitTodayColor.textPrimary)

                        HStack(spacing: FitTodaySpacing.xs) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 10))
                            Text("\(challenge.participants) participantes")
                                .font(FitTodayFont.ui(size: 11, weight: .medium))
                        }
                        .foregroundStyle(FitTodayColor.textTertiary)
                    }

                    Spacer()

                    if challenge.progress >= 1.0 {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.green)
                    } else {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(challenge.progressPercentage)%")
                                .font(FitTodayFont.ui(size: 14, weight: .bold))
                                .foregroundStyle(challenge.progressColor)

                            if challenge.daysRemaining > 0 {
                                Text("\(challenge.daysRemaining) dias")
                                    .font(FitTodayFont.ui(size: 11, weight: .medium))
                                    .foregroundStyle(FitTodayColor.textTertiary)
                            }
                        }
                    }
                }

                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(FitTodayColor.outline)
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(challenge.progressColor)
                            .frame(width: geometry.size.width * min(challenge.progress, 1.0), height: 8)
                    }
                }
                .frame(height: 8)

                // Progress Text
                HStack {
                    Text("\(challenge.currentValue) / \(challenge.targetValue) \(challenge.unit)")
                        .font(FitTodayFont.ui(size: 13, weight: .medium))
                        .foregroundStyle(FitTodayColor.textSecondary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(FitTodayColor.textTertiary)
                }
            }
            .padding(FitTodaySpacing.md)
            .background(
                RoundedRectangle(cornerRadius: FitTodayRadius.md)
                    .fill(FitTodayColor.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: FitTodayRadius.md)
                    .stroke(challenge.progress >= 1.0 ? Color.green.opacity(0.3) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Challenge Detail View

struct ChallengeDetailView: View {
    let challenge: ChallengeDisplayModel
    var groupId: String?
    var resolver: Resolver?
    var onCheckInSubmitted: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var showCheckInSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FitTodaySpacing.lg) {
                    // Hero Section
                    heroSection

                    // Progress Section
                    progressSection

                    // Check-in Button (only for check-in type challenges)
                    if challenge.type == .checkIns && challenge.progress < 1.0 {
                        checkInButtonSection
                    }

                    // Stats Section
                    statsSection

                    // Description
                    descriptionSection

                    // Timeline
                    timelineSection
                }
                .padding(FitTodaySpacing.md)
            }
            .scrollIndicators(.hidden)
            .background(FitTodayColor.background)
            .navigationTitle(challenge.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    if let groupId {
                        let links = GenerateInviteLinkUseCase().execute(groupId: groupId)
                        ShareLink(
                            item: links.shareURL,
                            subject: Text("Convite para FitToday"),
                            message: Text("Participe do desafio '\(challenge.title)' no FitToday! 💪")
                        ) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
            .sheet(isPresented: $showCheckInSheet) {
                if let resolver = resolver {
                    CheckInSheet(
                        resolver: resolver,
                        challengeId: challenge.id
                    ) {
                        onCheckInSubmitted?()
                    }
                }
            }
        }
    }

    // MARK: - Check-in Button Section

    private var checkInButtonSection: some View {
        Button {
            showCheckInSheet = true
        } label: {
            HStack(spacing: FitTodaySpacing.sm) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 18))
                Text("Fazer Check-In")
                    .font(FitTodayFont.ui(size: 16, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(FitTodaySpacing.md)
            .background(
                LinearGradient(
                    colors: [FitTodayColor.brandPrimary, FitTodayColor.brandPrimary.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
        }
        .buttonStyle(.plain)
        .disabled(resolver == nil)
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: FitTodaySpacing.md) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [challenge.progressColor.opacity(0.3), challenge.progressColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: challenge.iconName)
                    .font(.system(size: 44))
                    .foregroundStyle(challenge.progressColor)
            }

            if challenge.progress >= 1.0 {
                HStack(spacing: FitTodaySpacing.xs) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                    Text("Desafio Concluído!")
                        .font(FitTodayFont.ui(size: 16, weight: .bold))
                        .foregroundStyle(.green)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(FitTodaySpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.lg)
                .fill(FitTodayColor.surface)
        )
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        VStack(spacing: FitTodaySpacing.md) {
            // Large progress indicator
            ZStack {
                Circle()
                    .stroke(FitTodayColor.outline, lineWidth: 12)

                Circle()
                    .trim(from: 0, to: min(challenge.progress, 1.0))
                    .stroke(
                        challenge.progressColor,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: challenge.progress)

                VStack(spacing: FitTodaySpacing.xs) {
                    Text("\(challenge.progressPercentage)%")
                        .font(FitTodayFont.ui(size: 32, weight: .bold))
                        .foregroundStyle(FitTodayColor.textPrimary)

                    Text("\(challenge.currentValue) de \(challenge.targetValue)")
                        .font(FitTodayFont.ui(size: 14, weight: .medium))
                        .foregroundStyle(FitTodayColor.textSecondary)
                }
            }
            .frame(width: 160, height: 160)

            Text(challenge.unit)
                .font(FitTodayFont.ui(size: 16, weight: .semiBold))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(FitTodaySpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.lg)
                .fill(FitTodayColor.surface)
        )
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        HStack(spacing: FitTodaySpacing.md) {
            statCard(
                title: "Participantes",
                value: "\(challenge.participants)",
                icon: "person.2.fill",
                color: FitTodayColor.brandPrimary
            )

            statCard(
                title: "Dias Restantes",
                value: challenge.daysRemaining > 0 ? "\(challenge.daysRemaining)" : "0",
                icon: "calendar",
                color: challenge.daysRemaining > 0 ? .orange : .green
            )

            statCard(
                title: "Tipo",
                value: challenge.type == .streak ? "Streak" : "Check-in",
                icon: challenge.type == .streak ? "bolt.fill" : "checkmark.circle.fill",
                color: .purple
            )
        }
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: FitTodaySpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)

            Text(value)
                .font(FitTodayFont.ui(size: 18, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)

            Text(title)
                .font(FitTodayFont.ui(size: 11, weight: .medium))
                .foregroundStyle(FitTodayColor.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(FitTodaySpacing.md)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .fill(FitTodayColor.surface)
        )
    }

    // MARK: - Description Section

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            Text("Sobre o Desafio")
                .font(FitTodayFont.ui(size: 17, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)

            Text(challenge.description)
                .font(FitTodayFont.ui(size: 15, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(FitTodaySpacing.md)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .fill(FitTodayColor.surface)
        )
    }

    // MARK: - Timeline Section

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            Text("Período")
                .font(FitTodayFont.ui(size: 17, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)

            HStack(spacing: FitTodaySpacing.md) {
                VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                    Text("Início")
                        .font(FitTodayFont.ui(size: 12, weight: .medium))
                        .foregroundStyle(FitTodayColor.textTertiary)

                    Text(challenge.startDate, format: .dateTime.day().month().year())
                        .font(FitTodayFont.ui(size: 14, weight: .semiBold))
                        .foregroundStyle(FitTodayColor.textPrimary)
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .foregroundStyle(FitTodayColor.textTertiary)

                Spacer()

                VStack(alignment: .trailing, spacing: FitTodaySpacing.xs) {
                    Text("Término")
                        .font(FitTodayFont.ui(size: 12, weight: .medium))
                        .foregroundStyle(FitTodayColor.textTertiary)

                    Text(challenge.endDate, format: .dateTime.day().month().year())
                        .font(FitTodayFont.ui(size: 14, weight: .semiBold))
                        .foregroundStyle(FitTodayColor.textPrimary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(FitTodaySpacing.md)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .fill(FitTodayColor.surface)
        )
    }
}

// MARK: - Previews

#Preview("Challenges List") {
    let container = Container()
    return ChallengesFullListView(resolver: container)
        .preferredColorScheme(.dark)
}

#Preview("Challenge Detail") {
    ChallengeDetailView(
        challenge: ChallengeDisplayModel(
            id: "1",
            title: "30 Dias de Treino",
            description: "Complete 30 treinos em 30 dias para ganhar medalha de ouro. Este desafio testa sua consistência e dedicação ao longo de um mês inteiro.",
            type: .checkIns,
            iconName: "flame.fill",
            progress: 0.6,
            currentValue: 18,
            targetValue: 30,
            unit: "treinos",
            daysRemaining: 12,
            participants: 24,
            isActive: true,
            startDate: Date().addingTimeInterval(-18 * 86400),
            endDate: Date().addingTimeInterval(12 * 86400)
        )
    )
    .preferredColorScheme(.dark)
}
