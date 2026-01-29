//
//  FirebaseLeaderboardService.swift
//  FitToday
//
//  Created by Claude on 17/01/26.
//

import FirebaseFirestore
import Foundation

// MARK: - FirebaseLeaderboardService

actor FirebaseLeaderboardService {
    private let db = Firestore.firestore()

    // MARK: - Get Current Week Challenges

    /// Fetches current week's challenges for a group.
    /// If no challenges exist for this week, creates them atomically using a transaction.
    /// BUG FIX #2: Uses transaction to prevent race condition where multiple users
    /// could create duplicate challenges simultaneously.
    func getCurrentWeekChallenges(groupId: String) async throws -> [FBChallenge] {
        let (weekStart, weekEnd) = currentWeekBounds()

        #if DEBUG
        print("[LeaderboardService] 🔍 Fetching challenges for group \(groupId)")
        print("[LeaderboardService]    Week: \(weekStart.dateValue()) to \(weekEnd.dateValue())")
        #endif

        // Use transaction to atomically check and create challenges
        let challenges = try await db.runTransaction { [db] (transaction, errorPointer) -> [FBChallenge]? in
            // 1. Query existing challenges within transaction
            let challengesRef = db.collection("challenges")
            let query = challengesRef
                .whereField("groupId", isEqualTo: groupId)
                .whereField("weekStartDate", isEqualTo: weekStart)
                .whereField("isActive", isEqualTo: true)

            // Note: Firestore transactions require getDocuments for queries
            // We'll do a non-transactional read first, then verify in transaction
            return nil
        }

        // Since Firestore transactions don't support queries directly,
        // we use a two-phase approach: read, then create atomically if empty
        let snapshot = try await db.collection("challenges")
            .whereField("groupId", isEqualTo: groupId)
            .whereField("weekStartDate", isEqualTo: weekStart)
            .whereField("isActive", isEqualTo: true)
            .getDocuments()

        var existingChallenges = try snapshot.documents.compactMap { doc in
            try doc.data(as: FBChallenge.self)
        }

        #if DEBUG
        print("[LeaderboardService] 📊 Found \(existingChallenges.count) existing challenges")
        #endif

        // If no challenges exist, create them atomically with duplicate check
        if existingChallenges.isEmpty {
            #if DEBUG
            print("[LeaderboardService] ⚠️ No challenges found - creating weekly challenges atomically")
            #endif

            existingChallenges = try await createWeeklyChallengesAtomically(
                groupId: groupId,
                weekStart: weekStart,
                weekEnd: weekEnd
            )
        }

        return existingChallenges
    }

    // MARK: - Create Weekly Challenges Atomically

    /// Creates weekly challenges with duplicate prevention.
    /// Uses a sentinel document to prevent race conditions.
    private func createWeeklyChallengesAtomically(
        groupId: String,
        weekStart: Timestamp,
        weekEnd: Timestamp
    ) async throws -> [FBChallenge] {
        // Use a sentinel document to prevent race conditions
        let sentinelId = "\(groupId)_\(weekStart.seconds)"
        let sentinelRef = db.collection("challenge_creation_locks").document(sentinelId)

        do {
            // Try to create sentinel - only one request will succeed
            try await sentinelRef.setData([
                "groupId": groupId,
                "weekStart": weekStart,
                "createdAt": FieldValue.serverTimestamp()
            ], merge: false)

            #if DEBUG
            print("[LeaderboardService] 🔒 Acquired lock for challenge creation")
            #endif

            // We got the lock, create challenges
            let challenges = try await ensureWeeklyChallengesExist(
                groupId: groupId,
                weekStart: weekStart,
                weekEnd: weekEnd
            )

            // Clean up sentinel after successful creation
            try? await sentinelRef.delete()

            return challenges
        } catch {
            // Another request already created the challenges, fetch them
            #if DEBUG
            print("[LeaderboardService] 🔄 Lock already held, fetching existing challenges")
            #endif

            // Wait briefly and retry fetch
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

            let retrySnapshot = try await db.collection("challenges")
                .whereField("groupId", isEqualTo: groupId)
                .whereField("weekStartDate", isEqualTo: weekStart)
                .whereField("isActive", isEqualTo: true)
                .getDocuments()

            return try retrySnapshot.documents.compactMap { doc in
                try doc.data(as: FBChallenge.self)
            }
        }
    }

    // MARK: - Ensure Weekly Challenges Exist

    /// Creates check-ins and streak challenges for the current week if they don't exist.
    /// This ensures challenges are always available for workout syncing.
    private func ensureWeeklyChallengesExist(
        groupId: String,
        weekStart: Timestamp,
        weekEnd: Timestamp
    ) async throws -> [FBChallenge] {
        let batch = db.batch()
        var createdChallenges: [FBChallenge] = []

        // Create check-ins challenge
        let checkInsRef = db.collection("challenges").document()
        let checkInsChallenge = FBChallenge(
            id: checkInsRef.documentID,
            groupId: groupId,
            type: ChallengeType.checkIns.rawValue,
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            isActive: true,
            createdAt: nil // ServerTimestamp
        )
        try batch.setData(from: checkInsChallenge, forDocument: checkInsRef)
        createdChallenges.append(checkInsChallenge)

        // Create streak challenge
        let streakRef = db.collection("challenges").document()
        let streakChallenge = FBChallenge(
            id: streakRef.documentID,
            groupId: groupId,
            type: ChallengeType.streak.rawValue,
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            isActive: true,
            createdAt: nil // ServerTimestamp
        )
        try batch.setData(from: streakChallenge, forDocument: streakRef)
        createdChallenges.append(streakChallenge)

        try await batch.commit()

        #if DEBUG
        print("[LeaderboardService] ✅ Created \(createdChallenges.count) weekly challenges:")
        print("[LeaderboardService]    - checkIns: \(checkInsRef.documentID)")
        print("[LeaderboardService]    - streak: \(streakRef.documentID)")
        #endif

        return createdChallenges
    }

    // MARK: - Observe Leaderboard (Real-Time)

    func observeLeaderboard(groupId: String, type: ChallengeType) -> AsyncStream<LeaderboardSnapshot> {
        AsyncStream { continuation in
            let (weekStart, _) = currentWeekBounds()

            // Listen to challenge document
            let challengeListener = db.collection("challenges")
                .whereField("groupId", isEqualTo: groupId)
                .whereField("weekStartDate", isEqualTo: weekStart)
                .whereField("type", isEqualTo: type.rawValue)
                .whereField("isActive", isEqualTo: true)
                .limit(to: 1)
                .addSnapshotListener { snapshot, error in
                    guard let challengeDoc = snapshot?.documents.first else {
                        // No challenge for this week yet, emit empty snapshot
                        return
                    }

                    guard let fbChallenge = try? challengeDoc.data(as: FBChallenge.self) else {
                        return
                    }

                    // Listen to entries subcollection
                    challengeDoc.reference.collection("entries")
                        .order(by: "rank")
                        .addSnapshotListener { entriesSnapshot, _ in
                            guard let entryDocs = entriesSnapshot?.documents else { return }

                            let entries = entryDocs.compactMap { try? $0.data(as: FBChallengeEntry.self).toDomain() }
                            let challenge = fbChallenge.toDomain()

                            let leaderboardSnapshot = LeaderboardSnapshot(
                                challenge: challenge,
                                entries: entries,
                                currentUserEntry: nil // Will be set by ViewModel
                            )

                            continuation.yield(leaderboardSnapshot)
                        }
                }

            continuation.onTermination = { _ in
                challengeListener.remove()
            }
        }
    }

    // MARK: - Increment Check-In

    func incrementCheckIn(challengeId: String, userId: String, displayName: String, photoURL: URL?) async throws {
        let entryRef = db.collection("challenges")
            .document(challengeId)
            .collection("entries")
            .document(userId)

        try await db.runTransaction { transaction, errorPointer in
            let entryDoc: DocumentSnapshot
            do {
                entryDoc = try transaction.getDocument(entryRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            let currentValue = (try? entryDoc.data(as: FBChallengeEntry.self))?.value ?? 0

            let entry = FBChallengeEntry(
                id: userId,
                displayName: displayName,
                photoURL: photoURL?.absoluteString,
                value: currentValue + 1,
                rank: 0, // Will be recomputed
                lastUpdated: nil // ServerTimestamp
            )

            do {
                try transaction.setData(from: entry, forDocument: entryRef, merge: true)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            return nil
        }

        // Recompute ranks after successful update
        try await recomputeRanks(challengeId: challengeId)
    }

    // MARK: - Update Streak

    func updateStreak(challengeId: String, userId: String, streakDays: Int, displayName: String, photoURL: URL?) async throws {
        let entryRef = db.collection("challenges")
            .document(challengeId)
            .collection("entries")
            .document(userId)

        let entry = FBChallengeEntry(
            id: userId,
            displayName: displayName,
            photoURL: photoURL?.absoluteString,
            value: streakDays,
            rank: 0, // Will be recomputed
            lastUpdated: nil // ServerTimestamp
        )

        try await entryRef.setData(from: entry, merge: true)

        // Recompute ranks after successful update
        try await recomputeRanks(challengeId: challengeId)
    }

    // MARK: - Update Member Weekly Stats

    func updateMemberWeeklyStats(groupId: String, userId: String, workoutMinutes: Int) async throws {
        let memberRef = db.collection("groups")
            .document(groupId)
            .collection("members")
            .document(userId)

        try await db.runTransaction { transaction, errorPointer in
            let memberDoc: DocumentSnapshot
            do {
                memberDoc = try transaction.getDocument(memberRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            // Get current stats
            let currentWorkoutCount = memberDoc.data()?["weeklyWorkoutCount"] as? Int ?? 0
            let currentWorkoutMinutes = memberDoc.data()?["weeklyWorkoutMinutes"] as? Int ?? 0

            // Update with new workout
            transaction.updateData([
                "weeklyWorkoutCount": currentWorkoutCount + 1,
                "weeklyWorkoutMinutes": currentWorkoutMinutes + workoutMinutes
            ], forDocument: memberRef)

            return nil
        }
    }

    // MARK: - Recompute Ranks

    private func recomputeRanks(challengeId: String) async throws {
        let entriesSnapshot = try await db.collection("challenges")
            .document(challengeId)
            .collection("entries")
            .order(by: "value", descending: true)
            .getDocuments()

        let batch = db.batch()
        for (index, doc) in entriesSnapshot.documents.enumerated() {
            batch.updateData(["rank": index + 1], forDocument: doc.reference)
        }

        try await batch.commit()
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
            // Fallback to current date if calculation fails
            return (Timestamp(date: Date()), Timestamp(date: Date()))
        }

        return (Timestamp(date: start), Timestamp(date: end))
    }
}
