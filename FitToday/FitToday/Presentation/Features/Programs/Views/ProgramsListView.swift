//
//  ProgramsListView.swift
//  FitToday
//
//  Catalog view of workout programs with search, featured, and category chips.
//

import SwiftUI
import Swinject

struct ProgramsListView: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.dependencyResolver) private var resolver

    @State private var viewModel: ProgramsListViewModel?
    @State private var dependencyError: String?
    @State private var hasInitialized = false
    @State private var gridAppeared = false

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
            VStack(alignment: .leading, spacing: FitTodaySpacing.lg) {
                // Search bar
                searchBar(viewModel: viewModel)

                // Incomplete profile banner
                if viewModel.isProfileIncomplete {
                    IncompleteProfileBanner {
                        router.push(.editProfile, on: .workout)
                    }
                    .padding(.horizontal, FitTodaySpacing.md)
                }

                // Featured program
                if let featured = viewModel.featuredProgram {
                    featuredSection(featured)
                }

                // Category chips
                categoryChips(viewModel: viewModel)

                // Programs grid
                programsGrid(viewModel: viewModel)
            }
            .padding(.vertical, FitTodaySpacing.md)
        }
        .scrollIndicators(.hidden)
        .task {
            await viewModel.loadPrograms()
        }
    }

    // MARK: - Search Bar

    private func searchBar(viewModel: ProgramsListViewModel) -> some View {
        @Bindable var vm = viewModel
        return HStack(spacing: FitTodaySpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(FitTodayColor.textTertiary)
            TextField("programs.search_placeholder".localized, text: $vm.searchText)
                .font(.system(.body))
                .foregroundStyle(FitTodayColor.textPrimary)
        }
        .padding(FitTodaySpacing.sm)
        .background(FitTodayColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
        .padding(.horizontal, FitTodaySpacing.md)
    }

    // MARK: - Featured Section

    private func featuredSection(_ program: Program) -> some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            Text("programs.featured.title".localized)
                .font(.system(.headline, weight: .semibold))
                .foregroundStyle(FitTodayColor.textPrimary)
                .padding(.horizontal, FitTodaySpacing.md)

            Button {
                router.push(.programDetail(program.id), on: .workout)
            } label: {
                ZStack(alignment: .bottomLeading) {
                    if UIImage(named: program.heroImageName) != nil {
                        Image(program.heroImageName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        LinearGradient(
                            colors: gradientColors(for: program.goalTag),
                            startPoint: .topTrailing,
                            endPoint: .bottomLeading
                        )
                    }

                    LinearGradient(
                        colors: [.clear, .black.opacity(0.65)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                        Text(program.durationDescription)
                            .font(.system(.caption, weight: .bold))
                            .padding(.horizontal, FitTodaySpacing.sm)
                            .padding(.vertical, 4)
                            .background(.white.opacity(0.25))
                            .clipShape(Capsule())

                        Text(program.name)
                            .font(.system(.title2, weight: .bold))

                        HStack(spacing: FitTodaySpacing.sm) {
                            Label(program.durationDescription, systemImage: "calendar")
                            Label(program.level.displayName, systemImage: "chart.bar")
                            Label(program.equipment.displayName, systemImage: program.equipment.iconName)
                        }
                        .font(.system(.caption))
                        .opacity(0.85)
                    }
                    .foregroundStyle(.white)
                    .padding(FitTodaySpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.lg))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, FitTodaySpacing.md)
        }
    }

    // MARK: - Category Chips

    private func categoryChips(viewModel: ProgramsListViewModel) -> some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            Text("programs.categories.title".localized)
                .font(.system(.headline, weight: .semibold))
                .foregroundStyle(FitTodayColor.textPrimary)
                .padding(.horizontal, FitTodaySpacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: FitTodaySpacing.sm) {
                    chipButton(
                        title: "programs.category.all".localized,
                        icon: "square.grid.2x2",
                        isSelected: viewModel.selectedGoalTag == nil
                    ) {
                        viewModel.selectedGoalTag = nil
                    }

                    ForEach(ProgramGoalTag.allCases, id: \.self) { tag in
                        chipButton(
                            title: tag.displayName,
                            icon: tag.iconName,
                            isSelected: viewModel.selectedGoalTag == tag
                        ) {
                            viewModel.selectedGoalTag = tag
                        }
                    }
                }
                .padding(.horizontal, FitTodaySpacing.md)
            }
        }
    }

    private func chipButton(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: FitTodaySpacing.xs) {
                Image(systemName: icon)
                    .font(.system(.caption2))
                Text(title)
                    .font(.system(.caption, weight: .medium))
            }
            .padding(.horizontal, FitTodaySpacing.sm)
            .padding(.vertical, FitTodaySpacing.xs)
            .background(isSelected ? FitTodayColor.brandPrimary : FitTodayColor.surface)
            .foregroundStyle(isSelected ? .white : FitTodayColor.textSecondary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Programs Grid

    private func programsGrid(viewModel: ProgramsListViewModel) -> some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            Text("programs.recommended.title".localized)
                .font(.system(.headline, weight: .semibold))
                .foregroundStyle(FitTodayColor.textPrimary)
                .padding(.horizontal, FitTodaySpacing.md)

            if viewModel.filteredPrograms.isEmpty && !viewModel.isLoading {
                Text("programs.empty.title".localized)
                    .font(.system(.subheadline))
                    .foregroundStyle(FitTodayColor.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else if viewModel.isLoading {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: FitTodaySpacing.md) {
                        ForEach(0..<4, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                                .fill(FitTodayColor.surface)
                                .frame(width: 170, height: 180)
                                .shimmer()
                        }
                    }
                    .padding(.horizontal, FitTodaySpacing.md)
                }
                .frame(height: 200)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: FitTodaySpacing.md) {
                        ForEach(Array(viewModel.filteredPrograms.enumerated()), id: \.element.id) { index, program in
                            ProgramCard(
                                program: program,
                                isRecommended: viewModel.recommendedProgramIds.contains(program.id)
                            ) {
                                router.push(.programDetail(program.id), on: .workout)
                            }
                            .opacity(gridAppeared ? 1 : 0)
                            .offset(x: gridAppeared ? 0 : 30)
                            .animation(
                                .easeOut(duration: 0.35).delay(Double(index) * 0.06),
                                value: gridAppeared
                            )
                        }
                    }
                    .padding(.horizontal, FitTodaySpacing.md)
                }
                .frame(height: 200)
                .onAppear {
                    gridAppeared = false
                    withAnimation { gridAppeared = true }
                }
            }
        }
    }

    private func gradientColors(for goalTag: ProgramGoalTag) -> [Color] {
        switch goalTag {
        case .strength: return [.blue, .purple]
        case .conditioning: return [.orange, .red]
        case .hypertrophy: return [.green, .teal]
        case .wellness: return [.cyan, .mint]
        case .endurance: return [.indigo, .blue]
        }
    }
}

