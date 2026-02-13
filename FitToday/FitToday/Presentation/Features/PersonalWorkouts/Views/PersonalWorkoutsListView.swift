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
    @State private var viewModel: PersonalWorkoutsViewModel?
    @State private var selectedWorkout: PersonalWorkout?
    @State private var dependencyError: String?
    @State private var cachedWorkouts: Set<String> = []

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
    }

    // MARK: - Content Views

    @ViewBuilder
    private func contentView(viewModel: PersonalWorkoutsViewModel) -> some View {
        if viewModel.isLoading {
            loadingView
        } else if viewModel.isEmpty {
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
            .padding(.horizontal, FitTodaySpacing.md)
            .padding(.vertical, FitTodaySpacing.sm)
        }
        .refreshable {
            if let authRepository = resolver.resolve(AuthenticationRepository.self),
               let user = try? await authRepository.currentUser() {
                await viewModel.loadWorkouts(userId: user.id)
            }
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
}

// MARK: - Preview

#Preview {
    let container = Container()

    return NavigationStack {
        PersonalWorkoutsListView()
            .environment(\.dependencyResolver, container)
    }
}
