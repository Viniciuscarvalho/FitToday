//
//  WorkoutExerciseDetailView.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import SwiftUI

struct WorkoutExerciseDetailView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var sessionStore: WorkoutSessionStore
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if let prescription = sessionStore.currentPrescription,
               let plan = sessionStore.plan {
                content(for: prescription, plan: plan)
            } else {
                EmptyStateView(
                    title: "Exercício não encontrado",
                    message: "Selecione um exercício válido na lista para continuar."
                )
                .padding()
            }
        }
        .navigationTitle("Execução")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .alert("Ops!", isPresented: Binding(
            get: { errorMessage != nil },
            set: { _ in errorMessage = nil }
        )) {
            Button("Ok", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Algo inesperado aconteceu.")
        }
    }

    private func content(for prescription: ExercisePrescription, plan: WorkoutPlan) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FitTodaySpacing.lg) {
                StepperHeader(
                    title: prescription.exercise.name,
                    step: sessionStore.currentExerciseIndex + 1,
                    totalSteps: plan.exercises.count
                )

                ExerciseHeroImage(media: prescription.exercise.media)
                    .fitCardShadow()

                VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
                    infoRow(icon: "repeat", title: "\(prescription.sets)x séries", subtitle: "\(prescription.reps.lowerBound)-\(prescription.reps.upperBound) reps")
                    infoRow(icon: "timer", title: "Descanso", subtitle: "\(Int(prescription.restInterval))s entre séries")
                    infoRow(icon: "flame", title: sessionStore.plan?.intensity.displayTitle ?? "", subtitle: "Intensidade alvo")
                }

                if !prescription.exercise.instructions.isEmpty {
                    VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                        Text("Instruções rápidas")
                            .font(FitTodayFont.ui(size: 17, weight: .semiBold))  // Retro font
                        ForEach(prescription.exercise.instructions, id: \.self) { instruction in
                            HStack(alignment: .top, spacing: FitTodaySpacing.xs) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(FitTodayColor.brandPrimary)
                                    .fitGlowEffect(color: FitTodayColor.brandPrimary.opacity(0.3))  // Neon glow
                                Text(instruction)
                                    .font(FitTodayFont.ui(size: 17, weight: .medium))  // Retro font
                                    .foregroundStyle(FitTodayColor.textSecondary)
                            }
                        }
                    }
                }

                if let tip = prescription.tip {
                    FitCard {
                        VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                            Text("Dica do coach")
                                .font(FitTodayFont.ui(size: 17, weight: .semiBold))  // Retro font
                            Text(tip)
                                .font(FitTodayFont.ui(size: 17, weight: .medium))  // Retro font
                                .foregroundStyle(FitTodayColor.textSecondary)
                        }
                    }
                }

                actionButtons
            }
            .padding()
        }
        .background(
            ZStack {
                FitTodayColor.background
                RetroGridPattern(lineColor: FitTodayColor.gridLine.opacity(0.3), spacing: 40)  // Grid background
            }
            .ignoresSafeArea()
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Encerrar") {
                    finishSession(as: .completed)
                }
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: FitTodaySpacing.sm) {
            Button("Concluir exercício") {
                handleCompletion()
            }
            .fitPrimaryStyle()

            Button("Pular exercício") {
                handleSkip()
            }
            .fitSecondaryStyle()

            Button("Pular treino") {
                finishSession(as: .skipped)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.orange)
            .padding(.top, FitTodaySpacing.sm)
        }
    }

    private func handleCompletion() {
        let finished = sessionStore.advanceToNextExercise()
        if finished {
            finishSession(as: .completed)
        }
    }

    private func handleSkip() {
        let finished = sessionStore.skipCurrentExercise()
        if finished {
            finishSession(as: .completed)
        }
    }

    private func finishSession(as status: WorkoutStatus) {
        Task {
            do {
                try await sessionStore.finish(status: status)
                router.push(.workoutSummary, on: .home)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func infoRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: FitTodaySpacing.sm) {
            Image(systemName: icon)
                .font(.system(.title3))
                .foregroundStyle(FitTodayColor.brandPrimary)
                .fitGlowEffect(color: FitTodayColor.brandPrimary.opacity(0.3))  // Neon glow
            VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                Text(title)
                    .font(FitTodayFont.ui(size: 17, weight: .semiBold))  // Retro font
                Text(subtitle)
                    .font(FitTodayFont.ui(size: 15, weight: .medium))  // Retro font
                    .foregroundStyle(FitTodayColor.textSecondary)
            }
        }
    }
}

