//
//  StoreKitEntitlementRepository.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import Foundation
import SwiftData
import Combine

@MainActor
final class StoreKitEntitlementRepository: EntitlementRepository, @unchecked Sendable {
    private let modelContainer: ModelContainer
    private let storeKitService: StoreKitService
    private var latest: ProEntitlement
    private var streamContinuation: AsyncStream<ProEntitlement>.Continuation?
    private var cancellables = Set<AnyCancellable>()
    
    private lazy var stream: AsyncStream<ProEntitlement> = {
        AsyncStream { continuation in
            continuation.yield(latest)
            continuation.onTermination = { _ in }
            self.streamContinuation = continuation
        }
    }()

    init(modelContainer: ModelContainer, storeKitService: StoreKitService) {
        self.modelContainer = modelContainer
        self.storeKitService = storeKitService
        
        // Carregar do cache local primeiro (startup rápido)
        if let snapshot = try? Self.fetchSnapshot(from: modelContainer) {
            latest = EntitlementMapper.toDomain(snapshot)
        } else {
            latest = .free
        }
        
        // Observar mudanças no StoreKitService
        setupSubscriptionObserver()
        
        // Verificar status atual do StoreKit em background
        Task {
            await refreshFromStoreKit()
        }
    }
    
    private func setupSubscriptionObserver() {
        // 💡 Learn: Com @Observable, usamos withObservationTracking para observar mudanças
        Task {
            var previousValue = storeKitService.hasProAccess
            while !Task.isCancelled {
                let currentValue = await withObservationTracking {
                    storeKitService.hasProAccess
                } onChange: {
                    // Retorna quando há mudança
                }

                if currentValue != previousValue {
                    await handleSubscriptionChange(currentValue)
                    previousValue = currentValue
                }

                // Pequeno delay para evitar loop muito apertado
                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
            }
        }
    }
    
    private func handleSubscriptionChange(_ hasPro: Bool) async {
        let entitlement = await storeKitService.getCurrentEntitlement()
        await updateEntitlement(entitlement)
    }
    
    private func refreshFromStoreKit() async {
        await storeKitService.refreshPurchaseStatus()
        let entitlement = await storeKitService.getCurrentEntitlement()
        await updateEntitlement(entitlement)
    }

    func currentEntitlement() async throws -> ProEntitlement {
        latest
    }

    func entitlementStream() -> AsyncStream<ProEntitlement> {
        _ = stream
        return stream
    }
    
    private func updateEntitlement(_ entitlement: ProEntitlement) async {
        guard entitlement != latest else { return }
        latest = entitlement
        streamContinuation?.yield(entitlement)
        try? Self.save(snapshot: entitlement, in: modelContainer)
    }
    
    // MARK: - StoreKit Service Access
    
    var service: StoreKitService {
        storeKitService
    }

    // MARK: - Persistence

    private static func fetchSnapshot(from container: ModelContainer) throws -> SDProEntitlementSnapshot? {
        let context = ModelContext(container)
        var descriptor = FetchDescriptor<SDProEntitlementSnapshot>()
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private static func save(snapshot entitlement: ProEntitlement, in container: ModelContainer) throws {
        let context = ModelContext(container)
        var descriptor = FetchDescriptor<SDProEntitlementSnapshot>()
        descriptor.fetchLimit = 1
        if let existing = try context.fetch(descriptor).first {
            existing.isPro = entitlement.isPro
            existing.sourceRaw = entitlement.source.rawValue
            existing.expirationDate = entitlement.expirationDate
            existing.updatedAt = Date()
        } else {
            context.insert(EntitlementMapper.toSnapshot(entitlement))
        }
        try context.save()
    }
}

