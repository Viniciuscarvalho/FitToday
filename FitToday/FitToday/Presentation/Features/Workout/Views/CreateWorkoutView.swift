//
//  CreateWorkoutView.swift
//  FitToday
//
//  View for creating a new custom workout template.
//

import SwiftUI
import Swinject

/// View for creating a new custom workout template.
struct CreateWorkoutView: View {
    let resolver: Resolver
    let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = CreateWorkoutViewModel()
    @State private var showExerciseSearch = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FitTodaySpacing.lg) {
                    // Workout Name
                    nameSection

                    // Icon Selection
                    iconSection

                    // Color Selection
                    colorSection

                    // Exercises List
                    exercisesSection

                    // Add Exercise Button
                    addExerciseButton

                    Spacer(minLength: FitTodaySpacing.xxl)
                }
                .padding(FitTodaySpacing.md)
            }
            .scrollIndicators(.hidden)
            .background(FitTodayColor.background)
            .navigationTitle("create_workout.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) {
                        onDismiss()
                        dismiss()
                    }
                    .foregroundStyle(FitTodayColor.textSecondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save".localized) {
                        Task {
                            await viewModel.saveWorkout()
                            onDismiss()
                            dismiss()
                        }
                    }
                    .foregroundStyle(viewModel.canSave ? FitTodayColor.brandPrimary : FitTodayColor.textTertiary)
                    .disabled(!viewModel.canSave)
                }
            }
            .sheet(isPresented: $showExerciseSearch) {
                ExerciseSearchSheet(onSelect: { exercise in
                    viewModel.addExercise(exercise)
                })
            }
        }
    }

    // MARK: - Name Section

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            Text("create_workout.name.label".localized)
                .font(FitTodayFont.ui(size: 14, weight: .semiBold))
                .foregroundStyle(FitTodayColor.textSecondary)

            TextField("create_workout.name.placeholder".localized, text: $viewModel.workoutName)
                .font(FitTodayFont.ui(size: 17, weight: .medium))
                .foregroundStyle(FitTodayColor.textPrimary)
                .padding(FitTodaySpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: FitTodayRadius.sm)
                        .fill(FitTodayColor.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: FitTodayRadius.sm)
                                .stroke(FitTodayColor.outline, lineWidth: 1)
                        )
                )
        }
    }

    // MARK: - Icon Section

    private var iconSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            Text("create_workout.icon.label".localized)
                .font(FitTodayFont.ui(size: 14, weight: .semiBold))
                .foregroundStyle(FitTodayColor.textSecondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: FitTodaySpacing.sm), count: 6), spacing: FitTodaySpacing.sm) {
                ForEach(WorkoutIcon.allCases, id: \.self) { icon in
                    iconButton(icon)
                }
            }
            .padding(FitTodaySpacing.md)
            .background(
                RoundedRectangle(cornerRadius: FitTodayRadius.md)
                    .fill(FitTodayColor.surface)
            )
        }
    }

    private func iconButton(_ icon: WorkoutIcon) -> some View {
        let isSelected = viewModel.selectedIcon == icon

        return Button {
            viewModel.selectedIcon = icon
        } label: {
            Image(systemName: icon.systemName)
                .font(.system(size: 20))
                .foregroundStyle(isSelected ? FitTodayColor.brandPrimary : FitTodayColor.textSecondary)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: FitTodayRadius.sm)
                        .fill(isSelected ? FitTodayColor.brandPrimary.opacity(0.2) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: FitTodayRadius.sm)
                        .stroke(isSelected ? FitTodayColor.brandPrimary : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Color Section

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            Text("create_workout.color.label".localized)
                .font(FitTodayFont.ui(size: 14, weight: .semiBold))
                .foregroundStyle(FitTodayColor.textSecondary)

            HStack(spacing: FitTodaySpacing.sm) {
                ForEach(WorkoutColor.allCases, id: \.self) { color in
                    colorButton(color)
                }
            }
            .padding(FitTodaySpacing.md)
            .background(
                RoundedRectangle(cornerRadius: FitTodayRadius.md)
                    .fill(FitTodayColor.surface)
            )
        }
    }

    private func colorButton(_ workoutColor: WorkoutColor) -> some View {
        let isSelected = viewModel.selectedColor == workoutColor

        return Button {
            viewModel.selectedColor = workoutColor
        } label: {
            Circle()
                .fill(workoutColor.color)
                .frame(width: 36, height: 36)
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.white : Color.clear, lineWidth: 3)
                )
                .shadow(color: isSelected ? workoutColor.color.opacity(0.5) : Color.clear, radius: 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Exercises Section

    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            HStack {
                Text("create_workout.exercises.label".localized)
                    .font(FitTodayFont.ui(size: 14, weight: .semiBold))
                    .foregroundStyle(FitTodayColor.textSecondary)

                Spacer()

                if !viewModel.exercises.isEmpty {
                    Text("\(viewModel.exercises.count)")
                        .font(FitTodayFont.ui(size: 13, weight: .medium))
                        .foregroundStyle(FitTodayColor.textTertiary)
                }
            }

            if viewModel.exercises.isEmpty {
                emptyExercisesView
            } else {
                exercisesList
            }
        }
    }

    private var emptyExercisesView: some View {
        VStack(spacing: FitTodaySpacing.md) {
            Image(systemName: "plus.circle.dashed")
                .font(.system(size: 40))
                .foregroundStyle(FitTodayColor.textTertiary)

            Text("create_workout.exercises.empty".localized)
                .font(FitTodayFont.ui(size: 15, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, FitTodaySpacing.xl)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .fill(FitTodayColor.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: FitTodayRadius.md)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [8]))
                        .foregroundStyle(FitTodayColor.outline)
                )
        )
    }

    private var exercisesList: some View {
        LazyVStack(spacing: FitTodaySpacing.sm) {
            ForEach(viewModel.exercises) { exercise in
                ExerciseEntryRow(
                    exercise: exercise,
                    onDelete: {
                        viewModel.removeExercise(exercise)
                    },
                    onConfigureSets: {
                        // TODO: Open sets configuration sheet
                    }
                )
            }
            .onMove { source, destination in
                viewModel.moveExercise(from: source, to: destination)
            }
        }
    }

    // MARK: - Add Exercise Button

    private var addExerciseButton: some View {
        Button {
            showExerciseSearch = true
        } label: {
            HStack(spacing: FitTodaySpacing.sm) {
                Image(systemName: "plus.circle.fill")
                Text("create_workout.add_exercise".localized)
            }
        }
        .fitSecondaryStyle()
    }
}

