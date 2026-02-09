//
//  ExerciseExecutionCard.swift
//  FitToday
//
//  Card component displaying exercise information during workout execution.
//  Shows media (video/GIF/image), exercise name, Portuguese description, and set/rep details.
//

import SwiftUI
import Swinject

struct ExerciseExecutionCard: View {
    let prescription: ExercisePrescription
    let description: String
    let viewModel: WorkoutExecutionViewModel
    let onSubstitute: () -> Void

    var body: some View {
        VStack(spacing: FitTodaySpacing.lg) {
            // Exercise Media
            exerciseMediaSection

            // Exercise Info
            exerciseInfoSection

            // Exercise Description
            if !description.isEmpty {
                exerciseDescriptionSection
            }

            // Exercise Details
            exerciseDetailsSection
        }
        .padding(FitTodaySpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.lg)
                .fill(FitTodayColor.surfaceElevated)
                .retroGridOverlay(spacing: 20)
        )
        .techCornerBorders(length: 12, thickness: 1.5)
    }

    // MARK: - Exercise Media Section

    private var exerciseMediaSection: some View {
        Group {
            if let media = prescription.exercise.media, let mediaURL = media.bestMediaURL {
                ExerciseMediaImageURL(
                    url: mediaURL,
                    size: CGSize(width: UIScreen.main.bounds.width - 80, height: 240),
                    contentMode: .fit,
                    cornerRadius: FitTodayRadius.md
                )
            } else {
                placeholderMedia
            }
        }
        .frame(height: 240)
    }

    private var placeholderMedia: some View {
        ZStack {
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .fill(FitTodayColor.surface)

            VStack(spacing: FitTodaySpacing.md) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 60))
                    .foregroundStyle(FitTodayColor.brandPrimary)

                Text("Sem mídia disponível")
                    .font(FitTodayFont.ui(size: 14, weight: .medium))
                    .foregroundStyle(FitTodayColor.textTertiary)
            }
        }
    }

    // MARK: - Exercise Info Section

    private var exerciseInfoSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            // Exercise Name
            HStack {
                Text(prescription.exercise.name)
                    .font(FitTodayFont.display(size: 24, weight: .bold))
                    .foregroundStyle(FitTodayColor.textPrimary)

                Spacer()

                // Substitute Button
                Button(action: onSubstitute) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 18))
                        .foregroundStyle(FitTodayColor.brandPrimary)
                        .frame(width: 36, height: 36)
                        .background(FitTodayColor.brandPrimary.opacity(0.15))
                        .clipShape(Circle())
                }
            }

            // Muscle Group Badge
            HStack(spacing: FitTodaySpacing.xs) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 12))

                Text(prescription.exercise.mainMuscle.displayName)
                    .font(FitTodayFont.ui(size: 13, weight: .medium))
            }
            .foregroundStyle(FitTodayColor.brandSecondary)
            .padding(.horizontal, FitTodaySpacing.sm)
            .padding(.vertical, FitTodaySpacing.xs)
            .background(
                Capsule()
                    .fill(FitTodayColor.brandSecondary.opacity(0.15))
            )
        }
    }

    // MARK: - Exercise Description Section

    private var exerciseDescriptionSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
            Text("Descrição")
                .font(FitTodayFont.ui(size: 14, weight: .semiBold))
                .foregroundStyle(FitTodayColor.textSecondary)

            Text(description)
                .font(FitTodayFont.ui(size: 15, weight: .medium))
                .foregroundStyle(FitTodayColor.textPrimary)
                .lineSpacing(4)
        }
        .padding(FitTodaySpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FitTodayColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.sm))
    }

    // MARK: - Exercise Details Section

    private var exerciseDetailsSection: some View {
        HStack(spacing: FitTodaySpacing.lg) {
            // Sets
            DetailBadge(
                icon: "repeat",
                label: "Séries",
                value: "\(prescription.sets)"
            )

            Divider()
                .frame(height: 40)

            // Reps
            DetailBadge(
                icon: "arrow.up.arrow.down",
                label: "Repetições",
                value: "\(prescription.reps.lowerBound)-\(prescription.reps.upperBound)"
            )

            Divider()
                .frame(height: 40)

            // Rest
            DetailBadge(
                icon: "timer",
                label: "Descanso",
                value: "\(Int(prescription.restInterval))s"
            )
        }
        .padding(FitTodaySpacing.md)
        .frame(maxWidth: .infinity)
        .background(FitTodayColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
    }
}

// MARK: - Detail Badge

private struct DetailBadge: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: FitTodaySpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(FitTodayColor.brandPrimary)

            Text(value)
                .font(FitTodayFont.ui(size: 18, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)

            Text(label)
                .font(FitTodayFont.ui(size: 11, weight: .medium))
                .foregroundStyle(FitTodayColor.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var sessionStore = WorkoutSessionStore(resolver: Container())
    @Previewable @State var restTimer = RestTimerStore()
    @Previewable @State var workoutTimer = WorkoutTimerStore()

    let samplePrescription = ExercisePrescription(
        exercise: WorkoutExercise(
            id: "1",
            name: "Supino Reto com Barra",
            mainMuscle: .chest,
            equipment: .barbell,
            instructions: [
                "Deite no banco com os pés apoiados no chão.",
                "Segure a barra com as mãos afastadas na largura dos ombros.",
                "Desça a barra lentamente até tocar o peito.",
                "Empurre a barra para cima até estender os braços completamente."
            ],
            media: ExerciseMedia(
                videoURL: nil,
                imageURL: URL(string: "https://wger.de/media/exercise-images/192/Bench-press-1.png"),
                gifURL: nil
            )
        ),
        sets: 4,
        reps: IntRange(8, 12),
        restInterval: 90,
        tip: nil
    )

    let vm = WorkoutExecutionViewModel(
        sessionStore: sessionStore,
        restTimer: restTimer,
        workoutTimer: workoutTimer
    )

    ScrollView {
        ExerciseExecutionCard(
            prescription: samplePrescription,
            description: "O supino reto é um exercício composto que trabalha principalmente o peitoral maior, mas também envolve os deltoides anteriores e os tríceps. É considerado um dos melhores exercícios para desenvolvimento do peitoral.",
            viewModel: vm,
            onSubstitute: { print("Substitute tapped") }
        )
        .padding()
    }
    .background(FitTodayColor.background)
}
