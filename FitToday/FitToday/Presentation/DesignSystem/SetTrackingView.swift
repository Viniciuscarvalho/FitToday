//
//  SetTrackingView.swift
//  FitToday
//
//  Componente para tracking de séries com checkboxes.
//

import SwiftUI

/// Checkbox individual para uma série
struct SetCheckbox: View {
    let setNumber: Int
    let isCompleted: Bool
    let reps: String
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: FitTodaySpacing.sm) {
                // Checkbox visual
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
                
                // Informação da série
                VStack(alignment: .leading, spacing: 2) {
                    Text("Série \(setNumber)")
                        .font(FitTodayFont.ui(size: 15, weight: .semiBold))
                        .foregroundStyle(isCompleted ? FitTodayColor.textSecondary : FitTodayColor.textPrimary)
                    
                    Text(reps)
                        .font(FitTodayFont.ui(size: 13, weight: .medium))
                        .foregroundStyle(FitTodayColor.textSecondary)
                }
                
                Spacer()
                
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(FitTodayColor.brandPrimary)
                        .fitGlowEffect(color: FitTodayColor.brandPrimary.opacity(0.3))
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
        }
        .buttonStyle(.plain)
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
        SetCheckbox(setNumber: 2, isCompleted: true, reps: "8-12") {}
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

