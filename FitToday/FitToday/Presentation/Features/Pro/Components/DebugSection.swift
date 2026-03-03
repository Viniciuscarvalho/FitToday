//
//  DebugSection.swift
//  FitToday
//
//  Created by AI on 14/01/26.
//

import SwiftUI
import SwiftData
import Swinject

#if DEBUG
// 💡 Learn: Seção de debug com ferramentas para desenvolvimento
// Componente extraído para manter a view principal < 100 linhas
struct DebugSection: View {
    @Binding var debugModeEnabled: Bool
    @Binding var debugIsPro: Bool
    @Binding var showingRestoreAlert: Bool
    @Binding var restoreMessage: String

    let resolver: Resolver
    let onDebugModeChange: (Bool) -> Void
    let onDebugProChange: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            SectionHeader(title: "🛠 Modo Debug", actionTitle: nil)

            VStack(spacing: 0) {
                debugModeToggle

                if debugModeEnabled {
                    Divider().padding(.leading, 56)
                    proModeToggle
                    Divider().padding(.leading, 56)
                    resetAICounterButton
                    Divider().padding(.leading, 56)
                    clearExerciseCachesButton
                    Divider().padding(.leading, 56)
                    clearWorkoutCompositionCachesButton
                    Divider().padding(.leading, 56)
                    seedTestDataButton
                }
            }
            .background(FitTodayColor.surface)
            .cornerRadius(FitTodayRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: FitTodayRadius.md)
                    .stroke(.orange.opacity(0.5), lineWidth: 1)
            )

            Text("⚠️ Esta seção é visível apenas em builds de desenvolvimento.")
                .font(.system(.caption2))
                .foregroundStyle(.orange)
                .padding(.horizontal, FitTodaySpacing.sm)
        }
    }

    // MARK: - Debug Mode Toggle

    private var debugModeToggle: some View {
        Toggle(isOn: $debugModeEnabled) {
            HStack(spacing: FitTodaySpacing.md) {
                Image(systemName: "ladybug.fill")
                    .foregroundStyle(.orange)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ativar Modo Debug")
                        .font(.system(.body))
                        .foregroundStyle(FitTodayColor.textPrimary)
                    Text("Sobrescreve o status real do StoreKit")
                        .font(.system(.caption))
                        .foregroundStyle(FitTodayColor.textSecondary)
                }
            }
        }
        .tint(FitTodayColor.brandPrimary)
        .padding()
        .onChange(of: debugModeEnabled) { _, enabled in
            onDebugModeChange(enabled)
        }
    }

    // MARK: - Pro Mode Toggle

    private var proModeToggle: some View {
        Toggle(isOn: $debugIsPro) {
            HStack(spacing: FitTodaySpacing.md) {
                Image(systemName: debugIsPro ? "crown.fill" : "person.fill")
                    .foregroundStyle(debugIsPro ? .yellow : FitTodayColor.textSecondary)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(debugIsPro ? "Modo Pro" : "Modo Free")
                        .font(.system(.body, weight: .medium))
                        .foregroundStyle(FitTodayColor.textPrimary)
                    Text("Simular status de assinatura")
                        .font(.system(.caption))
                        .foregroundStyle(FitTodayColor.textSecondary)
                }
            }
        }
        .tint(.yellow)
        .padding()
        .onChange(of: debugIsPro) { _, isPro in
            onDebugProChange(isPro)
        }
    }

    // MARK: - Debug Actions

    private var resetAICounterButton: some View {
        DebugActionButton(
            icon: "sparkles",
            iconColor: .purple,
            title: "Resetar contador de IA",
            subtitle: "Limpa o limite diário de uso da OpenAI"
        ) {
            resetAIUsageCounter()
        }
    }

    private var clearExerciseCachesButton: some View {
        DebugActionButton(
            icon: "trash.fill",
            iconColor: .red,
            title: "Limpar caches de exercícios",
            subtitle: "Limpa cache de exercícios e imagens do Firestore",
            isBold: true
        ) {
            clearExerciseCaches()
        }
    }

    private var clearWorkoutCompositionCachesButton: some View {
        DebugActionButton(
            icon: "figure.run.circle.fill",
            iconColor: .cyan,
            title: "Limpar cache de treinos",
            subtitle: "Força nova geração de treinos via IA",
            isBold: true
        ) {
            clearWorkoutCompositionCaches()
        }
    }

    private var seedTestDataButton: some View {
        DebugActionButton(
            icon: "testtube.2",
            iconColor: .purple,
            title: "Criar dados de teste",
            subtitle: "Perfil + Pro + CheckIn (para debug)",
            isBold: true
        ) {
            seedTestData()
        }
    }

    // MARK: - Debug Actions Implementation

    private func resetAIUsageCounter() {
        UserDefaults.standard.removeObject(forKey: "openai_usage_records")
        restoreMessage = "Contador de IA resetado! Você pode gerar novos treinos com IA."
        showingRestoreAlert = true
    }

    private func clearExerciseCaches() {
        // Limpa caches de exercícios
        Task {
            await ExerciseImageCache.shared.clearCache()
        }
        restoreMessage = "Caches de exercícios foram limpos! O app fará novas buscas na próxima visualização."
        showingRestoreAlert = true
    }

    private func clearWorkoutCompositionCaches() {
        Task {
            if let cacheRepo = resolver.resolve(WorkoutCompositionCacheRepository.self) {
                do {
                    try await cacheRepo.clearAll()
                    print("[Debug] ✅ Cache de composição (SwiftData) limpo")
                } catch {
                    print("[Debug] ⚠️ Erro ao limpar cache de composição: \(error)")
                }
            }

            print("[Debug] ℹ️ Cache de respostas OpenAI (memória) será limpo ao reiniciar o app")

            await MainActor.run {
                restoreMessage = "Caches de treino limpos! Reinicie o app para limpar o cache em memória da OpenAI. Novos treinos serão gerados na próxima requisição."
                showingRestoreAlert = true
            }
        }
    }

    private func seedTestData() {
        Task {
            if let modelContainer = resolver.resolve(ModelContainer.self) {
                await DebugDataSeeder.seedTestProfileIfNeeded(in: modelContainer.mainContext)
            }

            DebugDataSeeder.enableProMode()
            debugModeEnabled = true
            debugIsPro = true

            DebugDataSeeder.seedDailyCheckIn()

            await MainActor.run {
                restoreMessage = "Dados de teste criados!\n\n• Perfil: Hipertrofia + Academia\n• Modo Pro: Ativado\n• Check-in: FullBody + Sem dor\n\nVá para Home e toque em 'Ver Treino de Hoje'"
                showingRestoreAlert = true
            }
        }
    }
}

// MARK: - Debug Action Button Component

private struct DebugActionButton: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    var isBold: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: FitTodaySpacing.md) {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.body, weight: isBold ? .semibold : .regular))
                        .foregroundStyle(FitTodayColor.textPrimary)
                    Text(subtitle)
                        .font(.system(.caption))
                        .foregroundStyle(FitTodayColor.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(.caption, weight: .semibold))
                    .foregroundStyle(FitTodayColor.textTertiary)
            }
            .padding()
        }
        .buttonStyle(.plain)
    }
}
#endif
