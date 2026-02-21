//
//  PersonalWorkoutsListView.swift
//  FitToday
//
//  Lista de treinos enviados pelo Personal Trainer.
//

import SwiftUI
import Swinject

/// View que exibe a lista de treinos do Personal Trainer.
struct PersonalWorkoutsListView: View {
    @Environment(\.dependencyResolver) private var resolver
    @Environment(AppRouter.self) private var router
    @State private var viewModel: PersonalWorkoutsViewModel?
    @State private var selectedWorkout: PersonalWorkout?
    @State private var dependencyError: String?
    @State private var cachedWorkouts: Set<String> = []
    @State private var cmsWorkouts: [TrainerWorkout] = []
    @State private var isCMSLoading = false
    @State private var cmsPDFSheet: CMSPDFInfo?

    var body: some View {
        Group {
            if let error = dependencyError {
                DependencyErrorView(message: error)
            } else if let viewModel {
                contentView(viewModel: viewModel)
            } else {
                loadingView
            }
        }
        .background(FitTodayColor.background)
        .task {
            await initializeViewModel()
        }
    }

    // MARK: - Initialization

    private func initializeViewModel() async {
        guard let repository = resolver.resolve(PersonalWorkoutRepository.self),
              let pdfCache = resolver.resolve(PDFCaching.self),
              let authRepository = resolver.resolve(AuthenticationRepository.self) else {
            dependencyError = "error.generic".localized
            return
        }

        let vm = PersonalWorkoutsViewModel(repository: repository, pdfCache: pdfCache)
        viewModel = vm

        // Carregar treinos do usuário atual
        if let user = try? await authRepository.currentUser() {
            await vm.loadWorkouts(userId: user.id)
            vm.startObserving(userId: user.id)

            // Verificar cache para cada treino
            for workout in vm.workouts {
                if await vm.isPDFCached(workout) {
                    cachedWorkouts.insert(workout.id)
                }
            }
        }

        // Carregar treinos do CMS
        await loadCMSWorkouts()
    }

    // MARK: - CMS Workouts

    private func loadCMSWorkouts() async {
        guard let useCase = resolver.resolve(FetchCMSWorkoutsUseCase.self) else { return }

        isCMSLoading = true
        defer { isCMSLoading = false }

        do {
            let result = try await useCase.execute()
            cmsWorkouts = result.workouts
        } catch {
            // CMS loading failure is non-blocking — PDF workouts still show
            #if DEBUG
            print("[PersonalWorkoutsListView] CMS load error: \(error)")
            #endif
        }
    }

    // MARK: - Content Views

