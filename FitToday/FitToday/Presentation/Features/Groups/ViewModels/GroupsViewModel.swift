//
//  GroupsViewModel.swift
//  FitToday
//
//  Created by Claude on 16/01/26.
//

import Foundation
import Swinject

// MARK: - GroupsViewModel

@MainActor
@Observable final class GroupsViewModel {
    // MARK: - Properties

    private(set) var currentGroup: SocialGroup?
    private(set) var members: [GroupMember] = []
    private(set) var currentUserId: String?
    private(set) var isLoading = false
    private(set) var isAdmin = false
    private(set) var unreadNotificationsCount = 0
    private(set) var isSocialGroupsEnabled = true
    var errorMessage: ErrorMessage?

    // MARK: - Dependencies

    private let resolver: Resolver
    private let authRepository: AuthenticationRepository
    private let groupRepository: GroupRepository
    private let leaveGroupUseCase: LeaveGroupUseCase
    private var notificationService: FirebaseNotificationService?

    // MARK: - Init

    init(resolver: Resolver) {
        self.resolver = resolver
        self.authRepository = resolver.resolve(AuthenticationRepository.self)!
        self.groupRepository = resolver.resolve(GroupRepository.self)!
        self.leaveGroupUseCase = resolver.resolve(LeaveGroupUseCase.self)!
        self.notificationService = resolver.resolve(FirebaseNotificationService.self)
    }

    // MARK: - Lifecycle

    func onAppear() async {
        // Check feature flag
        if let featureFlags = resolver.resolve(FeatureFlagChecking.self) {
            isSocialGroupsEnabled = await featureFlags.isFeatureEnabled(.socialGroupsEnabled)
        }
        guard isSocialGroupsEnabled else { return }

        await loadCurrentGroup()
        await loadUnreadNotificationsCount()
    }

    // MARK: - Actions

    func loadCurrentGroup() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Get current user
            guard let user = try await authRepository.currentUser() else {
                currentGroup = nil
                members = []
                currentUserId = nil
                return
            }

            currentUserId = user.id

            // Load group if user is in one
            if let groupId = user.currentGroupId {
                currentGroup = try await groupRepository.getGroup(groupId)
                if let group = currentGroup {
                    members = try await groupRepository.getMembers(groupId: group.id)

                    // Check if current user is admin
                    isAdmin = members.first(where: { $0.id == user.id })?.role == .admin
                }
            } else {
                currentGroup = nil
                members = []
            }
        } catch {
            handleError(error)
        }
    }

    func leaveGroup() async {
        guard let group = currentGroup else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            try await leaveGroupUseCase.execute(groupId: group.id)
            currentGroup = nil
            members = []
            isAdmin = false
        } catch {
            handleError(error)
        }
    }

    func refreshMembers() async {
        guard let group = currentGroup else { return }

        do {
            members = try await groupRepository.getMembers(groupId: group.id)
        } catch {
            handleError(error)
        }
    }

    func removeMember(userId: String) async {
        guard let group = currentGroup, isAdmin else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            try await groupRepository.removeMember(groupId: group.id, userId: userId)
            // Update local state
            members.removeAll { $0.id == userId }
        } catch {
            handleError(error)
        }
    }

    func deleteGroup() async {
        guard let group = currentGroup, isAdmin else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            try await groupRepository.deleteGroup(group.id)
            // Clear local state
            currentGroup = nil
            members = []
            isAdmin = false
        } catch {
            handleError(error)
        }
    }

    func loadUnreadNotificationsCount() async {
        guard let userId = currentUserId,
              let service = notificationService else { return }

        do {
            unreadNotificationsCount = try await service.getUnreadCount(userId: userId)
        } catch {
            #if DEBUG
            print("[GroupsViewModel] Failed to load unread count: \(error)")
            #endif
        }
    }

    func clearUnreadCount() {
        unreadNotificationsCount = 0
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

extension GroupsViewModel: ErrorPresenting {}
