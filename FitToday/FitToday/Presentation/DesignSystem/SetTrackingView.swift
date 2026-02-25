//
//  SetTrackingView.swift
//  FitToday
//
//  Componente para tracking de séries com checkboxes, reps e peso editáveis.
//

import SwiftUI

/// Checkbox individual para uma série com reps e peso editáveis
struct SetCheckbox: View {
    let setNumber: Int
    let isCompleted: Bool
    let reps: String
    var actualReps: Int?
    var weight: Double?
    let onToggle: () -> Void
    var onRepsChanged: ((Int?) -> Void)?
    var onWeightChanged: ((Double?) -> Void)?

    @State private var repsText: String = ""
    @State private var weightText: String = ""

    var body: some View {
        HStack(spacing: FitTodaySpacing.sm) {
            // Checkbox
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .stroke(isCompleted ? FitTodayColor.brandPrimary : FitTodayColor.textSecondary.opacity(0.5), lineWidth: 2)
                        .frame(width: 28, height: 28)

                    if isCompleted {
                        Circle()
                            .fill(FitTodayColor.brandPrimary)
                            .frame(width: 28, height: 28)

                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(FitTodayColor.background)
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCompleted)
            }
            .buttonStyle(.plain)

            // Set number label
            Text("execution.set".localized + " \(setNumber)")
                .font(FitTodayFont.ui(size: 14, weight: .semiBold))
                .foregroundStyle(isCompleted ? FitTodayColor.textSecondary : FitTodayColor.textPrimary)
                .frame(width: 52, alignment: .leading)

            Spacer()

            // Reps input
            HStack(spacing: 4) {
                TextField(reps, text: $repsText)
                    .keyboardType(.numberPad)
                    .font(FitTodayFont.ui(size: 14, weight: .medium))
                    .foregroundStyle(FitTodayColor.textPrimary)
                    .multilineTextAlignment(.center)
                    .frame(width: 44)
                    .padding(.vertical, 6)
                    .background(FitTodayColor.background)
                    .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.sm))
                    .onChange(of: repsText) {
                        onRepsChanged?(Int(repsText))
                    }

                Text("reps")
                    .font(FitTodayFont.ui(size: 11, weight: .medium))
                    .foregroundStyle(FitTodayColor.textTertiary)
            }

            // Weight input
            HStack(spacing: 4) {
                TextField("—", text: $weightText)
                    .keyboardType(.decimalPad)
                    .font(FitTodayFont.ui(size: 14, weight: .medium))
                    .foregroundStyle(FitTodayColor.textPrimary)
                    .multilineTextAlignment(.center)
                    .frame(width: 50)
                    .padding(.vertical, 6)
                    .background(FitTodayColor.background)
                    .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.sm))
                    .onChange(of: weightText) {
                        onWeightChanged?(Double(weightText))
                    }

                Text("kg")
                    .font(FitTodayFont.ui(size: 11, weight: .medium))
                    .foregroundStyle(FitTodayColor.textTertiary)
            }
        }
        .padding(.vertical, FitTodaySpacing.sm)
        .padding(.horizontal, FitTodaySpacing.md)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.sm)
                .fill(isCompleted ? FitTodayColor.brandPrimary.opacity(0.1) : FitTodayColor.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: FitTodayRadius.sm)
                .stroke(isCompleted ? FitTodayColor.brandPrimary.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .onAppear {
            if let actualReps { repsText = "\(actualReps)" }
            if let weight { weightText = String(format: "%.1g", weight) }
        }
    }
}

/// Lista de séries para um exercício
struct SetTrackingList: View {
    let exerciseProgress: ExerciseProgress
    let repsDisplay: String
    let onToggleSet: (Int) -> Void

    var body: some View {
        VStack(spacing: FitTodaySpacing.sm) {
            ForEach(Array(exerciseProgress.sets.enumerated()), id: \.element.id) { index, setProgress in
                SetCheckbox(
                    setNumber: setProgress.setNumber,
                    isCompleted: setProgress.isCompleted,
                    reps: "\(repsDisplay) reps",
                    onToggle: { onToggleSet(index) }
                )
            }
        }
    }
}

/// Progress bar circular mini para preview
struct MiniProgressRing: View {
    let progress: Double
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(FitTodayColor.surface, lineWidth: 3)

            Circle()
                .trim(from: 0, to: min(progress, 1))
                .stroke(FitTodayColor.brandPrimary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.3), value: progress)
        }
        .frame(width: size, height: size)
    }
}

/// Progress bar horizontal do treino
struct WorkoutProgressBar: View {
    let completedExercises: Int
    let totalExercises: Int
    let overallProgress: Double

    var body: some View {
        VStack(spacing: FitTodaySpacing.xs) {
            HStack {
                Text("Progresso")
                    .font(FitTodayFont.ui(size: 13, weight: .medium))
                    .foregroundStyle(FitTodayColor.textSecondary)

                Spacer()

                Text("\(completedExercises)/\(totalExercises) exercícios")
                    .font(FitTodayFont.ui(size: 13, weight: .semiBold))
                    .foregroundStyle(FitTodayColor.textPrimary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(FitTodayColor.surface)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [FitTodayColor.brandPrimary, FitTodayColor.brandSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(min(overallProgress, 1)), height: 8)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: overallProgress)
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal, FitTodaySpacing.md)
        .padding(.vertical, FitTodaySpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.sm)
                .fill(FitTodayColor.surfaceElevated)
        )
    }
}

// MARK: - Previews

#Preview("Set Checkbox") {
    VStack(spacing: 12) {
        SetCheckbox(setNumber: 1, isCompleted: false, reps: "8-12") {}
        SetCheckbox(setNumber: 2, isCompleted: true, reps: "8-12", actualReps: 10, weight: 40) {}
        SetCheckbox(setNumber: 3, isCompleted: false, reps: "8-12") {}
    }
    .padding()
    .background(FitTodayColor.background)
}

#Preview("Progress Bar") {
    VStack(spacing: 20) {
        WorkoutProgressBar(completedExercises: 3, totalExercises: 10, overallProgress: 0.3)
        WorkoutProgressBar(completedExercises: 7, totalExercises: 10, overallProgress: 0.7)
        WorkoutProgressBar(completedExercises: 10, totalExercises: 10, overallProgress: 1.0)
    }
    .padding()
    .background(FitTodayColor.background)
}
