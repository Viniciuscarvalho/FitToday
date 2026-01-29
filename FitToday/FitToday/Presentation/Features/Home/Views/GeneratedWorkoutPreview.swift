//
//  GeneratedWorkoutPreview.swift
//  FitToday
//
//  Preview and actions for an AI-generated workout.
//

import SwiftUI

/// Model for a generated workout from AI.
struct GeneratedWorkout: Identifiable, Sendable {
    let id: UUID
    let name: String
    let exercises: [GeneratedExercise]
    let estimatedDuration: Int
    let targetMuscles: [String]
    let fatigueAdjusted: Bool
    let warmupIncluded: Bool
    let generatedAt: Date

    var totalSets: Int {
        exercises.reduce(0) { $0 + $1.sets }
    }

    var exerciseCount: Int {
        exercises.count
    }

    init(
        id: UUID = UUID(),
        name: String,
        exercises: [GeneratedExercise],
        estimatedDuration: Int,
        targetMuscles: [String],
        fatigueAdjusted: Bool = false,
        warmupIncluded: Bool = false,
        generatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.exercises = exercises
        self.estimatedDuration = estimatedDuration
        self.targetMuscles = targetMuscles
        self.fatigueAdjusted = fatigueAdjusted
        self.warmupIncluded = warmupIncluded
        self.generatedAt = generatedAt
    }
}

/// Exercise within a generated workout.
struct GeneratedExercise: Identifiable, Sendable {
    let id: UUID
    let exerciseId: Int
    let name: String
    let targetMuscle: String
    let equipment: String
    let sets: Int
    let repsRange: String
    let restSeconds: Int
    let notes: String?
    let imageURL: String?

    init(
        id: UUID = UUID(),
        exerciseId: Int,
        name: String,
        targetMuscle: String,
        equipment: String,
        sets: Int,
        repsRange: String,
        restSeconds: Int,
        notes: String? = nil,
        imageURL: String? = nil
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.name = name
        self.targetMuscle = targetMuscle
        self.equipment = equipment
        self.sets = sets
        self.repsRange = repsRange
        self.restSeconds = restSeconds
        self.notes = notes
        self.imageURL = imageURL
    }
}

/// Preview view for an AI-generated workout with actions.
struct GeneratedWorkoutPreview: View {
    let workout: GeneratedWorkout
    let onStartWorkout: () -> Void
    let onSaveAsTemplate: () -> Void
    let onRegenerate: () -> Void
    let onDismiss: () -> Void

