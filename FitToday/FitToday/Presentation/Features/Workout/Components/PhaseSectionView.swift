//
//  PhaseSectionView.swift
//  FitToday
//
//  Created by AI on 14/01/26.
//

import SwiftUI

// 💡 Learn: Seção de fase do treino (Aquecimento, Força, Aeróbio, etc.)
// Componente extraído para manter a view principal < 100 linhas
struct PhaseSectionView: View {
    @Environment(AppRouter.self) private var router
    @Environment(WorkoutSessionStore.self) private var sessionStore

    let phase: WorkoutPlanPhase
    let phaseIndex: Int
    let displayMode: PhaseDisplayMode

    @State private var showDeleteConfirmation = false
    @State private var itemToDelete: Int?

    var body: some View {
        // Não exibe a fase se não tiver itens após filtragem
        if !filteredItems.isEmpty {
            VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
                SectionHeader(
                    title: phaseHeaderTitle,
                    actionTitle: nil,
                    action: nil
                )
                .padding(.horizontal, -FitTodaySpacing.md)

                LazyVStack(spacing: FitTodaySpacing.sm) {
                    ForEach(filteredItems.indices, id: \.self) { idx in
                        let item = filteredItems[idx]
                        switch item {
                        case .activity(let activity):
                            ActivityRow(activity: activity)

                        case .exercise(let prescription):
                            // Usar índice local dentro da fase (não global)
                            let localIndex = idx + 1
                            Button {
                                router.push(.workoutExercisePreview(prescription), on: .home)
                            } label: {
                                WorkoutExerciseRow(
                                    index: localIndex,
                                    prescription: prescription,
                                    isCurrent: sessionStore.currentExerciseIndex == localIndex
                                )
                            }
                            .buttonStyle(ExerciseRowButtonStyle())
                            .contextMenu {
                                Button {
                                    router.push(.workoutExercisePreview(prescription), on: .home)
                                } label: {
                                    Label("Ver detalhes", systemImage: "info.circle")
                                }

                                Button(role: .destructive) {
                                    itemToDelete = idx
                                    showDeleteConfirmation = true
                                } label: {
                                    Label("Remover exercício", systemImage: "trash")
                                }
                            }
                            .accessibilityHint("Toque para ver detalhes. Segure para mais opções.")
                        }
                    }
                }
            }
            .padding(.top, FitTodaySpacing.md)
            .confirmationDialog(
                "Remover exercício?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Remover", role: .destructive) {
                    if let idx = itemToDelete {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            sessionStore.removeExercise(fromPhase: phaseIndex, at: idx)
                        }
                    }
                    itemToDelete = nil
                }
                Button("Cancelar", role: .cancel) {
                    itemToDelete = nil
                }
            } message: {
                Text("Este exercício será removido do treino atual.")
            }
        }
    }

    // MARK: - Computed Properties

    /// Fases que são afetadas pelo modo de exibição
    private var isFilterablePhase: Bool {
        phase.kind == .warmup || phase.kind == .aerobic || phase.kind == .finisher
    }

    /// Itens filtrados conforme o modo de exibição
    private var filteredItems: [WorkoutPlanItem] {
        guard isFilterablePhase else {
            // Força, Acessórios, etc. sempre mostram todos os itens
            return phase.items
        }

        switch displayMode {
        case .auto:
            // Mostra tudo (mesclado)
            return phase.items
        case .exercises:
            // Apenas exercícios
            return phase.items.filter { item in
                if case .exercise = item { return true }
                return false
            }
        case .guided:
            // Apenas atividades guiadas
            return phase.items.filter { item in
                if case .activity = item { return true }
                return false
            }
        }
    }

    private var phaseHeaderTitle: String {
        var title = phase.title

        // Adiciona indicador do modo quando aplicável
        if isFilterablePhase && displayMode != .auto {
            let modeIndicator = displayMode == .exercises ? "🏋️" : "🎯"
            title = "\(title) \(modeIndicator)"
        }

        if let rpe = phase.rpeTarget {
            return "\(title) · RPE \(rpe)"
        }
        return title
    }
}

// MARK: - Button Style for Exercise Row

/// Custom button style that provides visual feedback on press
/// without interfering with the row's appearance
struct ExerciseRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
