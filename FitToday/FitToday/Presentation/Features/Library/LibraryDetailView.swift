//
//  LibraryDetailView.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import SwiftUI
import Swinject

struct LibraryDetailView: View {
    @Environment(\.dependencyResolver) private var resolver
    @Environment(AppRouter.self) private var router
    @Environment(WorkoutSessionStore.self) private var sessionStore
    @State private var workout: LibraryWorkout?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var dependencyError: String?

    let workoutId: String
    private let repository: LibraryWorkoutsRepository?

    init(workoutId: String, resolver: Resolver) {
        self.workoutId = workoutId
        if let repo = resolver.resolve(LibraryWorkoutsRepository.self) {
            self.repository = repo
            _dependencyError = State(initialValue: nil)
        } else {
            self.repository = nil
            _dependencyError = State(initialValue: "Erro de configuração: repositório de treinos não está registrado.")
        }
    }

    var body: some View {
        Group {
            if let error = dependencyError {
                DependencyErrorView(message: error)
            } else {
                ScrollView {
                    if isLoading {
                        VStack(spacing: FitTodaySpacing.md) {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(FitTodayColor.brandPrimary)
                            Text("Carregando treino...")
                                .font(.system(.subheadline))
                                .foregroundStyle(FitTodayColor.textSecondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 300)
                    } else if let workout = workout {
                        content(for: workout)
                    } else {
                        EmptyStateView(
                            title: "Treino não encontrado",
                            message: "O treino que você procura não está disponível.",
                            systemIcon: "questionmark.circle"
                        )
                        .padding()
                    }
                }
                .task {
                    await loadWorkout()
                }
            }
        }
        .background(FitTodayColor.background.ignoresSafeArea())
        .navigationTitle(workout?.title ?? "Detalhes")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Ops!", isPresented: Binding(
            get: { errorMessage != nil },
            set: { _ in errorMessage = nil }
        )) {
            Button("Ok", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Algo inesperado aconteceu.")
        }
    }

    // MARK: - Content

