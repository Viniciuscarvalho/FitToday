//
//  ChallengesView.swift
//  FitToday
//
//  Full implementation of ChallengesListView and ChallengeDetailView.
//

import SwiftUI

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
    @State private var challenges: [ChallengeDisplayModel] = []
    @State private var isLoading = true
    @State private var selectedFilter: ChallengeFilter = .active
    @State private var selectedChallenge: ChallengeDisplayModel?

    enum ChallengeFilter: String, CaseIterable {
        case active = "Ativos"
        case completed = "Concluídos"
        case all = "Todos"
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
            ChallengeDetailView(challenge: challenge)
        }
        .task {
            await loadChallenges()
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
            Image(systemName: "trophy.circle")
                .font(.system(size: 48))
                .foregroundStyle(FitTodayColor.textTertiary)

            Text("Nenhum desafio encontrado")
                .font(FitTodayFont.ui(size: 17, weight: .semiBold))
                .foregroundStyle(FitTodayColor.textPrimary)

            Text("Participe de um grupo para acessar desafios")
                .font(FitTodayFont.ui(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(FitTodaySpacing.xl)
    }

    // MARK: - Data Loading

    private func loadChallenges() async {
        try? await Task.sleep(for: .milliseconds(500))

        // Mock data
        challenges = [
            ChallengeDisplayModel(
                id: "1",
                title: "30 Dias de Treino",
                description: "Complete 30 treinos em 30 dias para ganhar medalha de ouro",
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
            ),
            ChallengeDisplayModel(
                id: "2",
                title: "Streak Semanal",
                description: "Mantenha uma sequência de 7 dias consecutivos de treino",
                type: .streak,
                iconName: "bolt.fill",
                progress: 0.71,
                currentValue: 5,
                targetValue: 7,
                unit: "dias",
                daysRemaining: 2,
                participants: 15,
                isActive: true,
                startDate: Date().addingTimeInterval(-5 * 86400),
                endDate: Date().addingTimeInterval(2 * 86400)
            ),
            ChallengeDisplayModel(
                id: "3",
                title: "Desafio Volume",
                description: "Levante 50.000kg de volume total no mês",
                type: .checkIns,
                iconName: "scalemass.fill",
                progress: 1.0,
                currentValue: 52340,
                targetValue: 50000,
                unit: "kg",
                daysRemaining: 0,
                participants: 8,
                isActive: false,
                startDate: Date().addingTimeInterval(-30 * 86400),
                endDate: Date().addingTimeInterval(-1 * 86400)
            )
        ]
        isLoading = false
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
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FitTodaySpacing.lg) {
                    // Hero Section
                    heroSection

                    // Progress Section
                    progressSection

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
                    Button {
                        // Share action
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
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
    ChallengesFullListView()
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
