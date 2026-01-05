//
//  WorkoutExercisePreviewView.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import SwiftUI

/// View de preview para visualização de exercício durante o treino.
/// Não altera o estado do treino (índice atual) - apenas exibe informações.
struct WorkoutExercisePreviewView: View {
    let prescription: ExercisePrescription
    let exerciseNumber: Int?
    let totalExercises: Int?
    
    @EnvironmentObject private var router: AppRouter
    
    init(
        prescription: ExercisePrescription,
        exerciseNumber: Int? = nil,
        totalExercises: Int? = nil
    ) {
        self.prescription = prescription
        self.exerciseNumber = exerciseNumber
        self.totalExercises = totalExercises
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FitTodaySpacing.lg) {
                // Header com número do exercício (se disponível)
                if let number = exerciseNumber, let total = totalExercises {
                    StepperHeader(
                        title: prescription.exercise.name,
                        step: number,
                        totalSteps: total
                    )
                } else {
                    Text(prescription.exercise.name)
                        .font(.system(.title2, weight: .bold))
                        .foregroundStyle(FitTodayColor.textPrimary)
                }
                
                // Hero Image/GIF
                ExerciseHeroImage(media: prescription.exercise.media)
                    .fitCardShadow()
                
                // Badges de músculo e equipamento
                HStack(spacing: FitTodaySpacing.sm) {
                    FitBadge(text: prescription.exercise.mainMuscle.displayTitle, style: .info)
                    FitBadge(text: prescription.exercise.equipment.displayName, style: .warning)
                }
                
                // Prescrição
                prescriptionSection
                
                // Instruções
                if !prescription.exercise.instructions.isEmpty {
                    instructionsSection
                }
                
                // Dica do coach
                if let tip = prescription.tip {
                    tipSection(tip)
                }
                
                Spacer(minLength: FitTodaySpacing.xl)
            }
            .padding()
        }
        .background(FitTodayColor.background.ignoresSafeArea())
        .navigationTitle("Exercício")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Prescrição
    
    private var prescriptionSection: some View {
        FitCard {
            VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
                Text("Prescrição")
                    .font(.system(.headline, weight: .bold))
                    .foregroundStyle(FitTodayColor.textPrimary)
                
                HStack(spacing: FitTodaySpacing.lg) {
                    prescriptionItem(
                        icon: "repeat",
                        value: "\(prescription.sets)",
                        label: "séries"
                    )
                    
                    prescriptionItem(
                        icon: "number",
                        value: prescription.reps.display,
                        label: "reps"
                    )
                    
                    prescriptionItem(
                        icon: "timer",
                        value: "\(Int(prescription.restInterval))s",
                        label: "descanso"
                    )
                }
            }
        }
    }
    
    private func prescriptionItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: FitTodaySpacing.xs) {
            HStack(spacing: FitTodaySpacing.xs) {
                Image(systemName: icon)
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(FitTodayColor.brandPrimary)
                Text(value)
                    .font(.system(.title3, weight: .bold))
                    .foregroundStyle(FitTodayColor.textPrimary)
            }
            Text(label)
                .font(.system(.caption))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Instruções
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            Text("Como executar")
                .font(.system(.headline, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)
            
            VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
                ForEach(Array(prescription.exercise.instructions.enumerated()), id: \.offset) { index, instruction in
                    HStack(alignment: .top, spacing: FitTodaySpacing.sm) {
                        Text("\(index + 1).")
                            .font(.system(.body, weight: .semibold))
                            .foregroundStyle(FitTodayColor.brandPrimary)
                            .frame(width: 24, alignment: .leading)
                        
                        Text(instruction)
                            .font(.system(.body))
                            .foregroundStyle(FitTodayColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding()
            .background(FitTodayColor.surface)
            .cornerRadius(FitTodayRadius.md)
        }
    }
    
    // MARK: - Dica
    
    private func tipSection(_ tip: String) -> some View {
        FitCard {
            HStack(alignment: .top, spacing: FitTodaySpacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(.title3))
                    .foregroundStyle(.yellow)
                
                VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                    Text("Dica do coach")
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(FitTodayColor.textPrimary)
                    Text(tip)
                        .font(.system(.body))
                        .foregroundStyle(FitTodayColor.textSecondary)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        WorkoutExercisePreviewView(
            prescription: ExercisePrescription(
                exercise: WorkoutExercise(
                    id: "bench_press",
                    name: "Supino Reto",
                    mainMuscle: .chest,
                    equipment: .barbell,
                    instructions: [
                        "Deite no banco com os pés firmes no chão",
                        "Segure a barra com as mãos ligeiramente mais afastadas que a largura dos ombros",
                        "Desça a barra controladamente até tocar o peito",
                        "Empurre a barra de volta até a posição inicial"
                    ],
                    media: nil
                ),
                sets: 4,
                reps: IntRange(8, 12),
                restInterval: 90,
                tip: "Mantenha as escápulas retraídas durante todo o movimento"
            ),
            exerciseNumber: 2,
            totalExercises: 6
        )
        .environmentObject(AppRouter())
    }
}

