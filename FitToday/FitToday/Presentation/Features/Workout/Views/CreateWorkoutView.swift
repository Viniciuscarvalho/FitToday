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
    @State private var viewModel: CreateWorkoutViewModel
    @State private var showExerciseSearch = false
    @State private var isEditMode = false

    init(resolver: Resolver, onDismiss: @escaping () -> Void) {
        self.resolver = resolver
        self.onDismiss = onDismiss
        let saveUseCase = resolver.resolve(SaveCustomWorkoutUseCase.self)
        _viewModel = State(initialValue: CreateWorkoutViewModel(saveUseCase: saveUseCase))
    }

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

                // Edit/Reorder toggle when exercises exist
                if !viewModel.exercises.isEmpty {
                    ToolbarItem(placement: .principal) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isEditMode.toggle()
                            }
                        } label: {
                            Text(isEditMode ? "Concluído" : "Reordenar")
                                .font(FitTodayFont.ui(size: 14, weight: .medium))
                                .foregroundStyle(FitTodayColor.brandPrimary)
                        }
                    }
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
                if let exerciseService = resolver.resolve(ExerciseServiceProtocol.self) {
                    ExerciseSearchSheet(
                        exerciseService: exerciseService,
                        onSelect: { exercise in
                            viewModel.addExercise(exercise)
                        }
                    )
                }
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
        VStack(spacing: FitTodaySpacing.sm) {
            ForEach(Array(viewModel.exercises.enumerated()), id: \.element.id) { index, exercise in
                ExerciseEntryRow(
                    exercise: exercise,
                    index: index + 1,
                    isEditMode: isEditMode,
                    onDelete: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.removeExercise(exercise)
                        }
                    },
                    onMoveUp: index > 0 ? {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.moveExercise(from: IndexSet(integer: index), to: index - 1)
                        }
                    } : nil,
                    onMoveDown: index < viewModel.exercises.count - 1 ? {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.moveExercise(from: IndexSet(integer: index), to: index + 2)
                        }
                    } : nil,
                    onConfigureSets: {
                        // TODO: Open sets configuration sheet
                    }
                )
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
    let index: Int
    let isEditMode: Bool
    let onDelete: () -> Void
    var onMoveUp: (() -> Void)?
    var onMoveDown: (() -> Void)?
    let onConfigureSets: () -> Void

    var body: some View {
        HStack(spacing: FitTodaySpacing.md) {
            // Index number or drag handle based on edit mode
            if isEditMode {
                // Move buttons in edit mode
                VStack(spacing: FitTodaySpacing.xs) {
                    Button {
                        onMoveUp?()
                    } label: {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(onMoveUp != nil ? FitTodayColor.brandPrimary : FitTodayColor.textTertiary.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                    .disabled(onMoveUp == nil)

                    Button {
                        onMoveDown?()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(onMoveDown != nil ? FitTodayColor.brandPrimary : FitTodayColor.textTertiary.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                    .disabled(onMoveDown == nil)
                }
                .frame(width: 28)
            } else {
                // Index number in normal mode
                Text("\(index)")
                    .font(FitTodayFont.ui(size: 14, weight: .bold))
                    .foregroundStyle(FitTodayColor.brandPrimary)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(FitTodayColor.brandPrimary.opacity(0.15))
                    )
            }

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

            if !isEditMode {
                // Configure sets button (only in normal mode)
                Button {
                    onConfigureSets()
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 16))
                        .foregroundStyle(FitTodayColor.brandPrimary)
                }
                .buttonStyle(.plain)
            }

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
                .fill(isEditMode ? FitTodayColor.surface.opacity(0.8) : FitTodayColor.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: FitTodayRadius.sm)
                        .stroke(isEditMode ? FitTodayColor.brandPrimary.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isEditMode)
    }
}

// MARK: - Preview

#Preview {
    let container = Container()
    return CreateWorkoutView(resolver: container, onDismiss: {})
        .preferredColorScheme(.dark)
}
