//
//  PersonalTrainerView.swift
//  FitToday
//
//  Created by AI on 04/02/26.
//

import SwiftUI
import Swinject

struct PersonalTrainerView: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.dependencyResolver) private var resolver

    @State private var viewModel: PersonalTrainerViewModel
    @State private var showSearchSheet = false

    init(resolver: Resolver) {
        _viewModel = State(wrappedValue: PersonalTrainerViewModel(resolver: resolver))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: FitTodaySpacing.lg) {
                if viewModel.isLoading && viewModel.currentTrainer == nil {
                    loadingView
                } else if !viewModel.isFeatureEnabled {
                    featureDisabledView
                } else if viewModel.hasTrainer {
                    connectedTrainerSection
                } else {
                    findTrainerSection
                }
            }
            .padding()
        }
        .background(FitTodayColor.background.ignoresSafeArea())
        .navigationTitle("Personal Trainer")
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
        .sheet(isPresented: $showSearchSheet) {
            TrainerSearchView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showConnectionSheet) {
            if let trainer = viewModel.selectedTrainer {
                ConnectionRequestSheet(
                    trainer: trainer,
                    isRequesting: viewModel.isRequestingConnection,
                    onConfirm: {
                        Task {
                            let success = await viewModel.requestConnection(to: trainer)
                            if success {
                                showSearchSheet = false
                            }
                        }
                    },
                    onCancel: {
                        viewModel.dismissConnectionSheet()
                    }
                )
                .presentationDetents([.medium])
            }
        }
        .alert(
            "Erro",
            isPresented: Binding(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.clearError() } }
            )
        ) {
            Button("Ok", role: .cancel) {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "Algo deu errado.")
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: FitTodaySpacing.md) {
            ProgressView()
                .tint(FitTodayColor.brandPrimary)
            Text("Carregando...")
                .font(FitTodayFont.ui(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }

    // MARK: - Feature Disabled View

    private var featureDisabledView: some View {
        VStack(spacing: FitTodaySpacing.lg) {
            Image(systemName: "person.badge.clock")
                .font(.system(size: 64))
                .foregroundStyle(FitTodayColor.textSecondary)

            Text("Em breve")
                .font(FitTodayFont.ui(size: 24, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)

            Text("A funcionalidade de Personal Trainer estara disponivel em breve. Fique ligado nas atualizacoes!")
                .font(FitTodayFont.ui(size: 16, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Find Trainer Section

    private var findTrainerSection: some View {
        VStack(spacing: FitTodaySpacing.xl) {
            // Header
            VStack(spacing: FitTodaySpacing.sm) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 64))
                    .foregroundStyle(FitTodayColor.brandPrimary)

                Text("Conecte-se ao seu Personal")
                    .font(FitTodayFont.ui(size: 24, weight: .bold))
                    .foregroundStyle(FitTodayColor.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Receba treinos personalizados e acompanhamento do seu personal trainer diretamente no app.")
                    .font(FitTodayFont.ui(size: 16, weight: .medium))
                    .foregroundStyle(FitTodayColor.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Actions
            VStack(spacing: FitTodaySpacing.md) {
                Button {
                    showSearchSheet = true
                } label: {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Buscar Personal Trainer")
                    }
                }
                .fitPrimaryStyle()

                // Invite Code Section
                VStack(spacing: FitTodaySpacing.sm) {
                    Text("Ou use um codigo de convite")
                        .font(FitTodayFont.ui(size: 14, weight: .medium))
                        .foregroundStyle(FitTodayColor.textSecondary)

                    HStack(spacing: FitTodaySpacing.sm) {
                        TextField("CODIGO", text: $viewModel.inviteCode)
                            .textFieldStyle(.roundedBorder)
                            .textCase(.uppercase)
                            .autocorrectionDisabled()
                            .frame(maxWidth: 200)

                        Button {
                            Task {
                                await viewModel.findByInviteCode()
                            }
                        } label: {
                            if viewModel.isSearching {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Usar")
                            }
                        }
                        .fitPrimaryStyle()
                        .disabled(!viewModel.canUseInviteCode || viewModel.isSearching)
                    }
                }
            }

            // Benefits
            benefitsSection
        }
    }

    // MARK: - Benefits Section

    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            Text("Beneficios")
                .font(FitTodayFont.ui(size: 18, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)

            benefitRow(icon: "dumbbell.fill", title: "Treinos Personalizados", description: "Receba treinos feitos especialmente para voce")

            benefitRow(icon: "chart.line.uptrend.xyaxis", title: "Acompanhamento", description: "Seu progresso monitorado pelo seu personal")

            benefitRow(icon: "message.fill", title: "Comunicacao Direta", description: "Tire duvidas e receba feedback")

            benefitRow(icon: "calendar", title: "Agenda Sincronizada", description: "Treinos na data certa automaticamente")
        }
        .padding()
        .background(FitTodayColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.lg))
    }

    private func benefitRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: FitTodaySpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(FitTodayColor.brandPrimary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(FitTodayFont.ui(size: 16, weight: .semiBold))
                    .foregroundStyle(FitTodayColor.textPrimary)

                Text(description)
                    .font(FitTodayFont.ui(size: 14, weight: .medium))
                    .foregroundStyle(FitTodayColor.textSecondary)
            }
        }
    }

    // MARK: - Connected Trainer Section

    private var connectedTrainerSection: some View {
        VStack(spacing: FitTodaySpacing.lg) {
            if let trainer = viewModel.currentTrainer {
                // Trainer Card
                TrainerCard(trainer: trainer, variant: .expanded)

                // Connection Status
                connectionStatusBadge

                // Assigned Workouts
                if viewModel.isConnected {
                    assignedWorkoutsSection
                }

                // Actions
                connectionActionsSection
            }
        }
    }

    // MARK: - Connection Status Badge

    private var connectionStatusBadge: some View {
        HStack(spacing: FitTodaySpacing.sm) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            Text(statusText)
                .font(FitTodayFont.ui(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .padding(.horizontal, FitTodaySpacing.md)
        .padding(.vertical, FitTodaySpacing.sm)
        .background(statusColor.opacity(0.1))
        .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch viewModel.connectionStatus {
        case .active: return FitTodayColor.success
        case .pending: return FitTodayColor.warning
        case .paused: return FitTodayColor.info
        case .cancelled: return FitTodayColor.error
        case .none: return FitTodayColor.textSecondary
        }
    }

    private var statusText: String {
        switch viewModel.connectionStatus {
        case .active: return "Conectado"
        case .pending: return "Aguardando aprovacao"
        case .paused: return "Conexao pausada"
        case .cancelled: return "Conexao cancelada"
        case .none: return "Sem conexao"
        }
    }

    // MARK: - Assigned Workouts Section

    private var assignedWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            HStack {
                Text("Treinos Atribuidos")
                    .font(FitTodayFont.ui(size: 18, weight: .bold))
                    .foregroundStyle(FitTodayColor.textPrimary)

                Spacer()

                if viewModel.pendingWorkoutsCount > 0 {
                    Text("\(viewModel.pendingWorkoutsCount) pendente(s)")
                        .font(FitTodayFont.ui(size: 12, weight: .medium))
                        .foregroundStyle(FitTodayColor.brandPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(FitTodayColor.brandPrimary.opacity(0.1))
                        .clipShape(Capsule())
                }
            }

            if viewModel.assignedWorkouts.isEmpty {
                Text("Nenhum treino atribuido ainda.")
                    .font(FitTodayFont.ui(size: 14, weight: .medium))
                    .foregroundStyle(FitTodayColor.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(viewModel.assignedWorkouts) { workout in
                    AssignedWorkoutRow(workout: workout)
                }
            }
        }
        .padding()
        .background(FitTodayColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.lg))
    }

    // MARK: - Connection Actions Section

    private var connectionActionsSection: some View {
        VStack(spacing: FitTodaySpacing.sm) {
            if viewModel.isPending {
                Button {
                    Task {
                        await viewModel.cancelConnection()
                    }
                } label: {
                    HStack {
                        Image(systemName: "xmark.circle")
                        Text("Cancelar Solicitacao")
                    }
                }
                .fitSecondaryStyle()
            } else if viewModel.isConnected {
                Button(role: .destructive) {
                    Task {
                        await viewModel.cancelConnection()
                    }
                } label: {
                    HStack {
                        Image(systemName: "person.badge.minus")
                        Text("Desconectar")
                    }
                }
                .fitSecondaryStyle()
            }
        }
    }
}

// MARK: - Assigned Workout Row

private struct AssignedWorkoutRow: View {
    let workout: TrainerWorkout

    private var exerciseCount: Int {
        workout.phases.reduce(0) { $0 + $1.items.count }
    }

    private var scheduledDate: Date? {
        workout.schedule.scheduledDate
    }

    var body: some View {
        HStack(spacing: FitTodaySpacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(workout.isActive ? FitTodayColor.brandPrimary.opacity(0.1) : FitTodayColor.textSecondary.opacity(0.1))
                    .frame(width: 44, height: 44)

                Image(systemName: workout.isActive ? "dumbbell.fill" : "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(workout.isActive ? FitTodayColor.brandPrimary : FitTodayColor.success)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.title)
                    .font(FitTodayFont.ui(size: 16, weight: .semiBold))
                    .foregroundStyle(FitTodayColor.textPrimary)
                    .lineLimit(1)

                HStack(spacing: FitTodaySpacing.sm) {
                    Text("\(exerciseCount) exercicios")
                        .font(FitTodayFont.ui(size: 12, weight: .medium))
                        .foregroundStyle(FitTodayColor.textSecondary)

                    if let scheduledDate = scheduledDate {
                        Text("- \(scheduledDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(FitTodayFont.ui(size: 12, weight: .medium))
                            .foregroundStyle(FitTodayColor.textSecondary)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .padding()
        .background(FitTodayColor.background)
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PersonalTrainerView(resolver: Container())
            .environment(AppRouter())
    }
}
