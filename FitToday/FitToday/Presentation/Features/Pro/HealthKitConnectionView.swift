//
//  HealthKitConnectionView.swift
//  FitToday
//
//  Created by AI on 12/01/26.
//

import SwiftUI
import Combine
import Swinject

final class HealthKitConnectionViewModel: ObservableObject {
    @Published private(set) var authorizationState: HealthKitAuthorizationState = .notDetermined
    @Published private(set) var isWorking = false
    @Published private(set) var lastSyncResult: String?
    @Published var errorMessage: ErrorMessage?
    
    private let entitlementRepository: EntitlementRepository
    private let healthKit: any HealthKitServicing
    private let syncService: HealthKitHistorySyncService
    
    init(
        entitlementRepository: EntitlementRepository,
        healthKit: any HealthKitServicing,
        syncService: HealthKitHistorySyncService
    ) {
        self.entitlementRepository = entitlementRepository
        self.healthKit = healthKit
        self.syncService = syncService
    }
    
    func load() {
        Task { await refreshAuthorizationState() }
    }
    
    func connect() async {
        do {
            await MainActor.run { self.isWorking = true }
            defer { 
                Task { @MainActor in self.isWorking = false }
            }
            
            let entitlement = try await entitlementRepository.currentEntitlement()
            guard entitlement.isPro else {
                throw DomainError.invalidInput(reason: "Apple Health é um recurso PRO.")
            }
            
            try await healthKit.requestAuthorization()
            await refreshAuthorizationState()
        } catch {
            handleError(error)
        }
    }
    
    func syncLast30Days() async {
        do {
            await MainActor.run { self.isWorking = true }
            defer { 
                Task { @MainActor in self.isWorking = false }
            }
            
            let entitlement = try await entitlementRepository.currentEntitlement()
            guard entitlement.isPro else {
                throw DomainError.invalidInput(reason: "Apple Health é um recurso PRO.")
            }
            
            let updated = try await syncService.syncLastDays(30)
            await MainActor.run { self.lastSyncResult = "\(updated) treinos atualizados com duração/calorias." }
        } catch {
            handleError(error)
        }
    }
    
    private func refreshAuthorizationState() async {
        let state = await healthKit.authorizationState()
        await MainActor.run { self.authorizationState = state }
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ error: Error) {
        #if DEBUG
        print("[Error] \(type(of: self)): \(error.localizedDescription)")
        #endif
        
        let mapped = ErrorMapper.userFriendlyMessage(for: error)
        Task { @MainActor in
            self.errorMessage = mapped
        }
    }
}

struct HealthKitConnectionView: View {
    @StateObject private var viewModel: HealthKitConnectionViewModel
    
    init(resolver: Resolver) {
        guard
            let entitlementRepo = resolver.resolve(EntitlementRepository.self),
            let healthKit = resolver.resolve(HealthKitServicing.self),
            let sync = resolver.resolve(HealthKitHistorySyncService.self)
        else {
            fatalError("Dependências de HealthKit não registradas.")
        }
        _viewModel = StateObject(wrappedValue: HealthKitConnectionViewModel(
            entitlementRepository: entitlementRepo,
            healthKit: healthKit,
            syncService: sync
        ))
    }
    
    var body: some View {
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
        .background(FitTodayColor.background.ignoresSafeArea())
        .navigationTitle("Apple Health")
        .navigationBarTitleDisplayMode(.inline)
        .task { viewModel.load() }
        .errorToast(errorMessage: $viewModel.errorMessage)
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

