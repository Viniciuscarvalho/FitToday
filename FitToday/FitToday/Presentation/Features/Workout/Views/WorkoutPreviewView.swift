//
//  WorkoutPreviewView.swift
//  FitToday
//
//  Preview screen showing exercises before starting a workout.
//  User can review the workout structure, then tap "Iniciar Treino" to begin execution.
//

import SwiftUI
import Swinject

struct WorkoutPreviewView: View {
    let workout: ProgramWorkout
    let resolver: Resolver

    @Environment(AppRouter.self) private var router
    @Environment(WorkoutSessionStore.self) private var sessionStore
    @State private var showStartConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: FitTodaySpacing.lg) {
                headerSection
                exercisesPreviewSection
                startButton
            }
            .padding()
        }
        .background(FitTodayColor.background.ignoresSafeArea())
        .navigationTitle("Pré-visualização")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .confirmationDialog("Iniciar Treino?", isPresented: $showStartConfirmation) {
            Button("Iniciar Treino") {
                startWorkout()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Você está pronto para começar este treino de \(workout.estimatedDurationMinutes) minutos?")
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            Text(workout.title)
                .font(.system(.title2, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)

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
                    value: "\(workout.exercises.count)",
                    label: "exercícios"
                )

                StatBadge(
                    icon: "flame",
                    value: "\(estimatedCalories)",
                    label: "kcal"
                )
            }
        }
        .padding(FitTodaySpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FitTodayColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
    }

    private var estimatedCalories: Int {
        // Rough estimate: 5 kcal per minute of exercise
        workout.estimatedDurationMinutes * 5
    }

    // MARK: - Exercises Preview Section

    private var exercisesPreviewSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            Text("Exercícios do Treino")
                .font(.system(.headline, weight: .semibold))
                .foregroundStyle(FitTodayColor.textPrimary)

            if workout.exercises.isEmpty {
                emptyExercisesView
            } else {
                LazyVStack(spacing: FitTodaySpacing.sm) {
                    ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { index, exercise in
                        ExercisePreviewCard(
                            exercise: exercise,
                            index: index + 1
                        )
                    }
                }
            }
        }
    }

    private var emptyExercisesView: some View {
        VStack(spacing: FitTodaySpacing.md) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 40))
                .foregroundStyle(FitTodayColor.textTertiary)

            Text("Nenhum exercício encontrado")
                .font(.system(.subheadline))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(FitTodaySpacing.xl)
    }

    // MARK: - Start Button

    private var startButton: some View {
        Button {
            showStartConfirmation = true
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
        .disabled(workout.exercises.isEmpty)
    }

    // MARK: - Actions

    private func startWorkout() {
        // Convert ProgramWorkout to WorkoutPlan for execution
        let workoutPlan = convertToWorkoutPlan()

        // Initialize workout session
        sessionStore.start(with: workoutPlan)

        // Navigate to exercise detail (execution view)
        router.push(.exerciseDetail, on: router.selectedTab)
    }

    // MARK: - Conversion Helper

    /// Converts ProgramWorkout to WorkoutPlan for execution
    private func convertToWorkoutPlan() -> WorkoutPlan {
        let exercisePrescriptions = workout.exercises.map { programExercise -> ExercisePrescription in
            let wgerExercise = programExercise.wgerExercise
            let workoutExercise = WorkoutExercise(
                id: String(wgerExercise.id),
                name: wgerExercise.name,
                mainMuscle: mapCategoryToMuscleGroup(wgerExercise.category),
                equipment: mapEquipment(wgerExercise.equipment),
                instructions: extractInstructions(from: wgerExercise),
                media: createMedia(from: wgerExercise)
            )

            return ExercisePrescription(
                exercise: workoutExercise,
                sets: programExercise.sets,
                reps: IntRange(
                    programExercise.repsRange.lowerBound,
                    programExercise.repsRange.upperBound
                ),
                restInterval: TimeInterval(programExercise.restSeconds),
                tip: programExercise.notes
            )
        }

        return WorkoutPlan(
            id: UUID(),
            title: workout.title,
            focus: .fullBody,
            estimatedDurationMinutes: workout.estimatedDurationMinutes,
            intensity: .moderate,
            exercises: exercisePrescriptions,
            createdAt: Date()
        )
    }

    // MARK: - Mapping Helpers

    private func mapCategoryToMuscleGroup(_ categoryId: Int?) -> MuscleGroup {
        guard let categoryId else { return .fullBody }

        // Map Wger category IDs to MuscleGroup
        switch categoryId {
        case 8:  return .arms          // Arms
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

    private func extractInstructions(from wgerExercise: WgerExercise) -> [String] {
        guard let description = wgerExercise.description, !description.isEmpty else {
            return ["Realize o exercício com boa técnica."]
        }

        let lines = description
            .components(separatedBy: CharacterSet.newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        return lines.isEmpty ? ["Realize o exercício com boa técnica."] : lines
    }

    private func createMedia(from wgerExercise: WgerExercise) -> ExerciseMedia? {
        let imageURL = wgerExercise.mainImageURL.flatMap { URL(string: $0) }
            ?? wgerExercise.imageURLs.first.flatMap { URL(string: $0) }

        guard imageURL != nil else { return nil }
        return ExerciseMedia(videoURL: nil, imageURL: imageURL, gifURL: nil)
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

// MARK: - Exercise Preview Card

private struct ExercisePreviewCard: View {
    let exercise: ProgramExercise
    let index: Int

    var body: some View {
        HStack(spacing: FitTodaySpacing.md) {
            // Exercise number badge
            Text("\(index)")
                .font(.system(.subheadline, weight: .bold))
                .foregroundStyle(FitTodayColor.brandPrimary)
                .frame(width: 28, height: 28)
                .background(FitTodayColor.brandPrimary.opacity(0.15))
                .clipShape(Circle())

            // Exercise image
            exerciseImage

            // Exercise info
            VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                Text(exercise.name)
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(FitTodayColor.textPrimary)
                    .lineLimit(2)

                // Sets x Reps info
                HStack(spacing: FitTodaySpacing.sm) {
                    Text("\(exercise.sets) séries")
                    Text("•")
                    Text("\(exercise.repsRange.lowerBound)-\(exercise.repsRange.upperBound) reps")
                }
                .font(.system(.caption))
                .foregroundStyle(FitTodayColor.textSecondary)
            }

            Spacer()
        }
        .padding(FitTodaySpacing.md)
        .background(FitTodayColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
    }

    @ViewBuilder
    private var exerciseImage: some View {
        if let imageURL = exercise.imageURL {
            ExerciseMediaImageURL(
                url: imageURL,
                size: CGSize(width: 56, height: 56),
                contentMode: .fill,
                cornerRadius: FitTodayRadius.sm
            )
        } else {
            placeholderImage
        }
    }

    private var placeholderImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: FitTodayRadius.sm)
                .fill(FitTodayColor.brandPrimary.opacity(0.1))
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 24))
                .foregroundStyle(FitTodayColor.brandPrimary)
        }
        .frame(width: 56, height: 56)
    }
}

#Preview {
    let sampleExercise = WgerExercise(
        id: 1,
        uuid: UUID().uuidString,
        name: "Supino Reto com Barra",
        exerciseBaseId: 1,
        description: "Deite no banco com os pés apoiados no chão...",
        category: 11,
        muscles: [3],
        musclesSecondary: [],
        equipment: [1],
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
        WorkoutPreviewView(workout: workout, resolver: container)
            .environment(AppRouter())
            .environment(WorkoutSessionStore(resolver: container))
    }
}
