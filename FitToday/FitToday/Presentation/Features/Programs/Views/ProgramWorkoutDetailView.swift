//
//  ProgramWorkoutDetailView.swift
//  FitToday
//
//  Tela de detalhe de um treino de programa, mostrando exercícios da API Wger
//  com suporte a reordenação e persistência de customizações.
//

import SwiftUI
import Swinject

struct ProgramWorkoutDetailView: View {
    let workout: ProgramWorkout
    let resolver: Resolver

    @Environment(AppRouter.self) private var router
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
            VStack(spacing: FitTodaySpacing.lg) {
                headerSection
                exercisesSection
                startWorkoutButton
            }
            .padding(.bottom, FitTodaySpacing.xl)
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
                    Text(editMode == .active ? "Concluído" : "Editar")
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

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            // Subtitle
            Text(workout.subtitle)
                .font(.system(.subheadline))
                .foregroundStyle(FitTodayColor.textSecondary)

            // Stats row
            HStack(spacing: FitTodaySpacing.lg) {
                StatBadge(
                    icon: "clock",
                    value: "\(workout.estimatedDurationMinutes)",
                    label: "min"
                )

                StatBadge(
                    icon: "figure.run",
                    value: "\(exercises.count)",
                    label: "exercícios"
                )

                StatBadge(
                    icon: "flame",
                    value: "\(estimatedCalories)",
                    label: "kcal"
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(FitTodaySpacing.lg)
        .background(FitTodayColor.surface)
    }

    private var estimatedCalories: Int {
        // Rough estimate: 5 kcal per minute of exercise
        workout.estimatedDurationMinutes * 5
    }

    // MARK: - Exercises Section

    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            HStack {
                Text("Exercícios")
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
        .padding(.top, FitTodaySpacing.md)
    }

    private var emptyExercisesView: some View {
        VStack(spacing: FitTodaySpacing.md) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 40))
                .foregroundStyle(FitTodayColor.textTertiary)

            Text("Nenhum exercício encontrado")
                .font(.system(.subheadline))
                .foregroundStyle(FitTodayColor.textSecondary)

            Text("Não foi possível carregar os exercícios da API")
                .font(.system(.caption))
                .foregroundStyle(FitTodayColor.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(FitTodaySpacing.xl)
    }

