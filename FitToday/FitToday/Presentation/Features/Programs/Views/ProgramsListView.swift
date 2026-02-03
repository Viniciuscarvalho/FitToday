//
//  ProgramsListView.swift
//  FitToday
//
//  Grid view of pre-made workout programs with filters.
//

import SwiftUI
import Swinject

/// View displaying the catalog of workout programs.
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
        VStack(spacing: 0) {
            // Filters
            filtersSection(viewModel: viewModel)
                .padding(.horizontal, FitTodaySpacing.md)
                .padding(.vertical, FitTodaySpacing.sm)

            // Content
            if viewModel.isLoading {
                loadingView
            } else if viewModel.filteredPrograms.isEmpty {
                emptyView(viewModel: viewModel)
            } else {
                programsScrollView(viewModel: viewModel)
            }
        }
        .task {
            await viewModel.loadPrograms()
        }
    }

    // MARK: - Filters Section

    private func filtersSection(viewModel: ProgramsListViewModel) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: FitTodaySpacing.sm) {
                // Level Filter
                FilterDropdown(
                    title: "programs.filter.level".localized,
                    selection: Binding(
                        get: { viewModel.selectedLevel?.displayName },
                        set: { newValue in
                            if let newValue {
                                viewModel.selectedLevel = ProgramLevel.allCases.first { $0.displayName == newValue }
                            } else {
                                viewModel.selectedLevel = nil
                            }
                        }
                    ),
                    options: ProgramLevel.allCases.map { $0.displayName },
                    allLabel: "programs.filter.all".localized
                )

                // Goal Filter
                FilterDropdown(
                    title: "programs.filter.goal".localized,
                    selection: Binding(
                        get: { viewModel.selectedGoal?.displayName },
                        set: { newValue in
                            if let newValue {
                                viewModel.selectedGoal = ProgramGoalTag.allCases.first { $0.displayName == newValue }
                            } else {
                                viewModel.selectedGoal = nil
                            }
                        }
                    ),
                    options: ProgramGoalTag.allCases.map { $0.displayName },
                    allLabel: "programs.filter.all".localized
                )

                // Equipment Filter
                FilterDropdown(
                    title: "programs.filter.equipment".localized,
                    selection: Binding(
                        get: { viewModel.selectedEquipment?.displayName },
                        set: { newValue in
                            if let newValue {
                                viewModel.selectedEquipment = ProgramEquipment.allCases.first { $0.displayName == newValue }
                            } else {
                                viewModel.selectedEquipment = nil
                            }
                        }
                    ),
                    options: ProgramEquipment.allCases.map { $0.displayName },
                    allLabel: "programs.filter.all".localized
                )
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: FitTodaySpacing.md) {
            ProgressView()
                .tint(FitTodayColor.brandPrimary)
            Text("programs.loading".localized)
                .font(FitTodayFont.ui(size: 15, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty View

    private func emptyView(viewModel: ProgramsListViewModel) -> some View {
        VStack(spacing: FitTodaySpacing.md) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(FitTodayColor.textTertiary)

            Text("programs.empty.title".localized)
                .font(FitTodayFont.ui(size: 17, weight: .semiBold))
                .foregroundStyle(FitTodayColor.textPrimary)

            Text("programs.empty.message".localized)
                .font(FitTodayFont.ui(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
                .multilineTextAlignment(.center)

            if viewModel.hasActiveFilters {
                Button("programs.empty.clear_filters".localized) {
                    viewModel.clearFilters()
                }
                .fitSecondaryStyle()
                .frame(width: 160)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Programs Scroll View

    private func programsScrollView(viewModel: ProgramsListViewModel) -> some View {
        ScrollView {
            LazyVStack(spacing: FitTodaySpacing.md) {
                ForEach(viewModel.filteredPrograms) { program in
                    Button {
                        #if DEBUG
                        print("[ProgramsListView] 👆 Tapped program: '\(program.id)' - '\(program.name)'")
                        #endif
                        router.push(.programDetail(program.id), on: .workout)
                    } label: {
                        ProgramListCard(program: program)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(FitTodaySpacing.md)
        }
        .scrollIndicators(.hidden)
    }
}

// MARK: - Filter Dropdown

struct FilterDropdown: View {
    let title: String
    @Binding var selection: String?
    let options: [String]
    var allLabel: String = "Todos"

    var body: some View {
        Menu {
            Button(allLabel) {
                selection = nil
            }

            ForEach(options, id: \.self) { option in
                Button(option) {
                    selection = option
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(selection ?? title)
                    .font(FitTodayFont.ui(size: 13, weight: selection != nil ? .bold : .medium))
                    .foregroundStyle(selection != nil ? FitTodayColor.brandPrimary : FitTodayColor.textSecondary)

                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(selection != nil ? FitTodayColor.brandPrimary : FitTodayColor.textTertiary)
            }
            .padding(.horizontal, FitTodaySpacing.sm)
            .padding(.vertical, FitTodaySpacing.xs)
            .background(
                Capsule()
                    .fill(selection != nil ? FitTodayColor.brandPrimary.opacity(0.15) : FitTodayColor.surface)
            )
            .overlay(
                Capsule()
                    .stroke(selection != nil ? FitTodayColor.brandPrimary : FitTodayColor.outline, lineWidth: 1)
            )
        }
    }
}

// MARK: - Program List Card

struct ProgramListCard: View {
    let program: Program

    private var durationText: String {
        String(format: NSLocalizedString("programs.card.days", comment: "Days duration"), program.durationWeeks * 7)
    }

    private var sessionsText: String {
        let daysPerWeek = String(format: NSLocalizedString("programs.card.days_per_week", comment: "Days per week"), program.sessionsPerWeek)
        let exercises = String(format: NSLocalizedString("programs.card.exercises", comment: "Exercises count"), program.totalWorkouts)
        return "\(daysPerWeek) • \(exercises)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Hero image section
            ZStack(alignment: .topLeading) {
                // Background gradient based on goal
                gradientForGoal(program.goalTag)
                    .frame(height: 120)

                // Duration badge
                HStack(spacing: 4) {
                    Text(durationText)
                        .font(FitTodayFont.ui(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.black.opacity(0.3))
                .clipShape(Capsule())
                .padding(FitTodaySpacing.sm)
            }
            .clipShape(
                .rect(
                    topLeadingRadius: FitTodayRadius.md,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: FitTodayRadius.md
                )
            )

            // Content section
            VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                Text(program.name)
                    .font(FitTodayFont.ui(size: 17, weight: .bold))
                    .foregroundStyle(FitTodayColor.textPrimary)
                    .lineLimit(1)

                // Tags row
                HStack(spacing: FitTodaySpacing.xs) {
                    Text(program.level.displayName)
                        .font(FitTodayFont.ui(size: 12, weight: .medium))
                        .foregroundStyle(FitTodayColor.textSecondary)

                    Text("•")
                        .foregroundStyle(FitTodayColor.textTertiary)

                    Text(program.goalTag.displayName)
                        .font(FitTodayFont.ui(size: 12, weight: .medium))
                        .foregroundStyle(FitTodayColor.textSecondary)

                    Text("•")
                        .foregroundStyle(FitTodayColor.textTertiary)

                    Text(program.equipment.displayName)
                        .font(FitTodayFont.ui(size: 12, weight: .medium))
                        .foregroundStyle(FitTodayColor.textSecondary)
                }

                // Sessions info
                Text(sessionsText)
                    .font(FitTodayFont.ui(size: 11, weight: .medium))
                    .foregroundStyle(FitTodayColor.textTertiary)
            }
            .padding(FitTodaySpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(FitTodayColor.surface)
        }
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .stroke(FitTodayColor.outline.opacity(0.3), lineWidth: 1)
        )
    }

    private func gradientForGoal(_ goal: ProgramGoalTag) -> LinearGradient {
        switch goal {
        case .strength:
            return FitTodayColor.gradientStrength
        case .conditioning:
            return FitTodayColor.gradientConditioning
        case .aerobic:
            return FitTodayColor.gradientAerobic
        case .core:
            return FitTodayColor.gradientWellness
        case .endurance:
            return FitTodayColor.gradientEndurance
        }
    }
}

// MARK: - ViewModel

@MainActor
@Observable final class ProgramsListViewModel {
    private(set) var programs: [Program] = []
    private(set) var isLoading = false
    var errorMessage: String?

    var selectedLevel: ProgramLevel?
    var selectedGoal: ProgramGoalTag?
    var selectedEquipment: ProgramEquipment?

    private let repository: ProgramRepository

    init(repository: ProgramRepository) {
        self.repository = repository
    }

    var filteredPrograms: [Program] {
        programs.filter { program in
            let matchesLevel = selectedLevel == nil || program.level == selectedLevel
            let matchesGoal = selectedGoal == nil || program.goalTag == selectedGoal
            let matchesEquipment = selectedEquipment == nil || program.equipment == selectedEquipment
            return matchesLevel && matchesGoal && matchesEquipment
        }
    }

    var hasActiveFilters: Bool {
        selectedLevel != nil || selectedGoal != nil || selectedEquipment != nil
    }

    func loadPrograms() async {
        isLoading = true
        defer { isLoading = false }

        do {
            programs = try await repository.listPrograms()
            #if DEBUG
            print("[ProgramsListViewModel] ✅ Loaded \(programs.count) programs")
            #endif
        } catch {
            errorMessage = "Não foi possível carregar os programas: \(error.localizedDescription)"
            #if DEBUG
            print("[ProgramsListViewModel] ❌ Error loading programs: \(error)")
            #endif
        }
    }

    func clearFilters() {
        selectedLevel = nil
        selectedGoal = nil
        selectedEquipment = nil
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
    .preferredColorScheme(.dark)
}