// MARK: - Program Card

private struct ProgramCard: View {
    let program: Program
    var isRecommended: Bool = false
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
                ZStack(alignment: .topTrailing) {
                    if UIImage(named: program.heroImageName) != nil {
                        Image(program.heroImageName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 100)
                            .clipped()
                    } else {
                        LinearGradient(
                            colors: gradientColors(for: program.goalTag),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(height: 100)
                    }

                    Text(program.durationDescription)
                        .font(.system(.caption2, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.black.opacity(0.4))
                        .clipShape(Capsule())
                        .foregroundStyle(.white)
                        .padding(FitTodaySpacing.sm)
                }

                VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                    if isRecommended {
                        Text("programs.for_you".localized)
                            .font(.system(.caption2, weight: .semibold))
                            .foregroundStyle(FitTodayColor.brandPrimary)
                            .padding(.horizontal, FitTodaySpacing.xs)
                            .padding(.vertical, 2)
                            .background(FitTodayColor.brandPrimary.opacity(0.15))
                            .clipShape(Capsule())
                    }

                    Text(program.shortName)
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(FitTodayColor.textPrimary)
                        .lineLimit(2)

                    HStack(spacing: FitTodaySpacing.xs) {
                        Text(program.level.displayName)
                        Text("·")
                        Text(program.equipment.displayName)
                    }
                    .font(.system(.caption2))
                    .foregroundStyle(FitTodayColor.textSecondary)
                    .lineLimit(1)
                }
                .padding(.horizontal, FitTodaySpacing.sm)
                .padding(.bottom, FitTodaySpacing.sm)
            }
            .frame(width: 170)
            .background(FitTodayColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
        }
        .buttonStyle(.plain)
    }

    private func gradientColors(for goalTag: ProgramGoalTag) -> [Color] {
        switch goalTag {
        case .strength: return [.blue, .purple]
        case .conditioning: return [.orange, .red]
        case .hypertrophy: return [.green, .teal]
        case .wellness: return [.cyan, .mint]
        case .endurance: return [.indigo, .blue]
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
    var searchText: String = ""
    var selectedGoalTag: ProgramGoalTag?

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

    var featuredProgram: Program? {
        recommendedPrograms.first
    }

    var isProfileIncomplete: Bool {
        userProfile?.isProfileComplete == false
    }

    var recommendedProgramIds: Set<String> {
        Set(recommendedPrograms.map { $0.id })
    }

    var filteredPrograms: [Program] {
        var result = programs

        if let tag = selectedGoalTag {
            result = result.filter { $0.goalTag == tag }
        }

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(query) ||
                $0.subtitle.lowercased().contains(query)
            }
        }

        return result
    }

    func loadPrograms() async {
        isLoading = true
        defer { isLoading = false }

        do {
            programs = try await repository.listPrograms()

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
            errorMessage = error.localizedDescription
            #if DEBUG
            print("[ProgramsListViewModel] Error: \(error)")
            #endif
        }
    }
}

// MARK: - Incomplete Profile Banner

struct IncompleteProfileBanner: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: FitTodaySpacing.sm) {
                Image(systemName: "person.crop.circle.badge.exclamationmark")
                    .foregroundStyle(FitTodayColor.brandAccent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("programs.incomplete_profile.title".localized)
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(FitTodayColor.textPrimary)
                    Text("programs.incomplete_profile.subtitle".localized)
                        .font(.system(.caption))
                        .foregroundStyle(FitTodayColor.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(FitTodayColor.textTertiary)
                    .font(.system(size: 12))
            }
            .padding(FitTodaySpacing.md)
            .background(FitTodayColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: FitTodayRadius.md)
                    .strokeBorder(FitTodayColor.brandAccent.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
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
