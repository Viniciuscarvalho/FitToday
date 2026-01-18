//
//  JoinGroupViewModel.swift
//  FitToday
//
//  Created by Claude on 16/01/26.
//

import Foundation
import Swinject

// MARK: - JoinGroupViewModel

@MainActor
@Observable final class JoinGroupViewModel {
    // MARK: - Properties

    private(set) var groupPreview: SocialGroup?
    private(set) var isLoading = false
    private(set) var isJoining = false
    var errorMessage: ErrorMessage?

    // MARK: - Dependencies

    private let groupRepository: GroupRepository
    private let joinGroupUseCase: JoinGroupUseCase

    // MARK: - Init

    init(resolver: Resolver) {
        self.groupRepository = resolver.resolve(GroupRepository.self)!
        self.joinGroupUseCase = resolver.resolve(JoinGroupUseCase.self)!
    }

    // MARK: - Actions

    func loadGroupPreview(groupId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            groupPreview = try await groupRepository.getGroup(groupId)
        } catch {
            handleError(error)
        }
    }

    func joinGroup(groupId: String) async -> Bool {
        isJoining = true
        defer { isJoining = false }

        do {
            try await joinGroupUseCase.execute(groupId: groupId)
            return true
        } catch {
            handleError(error)
            return false
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

extension JoinGroupViewModel: ErrorPresenting {}
