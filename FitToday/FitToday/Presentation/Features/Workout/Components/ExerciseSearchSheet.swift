//
//  ExerciseSearchSheet.swift
//  FitToday
//
//  Sheet for searching and selecting exercises from Wger API.
//

import SwiftUI

/// Sheet for searching and adding exercises to a workout.
struct ExerciseSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (CustomExerciseEntry) -> Void

    @State private var searchText = ""
    @State private var selectedCategory: Int?
    @State private var selectedEquipment: Int?
    @State private var exercises: [WgerExercise] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search and filters
                VStack(spacing: FitTodaySpacing.sm) {
                    searchBar
                    filtersRow
                }
                .padding(FitTodaySpacing.md)

                Divider()
                    .background(FitTodayColor.outline)

                // Results
                if isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(error)
                } else if exercises.isEmpty {
                    emptyView
                } else {
                    resultsList
                }
            }
            .background(FitTodayColor.background)
            .navigationTitle("Adicionar Exercício")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundStyle(FitTodayColor.textSecondary)
                }
            }
            .task {
                await loadInitialExercises()
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: FitTodaySpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundStyle(FitTodayColor.textTertiary)

            TextField("Buscar exercícios...", text: $searchText)
                .font(FitTodayFont.ui(size: 15, weight: .medium))
                .foregroundStyle(FitTodayColor.textPrimary)
                .submitLabel(.search)
                .onSubmit {
                    Task {
                        await searchExercises()
                    }
                }

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

    // MARK: - Filters

    private var filtersRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: FitTodaySpacing.sm) {
                // Category filter
                Menu {
                    Button("Todos") { selectedCategory = nil }
                    ForEach(WgerCategoryMapping.allCases, id: \.rawValue) { category in
                        Button(category.portugueseName) {
                            selectedCategory = category.rawValue
                        }
                    }
                } label: {
                    filterChip(
                        title: selectedCategory.flatMap { WgerCategoryMapping.from(id: $0)?.portugueseName } ?? "Músculo",
                        isActive: selectedCategory != nil
                    )
                }

                // Equipment filter
                Menu {
                    Button("Todos") { selectedEquipment = nil }
                    ForEach(WgerEquipmentMapping.allCases, id: \.rawValue) { equipment in
                        Button(equipment.portugueseName) {
                            selectedEquipment = equipment.rawValue
                        }
                    }
                } label: {
                    filterChip(
                        title: selectedEquipment.flatMap { WgerEquipmentMapping.from(id: $0)?.portugueseName } ?? "Equipamento",
                        isActive: selectedEquipment != nil
                    )
                }

                // Clear filters
                if selectedCategory != nil || selectedEquipment != nil {
                    Button {
                        selectedCategory = nil
                        selectedEquipment = nil
                    } label: {
                        Text("Limpar")
                            .font(FitTodayFont.ui(size: 13, weight: .medium))
                            .foregroundStyle(FitTodayColor.error)
                    }
                }
            }
        }
        .onChange(of: selectedCategory) { _, _ in
            Task { await loadFilteredExercises() }
        }
        .onChange(of: selectedEquipment) { _, _ in
            Task { await loadFilteredExercises() }
        }
    }

    private func filterChip(title: String, isActive: Bool) -> some View {
        HStack(spacing: FitTodaySpacing.xs) {
            Text(title)
                .font(FitTodayFont.ui(size: 13, weight: isActive ? .bold : .medium))
                .foregroundStyle(isActive ? FitTodayColor.brandPrimary : FitTodayColor.textSecondary)

            Image(systemName: "chevron.down")
                .font(.system(size: 10))
                .foregroundStyle(isActive ? FitTodayColor.brandPrimary : FitTodayColor.textTertiary)
        }
        .padding(.horizontal, FitTodaySpacing.sm)
        .padding(.vertical, FitTodaySpacing.xs)
        .background(
            Capsule()
                .fill(isActive ? FitTodayColor.brandPrimary.opacity(0.1) : FitTodayColor.surface)
        )
        .overlay(
            Capsule()
                .stroke(isActive ? FitTodayColor.brandPrimary : FitTodayColor.outline, lineWidth: 1)
        )
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: FitTodaySpacing.md) {
            ProgressView()
                .tint(FitTodayColor.brandPrimary)
            Text("Buscando exercícios...")
                .font(FitTodayFont.ui(size: 15, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        VStack(spacing: FitTodaySpacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(FitTodayColor.warning)

            Text(message)
                .font(FitTodayFont.ui(size: 15, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
                .multilineTextAlignment(.center)

            Button("Tentar novamente") {
                Task { await loadInitialExercises() }
            }
            .fitSecondaryStyle()
            .frame(width: 160)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty View

    private var emptyView: some View {
        VStack(spacing: FitTodaySpacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(FitTodayColor.textTertiary)

            Text("Nenhum exercício encontrado")
                .font(FitTodayFont.ui(size: 15, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)

            Text("Tente buscar por outro termo ou ajuste os filtros")
                .font(FitTodayFont.ui(size: 13, weight: .medium))
                .foregroundStyle(FitTodayColor.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Results List

    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: FitTodaySpacing.sm) {
                ForEach(exercises) { exercise in
                    ExerciseSearchResultRow(exercise: exercise) {
                        selectExercise(exercise)
                    }
                }
            }
            .padding(FitTodaySpacing.md)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Actions

    private func loadInitialExercises() async {
        isLoading = true
        errorMessage = nil

        // TODO: Use actual WgerAPIService
        try? await Task.sleep(for: .milliseconds(500))

        // Mock data for now
        exercises = []
        isLoading = false
    }

    private func searchExercises() async {
        guard !searchText.isEmpty else {
            await loadInitialExercises()
            return
        }

        isLoading = true
        errorMessage = nil

        // TODO: Use actual WgerAPIService
        try? await Task.sleep(for: .milliseconds(300))

        exercises = []
        isLoading = false
    }

    private func loadFilteredExercises() async {
        isLoading = true
        errorMessage = nil

        // TODO: Use actual WgerAPIService with filters
        try? await Task.sleep(for: .milliseconds(300))

        exercises = []
        isLoading = false
    }

    private func selectExercise(_ exercise: WgerExercise) {
        let entry = CustomExerciseEntry(from: exercise, orderIndex: 0)
        onSelect(entry)
        dismiss()
    }
}

// MARK: - Exercise Search Result Row

struct ExerciseSearchResultRow: View {
    let exercise: WgerExercise
    let onSelect: () -> Void

    var body: some View {
        Button {
            onSelect()
        } label: {
            HStack(spacing: FitTodaySpacing.md) {
                // Placeholder image
                ExercisePlaceholderView(
                    muscleGroup: exercise.category.flatMap { WgerCategoryMapping.from(id: $0)?.muscleGroup } ?? .fullBody,
                    size: .medium
                )

                // Exercise info
                VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                    Text(exercise.name)
                        .font(FitTodayFont.ui(size: 15, weight: .semiBold))
                        .foregroundStyle(FitTodayColor.textPrimary)
                        .lineLimit(2)

                    HStack(spacing: FitTodaySpacing.sm) {
                        if let category = exercise.category,
                           let mapping = WgerCategoryMapping.from(id: category) {
                            Text(mapping.portugueseName)
                                .font(FitTodayFont.ui(size: 12, weight: .medium))
                                .foregroundStyle(FitTodayColor.brandSecondary)
                        }

                        if let equipmentId = exercise.equipment.first,
                           let mapping = WgerEquipmentMapping.from(id: equipmentId) {
                            Text(mapping.portugueseName)
                                .font(FitTodayFont.ui(size: 12, weight: .medium))
                                .foregroundStyle(FitTodayColor.textTertiary)
                        }
                    }
                }

                Spacer()

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(FitTodayColor.brandPrimary)
            }
            .padding(FitTodaySpacing.md)
            .background(
                RoundedRectangle(cornerRadius: FitTodayRadius.sm)
                    .fill(FitTodayColor.surface)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ExerciseSearchSheet { exercise in
        print("Selected: \(exercise.exerciseName)")
    }
    .preferredColorScheme(.dark)
}
