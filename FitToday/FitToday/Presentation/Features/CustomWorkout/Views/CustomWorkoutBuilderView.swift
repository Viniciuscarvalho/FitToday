//
//  CustomWorkoutBuilderView.swift
//  FitToday
//
//  Created by Claude on 28/01/26.
//

import SwiftUI

/// Main view for creating and editing custom workout templates
struct CustomWorkoutBuilderView: View {
    @State private var viewModel: CustomWorkoutBuilderViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: CustomWorkoutBuilderViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            List {
                // Workout name section
                Section {
                    TextField("Workout Name", text: $viewModel.name)
                        .font(.title3)
                } header: {
                    Text("Name")
                } footer: {
                    Text("Give your workout a memorable name")
                }

                // Exercises section
                Section {
                    if viewModel.exercises.isEmpty {
                        ContentUnavailableView(
                            "No Exercises",
                            systemImage: "figure.strengthtraining.traditional",
                            description: Text("Tap the button below to add exercises")
                        )
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(Array(viewModel.exercises.enumerated()), id: \.element.id) { index, exercise in
                            ExerciseRowView(
                                exercise: exercise,
                                onAddSet: { viewModel.addSet(to: index) },
                                onRemoveSet: { setIndex in viewModel.removeSet(from: index, at: setIndex) },
                                onUpdateSet: { setIndex, reps, weight in
                                    viewModel.updateSet(exerciseIndex: index, setIndex: setIndex, reps: reps, weight: weight)
                                }
                            )
                        }
                        .onMove { viewModel.moveExercise(from: $0, to: $1) }
                        .onDelete { indexSet in
                            indexSet.forEach { viewModel.removeExercise(at: $0) }
                        }
                    }

                    // Add exercise button
                    Button {
                        viewModel.showExercisePicker = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Exercise")
                        }
                    }
                } header: {
                    HStack {
                        Text("Exercises")
                        Spacer()
                        if !viewModel.exercises.isEmpty {
                            Text("\(viewModel.exercises.count) exercises")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Summary section
                if !viewModel.exercises.isEmpty {
                    Section("Summary") {
                        LabeledContent("Total Sets", value: "\(viewModel.totalSets)")
                        LabeledContent("Est. Duration", value: "~\(viewModel.estimatedDuration) min")
                    }
                }
            }
            .navigationTitle(viewModel.isEditing ? "Edit Workout" : "New Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            do {
                                _ = try await viewModel.save()
                                dismiss()
                            } catch {
                                // Error is shown via viewModel.error
                            }
                        }
                    }
                    .disabled(!viewModel.canSave || viewModel.isLoading)
                }

                ToolbarItem(placement: .primaryAction) {
                    EditButton()
                        .disabled(viewModel.exercises.isEmpty)
                }
            }
            .sheet(isPresented: $viewModel.showExercisePicker) {
                ExercisePickerView(exerciseService: viewModel.exerciseService) { exercise in
                    viewModel.addExercise(from: exercise, imageURL: nil)
                }
            }
            .alert("Error", isPresented: .init(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )) {
                Button("OK") { viewModel.error = nil }
            } message: {
                Text(viewModel.error?.localizedDescription ?? "An error occurred")
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.ultraThinMaterial)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    CustomWorkoutBuilderView(
        viewModel: CustomWorkoutBuilderViewModel(
            saveUseCase: SaveCustomWorkoutUseCase(
                repository: PreviewCustomWorkoutRepository()
            )
        )
    )
}

// MARK: - Preview Repository

private struct PreviewCustomWorkoutRepository: CustomWorkoutRepository {
    func listTemplates() async throws -> [CustomWorkoutTemplate] { [] }
    func getTemplate(id: UUID) async throws -> CustomWorkoutTemplate? { nil }
    func saveTemplate(_ template: CustomWorkoutTemplate) async throws {}
    func deleteTemplate(id: UUID) async throws {}
    func recordCompletion(templateId: UUID, actualExercises: [CustomExerciseEntry], duration: Int, completedAt: Date) async throws {}
    func getCompletionHistory(templateId: UUID) async throws -> [CustomWorkoutCompletion] { [] }
    func updateLastUsed(id: UUID) async throws {}
}
