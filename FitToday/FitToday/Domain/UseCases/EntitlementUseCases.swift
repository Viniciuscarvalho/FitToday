//
//  EntitlementUseCases.swift
//  FitToday
//
//  Created by AI on 03/01/26.
//

import Foundation

struct GetProEntitlementUseCase {
    private let repository: EntitlementRepository

    init(repository: EntitlementRepository) {
        self.repository = repository
    }

    func execute() async throws -> ProEntitlement {
        try await repository.currentEntitlement()
    }

    func observe() -> AsyncStream<ProEntitlement> {
        repository.entitlementStream()
    }
}




