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
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var sessionStore: WorkoutSessionStore
    @State private var workout: LibraryWorkout?
    @State private var isLoading = true
    @State private var errorMessage: String?

    let workoutId: String
    private let repository: LibraryWorkoutsRepository

    init(workoutId: String, resolver: Resolver) {
        self.workoutId = workoutId
        guard let repo = resolver.resolve(LibraryWorkoutsRepository.self) else {
            fatalError("LibraryWorkoutsRepository não registrado.")
        }
        self.repository = repo
    }

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView()
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
        .background(FitTodayColor.background.ignoresSafeArea())
        .navigationTitle(workout?.title ?? "Detalhes")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadWorkout()
        }
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
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            Text(workout.title)
                .font(.system(.title, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)
            Text(workout.subtitle)
                .font(.system(.body))
                .foregroundStyle(FitTodayColor.textSecondary)
            HStack(spacing: FitTodaySpacing.sm) {
                FitBadge(text: workout.goal.displayName, style: .info)
                FitBadge(text: workout.structure.displayName, style: .success)
            }
        }
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

            ForEach(workout.exercises.indices, id: \.self) { index in
                Button {
                    router.push(.libraryExerciseDetail(workout.exercises[index]), on: .library)
                } label: {
                    ExerciseRow(index: index + 1, prescription: workout.exercises[index])
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
        isLoading = true
        do {
            let workouts = try await repository.loadWorkouts()
            workout = workouts.first { $0.id == workoutId }
        } catch {
            errorMessage = "Erro ao carregar treino: \(error.localizedDescription)"
        }
        isLoading = false
    }

    private func startWorkout(_ workout: LibraryWorkout) {
        let plan = workout.toWorkoutPlan()
        sessionStore.start(with: plan)
        router.push(.workoutPlan(plan.id), on: .library)
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

