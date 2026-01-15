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
    let displayMode: PhaseDisplayMode

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
                            WorkoutExerciseRow(
                                index: localIndex,
                                prescription: prescription,
                                isCurrent: sessionStore.currentExerciseIndex == localIndex
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                router.push(.workoutExercisePreview(prescription), on: .home)
                            }
                            .accessibilityHint("Toque para ver detalhes do exercício")
                        }
                    }
                }
            }
            .padding(.top, FitTodaySpacing.md)
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
