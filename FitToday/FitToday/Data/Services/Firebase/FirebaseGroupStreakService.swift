//
//  FirebaseGroupStreakService.swift
//  FitToday
//
//  Created by Claude on 27/01/26.
//

import FirebaseFirestore
import Foundation

// MARK: - FirebaseGroupStreakService

actor FirebaseGroupStreakService {
    private let db = Firestore.firestore()

    // MARK: - Collections

    private func groupRef(_ groupId: String) -> DocumentReference {
        db.collection("groups").document(groupId)
    }

    private func streakRef(_ groupId: String) -> DocumentReference {
        groupRef(groupId).collection("streak").document("status")
    }

    private func streakWeeksRef(_ groupId: String) -> CollectionReference {
        groupRef(groupId).collection("streakWeeks")
    }

    // MARK: - Get Streak Status

    func getStreakStatus(groupId: String) async throws -> FBGroupStreak? {
        let doc = try await streakRef(groupId).getDocument()
        guard doc.exists else { return nil }
        return try doc.data(as: FBGroupStreak.self)
    }

    // MARK: - Observe Streak Status

    func observeStreakStatus(groupId: String) -> AsyncStream<(FBGroupStreak?, FBGroupStreakWeek?)> {
        AsyncStream { continuation in
            var streakData: FBGroupStreak?
            var weekData: FBGroupStreakWeek?

            // Listen to streak status
            let streakListener = streakRef(groupId).addSnapshotListener { snapshot, error in
                if let snapshot, snapshot.exists {
                    streakData = try? snapshot.data(as: FBGroupStreak.self)
                } else {
                    streakData = nil
                }
                continuation.yield((streakData, weekData))
            }

            // Listen to current week
            let (weekStart, weekEnd) = self.currentWeekBounds()
            let weekListener = streakWeeksRef(groupId)
                .whereField("weekStartDate", isEqualTo: weekStart)
                .limit(to: 1)
                .addSnapshotListener { snapshot, error in
                    if let doc = snapshot?.documents.first {
                        weekData = try? doc.data(as: FBGroupStreakWeek.self)
                    } else {
                        weekData = nil
                    }
                    continuation.yield((streakData, weekData))
                }

            continuation.onTermination = { _ in
                streakListener.remove()
                weekListener.remove()
            }
        }
    }

    // MARK: - Get Current Week

    func getCurrentWeek(groupId: String) async throws -> FBGroupStreakWeek? {
        let (weekStart, _) = currentWeekBounds()

        let snapshot = try await streakWeeksRef(groupId)
            .whereField("weekStartDate", isEqualTo: weekStart)
            .limit(to: 1)
            .getDocuments()

        guard let doc = snapshot.documents.first else { return nil }
        return try doc.data(as: FBGroupStreakWeek.self)
    }

    // MARK: - Increment Workout Count

    func incrementWorkoutCount(
        groupId: String,
        userId: String,
        displayName: String,
        photoURL: String?
    ) async throws {
        let (weekStart, _) = currentWeekBounds()

        // Find or create current week record
        let weekSnapshot = try await streakWeeksRef(groupId)
            .whereField("weekStartDate", isEqualTo: weekStart)
            .limit(to: 1)
            .getDocuments()

        guard let weekDoc = weekSnapshot.documents.first else {
            // No week record exists - will be created by Cloud Function
            return
        }

        let weekRef = weekDoc.reference
        let memberKey = "memberCompliance.\(userId)"

        try await db.runTransaction { transaction, errorPointer in
            let doc: DocumentSnapshot
            do {
                doc = try transaction.getDocument(weekRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            guard let data = doc.data(),
                  let memberCompliance = data["memberCompliance"] as? [String: Any],
                  let memberData = memberCompliance[userId] as? [String: Any] else {
                // Member not in compliance list - add them
                let newMember = FBMemberWeeklyStatus(
                    displayName: displayName,
                    photoURL: photoURL,
                    workoutCount: 1,
                    lastWorkoutDate: nil
                )
                do {
                    let encoded = try Firestore.Encoder().encode(newMember)
                    transaction.updateData([memberKey: encoded], forDocument: weekRef)
                } catch let error as NSError {
                    errorPointer?.pointee = error
                }
                return nil
            }

            let currentCount = memberData["workoutCount"] as? Int ?? 0

            transaction.updateData([
                "\(memberKey).workoutCount": currentCount + 1,
                "\(memberKey).lastWorkoutDate": FieldValue.serverTimestamp()
            ], forDocument: weekRef)

            return nil
        }
    }

    // MARK: - Create Week Record

    func createWeekRecord(groupId: String, members: [(id: String, displayName: String, photoURL: String?)]) async throws -> FBGroupStreakWeek {
        let (weekStart, weekEnd) = currentWeekBounds()

        var memberCompliance: [String: FBMemberWeeklyStatus] = [:]
        for member in members {
            memberCompliance[member.id] = FBMemberWeeklyStatus(
                displayName: member.displayName,
                photoURL: member.photoURL,
                workoutCount: 0,
                lastWorkoutDate: nil
            )
        }

        let weekRecord = FBGroupStreakWeek(
            groupId: groupId,
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            memberCompliance: memberCompliance,
            allCompliant: nil,
            createdAt: nil
        )

        let docRef = try await streakWeeksRef(groupId).addDocument(from: weekRecord)
        var created = weekRecord
        created.id = docRef.documentID
        return created
    }

    // MARK: - Update Streak Days

    func updateStreakDays(groupId: String, days: Int, milestone: Int?) async throws {
        var updateData: [String: Any] = [
            "groupStreakDays": days
        ]

        if let milestone {
            updateData["lastMilestone"] = milestone
        }

        if days > 0 {
            // Set start date if not already set
            let currentStreak = try await getStreakStatus(groupId: groupId)
            if currentStreak?.streakStartDate == nil {
                updateData["streakStartDate"] = FieldValue.serverTimestamp()
            }
        }

        try await streakRef(groupId).setData(updateData, merge: true)
    }

    // MARK: - Reset Streak

    func resetStreak(groupId: String) async throws {
        try await streakRef(groupId).setData([
            "groupStreakDays": 0,
            "lastMilestone": FieldValue.delete(),
            "streakStartDate": FieldValue.delete()
        ], merge: true)
    }

    // MARK: - Pause Streak

    func pauseStreak(groupId: String, until: Date) async throws {
        try await streakRef(groupId).setData([
            "pausedUntil": Timestamp(date: until)
        ], merge: true)
    }

    // MARK: - Resume Streak

    func resumeStreak(groupId: String) async throws {
        try await streakRef(groupId).updateData([
            "pausedUntil": FieldValue.delete()
        ])
    }

    // MARK: - Mark Pause Used

    func markPauseUsedThisMonth(groupId: String) async throws {
        try await streakRef(groupId).setData([
            "pauseUsedThisMonth": true
        ], merge: true)
    }

    // MARK: - Reset Monthly Pause Flag

    func resetMonthlyPauseFlag(groupId: String) async throws {
        try await streakRef(groupId).setData([
            "pauseUsedThisMonth": false
        ], merge: true)
    }

    // MARK: - Get Week History

    func getWeekHistory(groupId: String, limit: Int) async throws -> [FBGroupStreakWeek] {
        let snapshot = try await streakWeeksRef(groupId)
            .order(by: "weekStartDate", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: FBGroupStreakWeek.self) }
    }

    // MARK: - Finalize Week

    func finalizeWeek(groupId: String, weekId: String, allCompliant: Bool) async throws {
        let weekRef = streakWeeksRef(groupId).document(weekId)
        try await weekRef.updateData([
            "allCompliant": allCompliant
        ])
    }

    // MARK: - Week Bounds Helper

    private func currentWeekBounds() -> (start: Timestamp, end: Timestamp) {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(identifier: "UTC")!

        let now = Date()
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)

        guard let start = calendar.date(from: components),
              let end = calendar.date(byAdding: .day, value: 6, to: start)?
            .addingTimeInterval(86399) else {
            return (Timestamp(date: now), Timestamp(date: now))
        }

        return (Timestamp(date: start), Timestamp(date: end))
    }
}
