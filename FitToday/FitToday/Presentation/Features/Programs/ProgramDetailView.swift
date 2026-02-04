//
//  ProgramDetailView.swift
//  FitToday
//
//  Tela de detalhe de um programa, listando os treinos com exercícios da API Wger.
//

import SwiftUI
import Swinject

struct ProgramDetailView: View {
    let programId: String

    @Environment(\.dependencyResolver) private var resolver
    @Environment(AppRouter.self) private var router
    @State private var viewModel: ProgramDetailViewModel?
    @State private var dependencyError: String?
    @State private var isSaved = false
    @State private var canSave = true
    @State private var isSaving = false
    @State private var showSaveError: String?
    @State private var showSaveSuccess = false

    init(programId: String, resolver: Resolver) {
        self.programId = programId

        #if DEBUG
        print("[ProgramDetailView] 🏗️ Init with programId: '\(programId)'")
        #endif

        let programRepo = resolver.resolve(ProgramRepository.self)
        let loadWorkoutsUseCase = resolver.resolve(LoadProgramWorkoutsUseCase.self)

        #if DEBUG
        print("[ProgramDetailView] 📦 ProgramRepository resolved: \(programRepo != nil)")
        print("[ProgramDetailView] 📦 LoadProgramWorkoutsUseCase resolved: \(loadWorkoutsUseCase != nil)")
        #endif

        if let programRepo, let loadWorkoutsUseCase {
            _viewModel = State(initialValue: ProgramDetailViewModel(
                programId: programId,
                programRepository: programRepo,
                loadProgramWorkoutsUseCase: loadWorkoutsUseCase
            ))
            _dependencyError = State(initialValue: nil)
            #if DEBUG
            print("[ProgramDetailView] ✅ ViewModel created successfully")
            #endif
        } else {
            _viewModel = State(initialValue: nil)
            _dependencyError = State(initialValue: "Erro de configuração: repositórios não estão registrados.")
            #if DEBUG
            print("[ProgramDetailView] ❌ Failed to create ViewModel - missing repositories")
            #endif
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
        .navigationTitle(viewModel?.program?.name ?? "Programa")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                saveButton
            }
        }
        .task {
            await checkSavedStatus()
        }
        .alert("Rotina Salva!", isPresented: $showSaveSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("O programa foi adicionado às suas rotinas.")
        }
        .alert("Erro", isPresented: .init(
            get: { showSaveError != nil },
            set: { if !$0 { showSaveError = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            if let error = showSaveError {
                Text(error)
            }
        }
    }

    // MARK: - Save Button

    @ViewBuilder
    private var saveButton: some View {
        if let program = viewModel?.program {
            Button {
                Task {
                    await saveRoutine(program)
                }
            } label: {
                if isSaving {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                        .font(.system(.body, weight: .semibold))
                }
            }
            .disabled(isSaved || !canSave || isSaving)
            .foregroundStyle(isSaved ? FitTodayColor.brandPrimary : .white)
        }
    }

    // MARK: - Save Actions

    private func checkSavedStatus() async {
        guard let routineRepo = resolver.resolve(SavedRoutineRepository.self) else { return }

        isSaved = await routineRepo.isRoutineSaved(programId: programId)
        canSave = await routineRepo.canSaveMore()
    }

    private func saveRoutine(_ program: Program) async {
        guard let routineRepo = resolver.resolve(SavedRoutineRepository.self) else {
            showSaveError = "Erro de configuração"
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            let routine = SavedRoutine(from: program)
            try await routineRepo.saveRoutine(routine)
            isSaved = true
            showSaveSuccess = true

            #if DEBUG
            print("[ProgramDetail] ✅ Routine saved: \(program.name)")
            #endif
        } catch let error as SavedRoutineError {
            showSaveError = error.localizedDescription
        } catch {
            showSaveError = error.localizedDescription
        }
    }

    @ViewBuilder
    private func contentView(viewModel: ProgramDetailViewModel) -> some View {
        ScrollView {
            VStack(spacing: FitTodaySpacing.lg) {
                if let program = viewModel.program {
                    heroSection(program)
                    workoutsSection(viewModel: viewModel)
                } else if viewModel.isLoading {
                    loadingView
                } else {
                    programNotFoundView
                }
            }
        }
        .task {
            await viewModel.load()
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: FitTodaySpacing.md) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(FitTodayColor.brandPrimary)
            Text("Carregando programa...")
                .font(.system(.subheadline))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }

    // MARK: - Program Not Found View

    private var programNotFoundView: some View {
        VStack(spacing: FitTodaySpacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(.largeTitle))
                .foregroundStyle(FitTodayColor.warning)
            Text("Programa não encontrado")
                .font(.system(.headline))
                .foregroundStyle(FitTodayColor.textPrimary)
            Text("O programa solicitado não está disponível.")
                .font(.system(.subheadline))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }

    // MARK: - Hero Section

    private func heroSection(_ program: Program) -> some View {
        ZStack(alignment: .bottomLeading) {
            // Background gradient
            LinearGradient(
                colors: gradientColors(for: program.goalTag),
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )

            // Overlay
            LinearGradient(
                colors: [.clear, .black.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )

            // Conteúdo
            VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
                Spacer()

                // Tag
                HStack(spacing: FitTodaySpacing.xs) {
                    Image(systemName: program.goalTag.iconName)
                    Text(program.goalTag.displayName)
                }
                .font(.system(.caption, weight: .semibold))
                .padding(.horizontal, FitTodaySpacing.sm)
                .padding(.vertical, FitTodaySpacing.xs)
                .background(.white.opacity(0.2))
                .clipShape(Capsule())

                Text(program.name)
                    .font(.system(.title, weight: .bold))

                Text(program.subtitle)
                    .font(.system(.body))
                    .opacity(0.9)

                // Metadados
                HStack(spacing: FitTodaySpacing.lg) {
                    VStack(alignment: .leading) {
                        Text(program.durationDescription)
                            .font(.system(.headline, weight: .bold))
                        Text("Duração")
                            .font(.system(.caption))
                            .opacity(0.7)
                    }

                    VStack(alignment: .leading) {
                        Text("\(program.totalWorkouts)")
                            .font(.system(.headline, weight: .bold))
                        Text("Treinos")
                            .font(.system(.caption))
                            .opacity(0.7)
                    }

                    VStack(alignment: .leading) {
                        Text(program.sessionsDescription)
                            .font(.system(.headline, weight: .bold))
                        Text("Frequência")
                            .font(.system(.caption))
                            .opacity(0.7)
                    }
                }
                .padding(.top, FitTodaySpacing.sm)
            }
            .foregroundStyle(.white)
            .padding(FitTodaySpacing.lg)
        }
        .frame(height: 280)
    }

    // MARK: - Workouts Section

    @ViewBuilder
    private func workoutsSection(viewModel: ProgramDetailViewModel) -> some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            Text("Treinos do Programa")
                .font(.system(.headline, weight: .semibold))
                .foregroundStyle(FitTodayColor.textPrimary)
                .padding(.horizontal)

            if viewModel.workouts.isEmpty && !viewModel.isLoading {
                emptyWorkoutsView
            } else if viewModel.isLoading {
                workoutsLoadingView
            } else {
                LazyVStack(spacing: FitTodaySpacing.sm) {
                    ForEach(Array(viewModel.workouts.enumerated()), id: \.element.id) { index, workout in
                        ProgramWorkoutRowCard(
                            workout: workout,
                            index: index + 1
                        ) {
                            router.push(.programWorkoutDetail(workout), on: router.selectedTab)
                        }
                        .padding(.horizontal)
                    }
                }
            }

            // Error message if any
            if let error = viewModel.errorMessage {
                errorView(error)
            }
        }
        .padding(.top, FitTodaySpacing.md)
    }