    private var exercisesList: some View {
        LazyVStack(spacing: FitTodaySpacing.sm) {
            ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                ExerciseRowCard(
                    exercise: exercise,
                    index: index + 1,
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
        // Update order values
        for (index, _) in exercises.enumerated() {
            exercises[index].order = index
        }

        #if DEBUG
        print("[ProgramWorkoutDetail] 📦 Moved exercises, new order:")
        for (i, ex) in exercises.enumerated() {
            print("  \(i+1). \(ex.name)")
        }
        #endif

        Task {
            await saveCustomization()
        }
    }

    private func deleteExercise(at offsets: IndexSet) {
        // Track deleted exercises
        for index in offsets {
            deletedExerciseIds.insert(exercises[index].id)
        }

        exercises.remove(atOffsets: offsets)
        // Update order values
        for (index, _) in exercises.enumerated() {
            exercises[index].order = index
        }

        #if DEBUG
        print("[ProgramWorkoutDetail] 🗑️ Deleted exercise(s)")
        #endif

        Task {
            await saveCustomization()
        }
    }

    private func addExerciseEntry(_ entry: CustomExerciseEntry) {
        // Convert CustomExerciseEntry back to WgerExercise + ProgramExercise
        let wger = WgerExercise(
            id: Int(entry.exerciseId) ?? 0,
            uuid: entry.id.uuidString,
            name: entry.exerciseName,
            exerciseBaseId: Int(entry.exerciseId) ?? 0,
            description: nil,
            category: nil,
            muscles: [],
            musclesSecondary: [],
            equipment: [],
            language: 2,
            mainImageURL: entry.exerciseGifURL,
            imageURLs: entry.exerciseGifURL.map { [$0] } ?? []
        )
        let newExercise = ProgramExercise(
            id: "\(workout.id)_added_\(exercises.count)",
            wgerExercise: wger,
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
            // Apply saved customization
            deletedExerciseIds = customization.deletedExerciseIds

            // Filter out deleted exercises
            var filteredExercises = workout.exercises.filter { !customization.deletedExerciseIds.contains($0.id) }

            // Reorder based on saved order
            if !customization.exerciseOrder.isEmpty {
                let orderMap = Dictionary(uniqueKeysWithValues: customization.exerciseOrder.enumerated().map { ($1, $0) })
                filteredExercises.sort { ex1, ex2 in
                    let order1 = orderMap[ex1.id] ?? Int.max
                    let order2 = orderMap[ex2.id] ?? Int.max
                    return order1 < order2
                }
            }

            exercises = filteredExercises

            #if DEBUG
            print("[ProgramWorkoutDetail] 📂 Loaded customization: \(customization.exerciseOrder.count) ordered, \(customization.deletedExerciseIds.count) deleted")
            #endif
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
            // Create a workout with the current (potentially customized) exercise list
            let customizedWorkout = ProgramWorkout(
                id: workout.id,
                templateId: workout.templateId,
                title: workout.title,
                subtitle: workout.subtitle,
                estimatedDurationMinutes: workout.estimatedDurationMinutes,
                exercises: exercises
            )
            router.push(.workoutPreview(customizedWorkout), on: router.selectedTab)
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
        .padding(.horizontal)
    }

    // MARK: - Conversion Helpers

    private func createWorkoutExercise(from programExercise: ProgramExercise) -> WorkoutExercise {
        let wger = programExercise.wgerExercise

        // Map Wger category ID to MuscleGroup
        let muscleGroup = mapCategoryToMuscleGroup(wger.category)

        // Create ExerciseMedia from Wger image URLs
        let media: ExerciseMedia? = {
            // Prioritize main image, fallback to first image in list
            let imageURL = wger.mainImageURL.flatMap { URL(string: $0) }
                ?? wger.imageURLs.first.flatMap { URL(string: $0) }
            guard imageURL != nil else { return nil }
            return ExerciseMedia(imageURL: imageURL, gifURL: nil)
        }()

        // Map instructions from description
        let instructions: [String] = {
            guard let desc = wger.description, !desc.isEmpty else {
                return ["Realize o exercício com boa técnica."]
            }
            let lines = desc
                .components(separatedBy: CharacterSet.newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            return lines.isEmpty ? ["Realize o exercício com boa técnica."] : lines
        }()

        return WorkoutExercise(
            id: String(wger.id),
            name: wger.name,
            mainMuscle: muscleGroup,
            equipment: mapEquipment(wger.equipment),
            instructions: instructions,
            media: media
        )
    }

    private func mapCategoryToMuscleGroup(_ categoryId: Int?) -> MuscleGroup {
        guard let categoryId else { return .fullBody }

        // Map Wger category IDs to MuscleGroup
        // Valid categories: 8=Arms, 9=Legs, 10=Abs, 11=Chest, 12=Back, 13=Shoulders, 14=Calves, 15=Cardio
        switch categoryId {
        case 8:  return .arms          // Arms (biceps + triceps)
        case 9:  return .quads         // Legs
        case 10: return .core          // Abs
        case 11: return .chest         // Chest
        case 12: return .back          // Back
        case 13: return .shoulders     // Shoulders
        case 14: return .calves        // Calves
        case 15: return .cardioSystem  // Cardio
        default: return .fullBody
        }
    }

    private func mapEquipment(_ equipmentIds: [Int]) -> EquipmentType {
        guard let first = equipmentIds.first else { return .bodyweight }

        // Map Wger equipment IDs to EquipmentType
        switch first {
        case 1: return .barbell        // Barbell
        case 3: return .dumbbell       // Dumbbell
        case 8: return .machine        // Gym mat (general gym)
        case 10: return .kettlebell    // Kettlebell
        case 7: return .bodyweight     // None (bodyweight)
        case 9: return .resistanceBand // Incline bench
        case 6: return .pullupBar      // Pull-up bar
        default: return .bodyweight
        }
    }

    private func muscleNames(for muscleIds: [Int]) -> String {
        let names = muscleIds.compactMap { muscleIdToName($0) }
        return names.isEmpty ? "Vários músculos" : names.joined(separator: ", ")
    }

    private func muscleIdToName(_ muscleId: Int) -> String? {
        // Map Wger muscle IDs to readable names
        switch muscleId {
        case 1: return "Bíceps"
        case 2: return "Deltóides"
        case 3: return "Peito"
        case 4: return "Tríceps"
        case 5: return "Abdominais"
        case 6: return "Glúteos"
        case 7: return "Adutor"
        case 8: return "Abdutores"
        case 9: return "Quadríceps"
        case 10: return "Isquiotibiais"
        case 11: return "Panturrilhas"
        case 12: return "Dorsais"
        case 13: return "Trapézio"
        case 14: return "Serrátil"
        case 15: return "Lombar"
        default: return nil
        }
    }
}

// MARK: - Stat Badge

private struct StatBadge: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: FitTodaySpacing.xs) {
            HStack(spacing: FitTodaySpacing.xs) {
                Image(systemName: icon)
                    .font(.system(.caption))
                Text(value)
                    .font(.system(.headline, weight: .bold))
            }
            .foregroundStyle(FitTodayColor.brandPrimary)

            Text(label)
                .font(.system(.caption))
                .foregroundStyle(FitTodayColor.textTertiary)
        }
    }
}

// MARK: - Exercise Row Card (Hevy-style)

private struct ExerciseRowCard: View {
    let exercise: ProgramExercise
    let index: Int
    let editMode: EditMode
    var onMoveUp: (() -> Void)?
    var onMoveDown: (() -> Void)?
    var onDelete: (() -> Void)?
    let onTap: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: FitTodaySpacing.sm) {
            // Reorder controls in edit mode
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
                .padding(.top, FitTodaySpacing.sm)
            }

