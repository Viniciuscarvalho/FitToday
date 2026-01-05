//
//  WorkoutPlanView.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import SwiftUI

struct WorkoutPlanView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var sessionStore: WorkoutSessionStore
    @StateObject private var timerStore = WorkoutTimerStore()
    @State private var errorMessage: String?
    @State private var isFinishing = false

    var body: some View {
        Group {
            if let plan = sessionStore.plan {
                ZStack(alignment: .bottom) {
                    ScrollView {
                        VStack(spacing: FitTodaySpacing.lg) {
                            header(for: plan)
                            exerciseList(for: plan)
                            footerActions
                        }
                        .padding()
                        .padding(.bottom, timerStore.hasStarted ? 100 : 0) // Espaço para o timer flutuante
                    }
                    .background(FitTodayColor.background.ignoresSafeArea())
                    
                    // Timer flutuante quando o treino está em andamento
                    if timerStore.hasStarted {
                        floatingTimerBar
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: timerStore.hasStarted)
            } else {
                EmptyStateView(
                    title: "Nenhum treino ativo",
                    message: "Gere um novo treino na Home respondendo ao questionário diário."
                )
                .padding()
            }
        }
        .navigationTitle("Treino gerado")
        .alert("Ops!", isPresented: Binding(
            get: { errorMessage != nil },
            set: { _ in errorMessage = nil }
        )) {
            Button("Ok", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Algo inesperado aconteceu.")
        }
        .onDisappear {
            // Não reseta o timer ao sair, mantém em background
        }
    }
    
    // MARK: - Floating Timer Bar
    
    private var floatingTimerBar: some View {
        HStack(spacing: FitTodaySpacing.md) {
            // Tempo decorrido
            HStack(spacing: FitTodaySpacing.xs) {
                Image(systemName: "timer")
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(FitTodayColor.brandPrimary)
                
                Text(timerStore.formattedTime)
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundStyle(FitTodayColor.textPrimary)
                    .contentTransition(.numericText())
            }
            
            Spacer()
            
            // Botão de pausar/retomar
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    timerStore.toggle()
                }
            } label: {
                Image(systemName: timerStore.isRunning ? "pause.fill" : "play.fill")
                    .font(.system(.title3, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(timerStore.isRunning ? Color.orange : FitTodayColor.brandPrimary)
                    .clipShape(Circle())
            }
            .accessibilityLabel(timerStore.isRunning ? "Pausar treino" : "Retomar treino")
            
            // Botão de finalizar
            Button {
                finishSession(as: .completed)
            } label: {
                Image(systemName: "checkmark")
                    .font(.system(.title3, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.green)
                    .clipShape(Circle())
            }
            .accessibilityLabel("Finalizar treino")
            .disabled(isFinishing)
        }
        .padding(.horizontal, FitTodaySpacing.lg)
        .padding(.vertical, FitTodaySpacing.md)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.lg)
                .fill(FitTodayColor.surface)
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: -4)
        )
        .padding(.horizontal)
        .padding(.bottom, FitTodaySpacing.sm)
    }

    private func header(for plan: WorkoutPlan) -> some View {
        FitCard {
            VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
                Text(plan.title)
                    .font(.system(.title2, weight: .bold))
                    .foregroundStyle(FitTodayColor.textPrimary)

                Text(plan.focusDescription)
                    .font(.system(.body))
                    .foregroundStyle(FitTodayColor.textSecondary)

                HStack(spacing: FitTodaySpacing.md) {
                    WorkoutMetaChip(
                        icon: "clock",
                        label: "\(plan.estimatedDurationMinutes) min"
                    )
                    WorkoutMetaChip(
                        icon: "bolt.fill",
                        label: plan.intensity.displayTitle
                    )
                    
                    // Exibe o tempo decorrido se o treino já começou
                    if timerStore.hasStarted {
                        WorkoutMetaChip(
                            icon: "timer",
                            label: timerStore.formattedTime
                        )
                    }
                }

                if !timerStore.hasStarted {
                    Button("Começar agora") {
                        startWorkoutWithTimer()
                    }
                    .fitPrimaryStyle()
                    .padding(.top, FitTodaySpacing.sm)
                } else {
                    HStack(spacing: FitTodaySpacing.sm) {
                        Button {
                            timerStore.toggle()
                        } label: {
                            Label(timerStore.isRunning ? "Pausar" : "Retomar", systemImage: timerStore.isRunning ? "pause.fill" : "play.fill")
                        }
                        .fitSecondaryStyle()
                        
                        Button("Ver exercício") {
                            startFromCurrentExercise()
                        }
                        .fitPrimaryStyle()
                    }
                    .padding(.top, FitTodaySpacing.sm)
                }
            }
        }
    }
    
    private func startWorkoutWithTimer() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            timerStore.start()
        }
    }

    private func exerciseList(for plan: WorkoutPlan) -> some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            SectionHeader(title: "Exercícios", actionTitle: nil, action: nil)
                .padding(.horizontal, -FitTodaySpacing.md)

            LazyVStack(spacing: FitTodaySpacing.sm) {
                ForEach(Array(plan.exercises.enumerated()), id: \.offset) { index, prescription in
                    WorkoutExerciseRow(
                        index: index + 1,
                        prescription: prescription,
                        isCurrent: index == sessionStore.currentExerciseIndex
                    )
                    .onTapGesture {
                        sessionStore.selectExercise(at: index)
                        router.push(.exerciseDetail, on: .home)
                    }
                }
            }
        }
    }

    private var footerActions: some View {
        VStack(spacing: FitTodaySpacing.sm) {
            Button("Retomar exercício atual") {
                startFromCurrentExercise()
            }
            .fitSecondaryStyle()

            Button("Pular treino de hoje") {
                finishSession(as: .skipped)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.orange)
            .padding(.top, FitTodaySpacing.sm)
            .disabled(isFinishing)
        }
    }

    private func startFromCurrentExercise() {
        guard sessionStore.plan != nil else {
            errorMessage = "Nenhum plano encontrado."
            return
        }
        router.push(.exerciseDetail, on: .home)
    }

    private func finishSession(as status: WorkoutStatus) {
        guard !isFinishing else { return }
        isFinishing = true
        timerStore.pause() // Pausa o timer ao finalizar
        
        Task {
            do {
                try await sessionStore.finish(status: status)
                timerStore.reset() // Reseta para próximo treino
                router.push(.workoutSummary, on: .home)
            } catch {
                errorMessage = error.localizedDescription
            }
            isFinishing = false
        }
    }
}

