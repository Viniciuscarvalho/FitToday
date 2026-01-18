//
//  FirebaseGroupRepository.swift
//  FitToday
//
//  Created by Claude on 16/01/26.
//

import Foundation

// MARK: - FirebaseGroupRepository

final class FirebaseGroupRepository: GroupRepository, @unchecked Sendable {
    private let groupService: FirebaseGroupService

    init(groupService: FirebaseGroupService = FirebaseGroupService()) {
        self.groupService = groupService
    }

    // MARK: - GroupRepository

    func createGroup(name: String, ownerId: String) async throws -> SocialGroup {
        let fbGroup = try await groupService.createGroup(name: name, ownerId: ownerId)
        return fbGroup.toDomain()
    }

    func getGroup(_ groupId: String) async throws -> SocialGroup? {
        guard let fbGroup = try await groupService.getGroup(groupId) else {
            return nil
        }
        return fbGroup.toDomain()
    }

    func addMember(groupId: String, userId: String, displayName: String, photoURL: URL?) async throws {
        do {
            try await groupService.addMember(
                groupId: groupId,
                userId: userId,
                displayName: displayName,
                photoURL: photoURL
            )
        } catch let error as NSError {
            // Map Firebase errors to domain errors
            switch error.code {
            case 404:
                throw DomainError.groupNotFound
            case 400 where error.localizedDescription.contains("full"):
                throw DomainError.groupFull
            default:
                throw DomainError.repositoryFailure(reason: error.localizedDescription)
            }
        }
    }

    func removeMember(groupId: String, userId: String) async throws {
        do {
            try await groupService.removeMember(groupId: groupId, userId: userId)
        } catch let error as NSError {
            if error.code == 404 {
                throw DomainError.groupNotFound
            }
            throw DomainError.repositoryFailure(reason: error.localizedDescription)
        }
    }

    func leaveGroup(groupId: String, userId: String) async throws {
        try await removeMember(groupId: groupId, userId: userId)
    }

    func deleteGroup(_ groupId: String) async throws {
        do {
            try await groupService.deleteGroup(groupId)
        } catch let error as NSError {
            if error.code == 404 {
                throw DomainError.groupNotFound
            }
            throw DomainError.repositoryFailure(reason: error.localizedDescription)
        }
    }

    func getMembers(groupId: String) async throws -> [GroupMember] {
        let fbMembers = try await groupService.getMembers(groupId: groupId)
        return fbMembers.map { $0.toDomain() }
    }
}