    @State private var showExerciseDetail: GeneratedExercise?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FitTodaySpacing.lg) {
                    // Header Card
                    headerCard

                    // Quick Stats
                    statsRow

                    // AI Insights
                    insightsSection

                    // Exercises List
                    exercisesSection

                    // Action Buttons
                    actionsSection
                }
                .padding(FitTodaySpacing.md)
            }
            .scrollIndicators(.hidden)
            .background(FitTodayColor.background)
            .navigationTitle("Treino Gerado")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") {
                        onDismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        onRegenerate()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .sheet(item: $showExerciseDetail) { exercise in
                ExerciseDetailSheet(exercise: exercise)
            }
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        VStack(spacing: FitTodaySpacing.md) {
            // Title with sparkle
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 24))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [FitTodayColor.brandPrimary, FitTodayColor.brandSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text(workout.name)
                    .font(FitTodayFont.ui(size: 22, weight: .bold))
                    .foregroundStyle(FitTodayColor.textPrimary)

                Spacer()
            }

            // Target muscles
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: FitTodaySpacing.sm) {
                    ForEach(workout.targetMuscles, id: \.self) { muscle in
                        Text(muscle)
                            .font(FitTodayFont.ui(size: 12, weight: .semiBold))
                            .foregroundStyle(FitTodayColor.brandPrimary)
                            .padding(.horizontal, FitTodaySpacing.sm)
                            .padding(.vertical, FitTodaySpacing.xs)
                            .background(
                                Capsule()
                                    .fill(FitTodayColor.brandPrimary.opacity(0.15))
                            )
                    }
                }
            }

            // Generated time
            HStack {
                Image(systemName: "clock")
                    .font(.system(size: 12))
                Text("Gerado \(workout.generatedAt, style: .relative) atrás")
                    .font(FitTodayFont.ui(size: 12, weight: .medium))
            }
            .foregroundStyle(FitTodayColor.textTertiary)
        }
        .padding(FitTodaySpacing.md)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.lg)
                .fill(FitTodayColor.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: FitTodayRadius.lg)
                .stroke(
                    LinearGradient(
                        colors: [FitTodayColor.brandPrimary.opacity(0.5), FitTodayColor.brandSecondary.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: FitTodaySpacing.md) {
            statItem(icon: "clock", value: "\(workout.estimatedDuration)", unit: "min", label: "Duração")
            statItem(icon: "figure.strengthtraining.traditional", value: "\(workout.exerciseCount)", unit: "", label: "Exercícios")
            statItem(icon: "number", value: "\(workout.totalSets)", unit: "", label: "Séries")
        }
    }

    private func statItem(icon: String, value: String, unit: String, label: String) -> some View {
        VStack(spacing: FitTodaySpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(FitTodayColor.brandPrimary)

            HStack(spacing: 2) {
                Text(value)
                    .font(FitTodayFont.ui(size: 20, weight: .bold))
                    .foregroundStyle(FitTodayColor.textPrimary)

                if !unit.isEmpty {
                    Text(unit)
                        .font(FitTodayFont.ui(size: 12, weight: .medium))
                        .foregroundStyle(FitTodayColor.textSecondary)
                }
            }

            Text(label)
                .font(FitTodayFont.ui(size: 11, weight: .medium))
                .foregroundStyle(FitTodayColor.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(FitTodaySpacing.md)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .fill(FitTodayColor.surface)
        )
    }

    // MARK: - Insights Section

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            Text("Insights da IA")
                .font(FitTodayFont.ui(size: 14, weight: .semiBold))
                .foregroundStyle(FitTodayColor.textSecondary)

            HStack(spacing: FitTodaySpacing.sm) {
                if workout.fatigueAdjusted {
                    insightChip(icon: "battery.50", text: "Volume ajustado pela fadiga", color: .orange)
                }

                if workout.warmupIncluded {
                    insightChip(icon: "flame", text: "Aquecimento incluso", color: .red)
                }
            }
        }
    }

    private func insightChip(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: FitTodaySpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(text)
                .font(FitTodayFont.ui(size: 11, weight: .medium))
        }
        .foregroundStyle(color)
        .padding(.horizontal, FitTodaySpacing.sm)
        .padding(.vertical, FitTodaySpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.sm)
                .fill(color.opacity(0.15))
        )
    }

    // MARK: - Exercises Section

    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            Text("Exercícios")
                .font(FitTodayFont.ui(size: 17, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)

            LazyVStack(spacing: FitTodaySpacing.sm) {
                ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { index, exercise in
                    GeneratedExerciseRow(
                        exercise: exercise,
                        index: index + 1
                    ) {
                        showExerciseDetail = exercise
                    }
                }
            }
        }
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(spacing: FitTodaySpacing.sm) {
            // Primary: Start Workout
            Button(action: onStartWorkout) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Iniciar Treino")
                }
                .font(FitTodayFont.ui(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, FitTodaySpacing.md)
                .background(
                    LinearGradient(
                        colors: [FitTodayColor.brandPrimary, FitTodayColor.brandSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
            }
            .buttonStyle(.plain)

            // Secondary: Save as Template
            Button(action: onSaveAsTemplate) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text("Salvar como Template")
                }
                .font(FitTodayFont.ui(size: 16, weight: .semiBold))
                .foregroundStyle(FitTodayColor.brandPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, FitTodaySpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: FitTodayRadius.md)
                        .stroke(FitTodayColor.brandPrimary, lineWidth: 2)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.top, FitTodaySpacing.md)
    }
}

// MARK: - Generated Exercise Row

