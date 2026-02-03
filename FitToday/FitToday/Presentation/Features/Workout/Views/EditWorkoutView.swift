//
//  EditWorkoutView.swift
//  FitToday
//
//  View for editing an existing custom workout template.
//

import SwiftUI
import Swinject

/// View for editing an existing custom workout template.
struct EditWorkoutView: View {
    let resolver: Resolver
    let workoutId: UUID
    let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: EditWorkoutViewModel?
    @State private var showExerciseSearch = false
    @State private var isEditMode = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel = viewModel {
                    if viewModel.isLoading {
                        loadingView
                    } else if viewModel.errorMessage != nil {
                        errorView
                    } else {
                        contentView(viewModel: viewModel)
                    }
                } else {
                    loadingView
                }
            }
            .background(FitTodayColor.background)
            .navigationTitle("Editar Treino")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        onDismiss()
                        dismiss()
                    }
                    .foregroundStyle(FitTodayColor.textSecondary)
                }

                if let viewModel = viewModel, !viewModel.exercises.isEmpty {
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
                    Button("Salvar") {
                        Task {
                            await viewModel?.saveChanges()
                            onDismiss()
                            dismiss()
                        }
                    }
                    .foregroundStyle(viewModel?.canSave == true ? FitTodayColor.brandPrimary : FitTodayColor.textTertiary)
                    .disabled(viewModel?.canSave != true)
                }
            }
            .task {
                let vm = EditWorkoutViewModel(resolver: resolver, workoutId: workoutId)
                viewModel = vm
                await vm.loadWorkout()
            }
            .sheet(isPresented: $showExerciseSearch) {
                if let exerciseService = resolver.resolve(ExerciseServiceProtocol.self) {
                    ExerciseSearchSheet(
                        exerciseService: exerciseService,
                        onSelect: { exerciseEntry in
                            viewModel?.addExerciseEntry(exerciseEntry)
                        }
                    )
                }
            }
            .confirmationDialog(
                "Excluir Treino",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Excluir", role: .destructive) {
                    Task {
                        await viewModel?.deleteWorkout()
                        onDismiss()
                        dismiss()
                    }
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Tem certeza que deseja excluir este treino? Esta ação não pode ser desfeita.")
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: FitTodaySpacing.md) {
            ProgressView()
                .tint(FitTodayColor.brandPrimary)
            Text("Carregando treino...")
                .font(FitTodayFont.ui(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error View

    private var errorView: some View {
        VStack(spacing: FitTodaySpacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(FitTodayColor.warning)

            Text("Erro ao carregar treino")
                .font(FitTodayFont.ui(size: 17, weight: .semiBold))
                .foregroundStyle(FitTodayColor.textPrimary)

            if let error = viewModel?.errorMessage {
                Text(error)
                    .font(FitTodayFont.ui(size: 14, weight: .medium))
                    .foregroundStyle(FitTodayColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(FitTodaySpacing.lg)
    }

    // MARK: - Content View

    @ViewBuilder
    private func contentView(viewModel: EditWorkoutViewModel) -> some View {
        ScrollView {
            VStack(spacing: FitTodaySpacing.lg) {
                // Workout Name
                nameSection(viewModel: viewModel)

                // Exercises List
                exercisesSection(viewModel: viewModel)

                // Add Exercise Button
                addExerciseButton

                // Delete Workout Button
                deleteWorkoutButton

                Spacer(minLength: FitTodaySpacing.xxl)
            }
            .padding(FitTodaySpacing.md)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Name Section

    private func nameSection(viewModel: EditWorkoutViewModel) -> some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            Text("Nome do treino")
                .font(FitTodayFont.ui(size: 14, weight: .semiBold))
                .foregroundStyle(FitTodayColor.textSecondary)

            TextField("Ex: Treino A - Peito e Tríceps", text: Binding(
                get: { viewModel.workoutName },
                set: { viewModel.workoutName = $0 }
            ))
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

    // MARK: - Exercises Section

    private func exercisesSection(viewModel: EditWorkoutViewModel) -> some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            HStack {
                Text("Exercícios")
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
                exercisesList(viewModel: viewModel)
            }
        }
    }

    private var emptyExercisesView: some View {
        VStack(spacing: FitTodaySpacing.md) {
            Image(systemName: "plus.circle.dashed")
                .font(.system(size: 40))
                .foregroundStyle(FitTodayColor.textTertiary)

            Text("Nenhum exercício adicionado")
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

    private func exercisesList(viewModel: EditWorkoutViewModel) -> some View {
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
                Text("Adicionar Exercício")
            }
        }
        .fitSecondaryStyle()
    }

    // MARK: - Delete Workout Button

    private var deleteWorkoutButton: some View {
        Button {
            showDeleteConfirmation = true
        } label: {
            HStack(spacing: FitTodaySpacing.sm) {
                Image(systemName: "trash")
                Text("Excluir Treino")
            }
            .font(FitTodayFont.ui(size: 15, weight: .medium))
            .foregroundStyle(FitTodayColor.error)
            .frame(maxWidth: .infinity)
            .padding(FitTodaySpacing.md)
            .background(
                RoundedRectangle(cornerRadius: FitTodayRadius.md)
                    .fill(FitTodayColor.error.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ViewModel

@MainActor
@Observable
final class EditWorkoutViewModel {
    var workoutName = ""
    private(set) var exercises: [CustomExerciseEntry] = []
    private(set) var isLoading = false
    var errorMessage: String?

    private let resolver: Resolver
    private let workoutId: UUID
    private var originalWorkout: CustomWorkoutTemplate?

    var canSave: Bool {
        !workoutName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !exercises.isEmpty &&
        !isLoading
    }

    init(resolver: Resolver, workoutId: UUID) {
        self.resolver = resolver
        self.workoutId = workoutId
    }

    func loadWorkout() async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        guard let repository = resolver.resolve(CustomWorkoutRepository.self) else {
            errorMessage = "Repositório não disponível"
            return
        }

        do {
            guard let workout = try await repository.getTemplate(id: workoutId) else {
                errorMessage = "Treino não encontrado"
                return
            }

            originalWorkout = workout
            workoutName = workout.name
            exercises = workout.exercises

        } catch {
            errorMessage = "Erro ao carregar treino: \(error.localizedDescription)"
        }
    }

    func addExerciseEntry(_ entry: CustomExerciseEntry) {
        // Adicionar entrada já convertida pelo ExerciseSearchSheet
        var newEntry = entry
        newEntry.orderIndex = exercises.count
        exercises.append(newEntry)
    }

    func removeExercise(_ exercise: CustomExerciseEntry) {
        exercises.removeAll { $0.id == exercise.id }
    }

    func moveExercise(from source: IndexSet, to destination: Int) {
        exercises.move(fromOffsets: source, toOffset: destination)
    }

    func saveChanges() async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        guard let saveUseCase = resolver.resolve(SaveCustomWorkoutUseCase.self) else {
            errorMessage = "Serviço de salvamento não disponível"
            return
        }

        do {
            // Create updated template preserving original ID
            let updatedTemplate = CustomWorkoutTemplate(
                id: workoutId,
                name: workoutName.trimmingCharacters(in: .whitespacesAndNewlines),
                exercises: exercises,
                createdAt: originalWorkout?.createdAt ?? Date(),
                lastUsedAt: originalWorkout?.lastUsedAt
            )

            try await saveUseCase.execute(template: updatedTemplate)

            #if DEBUG
            print("[EditWorkout] Workout saved successfully: \(workoutName)")
            #endif

        } catch {
            errorMessage = "Erro ao salvar: \(error.localizedDescription)"
        }
    }

    func deleteWorkout() async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        guard let repository = resolver.resolve(CustomWorkoutRepository.self) else {
            errorMessage = "Repositório não disponível"
            return
        }

        do {
            try await repository.deleteTemplate(id: workoutId)

            #if DEBUG
            print("[EditWorkout] Workout deleted: \(workoutId)")
            #endif

        } catch {
            errorMessage = "Erro ao excluir: \(error.localizedDescription)"
        }
    }
}

// MARK: - Preview

#Preview {
    let container = Container()
    return EditWorkoutView(resolver: container, workoutId: UUID()) {}
        .preferredColorScheme(.dark)
}