    private func content(for workout: LibraryWorkout) -> some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.lg) {
            headerSection(workout)
            infoCards(workout)
            exercisesList(workout)
            startButton(workout)
        }
        .padding()
    }

    // MARK: - Header

    private func headerSection(_ workout: LibraryWorkout) -> some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            // Title and subtitle
            VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                Text(workout.title)
                    .font(.system(.title, weight: .bold))
                    .foregroundStyle(FitTodayColor.textPrimary)
                Text(workout.subtitle)
                    .font(.system(.body))
                    .foregroundStyle(FitTodayColor.textSecondary)
            }

            // Badges
            HStack(spacing: FitTodaySpacing.sm) {
                FitBadge(text: workout.goal.displayName, style: .info)
                FitBadge(text: workout.structure.displayName, style: .success)
            }

            // Quick stats row
            HStack(spacing: FitTodaySpacing.lg) {
                quickStatItem(
                    icon: "figure.strengthtraining.traditional",
                    value: "\(workout.exerciseCount)",
                    label: "Exercícios"
                )
                quickStatItem(
                    icon: "number.square",
                    value: "\(totalSets(workout))",
                    label: "Séries"
                )
                quickStatItem(
                    icon: "clock",
                    value: "\(workout.estimatedDurationMinutes)",
                    label: "Minutos"
                )
            }
            .padding(.top, FitTodaySpacing.xs)
        }
    }

    private func quickStatItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(FitTodayColor.brandPrimary)
                Text(value)
                    .font(.system(.headline, weight: .bold))
                    .foregroundStyle(FitTodayColor.textPrimary)
            }
            Text(label)
                .font(.system(.caption2))
                .foregroundStyle(FitTodayColor.textTertiary)
        }
    }

    private func totalSets(_ workout: LibraryWorkout) -> Int {
        workout.exercises.reduce(0) { $0 + $1.sets }
    }

    // MARK: - Info Cards

    private func infoCards(_ workout: LibraryWorkout) -> some View {
        HStack(spacing: FitTodaySpacing.md) {
            InfoCard(icon: "clock", title: "Duração", value: "\(workout.estimatedDurationMinutes) min")
            InfoCard(icon: "figure.run", title: "Exercícios", value: "\(workout.exerciseCount)")
            InfoCard(icon: "flame", title: "Intensidade", value: workout.intensity.displayName)
        }
    }

    // MARK: - Exercises List

    private func exercisesList(_ workout: LibraryWorkout) -> some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            SectionHeader(title: "Exercícios", actionTitle: nil)

            ForEach(Array(workout.exercises.enumerated()), id: \.element.exercise.id) { index, prescription in
                Button {
                    // Usa a tab atual para manter a navegação na mesma tab (home ou programs)
                    router.push(.programExerciseDetail(prescription), on: router.selectedTab)
                } label: {
                    ExerciseRow(index: index + 1, prescription: prescription)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Start Button

    private func startButton(_ workout: LibraryWorkout) -> some View {
        Button {
            startWorkout(workout)
        } label: {
            Text("Iniciar Treino")
        }
        .fitPrimaryStyle()
        .padding(.vertical, FitTodaySpacing.md)
        .accessibilityLabel("Iniciar treino \(workout.title)")
        .accessibilityHint("Começar execução do treino selecionado")
    }

    // MARK: - Actions

    private func loadWorkout() async {
        guard let repository = repository else {
            #if DEBUG
            print("[LibraryDetail] Repository is nil")
            #endif
            isLoading = false
            return
        }

        #if DEBUG
        print("[LibraryDetail] Starting load for workoutId: \(workoutId)")
        #endif

        isLoading = true
        do {
            let workouts = try await repository.loadWorkouts()
            #if DEBUG
            print("[LibraryDetail] Total workouts loaded: \(workouts.count)")
            print("[LibraryDetail] Available IDs: \(workouts.map { $0.id })")
            #endif

            workout = workouts.first { $0.id == workoutId }

            #if DEBUG
            if let found = workout {
                print("[LibraryDetail] Found workout: \(found.title) with \(found.exerciseCount) exercises")
            } else {
                print("[LibraryDetail] Workout not found for id: \(workoutId)")
            }
            #endif
        } catch {
            #if DEBUG
            print("[LibraryDetail] Error: \(error)")
            #endif
            errorMessage = "Erro ao carregar treino: \(error.localizedDescription)"
        }
        isLoading = false
    }

    private func startWorkout(_ workout: LibraryWorkout) {
        let plan = workout.toWorkoutPlan()
        sessionStore.start(with: plan)
        // Usa a tab atual para manter a navegação na mesma tab (home ou programs)
        router.push(.workoutPlan(plan.id), on: router.selectedTab)
    }
}

// MARK: - Subviews

private struct InfoCard: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: FitTodaySpacing.xs) {
            Image(systemName: icon)
                .font(.system(.title3))
                .foregroundStyle(FitTodayColor.brandPrimary)
            Text(value)
                .font(.system(.headline, weight: .semibold))
                .foregroundStyle(FitTodayColor.textPrimary)
            Text(title)
                .font(.system(.caption))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(FitTodayColor.surface)
        .cornerRadius(FitTodayRadius.md)
    }
}

private struct ExerciseRow: View {
    let index: Int
    let prescription: ExercisePrescription

    var body: some View {
        HStack(spacing: FitTodaySpacing.md) {
            Text("\(index)")
                .font(.system(.headline, weight: .bold))
                .foregroundStyle(FitTodayColor.brandPrimary)
                .frame(width: 30, height: 30)
                .background(FitTodayColor.brandPrimary.opacity(0.15))
                .clipShape(Circle())

            ExerciseThumbnail(media: prescription.exercise.media, size: 56)

            VStack(alignment: .leading, spacing: 2) {
                Text(prescription.exercise.name)
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(FitTodayColor.textPrimary)
                    .lineLimit(2)
                Text("\(prescription.sets) séries × \(prescription.reps.display) reps • \(Int(prescription.restInterval))s")
                    .font(.system(.caption))
                    .foregroundStyle(FitTodayColor.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(.caption, weight: .semibold))
                .foregroundStyle(FitTodayColor.textTertiary)
        }
        .padding()
        .background(FitTodayColor.surface)
        .cornerRadius(FitTodayRadius.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(prescription.exercise.name), \(prescription.sets) séries de \(prescription.reps.display) repetições")
        .accessibilityHint("Toque para ver detalhes do exercício")
    }
}

#Preview {
    NavigationStack {
        LibraryDetailView(workoutId: "lib_upper_hypertrophy_gym", resolver: Container())
    }
}