struct GeneratedExerciseRow: View {
    let exercise: GeneratedExercise
    let index: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: FitTodaySpacing.md) {
                // Index badge
                Text("\(index)")
                    .font(FitTodayFont.ui(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(FitTodayColor.brandPrimary)
                    )

                // Exercise info
                VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                    Text(exercise.name)
                        .font(FitTodayFont.ui(size: 15, weight: .semiBold))
                        .foregroundStyle(FitTodayColor.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: FitTodaySpacing.sm) {
                        Label(exercise.targetMuscle, systemImage: "figure.strengthtraining.traditional")
                        Label(exercise.equipment, systemImage: "dumbbell")
                    }
                    .font(FitTodayFont.ui(size: 11, weight: .medium))
                    .foregroundStyle(FitTodayColor.textTertiary)
                }

                Spacer()

                // Sets x Reps
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(exercise.sets) séries")
                        .font(FitTodayFont.ui(size: 13, weight: .bold))
                        .foregroundStyle(FitTodayColor.textPrimary)

                    Text("\(exercise.repsRange) reps")
                        .font(FitTodayFont.ui(size: 11, weight: .medium))
                        .foregroundStyle(FitTodayColor.textSecondary)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(FitTodayColor.textTertiary)
            }
            .padding(FitTodaySpacing.md)
            .background(
                RoundedRectangle(cornerRadius: FitTodayRadius.md)
                    .fill(FitTodayColor.surface)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Exercise Detail Sheet

struct ExerciseDetailSheet: View {
    let exercise: GeneratedExercise
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: FitTodaySpacing.lg) {
                    // Exercise Image Placeholder
                    RoundedRectangle(cornerRadius: FitTodayRadius.md)
                        .fill(FitTodayColor.surface)
                        .frame(height: 200)
                        .overlay(
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.system(size: 64))
                                .foregroundStyle(FitTodayColor.textTertiary)
                        )

                    // Details
                    VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
                        detailRow(label: "Músculo Alvo", value: exercise.targetMuscle, icon: "target")
                        detailRow(label: "Equipamento", value: exercise.equipment, icon: "dumbbell")
                        detailRow(label: "Séries", value: "\(exercise.sets)", icon: "number")
                        detailRow(label: "Repetições", value: exercise.repsRange, icon: "repeat")
                        detailRow(label: "Descanso", value: "\(exercise.restSeconds)s", icon: "clock")

                        if let notes = exercise.notes {
                            VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                                Text("Notas da IA")
                                    .font(FitTodayFont.ui(size: 14, weight: .semiBold))
                                    .foregroundStyle(FitTodayColor.textSecondary)

                                Text(notes)
                                    .font(FitTodayFont.ui(size: 15, weight: .medium))
                                    .foregroundStyle(FitTodayColor.textPrimary)
                            }
                            .padding(FitTodaySpacing.md)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: FitTodayRadius.md)
                                    .fill(FitTodayColor.brandPrimary.opacity(0.1))
                            )
                        }
                    }
                }
                .padding(FitTodaySpacing.md)
            }
            .background(FitTodayColor.background)
            .navigationTitle(exercise.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func detailRow(label: String, value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(FitTodayColor.brandPrimary)
                .frame(width: 24)

            Text(label)
                .font(FitTodayFont.ui(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)

            Spacer()

            Text(value)
                .font(FitTodayFont.ui(size: 14, weight: .semiBold))
                .foregroundStyle(FitTodayColor.textPrimary)
        }
        .padding(FitTodaySpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.sm)
                .fill(FitTodayColor.surface)
        )
    }
}

// MARK: - Preview

#Preview {
    GeneratedWorkoutPreview(
        workout: GeneratedWorkout(
            name: "Push Day Personalizado",
            exercises: [
                GeneratedExercise(
                    exerciseId: 1,
                    name: "Supino Reto com Barra",
                    targetMuscle: "Peito",
                    equipment: "Barra",
                    sets: 4,
                    repsRange: "8-12",
                    restSeconds: 90,
                    notes: "Mantenha os cotovelos a 45 graus do corpo"
                ),
                GeneratedExercise(
                    exerciseId: 2,
                    name: "Supino Inclinado com Halteres",
                    targetMuscle: "Peito Superior",
                    equipment: "Halteres",
                    sets: 3,
                    repsRange: "10-12",
                    restSeconds: 75
                ),
                GeneratedExercise(
                    exerciseId: 3,
                    name: "Desenvolvimento com Halteres",
                    targetMuscle: "Ombros",
                    equipment: "Halteres",
                    sets: 3,
                    repsRange: "10-12",
                    restSeconds: 60
                ),
                GeneratedExercise(
                    exerciseId: 4,
                    name: "Tríceps Corda",
                    targetMuscle: "Tríceps",
                    equipment: "Cabo",
                    sets: 3,
                    repsRange: "12-15",
                    restSeconds: 60
                )
            ],
            estimatedDuration: 45,
            targetMuscles: ["Peito", "Ombros", "Tríceps"],
            fatigueAdjusted: true,
            warmupIncluded: true
        ),
        onStartWorkout: {},
        onSaveAsTemplate: {},
        onRegenerate: {},
        onDismiss: {}
    )
    .preferredColorScheme(.dark)
}