    private var emptyWorkoutsView: some View {
        VStack(spacing: FitTodaySpacing.md) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 40))
                .foregroundStyle(FitTodayColor.textTertiary)

            Text("Nenhum treino encontrado")
                .font(.system(.subheadline))
                .foregroundStyle(FitTodayColor.textSecondary)

            Text("Não foi possível carregar os exercícios da API")
                .font(.system(.caption))
                .foregroundStyle(FitTodayColor.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(FitTodaySpacing.xl)
    }

    private var workoutsLoadingView: some View {
        VStack(spacing: FitTodaySpacing.md) {
            ProgressView()
                .tint(FitTodayColor.brandPrimary)
            Text("Carregando exercícios da API Wger...")
                .font(.system(.caption))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(FitTodaySpacing.xl)
    }

    private func errorView(_ message: String) -> some View {
        HStack(spacing: FitTodaySpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(FitTodayColor.warning)
            Text(message)
                .font(.system(.caption))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .padding(FitTodaySpacing.md)
        .padding(.horizontal)
    }

    private func gradientColors(for goalTag: ProgramGoalTag) -> [Color] {
        switch goalTag {
        case .strength: return [.blue, .purple]
        case .conditioning: return [.orange, .red]
        case .aerobic: return [.green, .teal]
        case .core: return [.cyan, .mint]
        case .endurance: return [.indigo, .blue]
        }
    }
}

// MARK: - ViewModel

@MainActor
@Observable final class ProgramDetailViewModel {
    private(set) var program: Program?
    private(set) var workouts: [ProgramWorkout] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let programId: String
    private let programRepository: ProgramRepository
    private let loadProgramWorkoutsUseCase: LoadProgramWorkoutsUseCase

    init(
        programId: String,
        programRepository: ProgramRepository,
        loadProgramWorkoutsUseCase: LoadProgramWorkoutsUseCase
    ) {
        self.programId = programId
        self.programRepository = programRepository
        self.loadProgramWorkoutsUseCase = loadProgramWorkoutsUseCase
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        #if DEBUG
        print("══════════════════════════════════════════════════════")
        print("[ProgramDetail] 🔍 Loading program: '\(programId)'")
        #endif

        do {
            // Load program metadata
            program = try await programRepository.getProgram(id: programId)

            #if DEBUG
            if let program {
                print("[ProgramDetail] ✅ Program found: \(program.name)")
                print("[ProgramDetail] 📋 Templates: \(program.workoutTemplateIds)")
            } else {
                print("[ProgramDetail] ❌ Program NOT FOUND")
            }
            #endif

            guard program != nil else { return }

            // Load workouts with Wger exercises
            workouts = try await loadProgramWorkoutsUseCase.execute(programId: programId)

            #if DEBUG
            print("[ProgramDetail] ✅ Loaded \(workouts.count) workouts")
            for workout in workouts {
                print("[ProgramDetail]   - \(workout.title): \(workout.exercises.count) exercises")
            }
            #endif

        } catch {
            errorMessage = error.localizedDescription
            #if DEBUG
            print("[ProgramDetail] ❌ Error: \(error)")
            #endif
        }

        #if DEBUG
        print("══════════════════════════════════════════════════════")
        #endif
    }
}

// MARK: - Workout Row Card

private struct ProgramWorkoutRowCard: View {
    let workout: ProgramWorkout
    let index: Int
    let onTap: () -> Void

    private let maxPreviewExercises = 3

    private var previewExercises: [String] {
        workout.exercises.prefix(maxPreviewExercises).map { $0.name }
    }

    private var remainingCount: Int {
        max(0, workout.exerciseCount - maxPreviewExercises)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Header row
                HStack(spacing: FitTodaySpacing.md) {
                    // Número do treino
                    Text("\(index)")
                        .font(.system(.headline, weight: .bold))
                        .foregroundStyle(FitTodayColor.brandPrimary)
                        .frame(width: 32, height: 32)
                        .background(FitTodayColor.brandPrimary.opacity(0.15))
                        .clipShape(Circle())

                    // Info
                    VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                        Text(workout.title)
                            .font(.system(.subheadline, weight: .semibold))
                            .foregroundStyle(FitTodayColor.textPrimary)
                            .lineLimit(1)

                        HStack(spacing: FitTodaySpacing.sm) {
                            Label("\(workout.estimatedDurationMinutes) min", systemImage: "clock")
                            Label("\(workout.exerciseCount) exercícios", systemImage: "figure.run")
                        }
                        .font(.system(.caption))
                        .foregroundStyle(FitTodayColor.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(.caption, weight: .semibold))
                        .foregroundStyle(FitTodayColor.textTertiary)
                }

                // Exercise preview section
                if !workout.exercises.isEmpty {
                    Divider()
                        .padding(.vertical, FitTodaySpacing.sm)

                    VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                        ForEach(previewExercises, id: \.self) { exerciseName in
                            HStack(spacing: FitTodaySpacing.sm) {
                                Circle()
                                    .fill(FitTodayColor.brandPrimary)
                                    .frame(width: 6, height: 6)
                                Text(exerciseName)
                                    .font(.system(.caption))
                                    .foregroundStyle(FitTodayColor.textSecondary)
                                    .lineLimit(1)
                            }
                        }

                        if remainingCount > 0 {
                            Text("+ \(remainingCount) mais exercícios")
                                .font(.system(.caption, weight: .medium))
                                .foregroundStyle(FitTodayColor.brandPrimary)
                        }
                    }
                }
            }
            .padding(FitTodaySpacing.md)
            .background(FitTodayColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        ProgramDetailView(programId: "ppl_beginner_muscle_gym", resolver: Container())
            .environment(AppRouter())
    }
}
