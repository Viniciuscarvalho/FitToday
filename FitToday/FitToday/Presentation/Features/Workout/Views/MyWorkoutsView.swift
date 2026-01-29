//
//  MyWorkoutsView.swift
//  FitToday
//
//  Displays user's custom workout templates.
//

import SwiftUI
import Swinject

/// View displaying the user's saved workout templates.
struct MyWorkoutsView: View {
    @Binding var showCreateWorkout: Bool
    let resolver: Resolver

    @State private var workouts: [CustomWorkoutTemplate] = []
    @State private var isLoading = true
    @State private var searchText = ""

    private var filteredWorkouts: [CustomWorkoutTemplate] {
        if searchText.isEmpty {
            return workouts
        }
        return workouts.filter {
            $0.name.localizedStandardContains(searchText)
        }
    }

    var body: some View {
        Group {
            if isLoading {
                loadingView
            } else if workouts.isEmpty {
                emptyStateView
            } else {
                workoutsList
            }
        }
        .task {
            await loadWorkouts()
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: FitTodaySpacing.lg) {
            ProgressView()
                .tint(FitTodayColor.brandPrimary)
            Text("common.loading".localized)
                .font(FitTodayFont.ui(size: 15, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: FitTodaySpacing.lg) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 64))
                .foregroundStyle(FitTodayColor.brandPrimary.opacity(0.6))
                .fitGlowEffect(color: FitTodayColor.brandPrimary.opacity(0.3))

            VStack(spacing: FitTodaySpacing.sm) {
                Text("workout_tab.empty.title".localized)
                    .font(FitTodayFont.display(size: 20, weight: .bold))
                    .foregroundStyle(FitTodayColor.textPrimary)

                Text("workout_tab.empty.subtitle".localized)
                    .font(FitTodayFont.ui(size: 15, weight: .medium))
                    .foregroundStyle(FitTodayColor.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showCreateWorkout = true
            } label: {
                HStack(spacing: FitTodaySpacing.sm) {
                    Image(systemName: "plus.circle.fill")
                    Text("workout_tab.create_first".localized)
                }
            }
            .fitPrimaryStyle()
            .frame(width: 200)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Workouts List

    private var workoutsList: some View {
        ScrollView {
            LazyVStack(spacing: FitTodaySpacing.md) {
                // Search bar
                if workouts.count > 3 {
                    searchBar
                        .padding(.horizontal, FitTodaySpacing.md)
                }

                // Workout cards
                ForEach(filteredWorkouts) { workout in
                    NavigationLink {
                        WorkoutDetailView(workout: workout)
                    } label: {
                        WorkoutTemplateCard(workout: workout)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, FitTodaySpacing.md)

                // Bottom padding for FAB
                Spacer()
                    .frame(height: 80)
            }
            .padding(.top, FitTodaySpacing.md)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: FitTodaySpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundStyle(FitTodayColor.textTertiary)

            TextField("Buscar treinos...", text: $searchText)
                .font(FitTodayFont.ui(size: 15, weight: .medium))
                .foregroundStyle(FitTodayColor.textPrimary)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
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

    // MARK: - Data Loading

    private func loadWorkouts() async {
        // Simulate loading
        try? await Task.sleep(for: .milliseconds(500))

        // TODO: Load from repository
        // For now, use mock data
        workouts = []
        isLoading = false
    }
}

// MARK: - Workout Template Card

struct WorkoutTemplateCard: View {
    let workout: CustomWorkoutTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                    Text(workout.name)
                        .font(FitTodayFont.ui(size: 18, weight: .bold))
                        .foregroundStyle(FitTodayColor.textPrimary)

                    if let category = workout.category {
                        Text(category)
                            .font(FitTodayFont.ui(size: 13, weight: .medium))
                            .foregroundStyle(FitTodayColor.brandSecondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(FitTodayColor.textTertiary)
            }

            // Stats
            HStack(spacing: FitTodaySpacing.md) {
                statItem(icon: "figure.strengthtraining.traditional", value: "\(workout.exerciseCount)", label: "exercícios")
                statItem(icon: "clock.fill", value: "~\(workout.estimatedDurationMinutes)", label: "min")
                statItem(icon: "number", value: "\(workout.totalSets)", label: "séries")
            }

            // Last used
            if let lastUsed = workout.lastUsedAt {
                Text("Último uso: \(lastUsed, format: .relative(presentation: .named))")
                    .font(FitTodayFont.ui(size: 11, weight: .medium))
                    .foregroundStyle(FitTodayColor.textTertiary)
            }
        }
        .padding(FitTodaySpacing.md)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .fill(FitTodayColor.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: FitTodayRadius.md)
                        .stroke(FitTodayColor.outline.opacity(0.3), lineWidth: 1)
                )
        )
        .techCornerBorders(color: FitTodayColor.brandPrimary.opacity(0.3))
    }

    private func statItem(icon: String, value: String, label: String) -> some View {
        HStack(spacing: FitTodaySpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(FitTodayColor.brandPrimary)

            Text(value)
                .font(FitTodayFont.ui(size: 14, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)

            Text(label)
                .font(FitTodayFont.ui(size: 12, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
    }
}

// MARK: - Workout Detail View (Placeholder)

struct WorkoutDetailView: View {
    let workout: CustomWorkoutTemplate

    var body: some View {
        Text("Workout Detail: \(workout.name)")
            .navigationTitle(workout.name)
    }
}

// MARK: - Preview

#Preview {
    let container = Container()
    return NavigationStack {
        MyWorkoutsView(showCreateWorkout: .constant(false), resolver: container)
    }
    .preferredColorScheme(.dark)
}
