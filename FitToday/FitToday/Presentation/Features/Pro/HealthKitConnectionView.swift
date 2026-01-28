//
//  HealthKitConnectionView.swift
//  FitToday
//
//  Created by AI on 12/01/26.
//

import SwiftUI
import Swinject

// 💡 Learn: @Observable substitui ObservableObject para gerenciamento de estado moderno
@MainActor
@Observable final class HealthKitConnectionViewModel {
    private(set) var authorizationState: HealthKitAuthorizationState = .notDetermined
    private(set) var isWorking = false
    private(set) var lastSyncResult: String?
    var errorMessage: ErrorMessage?

    private let healthKit: any HealthKitServicing
    private let syncService: HealthKitHistorySyncService

    init(
        healthKit: any HealthKitServicing,
        syncService: HealthKitHistorySyncService
    ) {
        self.healthKit = healthKit
        self.syncService = syncService
    }
    
    func load() {
        Task { await refreshAuthorizationState() }
    }
    
    func connect() async {
        do {
            isWorking = true
            defer { isWorking = false }

            // HealthKit disponível para todos os usuários (free e PRO)
            try await healthKit.requestAuthorization()
            await refreshAuthorizationState()
        } catch {
            handleError(error)
        }
    }

    func syncLast30Days() async {
        do {
            isWorking = true
            defer { isWorking = false }

            // HealthKit disponível para todos os usuários (free e PRO)
            // 1. Sincronizar workouts existentes do FitToday com dados do HealthKit
            let updated = try await syncService.syncLastDays(30)

            // 2. Importar workouts externos do Apple Health (feitos fora do app)
            let imported = try await syncService.importExternalWorkouts(days: 30)

            if imported > 0 {
                lastSyncResult = "\(updated) treinos atualizados e \(imported) treinos do Apple Health importados."
            } else {
                lastSyncResult = "\(updated) treinos atualizados com duração/calorias."
            }
        } catch {
            handleError(error)
        }
    }

    private func refreshAuthorizationState() async {
        let state = await healthKit.authorizationState()
        authorizationState = state
    }

    // MARK: - Error Handling

    private func handleError(_ error: Error) {
        #if DEBUG
        print("[Error] \(type(of: self)): \(error.localizedDescription)")
        #endif

        let mapped = ErrorMapper.userFriendlyMessage(for: error)
        errorMessage = mapped
    }
}

struct HealthKitConnectionView: View {
    // 💡 Learn: Com @Observable, usamos @State em vez de @StateObject
    @State private var viewModel: HealthKitConnectionViewModel?
    @State private var dependencyError: String?

    init(resolver: Resolver) {
        if let healthKit = resolver.resolve(HealthKitServicing.self),
           let sync = resolver.resolve(HealthKitHistorySyncService.self) {
            _viewModel = State(initialValue: HealthKitConnectionViewModel(
                healthKit: healthKit,
                syncService: sync
            ))
            _dependencyError = State(initialValue: nil)
        } else {
            _viewModel = State(initialValue: nil)
            _dependencyError = State(initialValue: "Erro de configuração: serviços de HealthKit não estão registrados.")
        }
    }
    
    var body: some View {
        Group {
            if let error = dependencyError {
                DependencyErrorView(message: error)
            } else if let viewModel = viewModel {
                contentView(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .background(FitTodayColor.background.ignoresSafeArea())
        .navigationTitle("Apple Health")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func contentView(viewModel: HealthKitConnectionViewModel) -> some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.lg) {
            VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
                Text("Apple Health")
                    .font(FitTodayFont.display(size: 22, weight: .bold))
                Text("Conecte para importar duração/calorias e exportar seus treinos concluídos.")
                    .font(.system(.subheadline))
                    .foregroundStyle(FitTodayColor.textSecondary)
            }

            StatusCard(state: viewModel.authorizationState)

            VStack(spacing: FitTodaySpacing.sm) {
                Button("Conectar") {
                    Task { await viewModel.connect() }
                }
                .fitPrimaryStyle()
                .disabled(viewModel.isWorking)

                Button("Importar últimos 30 dias") {
                    Task { await viewModel.syncLast30Days() }
                }
                .fitSecondaryStyle()
                .disabled(viewModel.isWorking || viewModel.authorizationState != .authorized)
            }

            if let result = viewModel.lastSyncResult {
                Text(result)
                    .font(.system(.footnote, weight: .medium))
                    .foregroundStyle(FitTodayColor.textSecondary)
            }

            Spacer()
        }
        .padding()
        .task { viewModel.load() }
        .errorToast(errorMessage: Binding(
            get: { viewModel.errorMessage },
            set: { viewModel.errorMessage = $0 }
        ))
    }
}

private struct StatusCard: View {
    let state: HealthKitAuthorizationState
    
    private var title: String {
        switch state {
        case .notAvailable: return "Indisponível"
        case .notDetermined: return "Não configurado"
        case .denied: return "Permissão negada"
        case .authorized: return "Conectado"
        }
    }
    
    private var subtitle: String {
        switch state {
        case .notAvailable:
            return "HealthKit não está disponível neste dispositivo."
        case .notDetermined:
            return "Toque em Conectar para permitir acesso."
        case .denied:
            return "Você pode liberar o acesso em Ajustes > Saúde."
        case .authorized:
            return "Pronto para importar métricas e exportar treinos."
        }
    }
    
    private var style: FitBadge.Style {
        switch state {
        case .authorized: return .success
        case .denied: return .warning
        case .notAvailable: return .warning
        case .notDetermined: return .warning
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            HStack {
                Text("Status")
                    .font(.system(.caption, weight: .semibold))
                    .foregroundStyle(FitTodayColor.textSecondary)
                Spacer()
                FitBadge(text: title, style: style)
            }
            Text(subtitle)
                .font(.system(.subheadline))
                .foregroundStyle(FitTodayColor.textPrimary)
        }
        .padding()
        .background(FitTodayColor.surface)
        .cornerRadius(FitTodayRadius.md)
        .techCornerBorders(length: 12, thickness: 1.5)
        .fitCardShadow()
    }
}