            Button(action: onTap) {
                VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
                    // Header: circle image + title + rest timer
                    HStack(spacing: FitTodaySpacing.sm) {
                        exerciseCircleImage

                        VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                            Text(exercise.name)
                                .font(.system(.subheadline, weight: .semibold))
                                .foregroundStyle(FitTodayColor.brandPrimary)
                                .lineLimit(2)

                            if !exercise.wgerExercise.muscles.isEmpty {
                                Text(Self.muscleNames(for: exercise.wgerExercise.muscles))
                                    .font(.system(.caption2))
                                    .foregroundStyle(FitTodayColor.textTertiary)
                                    .lineLimit(1)
                            }
                        }

                        Spacer()

                        // Rest timer badge
                        HStack(spacing: 3) {
                            Image(systemName: "timer")
                                .font(.system(size: 11))
                            Text(restTimerLabel)
                                .font(.system(.caption2, weight: .medium))
                        }
                        .foregroundStyle(FitTodayColor.textSecondary)
                        .padding(.horizontal, FitTodaySpacing.sm)
                        .padding(.vertical, 4)
                        .background(FitTodayColor.surface)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(FitTodayColor.outline.opacity(0.2), lineWidth: 1))
                    }

                    // SET | KG | REP RANGE table
                    ExerciseSetsTable(sets: exercise.sets, repsRange: exercise.repsRange)
                }
                .padding(FitTodaySpacing.md)
                .background(FitTodayColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
            }
            .buttonStyle(.plain)

            // Delete button in edit mode
            if editMode == .active {
                Button { onDelete?() } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundStyle(FitTodayColor.error)
                }
                .buttonStyle(.plain)
                .padding(.top, FitTodaySpacing.sm)
            }
        }
    }

    // MARK: - Circle Image

    @ViewBuilder
    private var exerciseCircleImage: some View {
        ZStack {
            Circle()
                .fill(FitTodayColor.brandPrimary.opacity(0.1))
                .frame(width: 52, height: 52)

            if let imageURL = exercise.imageURL {
                ExerciseMediaImageURL(
                    url: imageURL,
                    size: CGSize(width: 52, height: 52),
                    contentMode: .fill,
                    cornerRadius: 26
                )
                .clipShape(Circle())
            } else {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 22))
                    .foregroundStyle(FitTodayColor.brandPrimary)
            }
        }
    }

    // MARK: - Rest Timer Label

    private var restTimerLabel: String {
        let seconds = exercise.restSeconds
        if seconds >= 60 {
            let mins = seconds / 60
            let secs = seconds % 60
            return secs == 0 ? "\(mins)min" : "\(mins)m\(secs)s"
        }
        return "\(seconds)s"
    }

    // MARK: - Static Helpers

    private static func muscleNames(for muscleIds: [Int]) -> String {
        let names = muscleIds.compactMap { muscleIdToName($0) }
        return names.isEmpty ? "Vários músculos" : names.joined(separator: ", ")
    }

    private static func muscleIdToName(_ muscleId: Int) -> String? {
        switch muscleId {
        case 1: return "Bíceps"
        case 2: return "Deltóides"
        case 3: return "Peito"
        case 4: return "Tríceps"
        case 5: return "Abdominais"
        case 6: return "Glúteos"
        case 7: return "Adutor"
        case 8: return "Abdutores"
        case 9: return "Quadríceps"
        case 10: return "Isquiotibiais"
        case 11: return "Panturrilhas"
        case 12: return "Dorsais"
        case 13: return "Trapézio"
        case 14: return "Serrátil"
        case 15: return "Lombar"
        default: return nil
        }
    }
}

