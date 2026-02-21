//
//  ProgramsListView.swift
//  FitToday
//
//  Catalog view of workout programs grouped by category.
//

import SwiftUI
import Swinject

/// View displaying the catalog of workout programs grouped by category.
struct ProgramsListView: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.dependencyResolver) private var resolver

    @State private var viewModel: ProgramsListViewModel?
    @State private var dependencyError: String?
    @State private var hasInitialized = false

    var body: some View {
        Group {
            if let error = dependencyError {
                DependencyErrorView(message: error)
            } else if let viewModel {
                contentView(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .background(FitTodayColor.background)
        .task {
            guard !hasInitialized else { return }
            hasInitialized = true
            initializeViewModel()
        }
    }

    private func initializeViewModel() {
        guard let repository = resolver.resolve(ProgramRepository.self) else {
            dependencyError = NSLocalizedString("error.generic", comment: "Generic error")
            return
        }

        viewModel = ProgramsListViewModel(
            repository: repository,
            profileRepository: resolver.resolve(UserProfileRepository.self),
            historyRepository: resolver.resolve(WorkoutHistoryRepository.self)
        )
    }

    @ViewBuilder
    private func contentView(viewModel: ProgramsListViewModel) -> some View {
        ScrollView {
            VStack(spacing: FitTodaySpacing.lg) {
                // Action Buttons Row
                actionButtonsRow
                    .padding(.horizontal, FitTodaySpacing.md)

                // Grouped Programs — vertical list per category
                ForEach(viewModel.sortedGroupedPrograms, id: \.category) { group in
                    categorySection(category: group.category, programs: group.programs)
                }
            }
            .padding(.vertical, FitTodaySpacing.md)
        }
        .scrollIndicators(.hidden)
        .task {
            await viewModel.loadPrograms()
        }
    }

    // MARK: - Action Buttons Row

    private var actionButtonsRow: some View {
        HStack(spacing: FitTodaySpacing.sm) {
            Button {
                // TODO: navigate to create routine
            } label: {
                Label("Nova Rotina", systemImage: "plus")
                    .font(FitTodayFont.ui(size: 14, weight: .semiBold))
                    .foregroundStyle(FitTodayColor.brandPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, FitTodaySpacing.sm)
                    .background(FitTodayColor.brandPrimary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: FitTodayRadius.md)
                            .stroke(FitTodayColor.brandPrimary.opacity(0.3), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            Button {
                router.push(.libraryExplore, on: .workout)
            } label: {
                Label("Explorar", systemImage: "safari")
                    .font(FitTodayFont.ui(size: 14, weight: .semiBold))
                    .foregroundStyle(FitTodayColor.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, FitTodaySpacing.sm)
                    .background(FitTodayColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: FitTodayRadius.md)
                            .stroke(FitTodayColor.outline.opacity(0.2), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Category Section

    private func categorySection(
        category: ProgramCategory,
        programs: [Program]
    ) -> some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            // Category Header with count
            HStack {
                Text("\(category.displayName) (\(programs.count))")
                    .font(FitTodayFont.ui(size: 13, weight: .semiBold))
                    .foregroundStyle(FitTodayColor.textSecondary)
                    .textCase(.uppercase)
                Spacer()
            }
            .padding(.horizontal, FitTodaySpacing.md)

            // Vertical list of program cards
            LazyVStack(spacing: FitTodaySpacing.sm) {
                ForEach(programs) { program in
                    RoutineListCard(program: program) {
                        router.push(.programDetail(program.id), on: .workout)
                    }
                    .padding(.horizontal, FitTodaySpacing.md)
                }
            }
        }
    }
}

// MARK: - Routine List Card (Hevy-style)

private struct RoutineListCard: View {
    let program: Program
    let onTap: () -> Void

    private var workoutPreviews: [String] {
        // Show the template IDs as workout count hint (no network call needed)
        let count = program.totalWorkouts
        let names = (1...max(1, min(count, 4))).map { "Treino \($0)" }
        return names
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            // Header row: level badge + name
            HStack(spacing: FitTodaySpacing.sm) {
                levelBadge
                Text(program.shortName)
                    .font(FitTodayFont.ui(size: 15, weight: .semiBold))
                    .foregroundStyle(FitTodayColor.textPrimary)
                    .lineLimit(1)
                Spacer()
                Text(program.equipment.displayName)
                    .font(FitTodayFont.ui(size: 11, weight: .medium))
                    .foregroundStyle(FitTodayColor.textTertiary)
            }

            // Workout preview lines
            VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                ForEach(workoutPreviews, id: \.self) { name in
                    HStack(spacing: FitTodaySpacing.xs) {
                        Circle()
                            .fill(FitTodayColor.brandPrimary.opacity(0.5))
                            .frame(width: 5, height: 5)
                        Text(name)
                            .font(FitTodayFont.ui(size: 13, weight: .medium))
                            .foregroundStyle(FitTodayColor.textSecondary)
                            .lineLimit(1)
                    }
                }
                if program.totalWorkouts > 4 {
                    Text("+ \(program.totalWorkouts - 4) treinos")
                        .font(FitTodayFont.ui(size: 12, weight: .medium))
                        .foregroundStyle(FitTodayColor.brandPrimary)
                }
            }

            // CTA Button
            Button(action: onTap) {
                Text("Iniciar Rotina")
                    .font(FitTodayFont.ui(size: 14, weight: .semiBold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, FitTodaySpacing.sm)
                    .background(FitTodayColor.brandPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.sm))
            }
            .buttonStyle(.plain)
        }
        .padding(FitTodaySpacing.md)
        .background(FitTodayColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .stroke(FitTodayColor.outline.opacity(0.15), lineWidth: 1)
        )
    }

    private var levelBadge: some View {
        Text(levelText)
            .font(FitTodayFont.ui(size: 10, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, FitTodaySpacing.sm)
            .padding(.vertical, 3)
            .background(levelColor)
            .clipShape(Capsule())
    }

    private var levelText: String {
        switch program.level {
        case .beginner: return "Iniciante"
        case .intermediate: return "Intermed."
        case .advanced: return "Avançado"
        }
    }

    private var levelColor: Color {
        switch program.level {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }
}

// MARK: - ViewModel

@MainActor
@Observable final class ProgramsListViewModel {
    private(set) var programs: [Program] = []
    private(set) var recommendedPrograms: [Program] = []
    private(set) var isLoading = false
    var errorMessage: String?

    private let repository: ProgramRepository
    private let profileRepository: UserProfileRepository?
    private let historyRepository: WorkoutHistoryRepository?
    private let recommender = ProgramRecommender()

    private var userProfile: UserProfile?

    init(
        repository: ProgramRepository,
        profileRepository: UserProfileRepository? = nil,
        historyRepository: WorkoutHistoryRepository? = nil
    ) {
        self.repository = repository
        self.profileRepository = profileRepository
        self.historyRepository = historyRepository
    }

    // MARK: - Computed Properties

    var beginnerCount: Int {
        programs.filter { $0.level == .beginner }.count
    }

    var intermediateCount: Int {
        programs.filter { $0.level == .intermediate }.count
    }

    var advancedCount: Int {
        programs.filter { $0.level == .advanced }.count
    }

    struct ProgramGroup {
        let category: ProgramCategory
        let programs: [Program]
    }

    var groupedPrograms: [ProgramGroup] {
        let grouped = Dictionary(grouping: programs) { $0.category }

        return ProgramCategory.allCases
            .compactMap { category -> ProgramGroup? in
                guard let programs = grouped[category], !programs.isEmpty else {
                    return nil
                }
                let sortedPrograms = programs.sorted { p1, p2 in
                    let levelOrder: [ProgramLevel: Int] = [.beginner: 0, .intermediate: 1, .advanced: 2]
                    return (levelOrder[p1.level] ?? 0) < (levelOrder[p2.level] ?? 0)
                }
                return ProgramGroup(category: category, programs: sortedPrograms)
            }
            .sorted { $0.category.sortOrder < $1.category.sortOrder }
    }

    /// Categories sorted by relevance to the user's profile goal.
    var sortedGroupedPrograms: [ProgramGroup] {
        guard let goal = userProfile?.mainGoal else {
            return groupedPrograms
        }

        let priorityCategories = Self.categoriesForGoal(goal)

        return groupedPrograms.sorted { a, b in
            let aPriority = priorityCategories.firstIndex(of: a.category) ?? Int.max
            let bPriority = priorityCategories.firstIndex(of: b.category) ?? Int.max
            if aPriority != bPriority {
                return aPriority < bPriority
            }
            return a.category.sortOrder < b.category.sortOrder
        }
    }

    // MARK: - Methods

    func loadPrograms() async {
        isLoading = true
        defer { isLoading = false }

        do {
            programs = try await repository.listPrograms()

            // Load profile and history for recommendations
            userProfile = try? await profileRepository?.loadProfile()
            let history = (try? await historyRepository?.listEntries()) ?? []

            recommendedPrograms = recommender.recommend(
                programs: programs,
                profile: userProfile,
                history: history,
                limit: 6
            )

            #if DEBUG
            print("[ProgramsListViewModel] Loaded \(programs.count) programs, \(recommendedPrograms.count) recommended")
            #endif
        } catch {
            errorMessage = "Não foi possível carregar os programas: \(error.localizedDescription)"
            #if DEBUG
            print("[ProgramsListViewModel] Error: \(error)")
            #endif
        }
    }

    // MARK: - Goal-to-Category Mapping

    private static func categoriesForGoal(_ goal: FitnessGoal) -> [ProgramCategory] {
        switch goal {
        case .hypertrophy:
            return [.pushPullLegs, .upperLower, .fullBody]
        case .conditioning, .performance:
            return [.fullBody, .specialized, .pushPullLegs]
        case .weightLoss:
            return [.fatLoss, .fullBody, .homeWorkout]
        case .endurance:
            return [.fullBody, .homeWorkout, .fatLoss]
        }
    }
}

// MARK: - Preview

#Preview {
    let container = Container()
    container.register(ProgramRepository.self) { _ in BundleProgramRepository() }

    return NavigationStack {
        ProgramsListView()
            .environment(AppRouter())
            .environment(\.dependencyResolver, container)
    }
}
