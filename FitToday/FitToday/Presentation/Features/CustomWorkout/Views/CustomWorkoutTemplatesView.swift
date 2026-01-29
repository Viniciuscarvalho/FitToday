//
//  CustomWorkoutTemplatesView.swift
//  FitToday
//
//  Created by Claude on 28/01/26.
//

import SwiftUI
import Swinject

/// View for listing and managing saved workout templates
struct CustomWorkoutTemplatesView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel: CustomWorkoutTemplatesViewModel

    private let resolver: Resolver

    init(resolver: Resolver) {
        self.resolver = resolver
        guard let repository = resolver.resolve(CustomWorkoutRepository.self) else {
            fatalError("CustomWorkoutRepository not registered")
        }
        _viewModel = State(initialValue: CustomWorkoutTemplatesViewModel(repository: repository))
    }

    var body: some View {
        Group {
            if viewModel.templates.isEmpty && !viewModel.isLoading {
                ContentUnavailableView(
                    "No Custom Workouts",
                    systemImage: "figure.strengthtraining.traditional",
                    description: Text("Create your first custom workout to get started")
                )
            } else {
                List {
                    ForEach(viewModel.templates) { template in
                        Button {
                            viewModel.selectTemplate(template)
                        } label: {
                            TemplateRow(template: template)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                viewModel.confirmDelete(template)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            Button {
                                viewModel.editTemplate(template)
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.orange)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    await viewModel.loadTemplates()
                }
            }
        }
        .navigationTitle("My Workouts")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.showCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(item: $viewModel.selectedTemplate) { template in
            NavigationStack {
                ActiveCustomWorkoutView(template: template)
            }
        }
        .sheet(isPresented: $viewModel.showCreateSheet) {
            createWorkoutBuilderView(templateId: nil)
        }
        .sheet(item: $viewModel.templateToEdit) { template in
            createWorkoutBuilderView(templateId: template.id)
        }
        .confirmationDialog(
            "Delete Workout",
            isPresented: .init(
                get: { viewModel.templateToDelete != nil },
                set: { if !$0 { viewModel.cancelDelete() } }
            ),
            presenting: viewModel.templateToDelete
        ) { template in
            Button("Delete \"\(template.name)\"", role: .destructive) {
                Task { await viewModel.performDelete() }
            }
            Button("Cancel", role: .cancel) {
                viewModel.cancelDelete()
            }
        } message: { template in
            Text("This will permanently delete this workout template.")
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .task {
            await viewModel.loadTemplates()
        }
    }

    @ViewBuilder
    private func createWorkoutBuilderView(templateId: UUID?) -> some View {
        if let saveUseCase = resolver.resolve(SaveCustomWorkoutUseCase.self) {
            let exerciseService = resolver.resolve((any ExerciseServiceProtocol).self)
            CustomWorkoutBuilderView(
                viewModel: CustomWorkoutBuilderViewModel(
                    saveUseCase: saveUseCase,
                    existingTemplateId: templateId,
                    exerciseService: exerciseService
                )
            )
        } else {
            Text("Unable to load workout builder")
        }
    }
}

// MARK: - Template Row

struct TemplateRow: View {
    let template: CustomWorkoutTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(template.name)
                    .font(.headline)

                Spacer()

                if let category = template.category {
                    Text(category)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.2))
                        .clipShape(Capsule())
                }
            }

            HStack(spacing: 16) {
                Label("\(template.exerciseCount) exercises", systemImage: "figure.strengthtraining.traditional")
                Label("\(template.totalSets) sets", systemImage: "number")
                Label("~\(template.estimatedDurationMinutes) min", systemImage: "clock")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if let lastUsed = template.lastUsedAt {
                Text("Last used \(lastUsed, style: .relative) ago")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Placeholder Active Workout View

struct ActiveCustomWorkoutView: View {
    let template: CustomWorkoutTemplate

    var body: some View {
        VStack {
            Text("Start Workout: \(template.name)")
                .font(.title)
            Text("Active workout view coming soon")
                .foregroundStyle(.secondary)
        }
        .navigationTitle(template.name)
    }
}

// MARK: - Preview

#Preview {
    let container = Container()
    container.register(CustomWorkoutRepository.self) { _ in PreviewRepository() }
    container.register(SaveCustomWorkoutUseCase.self) { r in
        SaveCustomWorkoutUseCase(repository: r.resolve(CustomWorkoutRepository.self)!)
    }
    // Note: ExerciseServiceProtocol registration is optional for previews

    return CustomWorkoutTemplatesView(resolver: container)
        .environment(AppRouter())
}

private struct PreviewRepository: CustomWorkoutRepository {
    func listTemplates() async throws -> [CustomWorkoutTemplate] {
        [
            CustomWorkoutTemplate(
                name: "Push Day",
                exercises: [
                    CustomExerciseEntry(
                        exerciseId: "1",
                        exerciseName: "Bench Press",
                        orderIndex: 0,
                        sets: [WorkoutSet(), WorkoutSet(), WorkoutSet()]
                    )
                ],
                category: "Push"
            ),
            CustomWorkoutTemplate(
                name: "Pull Day",
                exercises: [],
                category: "Pull"
            )
        ]
    }

    func getTemplate(id: UUID) async throws -> CustomWorkoutTemplate? { nil }
    func saveTemplate(_ template: CustomWorkoutTemplate) async throws {}
    func deleteTemplate(id: UUID) async throws {}
    func recordCompletion(templateId: UUID, actualExercises: [CustomExerciseEntry], duration: Int, completedAt: Date) async throws {}
    func getCompletionHistory(templateId: UUID) async throws -> [CustomWorkoutCompletion] { [] }
    func updateLastUsed(id: UUID) async throws {}
}