// MARK: - Exercise Entry Row

struct ExerciseEntryRow: View {
    let exercise: CustomExerciseEntry
    let onDelete: () -> Void
    let onConfigureSets: () -> Void

    var body: some View {
        HStack(spacing: FitTodaySpacing.md) {
            // Drag handle
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 14))
                .foregroundStyle(FitTodayColor.textTertiary)

            // Exercise info
            VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                Text(exercise.exerciseName)
                    .font(FitTodayFont.ui(size: 15, weight: .semiBold))
                    .foregroundStyle(FitTodayColor.textPrimary)
                    .lineLimit(1)

                HStack(spacing: FitTodaySpacing.sm) {
                    if let bodyPart = exercise.bodyPart {
                        Text(bodyPart)
                            .font(FitTodayFont.ui(size: 12, weight: .medium))
                            .foregroundStyle(FitTodayColor.brandSecondary)
                    }

                    Text("\(exercise.sets.count) séries")
                        .font(FitTodayFont.ui(size: 12, weight: .medium))
                        .foregroundStyle(FitTodayColor.textTertiary)
                }
            }

            Spacer()

            // Configure sets button
            Button {
                onConfigureSets()
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 16))
                    .foregroundStyle(FitTodayColor.brandPrimary)
            }
            .buttonStyle(.plain)

            // Delete button
            Button {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundStyle(FitTodayColor.error)
            }
            .buttonStyle(.plain)
        }
        .padding(FitTodaySpacing.md)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.sm)
                .fill(FitTodayColor.surface)
        )
    }
}

// MARK: - Preview

#Preview {
    let container = Container()
    return CreateWorkoutView(resolver: container, onDismiss: {})
        .preferredColorScheme(.dark)
}