private struct WorkoutMetaChip: View {
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: FitTodaySpacing.xs) {
            Image(systemName: icon)
                .font(.system(.footnote, weight: .semibold))
            Text(label)
                .font(.system(.footnote, weight: .medium))
        }
        .padding(.horizontal, FitTodaySpacing.sm)
        .padding(.vertical, FitTodaySpacing.xs)
        .background(FitTodayColor.surface)
        .cornerRadius(FitTodayRadius.pill)
    }
}

private struct WorkoutExerciseRow: View {
    let index: Int
    let prescription: ExercisePrescription
    let isCurrent: Bool

    var body: some View {
        HStack(alignment: .top, spacing: FitTodaySpacing.md) {
            ExerciseThumbnail(media: prescription.exercise.media, size: 64)

            VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                Text("\(index). \(prescription.exercise.name)")
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(FitTodayColor.textPrimary)
                Text("\(prescription.sets)x · \(prescription.reps.lowerBound)-\(prescription.reps.upperBound) reps")
                    .font(.system(.footnote))
                    .foregroundStyle(FitTodayColor.textSecondary)
                if let tip = prescription.tip {
                    Text(tip)
                        .font(.system(.caption))
                        .foregroundStyle(FitTodayColor.textTertiary)
                        .lineLimit(2)
                }
            }
            Spacer()
            if isCurrent {
                FitBadge(text: "Atual", style: .info)
            }
        }
        .padding()
        .background(FitTodayColor.surface)
        .cornerRadius(FitTodayRadius.md)
        .fitCardShadow()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(prescription.exercise.name), \(prescription.sets) séries de \(prescription.reps.display) repetições")
    }
}



