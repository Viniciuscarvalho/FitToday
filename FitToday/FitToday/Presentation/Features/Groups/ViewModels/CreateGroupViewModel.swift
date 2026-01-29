//
//  CreateGroupViewModel.swift
//  FitToday
//
//  Created by Claude on 16/01/26.
//

import Foundation
import Swinject

// MARK: - CreateGroupViewModel

@MainActor
@Observable final class CreateGroupViewModel {
    // MARK: - Properties

    var groupName = ""
    private(set) var isLoading = false
    var errorMessage: ErrorMessage?

    // MARK: - Computed

    var canCreate: Bool {
        !groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Dependencies

    private let createGroupUseCase: CreateGroupUseCase

    // MARK: - Init

    init(resolver: Resolver) {
        self.createGroupUseCase = resolver.resolve(CreateGroupUseCase.self)!
    }

    // MARK: - Actions

    func createGroup() async -> SocialGroup? {
        guard canCreate else { return nil }

        isLoading = true
        defer { isLoading = false }

        do {
            let group = try await createGroupUseCase.execute(name: groupName.trimmingCharacters(in: .whitespacesAndNewlines))
            return group
        } catch {
            handleError(error)
            return nil
        }
    }

    // MARK: - Error Handling

    func handleError(_ error: Error) {
        if let domainError = error as? DomainError {
            errorMessage = ErrorMessage(title: "Erro", message: domainError.errorDescription ?? "Erro desconhecido")
        } else {
            errorMessage = ErrorMessage(title: "Erro", message: error.localizedDescription)
        }
    }
}

// MARK: - ErrorPresenting Conformance

extension CreateGroupViewModel: ErrorPresenting {}