// MARK: - Exercise Sets Table

private struct ExerciseSetsTable: View {
    let sets: Int
    let repsRange: ClosedRange<Int>

    var body: some View {
        VStack(spacing: 0) {
            tableHeader
            Divider().padding(.vertical, 4)
            ForEach(1...sets, id: \.self) { setNumber in
                tableRow(setNumber: setNumber)
                if setNumber < sets {
                    Divider().opacity(0.4)
                }
            }
        }
        .background(FitTodayColor.background.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.sm))
    }

    private var tableHeader: some View {
        HStack {
            Text("SET").frame(width: 36, alignment: .center)
            Spacer()
            Text("KG").frame(width: 60, alignment: .center)
            Spacer()
            Text("REPS").frame(width: 80, alignment: .center)
        }
        .font(.system(.caption2, weight: .bold))
        .foregroundStyle(FitTodayColor.textTertiary)
        .padding(.horizontal, FitTodaySpacing.sm)
        .padding(.top, FitTodaySpacing.xs)
    }

    private func tableRow(setNumber: Int) -> some View {
        HStack {
            Text("\(setNumber)")
                .frame(width: 36, alignment: .center)
                .font(.system(.caption, weight: .semibold))
                .foregroundStyle(FitTodayColor.brandPrimary)
            Spacer()
            Text("—")
                .frame(width: 60, alignment: .center)
                .font(.system(.caption))
                .foregroundStyle(FitTodayColor.textTertiary)
            Spacer()
            Text("\(repsRange.lowerBound)–\(repsRange.upperBound)")
                .frame(width: 80, alignment: .center)
                .font(.system(.caption, weight: .medium))
                .foregroundStyle(FitTodayColor.textPrimary)
        }
        .padding(.horizontal, FitTodaySpacing.sm)
        .padding(.vertical, 5)
    }
}

#Preview {
    // WgerExercise usa Int? para category e [Int] para muscles
    let sampleExercise = WgerExercise(
        id: 1,
        uuid: UUID().uuidString,
        name: "Supino Reto com Barra",
        exerciseBaseId: 1,
        description: "Deite no banco com os pés apoiados no chão...",
        category: 11, // Chest category ID
        muscles: [3],  // Peitoral muscle ID
        musclesSecondary: [],
        equipment: [1], // Barbell equipment ID
        language: 2,
        mainImageURL: "https://wger.de/media/exercise-images/192/Bench-press-1.png",
        imageURLs: ["https://wger.de/media/exercise-images/192/Bench-press-1.png"]
    )

    let programExercise = ProgramExercise(
        id: "test_1",
        wgerExercise: sampleExercise,
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
        subtitle: "Peito, Ombros e Tríceps",
        estimatedDurationMinutes: 45,
        exercises: [programExercise]
    )

    let container = Container()
    return NavigationStack {
        ProgramWorkoutDetailView(workout: workout, resolver: container)
    }
    .environment(AppRouter())
}
