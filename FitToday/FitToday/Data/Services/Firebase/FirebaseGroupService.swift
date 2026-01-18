//
//  FirebaseGroupService.swift
//  FitToday
//
//  Created by Claude on 16/01/26.
//

import FirebaseFirestore
import Foundation

// MARK: - FirebaseGroupService

actor FirebaseGroupService {
    private let db = Firestore.firestore()

    // MARK: - Create Group

    func createGroup(name: String, ownerId: String) async throws -> FBGroup {
        let groupRef = db.collection("groups").document()

        let group = FBGroup(
            id: groupRef.documentID,
            name: name,
            createdAt: nil, // ServerTimestamp will set this
            createdBy: ownerId,
            memberCount: 1, // Creator is first member
            isActive: true
        )

        // Use batch write to create group and add creator as first member atomically
        let batch = db.batch()

        // Write group document
        try batch.setData(from: group, forDocument: groupRef)

        // Add creator as admin member
        let memberRef = groupRef.collection("members").document(ownerId)
        let member = FBMember(
            id: ownerId,
            displayName: "", // Will be updated when actual user info is available
            photoURL: nil,
            joinedAt: nil,
            role: GroupRole.admin.rawValue,
            isActive: true
        )
        try batch.setData(from: member, forDocument: memberRef)

        try await batch.commit()

        // Fetch the created group to get server timestamps
        let snapshot = try await groupRef.getDocument()
        return try snapshot.data(as: FBGroup.self)
    }

    // MARK: - Get Group

    func getGroup(_ groupId: String) async throws -> FBGroup? {
        let snapshot = try await db.collection("groups").document(groupId).getDocument()

        guard snapshot.exists else {
            return nil
        }

        return try snapshot.data(as: FBGroup.self)
    }

    // MARK: - Add Member

    func addMember(groupId: String, userId: String, displayName: String, photoURL: URL?) async throws {
        let groupRef = db.collection("groups").document(groupId)
        let memberRef = groupRef.collection("members").document(userId)

        try await db.runTransaction { transaction, errorPointer in
            // Read current group
            let groupSnapshot: DocumentSnapshot
            do {
                groupSnapshot = try transaction.getDocument(groupRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            // Verify group exists
            guard groupSnapshot.exists else {
                errorPointer?.pointee = NSError(
                    domain: "FirebaseGroupService",
                    code: 404,
                    userInfo: [NSLocalizedDescriptionKey: "Group not found"]
                )
                return nil
            }

            // Parse group data
            guard let group = try? groupSnapshot.data(as: FBGroup.self) else {
                errorPointer?.pointee = NSError(
                    domain: "FirebaseGroupService",
                    code: 500,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to parse group data"]
                )
                return nil
            }

            // Verify group not full
            guard group.memberCount < 10 else {
                errorPointer?.pointee = NSError(
                    domain: "FirebaseGroupService",
                    code: 400,
                    userInfo: [NSLocalizedDescriptionKey: "Group is full"]
                )
                return nil
            }

            // Create member document
            let member = FBMember(
                id: userId,
                displayName: displayName,
                photoURL: photoURL?.absoluteString,
                joinedAt: nil, // ServerTimestamp will set this
                role: GroupRole.member.rawValue,
                isActive: true
            )

            // Write member
            do {
                try transaction.setData(from: member, forDocument: memberRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            // Increment member count
            transaction.updateData(["memberCount": group.memberCount + 1], forDocument: groupRef)

            return nil
        }
    }

    // MARK: - Remove Member

    func removeMember(groupId: String, userId: String) async throws {
        let groupRef = db.collection("groups").document(groupId)
        let memberRef = groupRef.collection("members").document(userId)

        try await db.runTransaction { transaction, errorPointer in
            // Read current group
            let groupSnapshot: DocumentSnapshot
            do {
                groupSnapshot = try transaction.getDocument(groupRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            // Verify group exists
            guard groupSnapshot.exists else {
                errorPointer?.pointee = NSError(
                    domain: "FirebaseGroupService",
                    code: 404,
                    userInfo: [NSLocalizedDescriptionKey: "Group not found"]
                )
                return nil
            }

            // Parse group data
            guard let group = try? groupSnapshot.data(as: FBGroup.self) else {
                errorPointer?.pointee = NSError(
                    domain: "FirebaseGroupService",
                    code: 500,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to parse group data"]
                )
                return nil
            }

            // Delete member document
            transaction.deleteDocument(memberRef)

            // Decrement member count
            let newCount = max(0, group.memberCount - 1)
            transaction.updateData(["memberCount": newCount], forDocument: groupRef)

            return nil
        }
    }

    // MARK: - Leave Group

    func leaveGroup(groupId: String, userId: String) async throws {
        // Same as remove member
        try await removeMember(groupId: groupId, userId: userId)
    }

    // MARK: - Delete Group

    func deleteGroup(_ groupId: String) async throws {
        let groupRef = db.collection("groups").document(groupId)

        // Get all members first
        let membersSnapshot = try await groupRef.collection("members").getDocuments()

        // Create batch for deletion
        let batch = db.batch()

        // Delete all member documents
        for document in membersSnapshot.documents {
            batch.deleteDocument(document.reference)
        }

        // Delete group document
        batch.deleteDocument(groupRef)

        try await batch.commit()
    }

    // MARK: - Get Members

    func getMembers(groupId: String) async throws -> [FBMember] {
        let snapshot = try await db.collection("groups")
            .document(groupId)
            .collection("members")
            .whereField("isActive", isEqualTo: true)
            .getDocuments()

        return try snapshot.documents.compactMap { doc in
            try doc.data(as: FBMember.self)
        }
    }

    // MARK: - Update Member Info

    func updateMemberInfo(groupId: String, userId: String, displayName: String, photoURL: URL?) async throws {
        let memberRef = db.collection("groups")
            .document(groupId)
            .collection("members")
            .document(userId)

        var updates: [String: Any] = ["displayName": displayName]
        if let photoURL = photoURL {
            updates["photoURL"] = photoURL.absoluteString
        }

        try await memberRef.updateData(updates)
    }
}
