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

    func createGroup(name: String, ownerId: String, ownerDisplayName: String = "", ownerPhotoURL: URL? = nil) async throws -> FBGroup {
        let groupRef = db.collection("groups").document()

        let group = FBGroup(
            id: groupRef.documentID,
            name: name,
            createdAt: nil, // ServerTimestamp will set this
            createdBy: ownerId,
            memberCount: 1, // Creator is first member
            isActive: true
        )

        // Calculate current week bounds for initial challenges
        let (weekStart, weekEnd) = currentWeekBounds()

        // Use batch write to create group, member, and initial challenges atomically
        let batch = db.batch()

        // Write group document
        try batch.setData(from: group, forDocument: groupRef)

        // Add creator as admin member with their display name
        let memberRef = groupRef.collection("members").document(ownerId)
        let member = FBMember(
            id: ownerId,
            displayName: ownerDisplayName.isEmpty ? "User" : ownerDisplayName,
            photoURL: ownerPhotoURL?.absoluteString,
            joinedAt: nil,
            role: GroupRole.admin.rawValue,
            isActive: true
        )
        try batch.setData(from: member, forDocument: memberRef)

        // Create initial weekly challenges for the group
        let checkInsRef = db.collection("challenges").document()
        let checkInsChallenge = FBChallenge(
            id: checkInsRef.documentID,
            groupId: groupRef.documentID,
            type: ChallengeType.checkIns.rawValue,
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            isActive: true,
            createdAt: nil
        )
        try batch.setData(from: checkInsChallenge, forDocument: checkInsRef)

        let streakRef = db.collection("challenges").document()
        let streakChallenge = FBChallenge(
            id: streakRef.documentID,
            groupId: groupRef.documentID,
            type: ChallengeType.streak.rawValue,
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            isActive: true,
            createdAt: nil
        )
        try batch.setData(from: streakChallenge, forDocument: streakRef)

        try await batch.commit()

        #if DEBUG
        print("[GroupService] ✅ Created group '\(name)' with ID: \(groupRef.documentID)")
        print("[GroupService]    Owner: \(ownerDisplayName) (\(ownerId))")
        print("[GroupService]    Challenges created: checkIns, streak")
        #endif

        // Fetch the created group to get server timestamps
        let snapshot = try await groupRef.getDocument()
        return try snapshot.data(as: FBGroup.self)
    }

    // MARK: - Week Bounds Helper

    private func currentWeekBounds() -> (start: Timestamp, end: Timestamp) {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        components.weekday = 2 // Monday (1 = Sunday, 2 = Monday)
        components.hour = 0
        components.minute = 0
        components.second = 0

        guard let start = calendar.date(from: components),
              let end = calendar.date(byAdding: .day, value: 6, to: start) else {
            return (Timestamp(date: Date()), Timestamp(date: Date()))
        }

        return (Timestamp(date: start), Timestamp(date: end))
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
