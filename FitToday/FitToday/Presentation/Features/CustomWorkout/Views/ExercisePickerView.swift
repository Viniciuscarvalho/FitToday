//
//  ExercisePickerView.swift
//  FitToday
//
//  Modal view for searching and selecting exercises from Wger API.
//

import SwiftUI

/// Modal view for searching and selecting exercises.
struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ExercisePickerViewModel

    let onSelect: (WgerExercise) -> Void

    init(
        exerciseService: ExerciseServiceProtocol? = nil,
        onSelect: @escaping (WgerExercise) -> Void
    ) {
        _viewModel = State(initialValue: ExercisePickerViewModel(exerciseService: exerciseService))
        self.onSelect = onSelect
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                searchBar

                // Filters
                filtersSection

                // Exercise list
                exerciseList
            }
            .navigationTitle("Adicionar Exercício")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }

                if viewModel.selectedCategory != nil || viewModel.selectedEquipment != nil {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Limpar") {
                            viewModel.clearFilters()
                        }
                    }
                }
            }
            .task {
                await viewModel.loadInitialExercises()
            }
        }
    }

    // MARK: - Subviews

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(FitTodayColor.textTertiary)

            TextField("Buscar exercícios...", text: $viewModel.searchText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .foregroundStyle(FitTodayColor.textPrimary)

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(FitTodayColor.textTertiary)
                }
            }
        }
        .padding()
        .background(FitTodayColor.surface)
    }

    private var filtersSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: FitTodaySpacing.sm) {
                // Category filters
                ForEach(viewModel.categories, id: \.self) { category in
                    FilterChip(
                        title: category.portugueseName,
                        isSelected: viewModel.selectedCategory == category
                    ) {
                        viewModel.selectCategory(category)
                    }
                }

                Divider()
                    .frame(height: 24)
                    .background(FitTodayColor.outline)

                // Equipment filters
                ForEach(viewModel.equipmentTypes, id: \.self) { equipment in
                    FilterChip(
                        title: equipment.portugueseName,
                        isSelected: viewModel.selectedEquipment == equipment
                    ) {
                        viewModel.selectEquipment(equipment)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, FitTodaySpacing.sm)
        .background(FitTodayColor.surface.opacity(0.5))
    }

    private var exerciseList: some View {
        List(viewModel.exercises, id: \.id) { exercise in
            Button {
                onSelect(exercise)
                dismiss()
            } label: {
                ExerciseListRow(exercise: exercise)
            }
            .buttonStyle(.plain)
            .listRowBackground(FitTodayColor.surface)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(FitTodayColor.background)
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .tint(FitTodayColor.brandPrimary)
            } else if viewModel.exercises.isEmpty && !viewModel.searchText.isEmpty {
                ContentUnavailableView.search(text: viewModel.searchText)
            } else if viewModel.exercises.isEmpty {
                ContentUnavailableView(
                    "Nenhum Exercício",
                    systemImage: "figure.strengthtraining.traditional",
                    description: Text("Busque exercícios ou selecione uma categoria")
                )
            }
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(FitTodayFont.ui(size: 13, weight: isSelected ? .bold : .medium))
                .padding(.horizontal, FitTodaySpacing.sm)
                .padding(.vertical, FitTodaySpacing.xs)
                .background(isSelected ? FitTodayColor.brandPrimary.opacity(0.2) : FitTodayColor.surface)
                .foregroundStyle(isSelected ? FitTodayColor.brandPrimary : FitTodayColor.textSecondary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? FitTodayColor.brandPrimary : FitTodayColor.outline, lineWidth: 1)
                )
        }
    }
}

// MARK: - Exercise List Row

struct ExerciseListRow: View {
    let exercise: WgerExercise

    var body: some View {
        HStack(spacing: FitTodaySpacing.md) {
            // Placeholder thumbnail
            Image(systemName: iconForCategory)
                .font(.title2)
                .foregroundStyle(FitTodayColor.brandPrimary)
                .frame(width: 50, height: 50)
                .background(FitTodayColor.brandPrimary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.sm))

            VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                Text(exercise.name)
                    .font(FitTodayFont.ui(size: 15, weight: .semiBold))
                    .foregroundStyle(FitTodayColor.textPrimary)
                    .lineLimit(2)

                HStack(spacing: FitTodaySpacing.sm) {
                    if let categoryId = exercise.category,
                       let category = WgerCategoryMapping.from(id: categoryId) {
                        Label(category.portugueseName, systemImage: "figure.stand")
                            .font(FitTodayFont.ui(size: 12, weight: .medium))
                            .foregroundStyle(FitTodayColor.textSecondary)
                    }

                    if let equipmentId = exercise.equipment.first,
                       let equipment = WgerEquipmentMapping.from(id: equipmentId) {
                        Label(equipment.portugueseName, systemImage: "dumbbell")
                            .font(FitTodayFont.ui(size: 12, weight: .medium))
                            .foregroundStyle(FitTodayColor.textSecondary)
                    }
                }
            }

            Spacer()

            Image(systemName: "plus.circle.fill")
                .foregroundStyle(FitTodayColor.brandPrimary)
        }
        .contentShape(Rectangle())
    }

    private var iconForCategory: String {
        guard let categoryId = exercise.category,
              let category = WgerCategoryMapping.from(id: categoryId) else {
            return "figure.strengthtraining.traditional"
        }

        switch category {
        case .arms:
            return "figure.strengthtraining.traditional"
        case .legs:
            return "figure.run"
        case .abs:
            return "figure.core.training"
        case .chest:
            return "figure.strengthtraining.functional"
        case .back:
            return "figure.rowing"
        case .shoulders:
            return "figure.boxing"
        case .calves:
            return "figure.walk"
        case .cardio:
            return "figure.run.circle"
        }
    }
}

// MARK: - Preview

#Preview {
    ExercisePickerView { exercise in
        print("Selected: \(exercise.name)")
    }
    .preferredColorScheme(.dark)
}
