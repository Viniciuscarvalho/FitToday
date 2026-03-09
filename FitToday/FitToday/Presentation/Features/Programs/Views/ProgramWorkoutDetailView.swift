//
//  ProgramWorkoutDetailView.swift
//  FitToday
//
//  Tela de detalhe de um treino de programa, mostrando exercicios com imagens
//  e suporte a reordenacao e persistencia de customizacoes.
//

import SwiftUI
import Swinject

struct ProgramWorkoutDetailView: View {
    let workout: ProgramWorkout
    let resolver: Resolver

    @Environment(AppRouter.self) private var router
    @Environment(WorkoutSessionStore.self) private var sessionStore
    @State private var exercises: [ProgramExercise]
    @State private var deletedExerciseIds: Set<String> = []
    @State private var editMode: EditMode = .inactive
    @State private var showAddExercise = false
    @State private var isLoadingCustomization = true

    init(workout: ProgramWorkout, resolver: Resolver) {
        self.workout = workout
        self.resolver = resolver
        _exercises = State(initialValue: workout.exercises)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroSection
                statsRow
                exercisesSection
            }
            .padding(.bottom, 80)
        }
        .safeAreaInset(edge: .bottom) {
            if !exercises.isEmpty {
                startWorkoutButton
                    .padding(.horizontal, FitTodaySpacing.md)
                    .padding(.vertical, FitTodaySpacing.sm)
                    .background(.ultraThinMaterial)
            }
        }
        .background(FitTodayColor.background.ignoresSafeArea())
        .navigationTitle(workout.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation {
                        editMode = editMode == .active ? .inactive : .active
                    }
                } label: {
                    Text(editMode == .active ? "Concluido" : "Editar")
                        .font(.system(.subheadline, weight: .medium))
                }
            }
        }
        .environment(\.editMode, $editMode)
        .task {
            await loadCustomization()
        }
        .sheet(isPresented: $showAddExercise) {
            if let exerciseService = resolver.resolve(ExerciseServiceProtocol.self) {
                ExerciseSearchSheet(
                    exerciseService: exerciseService,
                    onSelect: { entry in
                        addExerciseEntry(entry)
                    }
                )
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            // First exercise image or gradient
            if let firstExercise = exercises.first {
                ExerciseImageView(
                    exerciseId: firstExercise.catalogExercise.id,
                    imageIndex: 0,
                    cornerRadius: 0
                )
                .frame(height: 250)
                .clipped()
            } else {
                LinearGradient(
                    colors: [.purple, .blue],
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )
                .frame(height: 250)
            }

            // Gradient overlay
            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .center,
                endPoint: .bottom
            )

            // Title
            VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                Spacer()
                Text(workout.title)
                    .font(.system(.title, weight: .bold))
                    .foregroundStyle(.white)

                Text(workout.subtitle)
                    .font(.system(.subheadline))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(FitTodaySpacing.lg)
        }
        .frame(height: 250)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: FitTodaySpacing.xl) {
            VStack(spacing: FitTodaySpacing.xs) {
                HStack(spacing: FitTodaySpacing.xs) {
                    Image(systemName: "flame")
                    Text("\(estimatedCalories)")
                        .font(.system(.title3, weight: .bold))
                }
                .foregroundStyle(FitTodayColor.brandPrimary)
                Text("Kcal Media")
                    .font(.system(.caption))
                    .foregroundStyle(FitTodayColor.textTertiary)
            }

            VStack(spacing: FitTodaySpacing.xs) {
                HStack(spacing: FitTodaySpacing.xs) {
                    Image(systemName: "clock")
                    Text("\(workout.estimatedDurationMinutes)")
                        .font(.system(.title3, weight: .bold))
                }
                .foregroundStyle(FitTodayColor.brandPrimary)
                Text("Minutos")
                    .font(.system(.caption))
                    .foregroundStyle(FitTodayColor.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(FitTodaySpacing.lg)
        .background(FitTodayColor.surface)
    }

    private var estimatedCalories: Int {
        workout.estimatedDurationMinutes * 5
    }

    // MARK: - Exercises Section

    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            HStack {
                Text("Exercicios (\(exercises.count))")
                    .font(.system(.headline, weight: .semibold))
                    .foregroundStyle(FitTodayColor.textPrimary)

                Spacer()

                if editMode == .active {
                    Button {
                        showAddExercise = true
                    } label: {
                        Label("Adicionar", systemImage: "plus")
                            .font(.system(.subheadline, weight: .medium))
                    }
                }
            }
            .padding(.horizontal)

            if exercises.isEmpty {
                emptyExercisesView
            } else {
                exercisesList
            }
        }
        .padding(.top, FitTodaySpacing.lg)
    }

    private var emptyExercisesView: some View {
        VStack(spacing: FitTodaySpacing.md) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 40))
                .foregroundStyle(FitTodayColor.textTertiary)
            Text("Nenhum exercicio encontrado")
                .font(.system(.subheadline))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(FitTodaySpacing.xl)
    }

    private var exercisesList: some View {
        LazyVStack(spacing: FitTodaySpacing.sm) {
            ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                ExerciseRowCard(
                    exercise: exercise,
                    editMode: editMode,
                    onMoveUp: editMode == .active && index > 0 ? {
                        moveExercise(from: IndexSet(integer: index), to: index - 1)
                    } : nil,
                    onMoveDown: editMode == .active && index < exercises.count - 1 ? {
                        moveExercise(from: IndexSet(integer: index), to: index + 2)
                    } : nil,
                    onDelete: editMode == .active ? {
                        deleteExercise(at: IndexSet(integer: index))
                    } : nil
                ) {
                    guard editMode != .active else { return }
                    let workoutExercise = createWorkoutExercise(from: exercise)
                    let prescription = ExercisePrescription(
                        exercise: workoutExercise,
                        sets: exercise.sets,
                        reps: IntRange(exercise.repsRange.lowerBound, exercise.repsRange.upperBound),
                        restInterval: TimeInterval(exercise.restSeconds),
                        tip: exercise.notes
                    )
                    router.push(.programExerciseDetail(prescription), on: router.selectedTab)
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Actions

    private func moveExercise(from source: IndexSet, to destination: Int) {
        exercises.move(fromOffsets: source, toOffset: destination)
        for (index, _) in exercises.enumerated() {
            exercises[index].order = index
        }
        Task { await saveCustomization() }
    }

    private func deleteExercise(at offsets: IndexSet) {
        for index in offsets {
            deletedExerciseIds.insert(exercises[index].id)
        }
        exercises.remove(atOffsets: offsets)
        for (index, _) in exercises.enumerated() {
            exercises[index].order = index
        }
        Task { await saveCustomization() }
    }

    private func addExerciseEntry(_ entry: CustomExerciseEntry) {
        let catalog = CatalogExercise(
            id: entry.exerciseId,
            name: entry.exerciseName
        )
        let newExercise = ProgramExercise(
            id: "\(workout.id)_added_\(exercises.count)",
            catalogExercise: catalog,
            sets: 3,
            repsRange: 8...12,
            restSeconds: 60,
            notes: nil,
            order: exercises.count
        )
        exercises.append(newExercise)
        Task { await saveCustomization() }
    }

    // MARK: - Customization Persistence

    private func loadCustomization() async {
        guard let repository = resolver.resolve(ProgramWorkoutCustomizationRepositoryProtocol.self) else {
            isLoadingCustomization = false
            return
        }

        if let customization = await repository.getCustomization(for: workout.id) {
            deletedExerciseIds = customization.deletedExerciseIds
            var filteredExercises = workout.exercises.filter { !customization.deletedExerciseIds.contains($0.id) }

            if !customization.exerciseOrder.isEmpty {
                let orderMap = Dictionary(uniqueKeysWithValues: customization.exerciseOrder.enumerated().map { ($1, $0) })
                filteredExercises.sort { ex1, ex2 in
                    let order1 = orderMap[ex1.id] ?? Int.max
                    let order2 = orderMap[ex2.id] ?? Int.max
                    return order1 < order2
                }
            }

            exercises = filteredExercises
        }

        isLoadingCustomization = false
    }

    private func saveCustomization() async {
        guard let repository = resolver.resolve(ProgramWorkoutCustomizationRepositoryProtocol.self) else {
            return
        }

        let customization = ProgramWorkoutCustomization(
            workoutId: workout.id,
            exerciseOrder: exercises.map { $0.id },
            deletedExerciseIds: deletedExerciseIds
        )

        await repository.saveCustomization(customization)
    }

    // MARK: - Start Workout Button

    private var startWorkoutButton: some View {
        Button {
            let customizedWorkout = ProgramWorkout(
                id: workout.id,
                templateId: workout.templateId,
                title: workout.title,
                subtitle: workout.subtitle,
                estimatedDurationMinutes: workout.estimatedDurationMinutes,
                exercises: exercises
            )
            sessionStore.start(with: customizedWorkout.toWorkoutPlan())
            router.push(.workoutExecution, on: router.selectedTab)
        } label: {
            HStack(spacing: FitTodaySpacing.sm) {
                Image(systemName: "play.fill")
                Text("Iniciar Treino")
                    .font(.system(.headline, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(FitTodayColor.brandPrimary)
            .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
        }
        .disabled(exercises.isEmpty || editMode == .active)
        .opacity(editMode == .active ? 0.5 : 1.0)
    }

    // MARK: - Conversion Helpers

    private func createWorkoutExercise(from programExercise: ProgramExercise) -> WorkoutExercise {
        let catalog = programExercise.catalogExercise
        let muscleGroup = MuscleGroup(rawValue: catalog.category ?? "") ?? .fullBody

        let instructions: [String] = {
            guard let desc = catalog.description, !desc.isEmpty else {
                return ["Realize o exercicio com boa tecnica."]
            }
            let lines = desc
                .components(separatedBy: CharacterSet.newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            return lines.isEmpty ? ["Realize o exercicio com boa tecnica."] : lines
        }()

        return WorkoutExercise(
            id: catalog.id,
            name: catalog.name,
            mainMuscle: muscleGroup,
            equipment: mapEquipment(catalog.equipment),
            instructions: instructions,
            media: nil
        )
    }

    private func mapEquipment(_ equipmentIds: [Int]) -> EquipmentType {
        guard let first = equipmentIds.first else { return .bodyweight }
        switch first {
        case 1: return .barbell
        case 3: return .dumbbell
        case 8: return .machine
        case 10: return .kettlebell
        case 7: return .bodyweight
        case 9: return .resistanceBand
        case 6: return .pullupBar
        default: return .bodyweight
        }
    }
}

// MARK: - Exercise Row Card

private struct ExerciseRowCard: View {
    let exercise: ProgramExercise
    let editMode: EditMode
    var onMoveUp: (() -> Void)?
    var onMoveDown: (() -> Void)?
    var onDelete: (() -> Void)?
    let onTap: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: FitTodaySpacing.sm) {
            if editMode == .active {
                VStack(spacing: FitTodaySpacing.xs) {
                    Button { onMoveUp?() } label: {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(onMoveUp != nil ? FitTodayColor.brandPrimary : FitTodayColor.textTertiary.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                    .disabled(onMoveUp == nil)

                    Button { onMoveDown?() } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(onMoveDown != nil ? FitTodayColor.brandPrimary : FitTodayColor.textTertiary.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                    .disabled(onMoveDown == nil)
                }
                .frame(width: 24)
            }

            Button(action: onTap) {
                HStack(spacing: FitTodaySpacing.md) {
                    // Circle image
                    ExerciseImageView(
                        exerciseId: exercise.catalogExercise.id,
                        imageIndex: 0,
                        cornerRadius: 26
                    )
                    .frame(width: 52, height: 52)
                    .clipShape(Circle())

                    // Exercise info
                    VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                        Text(exercise.name)
                            .font(.system(.subheadline, weight: .semibold))
                            .foregroundStyle(FitTodayColor.textPrimary)
                            .lineLimit(2)

                        Text("\(exercise.sets) series \u{2022} \(exercise.repsRange.lowerBound)-\(exercise.repsRange.upperBound) reps")
                            .font(.system(.caption))
                            .foregroundStyle(FitTodayColor.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(.caption2, weight: .semibold))
                        .foregroundStyle(FitTodayColor.textTertiary)
                }
                .padding(FitTodaySpacing.md)
                .background(FitTodayColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
            }
            .buttonStyle(.plain)

            if editMode == .active {
                Button { onDelete?() } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundStyle(FitTodayColor.error)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    let sampleExercise = CatalogExercise(
        id: "barbell_bench_press",
        name: "Supino Reto com Barra",
        description: "Deite no banco com os pes apoiados no chao...",
        category: "chest",
        muscles: [3],
        musclesSecondary: [],
        equipment: [1]
    )

    let programExercise = ProgramExercise(
        id: "test_1",
        catalogExercise: sampleExercise,
        sets: 4,
        repsRange: 8...12,
        restSeconds: 90,
        notes: nil,
        order: 0
    )

    let workout = ProgramWorkout(
        id: "test_workout",
        templateId: "lib_push_beginner_gym",
        title: "Treino 1 - Push",
        subtitle: "Peito, Ombros e Triceps",
        estimatedDurationMinutes: 45,
        exercises: [programExercise]
    )

    let container = Container()
    return NavigationStack {
        ProgramWorkoutDetailView(workout: workout, resolver: container)
    }
    .environment(AppRouter())
}
