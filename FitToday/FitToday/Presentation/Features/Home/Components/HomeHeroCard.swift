//
//  HomeHeroCard.swift
//  FitToday
//
//  Created by AI on 15/01/26.
//

import SwiftUI

// 💡 Learn: Hero card da Home com estados dinâmicos
// Componente extraído para manter a view principal < 100 linhas
struct HomeHeroCard: View {
    let journeyState: HomeJourneyState
    let isGeneratingPlan: Bool
    let heroErrorMessage: String?
    let onCreateProfile: () -> Void
    let onStartDailyCheckIn: () -> Void
    let onViewTodayWorkout: () -> Void
    let onGeneratePlan: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.lg) {
            heroContent
        }
        .padding(FitTodaySpacing.lg)
        .background(heroGradient)
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.lg))
        .padding(.horizontal)
        .padding(.top, FitTodaySpacing.md)
    }

    // MARK: - Hero Content

    @ViewBuilder
    private var heroContent: some View {
        switch journeyState {
        case .loading:
            loadingContent
        case .noProfile:
            noProfileContent
        case .needsDailyCheckIn:
            needsCheckInContent
        case .workoutReady:
            workoutReadyContent
        case .workoutCompleted:
            workoutCompletedContent
        case .error(let message):
            errorContent(message: message)
        }
    }

    // MARK: - Loading State

    private var loadingContent: some View {
        VStack(spacing: FitTodaySpacing.md) {
            ProgressView()
                .tint(.white)
            Text("Carregando...")
                .font(FitTodayFont.ui(size: 16, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }

    // MARK: - No Profile State

    private var noProfileContent: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(.largeTitle, weight: .bold))
                .foregroundStyle(.white)

            Text("Bem-vindo ao FitToday!")
                .font(FitTodayFont.ui(size: 24, weight: .bold))
                .foregroundStyle(.white)

            Text("Crie seu perfil de treino para começar sua jornada fitness")
                .font(FitTodayFont.ui(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)

            Button(action: onCreateProfile) {
                HStack {
                    Text("Criar Perfil")
                        .font(FitTodayFont.ui(size: 16, weight: .bold))
                    Image(systemName: "arrow.right")
                        .font(.system(.body, weight: .bold))
                }
                .foregroundStyle(FitTodayColor.brandPrimary)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Needs Check-In State

    private var needsCheckInContent: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            Image(systemName: "flame.fill")
                .font(.system(.largeTitle, weight: .bold))
                .foregroundStyle(.orange)

            Text("Como você está hoje?")
                .font(FitTodayFont.ui(size: 24, weight: .bold))
                .foregroundStyle(.white)

            Text("Responda um breve check-in para gerar seu treino personalizado do dia")
                .font(FitTodayFont.ui(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)

            Button(action: onStartDailyCheckIn) {
                HStack {
                    Text("Fazer Check-in")
                        .font(FitTodayFont.ui(size: 16, weight: .bold))
                    Image(systemName: "arrow.right")
                        .font(.system(.body, weight: .bold))
                }
                .foregroundStyle(FitTodayColor.brandPrimary)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Workout Ready State

    private var workoutReadyContent: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            HStack {
                Image(systemName: "figure.run")
                    .font(.system(.title, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                if let errorMsg = heroErrorMessage {
                    Text(errorMsg)
                        .font(FitTodayFont.ui(size: 12, weight: .medium))
                        .foregroundStyle(.red.opacity(0.9))
                        .padding(.horizontal, FitTodaySpacing.sm)
                        .padding(.vertical, FitTodaySpacing.xs)
                        .background(.white.opacity(0.2))
                        .clipShape(Capsule())
                }
            }

            Text("Treino de Hoje")
                .font(FitTodayFont.ui(size: 24, weight: .bold))
                .foregroundStyle(.white)

            Text("Treino personalizado pronto para você")
                .font(FitTodayFont.ui(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)

            if isGeneratingPlan {
                HStack {
                    ProgressView()
                        .tint(.white)
                    Text("Gerando novo plano...")
                        .font(FitTodayFont.ui(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
            } else {
                Button(action: onViewTodayWorkout) {
                    HStack {
                        Text("Ver Treino de Hoje")
                            .font(FitTodayFont.ui(size: 16, weight: .bold))
                        Image(systemName: "arrow.right")
                            .font(.system(.body, weight: .bold))
                    }
                    .foregroundStyle(Color(red: 0.4, green: 0.6, blue: 0))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Workout Completed State

    private var workoutCompletedContent: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(.largeTitle, weight: .bold))
                .foregroundStyle(.green)

            Text("Treino Concluído!")
                .font(FitTodayFont.ui(size: 24, weight: .bold))
                .foregroundStyle(.white)

            Text("Você já treinou hoje! Descanse e volte amanhã.")
                .font(FitTodayFont.ui(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Error State

    private func errorContent(message: String) -> some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(.largeTitle, weight: .bold))
                .foregroundStyle(.red)

            Text("Erro ao Carregar Treino")
                .font(FitTodayFont.ui(size: 24, weight: .bold))
                .foregroundStyle(.white)

            Text(message)
                .font(FitTodayFont.ui(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)

            Button(action: onGeneratePlan) {
                HStack {
                    Text("Tentar Novamente")
                        .font(FitTodayFont.ui(size: 16, weight: .bold))
                    Image(systemName: "arrow.clockwise")
                        .font(.system(.body, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.white.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Gradient

    private var heroGradient: LinearGradient {
        switch journeyState {
        case .loading:
            return LinearGradient(
                colors: [.gray.opacity(0.6), .gray.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .noProfile:
            return LinearGradient(
                colors: [FitTodayColor.brandPrimary.opacity(0.8), .purple.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .needsDailyCheckIn:
            return LinearGradient(
                colors: [.orange.opacity(0.8), .red.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .workoutReady:
            return LinearGradient(
                colors: [.blue.opacity(0.7), .cyan.opacity(0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .workoutCompleted:
            return LinearGradient(
                colors: [.green.opacity(0.7), .teal.opacity(0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .error:
            return LinearGradient(
                colors: [.red.opacity(0.6), .orange.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
