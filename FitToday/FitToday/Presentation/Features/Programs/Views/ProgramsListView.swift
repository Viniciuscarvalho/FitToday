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
        if let repository = resolver.resolve(ProgramRepository.self) {
            viewModel = ProgramsListViewModel(repository: repository)
        } else {
            dependencyError = NSLocalizedString("error.generic", comment: "Generic error")
        }
    }

    @ViewBuilder
    private func contentView(viewModel: ProgramsListViewModel) -> some View {
        ScrollView {
            VStack(spacing: FitTodaySpacing.lg) {
                // Stats Banner
                statsBanner(viewModel: viewModel)
                    .padding(.horizontal, FitTodaySpacing.md)

                // Grouped Programs
                ForEach(viewModel.groupedPrograms, id: \.category) { group in
                    categorySection(
                        category: group.category,
                        programs: group.programs,
                        viewModel: viewModel
                    )
                }
            }
            .padding(.vertical, FitTodaySpacing.md)
        }
        .scrollIndicators(.hidden)
        .task {
            await viewModel.loadPrograms()
        }
    }

    // MARK: - Stats Banner

    private func statsBanner(viewModel: ProgramsListViewModel) -> some View {
        VStack(spacing: FitTodaySpacing.md) {
            Text("\(viewModel.programs.count) Programas Disponíveis")
                .font(FitTodayFont.ui(size: 18, weight: .bold))
                .foregroundStyle(.white)

            HStack(spacing: FitTodaySpacing.lg) {
                levelStat(count: viewModel.beginnerCount, label: "Iniciante")
                levelStat(count: viewModel.intermediateCount, label: "Intermed.")
                levelStat(count: viewModel.advancedCount, label: "Avançado")
            }
        }
        .padding(FitTodaySpacing.lg)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [FitTodayColor.brandPrimary, FitTodayColor.brandPrimary.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.lg))
    }

    private func levelStat(count: Int, label: String) -> some View {
        VStack(spacing: FitTodaySpacing.xs) {
            Text("\(count)")
                .font(FitTodayFont.ui(size: 24, weight: .bold))
                .foregroundStyle(.white)

            Text(label)
                .font(FitTodayFont.ui(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(width: 70)
        .padding(.vertical, FitTodaySpacing.sm)
        .background(.white.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
    }

    // MARK: - Category Section

    private func categorySection(
        category: ProgramCategory,
        programs: [Program],
        viewModel: ProgramsListViewModel
    ) -> some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            // Category Header
            HStack {
                Text(category.displayName)
                    .font(FitTodayFont.ui(size: 17, weight: .semiBold))
                    .foregroundStyle(FitTodayColor.textPrimary)

                Spacer()

                Text("\(programs.count) variações")
                    .font(FitTodayFont.ui(size: 13, weight: .medium))
                    .foregroundStyle(FitTodayColor.textTertiary)
            }
            .padding(.horizontal, FitTodaySpacing.md)

            // Programs horizontal scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: FitTodaySpacing.sm) {
                    ForEach(programs) { program in
                        Button {
                            router.push(.programDetail(program.id), on: .workout)
                        } label: {
                            CompactProgramCard(program: program)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, FitTodaySpacing.md)
            }
        }
    }
}

// MARK: - Compact Program Card

private struct CompactProgramCard: View {
    let program: Program

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
            // Level Badge
            levelBadge

            // Program Name
            Text(program.shortName)
                .font(FitTodayFont.ui(size: 14, weight: .semiBold))
                .foregroundStyle(FitTodayColor.textPrimary)
                .lineLimit(1)

            // Equipment
            Text(program.equipment.displayName)
                .font(FitTodayFont.ui(size: 12, weight: .medium))
                .foregroundStyle(FitTodayColor.textTertiary)
        }
        .frame(width: 100, alignment: .leading)
        .padding(FitTodaySpacing.sm)
        .background(FitTodayColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .stroke(FitTodayColor.outline.opacity(0.2), lineWidth: 1)
        )
    }

    private var levelBadge: some View {
        Text(levelText)
            .font(FitTodayFont.ui(size: 10, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, FitTodaySpacing.sm)
            .padding(.vertical, 4)
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
    private(set) var isLoading = false
    var errorMessage: String?

    private let repository: ProgramRepository

    init(repository: ProgramRepository) {
        self.repository = repository
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
                // Sort programs within category by level
                let sortedPrograms = programs.sorted { p1, p2 in
                    let levelOrder: [ProgramLevel: Int] = [.beginner: 0, .intermediate: 1, .advanced: 2]
                    return (levelOrder[p1.level] ?? 0) < (levelOrder[p2.level] ?? 0)
                }
                return ProgramGroup(category: category, programs: sortedPrograms)
            }
            .sorted { $0.category.sortOrder < $1.category.sortOrder }
    }

    // MARK: - Methods

    func loadPrograms() async {
        isLoading = true
        defer { isLoading = false }

        do {
            programs = try await repository.listPrograms()
            #if DEBUG
            print("[ProgramsListViewModel] Loaded \(programs.count) programs")
            for category in ProgramCategory.allCases {
                let count = programs.filter { $0.category == category }.count
                if count > 0 {
                    print("  - \(category.displayName): \(count) programs")
                }
            }
            #endif
        } catch {
            errorMessage = "Não foi possível carregar os programas: \(error.localizedDescription)"
            #if DEBUG
            print("[ProgramsListViewModel] Error: \(error)")
            #endif
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
