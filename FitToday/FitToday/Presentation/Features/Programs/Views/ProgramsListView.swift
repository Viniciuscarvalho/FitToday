//
//  ProgramsListView.swift
//  FitToday
//
//  Grid view of pre-made workout programs.
//

import SwiftUI
import Swinject

/// View displaying the catalog of workout programs.
struct ProgramsListView: View {
    let resolver: Resolver

    @Environment(AppRouter.self) private var router

    @State private var programs: [Program] = []
    @State private var isLoading = true
    @State private var selectedGoal: ProgramGoalTag?
    @State private var selectedLevel: ProgramLevel?
    @State private var searchText = ""

    private var filteredPrograms: [Program] {
        programs.filter { program in
            // Search filter
            let matchesSearch = searchText.isEmpty ||
                program.name.localizedStandardContains(searchText) ||
                program.subtitle.localizedStandardContains(searchText)

            // Goal filter
            let matchesGoal = selectedGoal == nil || program.goalTag == selectedGoal

            // Level filter
            let matchesLevel = selectedLevel == nil || program.level == selectedLevel

            return matchesSearch && matchesGoal && matchesLevel
        }
    }

    private let columns = [
        GridItem(.flexible(), spacing: FitTodaySpacing.md),
        GridItem(.flexible(), spacing: FitTodaySpacing.md)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Filters
            filtersSection
                .padding(.horizontal, FitTodaySpacing.md)
                .padding(.vertical, FitTodaySpacing.sm)

            // Content
            if isLoading {
                loadingView
            } else if filteredPrograms.isEmpty {
                emptyView
            } else {
                programsGrid
            }
        }
        .task {
            await loadPrograms()
        }
    }

    // MARK: - Filters Section

    private var filtersSection: some View {
        VStack(spacing: FitTodaySpacing.sm) {
            // Search bar (only if many programs)
            if programs.count > 6 {
                searchBar
            }

            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: FitTodaySpacing.sm) {
                    // Goal filters
                    ForEach(ProgramGoalTag.allCases, id: \.self) { goal in
                        filterChip(
                            title: goal.displayName,
                            icon: goal.iconName,
                            isSelected: selectedGoal == goal
                        ) {
                            selectedGoal = selectedGoal == goal ? nil : goal
                        }
                    }

                    Divider()
                        .frame(height: 20)
                        .background(FitTodayColor.outline)

                    // Level filters
                    ForEach(ProgramLevel.allCases, id: \.self) { level in
                        filterChip(
                            title: level.displayName,
                            isSelected: selectedLevel == level
                        ) {
                            selectedLevel = selectedLevel == level ? nil : level
                        }
                    }
                }
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: FitTodaySpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundStyle(FitTodayColor.textTertiary)

            TextField("Buscar programas...", text: $searchText)
                .font(FitTodayFont.ui(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.textPrimary)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(FitTodayColor.textTertiary)
                }
            }
        }
        .padding(FitTodaySpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.sm)
                .fill(FitTodayColor.surface)
        )
    }

    private func filterChip(
        title: String,
        icon: String? = nil,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: FitTodaySpacing.xs) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                }
                Text(title)
                    .font(FitTodayFont.ui(size: 13, weight: isSelected ? .bold : .medium))
            }
            .foregroundStyle(isSelected ? FitTodayColor.textPrimary : FitTodayColor.textSecondary)
            .padding(.horizontal, FitTodaySpacing.sm)
            .padding(.vertical, FitTodaySpacing.xs)
            .background(
                Capsule()
                    .fill(isSelected ? FitTodayColor.brandPrimary.opacity(0.2) : FitTodayColor.surface)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? FitTodayColor.brandPrimary : FitTodayColor.outline, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: FitTodaySpacing.md) {
            ProgressView()
                .tint(FitTodayColor.brandPrimary)
            Text("Carregando programas...")
                .font(FitTodayFont.ui(size: 15, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty View

    private var emptyView: some View {
        VStack(spacing: FitTodaySpacing.md) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(FitTodayColor.textTertiary)

            Text("Nenhum programa encontrado")
                .font(FitTodayFont.ui(size: 17, weight: .semiBold))
                .foregroundStyle(FitTodayColor.textPrimary)

            Text("Tente ajustar os filtros para ver mais opções")
                .font(FitTodayFont.ui(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
                .multilineTextAlignment(.center)

            if selectedGoal != nil || selectedLevel != nil {
                Button("Limpar filtros") {
                    selectedGoal = nil
                    selectedLevel = nil
                }
                .fitSecondaryStyle()
                .frame(width: 140)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Programs Grid

    private var programsGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: FitTodaySpacing.md) {
                ForEach(filteredPrograms) { program in
                    Button {
                        router.push(.programDetail(program.id), on: .workout)
                    } label: {
                        ProgramCard(program: program)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(FitTodaySpacing.md)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Data Loading

    private func loadPrograms() async {
        // Simulate loading
        try? await Task.sleep(for: .milliseconds(500))

        // TODO: Load from catalog
        programs = ProgramsCatalog.allPrograms
        isLoading = false
    }
}

// MARK: - Program Card

struct ProgramCard: View {
    let program: Program

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            // Hero image/gradient
            ZStack(alignment: .bottomLeading) {
                // Background gradient based on goal
                gradientForGoal(program.goalTag)
                    .frame(height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.sm))

                // Goal icon
                Image(systemName: program.goalTag.iconName)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.3))
                    .padding(FitTodaySpacing.sm)
            }

            // Content
            VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                Text(program.name)
                    .font(FitTodayFont.ui(size: 15, weight: .bold))
                    .foregroundStyle(FitTodayColor.textPrimary)
                    .lineLimit(2)

                Text(program.subtitle)
                    .font(FitTodayFont.ui(size: 12, weight: .medium))
                    .foregroundStyle(FitTodayColor.textSecondary)
                    .lineLimit(1)

                // Tags
                HStack(spacing: FitTodaySpacing.xs) {
                    FitBadge(text: program.level.displayName, style: levelStyle(program.level))

                    Spacer()

                    Text(program.sessionsDescription)
                        .font(FitTodayFont.ui(size: 11, weight: .medium))
                        .foregroundStyle(FitTodayColor.textTertiary)
                }
            }
            .padding(.horizontal, FitTodaySpacing.sm)
            .padding(.bottom, FitTodaySpacing.sm)
        }
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .fill(FitTodayColor.surface)
        )
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

    private func levelStyle(_ level: ProgramLevel) -> FitBadge.Style {
        switch level {
        case .beginner:
            return .success
        case .intermediate:
            return .warning
        case .advanced:
            return .error
        }
    }
}

// MARK: - Programs Catalog (Mock Data)

enum ProgramsCatalog {
    static let allPrograms: [Program] = [
        Program(
            id: "ppl-beginner",
            name: "Push Pull Legs",
            subtitle: "Divisão clássica para iniciantes",
            goalTag: .strength,
            level: .beginner,
            durationWeeks: 8,
            heroImageName: "ppl",
            workoutTemplateIds: ["push-1", "pull-1", "legs-1"],
            estimatedMinutesPerSession: 45,
            sessionsPerWeek: 3
        ),
        Program(
            id: "full-body-3x",
            name: "Full Body 3x",
            subtitle: "Treino completo 3x por semana",
            goalTag: .strength,
            level: .beginner,
            durationWeeks: 6,
            heroImageName: "fullbody",
            workoutTemplateIds: ["fb-a", "fb-b", "fb-c"],
            estimatedMinutesPerSession: 50,
            sessionsPerWeek: 3
        ),
        Program(
            id: "hiit-fat-burn",
            name: "HIIT Fat Burn",
            subtitle: "Queima de gordura intensa",
            goalTag: .conditioning,
            level: .intermediate,
            durationWeeks: 4,
            heroImageName: "hiit",
            workoutTemplateIds: ["hiit-1", "hiit-2"],
            estimatedMinutesPerSession: 30,
            sessionsPerWeek: 4
        ),
        Program(
            id: "cardio-runner",
            name: "Cardio Runner",
            subtitle: "Melhore seu cardio e resistência",
            goalTag: .aerobic,
            level: .beginner,
            durationWeeks: 6,
            heroImageName: "cardio",
            workoutTemplateIds: ["run-1", "run-2", "run-3"],
            estimatedMinutesPerSession: 35,
            sessionsPerWeek: 3
        ),
        Program(
            id: "core-strength",
            name: "Core Strength",
            subtitle: "Fortaleça o abdômen e core",
            goalTag: .core,
            level: .beginner,
            durationWeeks: 4,
            heroImageName: "core",
            workoutTemplateIds: ["core-1", "core-2"],
            estimatedMinutesPerSession: 20,
            sessionsPerWeek: 3
        ),
        Program(
            id: "endurance-builder",
            name: "Endurance Builder",
            subtitle: "Aumente sua resistência muscular",
            goalTag: .endurance,
            level: .intermediate,
            durationWeeks: 8,
            heroImageName: "endurance",
            workoutTemplateIds: ["end-1", "end-2", "end-3"],
            estimatedMinutesPerSession: 40,
            sessionsPerWeek: 4
        )
    ]
}

// MARK: - Preview

#Preview {
    let container = Container()
    return NavigationStack {
        ProgramsListView(resolver: container)
    }
    .preferredColorScheme(.dark)
}