    @ViewBuilder
    private func contentView(viewModel: PersonalWorkoutsViewModel) -> some View {
        let isLoading = viewModel.isLoading && isCMSLoading
        let isEmpty = viewModel.isEmpty && cmsWorkouts.isEmpty

        if isLoading {
            loadingView
        } else if isEmpty {
            emptyStateView
        } else {
            workoutsListView(viewModel: viewModel)
        }
    }

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text("personal.loading".localized)
                .font(FitTodayFont.ui(size: 14))
                .foregroundStyle(FitTodayColor.textSecondary)
                .padding(.top, FitTodaySpacing.md)
            Spacer()
        }
    }

    private var emptyStateView: some View {
        EmptyStateView(
            title: "personal.empty.title".localized,
            message: "personal.empty.message".localized,
            systemIcon: "doc.text"
        )
        .padding()
    }

    private func workoutsListView(viewModel: PersonalWorkoutsViewModel) -> some View {
        ScrollView {
            LazyVStack(spacing: FitTodaySpacing.md) {
                // CMS Workouts Section
                if !cmsWorkouts.isEmpty {
                    cmsWorkoutsSection
                }

                // PDF Workouts Section
                if !viewModel.workouts.isEmpty {
                    if !cmsWorkouts.isEmpty {
                        Text("personal.pdf_workouts.title".localized)
                            .font(FitTodayFont.ui(size: 16, weight: .bold))
                            .foregroundStyle(FitTodayColor.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, FitTodaySpacing.sm)
                    }

                    ForEach(viewModel.workouts) { workout in
                        PersonalWorkoutRow(
                            workout: workout,
                            isCached: cachedWorkouts.contains(workout.id)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedWorkout = workout
                        }
                    }
                }
            }
            .padding(.horizontal, FitTodaySpacing.md)
            .padding(.vertical, FitTodaySpacing.sm)
        }
        .refreshable {
            if let authRepository = resolver.resolve(AuthenticationRepository.self),
               let user = try? await authRepository.currentUser() {
                await viewModel.loadWorkouts(userId: user.id)
            }
            await loadCMSWorkouts()
        }
        .sheet(item: $selectedWorkout) { workout in
            PDFViewerView(workout: workout, viewModel: viewModel)
        }
        .alert("error.generic.title".localized, isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.clearError() }
        )) {
            Button("error.action.dismiss".localized, role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "error.generic.message".localized)
        }
    }

    // MARK: - CMS Workouts Section

    private var cmsWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            Text("personal.cms_workouts.title".localized)
                .font(FitTodayFont.ui(size: 16, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)

            ForEach(cmsWorkouts) { workout in
                Button {
                    // PDF-only workout: open PDF directly
                    if let pdfUrlString = workout.pdfUrl,
                       let pdfUrl = URL(string: pdfUrlString),
                       workout.phases.isEmpty {
                        cmsPDFSheet = CMSPDFInfo(url: pdfUrl, title: workout.title)
                    } else {
                        router.push(.cmsWorkoutDetail(workout.id), on: .workout)
                    }
                } label: {
                    CMSWorkoutRow(workout: workout)
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(item: $cmsPDFSheet) { info in
            CMSPDFSheetView(url: info.url, title: info.title)
        }
    }
}

// MARK: - CMS PDF Info

/// Identifiable wrapper for presenting a CMS PDF sheet.
private struct CMSPDFInfo: Identifiable {
    let id = UUID()
    let url: URL
    let title: String
}

// MARK: - CMS Workout Row

private struct CMSWorkoutRow: View {
    let workout: TrainerWorkout

    private var isPDFOnly: Bool {
        workout.pdfUrl != nil && workout.phases.isEmpty
    }

    private var exerciseCount: Int {
        workout.phases.reduce(0) { $0 + $1.items.count }
    }

    var body: some View {
        HStack(spacing: FitTodaySpacing.md) {
            ZStack {
                Circle()
                    .fill(workout.isActive ? FitTodayColor.brandPrimary.opacity(0.1) : FitTodayColor.textSecondary.opacity(0.1))
                    .frame(width: 44, height: 44)

                Image(systemName: isPDFOnly ? "doc.fill" : (workout.isActive ? "dumbbell.fill" : "checkmark.circle.fill"))
                    .font(.system(size: 20))
                    .foregroundStyle(workout.isActive ? FitTodayColor.brandPrimary : FitTodayColor.success)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(workout.title)
                    .font(FitTodayFont.ui(size: 16, weight: .semiBold))
                    .foregroundStyle(FitTodayColor.textPrimary)
                    .lineLimit(1)

                HStack(spacing: FitTodaySpacing.sm) {
                    if isPDFOnly {
                        Text("PDF")
                            .font(FitTodayFont.ui(size: 12, weight: .medium))
                            .foregroundStyle(FitTodayColor.brandPrimary)
                    } else {
                        Text("personal_trainer.workouts.exercises_count".localized(with: exerciseCount))
                            .font(FitTodayFont.ui(size: 12, weight: .medium))
                            .foregroundStyle(FitTodayColor.textSecondary)
                    }

                    Text("\(workout.estimatedDurationMinutes) min")
                        .font(FitTodayFont.ui(size: 12, weight: .medium))
                        .foregroundStyle(FitTodayColor.textSecondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .padding()
        .background(FitTodayColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
    }
}

// MARK: - Preview

#Preview {
    let container = Container()

    return NavigationStack {
        PersonalWorkoutsListView()
            .environment(\.dependencyResolver, container)
    }
}
