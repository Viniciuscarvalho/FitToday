//
//  LibraryView.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import SwiftUI
import Swinject

struct LibraryView: View {
    @Environment(\.dependencyResolver) private var resolver
    @EnvironmentObject private var router: AppRouter
    @StateObject private var viewModel: LibraryViewModel
    @State private var showingFilters = false

    init(resolver: Resolver) {
        guard let repository = resolver.resolve(LibraryWorkoutsRepository.self) else {
            fatalError("LibraryWorkoutsRepository não registrado.")
        }
        _viewModel = StateObject(wrappedValue: LibraryViewModel(repository: repository))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: FitTodaySpacing.lg) {
                headerSection
                filterChips
                workoutsList
            }
            .padding()
        }
        .background(FitTodayColor.background.ignoresSafeArea())
        .navigationTitle("Biblioteca")
        .task {
            viewModel.loadWorkouts()
        }
        .sheet(isPresented: $showingFilters) {
            FilterSheet(viewModel: viewModel)
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
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            Text("Treinos Gratuitos")
                .font(.system(.title2, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)
            Text("Escolha um treino e comece agora mesmo, sem adaptação diária.")
                .font(.system(.subheadline))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Filters

    private var filterChips: some View {
        HStack(spacing: FitTodaySpacing.sm) {
            FilterButton(
                title: viewModel.filter.goal?.displayName ?? "Objetivo",
                isActive: viewModel.filter.goal != nil
            ) {
                showingFilters = true
            }

            FilterButton(
                title: viewModel.filter.structure?.displayName ?? "Local",
                isActive: viewModel.filter.structure != nil
            ) {
                showingFilters = true
            }

            Spacer()

            if viewModel.filter.isActive {
                Button {
                    viewModel.clearFilter()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(FitTodayColor.textSecondary)
                }
            }
        }
    }

    // MARK: - Workouts List

    @ViewBuilder
    private var workoutsList: some View {
        if viewModel.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 200)
        } else if viewModel.filteredWorkouts.isEmpty {
            EmptyStateView(
                title: "Nenhum treino encontrado",
                message: "Tente ajustar os filtros para ver mais opções.",
                systemIcon: "magnifyingglass"
            )
            .padding(.vertical, FitTodaySpacing.xl)
        } else {
            LazyVStack(spacing: FitTodaySpacing.md) {
                ForEach(viewModel.filteredWorkouts) { workout in
                    LibraryWorkoutCard(workout: workout) {
                        router.push(.libraryDetail(workout.id), on: .library)
                    }
                    .accessibilityLabel("\(workout.title), \(workout.estimatedDurationMinutes) minutos, \(workout.exerciseCount) exercícios")
                    .accessibilityHint("Toque para ver detalhes e iniciar o treino")
                }
            }
        }
    }
}

// MARK: - Subviews

private struct FilterButton: View {
    let title: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(.subheadline, weight: .medium))
                Image(systemName: "chevron.down")
                    .font(.system(.caption))
            }
            .padding(.horizontal, FitTodaySpacing.md)
            .padding(.vertical, FitTodaySpacing.sm)
            .background(isActive ? FitTodayColor.brandPrimary.opacity(0.15) : FitTodayColor.surface)
            .foregroundStyle(isActive ? FitTodayColor.brandPrimary : FitTodayColor.textPrimary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isActive ? FitTodayColor.brandPrimary : FitTodayColor.outline.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

private struct LibraryWorkoutCard: View {
    let workout: LibraryWorkout
    let onTap: () -> Void

    /// Thumbnail do primeiro exercício (se existir).
    private var firstExerciseMedia: ExerciseMedia? {
        workout.exercises.first?.exercise.media
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: FitTodaySpacing.md) {
                // Thumbnail do treino (primeiro exercício)
                ExerciseThumbnail(media: firstExerciseMedia, size: 72)

                VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                    Text(workout.title)
                        .font(.system(.headline, weight: .semibold))
                        .foregroundStyle(FitTodayColor.textPrimary)
                        .lineLimit(1)

                    Text(workout.subtitle)
                        .font(.system(.caption))
                        .foregroundStyle(FitTodayColor.textSecondary)
                        .lineLimit(2)

                    HStack(spacing: FitTodaySpacing.sm) {
                        Label("\(workout.estimatedDurationMinutes) min", systemImage: "clock")
                        Label("\(workout.exerciseCount)", systemImage: "figure.run")
                        IntensityBadge(intensity: workout.intensity)
                    }
                    .font(.system(.caption2))
                    .foregroundStyle(FitTodayColor.textTertiary)

                    HStack(spacing: FitTodaySpacing.xs) {
                        FitBadge(text: workout.goal.displayName, style: .info)
                        FitBadge(text: workout.structure.displayName, style: .success)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(.caption, weight: .semibold))
                    .foregroundStyle(FitTodayColor.textTertiary)
            }
            .padding()
            .background(FitTodayColor.surface)
            .cornerRadius(FitTodayRadius.md)
            .fitCardShadow()
        }
        .buttonStyle(.plain)
    }
}

private struct IntensityBadge: View {
    let intensity: WorkoutIntensity

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(intensityColor)
                .frame(width: 8, height: 8)
            Text(intensity.displayName)
        }
        .font(.system(.caption, weight: .medium))
        .foregroundStyle(FitTodayColor.textSecondary)
    }

    private var intensityColor: Color {
        switch intensity {
        case .low: return .green
        case .moderate: return .orange
        case .high: return .red
        }
    }
}

// MARK: - Filter Sheet

private struct FilterSheet: View {
    @ObservedObject var viewModel: LibraryViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Objetivo") {
                    ForEach(viewModel.availableGoals, id: \.self) { goal in
                        Button {
                            viewModel.filter.goal = viewModel.filter.goal == goal ? nil : goal
                        } label: {
                            HStack {
                                Text(goal.displayName)
                                Spacer()
                                if viewModel.filter.goal == goal {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(FitTodayColor.brandPrimary)
                                }
                            }
                        }
                        .foregroundStyle(FitTodayColor.textPrimary)
                    }
                }

                Section("Local") {
                    ForEach(viewModel.availableStructures, id: \.self) { structure in
                        Button {
                            viewModel.filter.structure = viewModel.filter.structure == structure ? nil : structure
                        } label: {
                            HStack {
                                Text(structure.displayName)
                                Spacer()
                                if viewModel.filter.structure == structure {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(FitTodayColor.brandPrimary)
                                }
                            }
                        }
                        .foregroundStyle(FitTodayColor.textPrimary)
                    }
                }
            }
            .navigationTitle("Filtros")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Aplicar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Limpar") {
                        viewModel.clearFilter()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    NavigationStack {
        LibraryView(resolver: Container())
    }
}

