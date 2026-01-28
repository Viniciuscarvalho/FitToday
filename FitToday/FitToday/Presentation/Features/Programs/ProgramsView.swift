//
//  ProgramsView.swift
//  FitToday
//
//  Redesigned on 23/01/26 - Category-based program discovery
//  5 Categories: Strength, Conditioning, Aerobic, Endurance, Wellness
//

import SwiftUI
import Swinject

// MARK: - Program Category

enum ProgramCategory: String, CaseIterable, Identifiable {
    case all
    case strength
    case conditioning
    case aerobic
    case endurance
    case wellness

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all: return "programs.category.all".localized
        case .strength: return "programs.category.strength".localized
        case .conditioning: return "programs.category.conditioning".localized
        case .aerobic: return "programs.category.aerobic".localized
        case .endurance: return "programs.category.endurance".localized
        case .wellness: return "programs.category.wellness".localized
        }
    }

    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .strength: return "dumbbell.fill"
        case .conditioning: return "flame.fill"
        case .aerobic: return "heart.fill"
        case .endurance: return "figure.run"
        case .wellness: return "leaf.fill"
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .all: return FitTodayColor.gradientPrimary
        case .strength: return FitTodayColor.gradientStrength
        case .conditioning: return FitTodayColor.gradientConditioning
        case .aerobic: return FitTodayColor.gradientAerobic
        case .endurance: return FitTodayColor.gradientEndurance
        case .wellness: return FitTodayColor.gradientWellness
        }
    }

    var accentColor: Color {
        switch self {
        case .all: return FitTodayColor.brandPrimary
        case .strength: return Color(hex: "#7C3AED")
        case .conditioning: return Color(hex: "#F97316")
        case .aerobic: return Color(hex: "#EC4899")
        case .endurance: return Color(hex: "#3B82F6")
        case .wellness: return Color(hex: "#22C55E")
        }
    }
}

struct ProgramsView: View {
    @Environment(\.dependencyResolver) private var resolver
    @Environment(AppRouter.self) private var router
    @State private var viewModel: ProgramsViewModel?
    @State private var dependencyError: String?
    @State private var selectedCategory: ProgramCategory = .all

    init(resolver: Resolver) {
        if let repository = resolver.resolve(ProgramRepository.self) {
            _viewModel = State(initialValue: ProgramsViewModel(repository: repository))
            _dependencyError = State(initialValue: nil)
        } else {
            _viewModel = State(initialValue: nil)
            _dependencyError = State(initialValue: "Erro de configuração: repositório de programas não está registrado.")
        }
    }

    var body: some View {
        Group {
            if let error = dependencyError {
                DependencyErrorView(message: error)
            } else if let viewModel = viewModel {
                contentView(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .background(FitTodayColor.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private func contentView(viewModel: ProgramsViewModel) -> some View {
        ScrollView {
            VStack(spacing: FitTodaySpacing.lg) {
                headerSection
                categorySelector
                programsContent(viewModel: viewModel)
            }
            .padding(.bottom, FitTodaySpacing.xxl)
        }
        .task {
            await viewModel.loadPrograms()
        }
        .refreshable {
            await viewModel.loadPrograms()
        }
        .alert("Ops!", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Button("Ok", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Algo inesperado aconteceu.")
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("programs.title".localized)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)
            Text("programs.subtitle".localized)
                .font(.system(size: 14))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.top, FitTodaySpacing.md)
    }

    // MARK: - Category Selector

    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(ProgramCategory.allCases) { category in
                    CategoryPill(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Programs Content

    @ViewBuilder
    private func programsContent(viewModel: ProgramsViewModel) -> some View {
        if viewModel.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 200)
        } else if filteredPrograms(viewModel.programs).isEmpty {
            EmptyStateView(
                title: "programs.empty.title".localized,
                message: "programs.empty.message".localized,
                systemIcon: "rectangle.stack"
            )
            .padding(.vertical, FitTodaySpacing.xl)
        } else {
            VStack(spacing: FitTodaySpacing.md) {
                ForEach(filteredPrograms(viewModel.programs), id: \.id) { program in
                    let programId = program.id
                    ProgramCategoryCard(
                        program: program,
                        category: categoryForProgram(program)
                    ) {
                        router.push(.programDetail(programId), on: .programs)
                    }
                    .id(programId)
                }
            }
            .padding(.horizontal)
        }
    }

    private func filteredPrograms(_ programs: [Program]) -> [Program] {
        guard selectedCategory != .all else { return programs }
        return programs.filter { categoryForProgram($0) == selectedCategory }
    }

    private func categoryForProgram(_ program: Program) -> ProgramCategory {
        // Map program goal to category
        switch program.goalTag {
        case .strength:
            return .strength
        case .conditioning:
            return .conditioning
        case .aerobic:
            return .aerobic
        case .core:
            return .wellness
        case .endurance:
            return .endurance
        }
    }
}

// MARK: - Category Pill

struct CategoryPill: View {
    let category: ProgramCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(category.displayName)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(isSelected ? .white : FitTodayColor.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Group {
                    if isSelected {
                        category.gradient
                    } else {
                        FitTodayColor.surface
                    }
                }
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Program Category Card

struct ProgramCategoryCard: View {
    let program: Program
    let category: ProgramCategory
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Image Section
                ZStack(alignment: .topLeading) {
                    Image(program.heroImageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 160)
                        .clipped()

                    // Gradient overlay
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.3)],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    // Category badge
                    HStack(spacing: 4) {
                        Image(systemName: category.icon)
                            .font(.system(size: 10, weight: .bold))
                        Text(category.displayName)
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(category.accentColor)
                    .clipShape(Capsule())
                    .padding(12)
                }

                // Content Section
                VStack(alignment: .leading, spacing: 8) {
                    Text(program.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(FitTodayColor.textPrimary)
                        .lineLimit(1)

                    Text(program.subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(FitTodayColor.textSecondary)
                        .lineLimit(2)

                    // Stats row
                    HStack(spacing: 16) {
                        statItem(icon: "calendar", value: program.durationDescription)
                        statItem(icon: "flame", value: program.sessionsDescription)
                        statItem(icon: "clock", value: "\(program.estimatedMinutesPerSession) min")
                    }
                    .padding(.top, 4)

                    // Start button
                    HStack {
                        Spacer()
                        Text("programs.card.start".localized)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .background(category.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.top, 8)
                }
                .padding(16)
                .background(FitTodayColor.surface)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .contentShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(FitTodayColor.outline.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func statItem(icon: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(FitTodayColor.textTertiary)
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
    }
}

// MARK: - ViewModel

@MainActor
@Observable final class ProgramsViewModel {
    private(set) var programs: [Program] = []
    private(set) var isLoading = false
    var errorMessage: String?

    private let repository: ProgramRepository

    init(repository: ProgramRepository) {
        self.repository = repository
    }

    func loadPrograms() async {
        isLoading = true
        defer { isLoading = false }

        do {
            programs = try await repository.listPrograms()
        } catch {
            errorMessage = "Não foi possível carregar os programas: \(error.localizedDescription)"
        }
    }
}

#Preview {
    let container = Container()
    NavigationStack {
        ProgramsView(resolver: container)
            .environment(AppRouter())
    }
}
