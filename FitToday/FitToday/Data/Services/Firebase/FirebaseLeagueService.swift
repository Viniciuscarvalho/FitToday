//
//  FirebaseLeagueService.swift
//  FitToday
//

import FirebaseAuth
import FirebaseFirestore
import Foundation

// MARK: - League Errors

enum LeagueError: LocalizedError {
    case userNotAuthenticated
    case firestoreError(Error)

    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User must be authenticated to access leagues"
        case .firestoreError(let error):
            return "Firestore error: \(error.localizedDescription)"
        }
    }
}

// MARK: - FirebaseLeagueService

actor FirebaseLeagueService {
    private let db = Firestore.firestore()

    // MARK: - Auth Check

    /// Verifies the user is authenticated before making Firestore calls.
    private func verifyAuthentication() throws -> String {
        guard let user = Auth.auth().currentUser else {
            #if DEBUG
            print("[LeagueService] User not authenticated")
            #endif
            throw LeagueError.userNotAuthenticated
        }
        return user.uid
    }

    // MARK: - Fetch Current League

    /// Fetches the most recent league the user is a member of.
    /// Queries leagues where the user appears in the members subcollection,
    /// ordered by seasonWeek descending, limited to 1.
    func fetchCurrentLeague(userId: String) async throws -> (FBLeague, [FBLeagueMember])? {
        _ = try verifyAuthentication()

        #if DEBUG
        print("[LeagueService] Fetching current league for user \(userId)")
        #endif

        // Query leagues where user is a member using memberUserIds array field
        let leaguesSnapshot = try await db.collection("leagues")
            .whereField("memberUserIds", arrayContains: userId)
            .order(by: "seasonWeek", descending: true)
            .limit(to: 1)
            .getDocuments()

        guard let leagueDoc = leaguesSnapshot.documents.first else {
            #if DEBUG
            print("[LeagueService] No league found for user \(userId)")
            #endif
            return nil
        }

        let fbLeague = try leagueDoc.data(as: FBLeague.self)

        let membersSnapshot = try await leagueDoc.reference
            .collection("members")
            .getDocuments()

        let members = try membersSnapshot.documents.map { doc in
            try doc.data(as: FBLeagueMember.self)
        }

        #if DEBUG
        print("[LeagueService] Found league \(leagueDoc.documentID) with \(members.count) members")
        #endif

        return (fbLeague, members)
    }

    // MARK: - Observe League

    /// Observes real-time updates for a specific league document and its members subcollection.
    nonisolated func observeLeague(leagueId: String) -> AsyncThrowingStream<(FBLeague, [FBLeagueMember]), Error> {
        AsyncThrowingStream { continuation in
            guard Auth.auth().currentUser != nil else {
                continuation.finish(throwing: LeagueError.userNotAuthenticated)
                return
            }

            let leagueRef = self.db.collection("leagues").document(leagueId)

            // Track latest values from both listeners
            let state = LeagueObservationState()

            // Listen to league document
            let leagueListener = leagueRef.addSnapshotListener { snapshot, error in
                if let error {
                    continuation.finish(throwing: LeagueError.firestoreError(error))
                    return
                }

                guard let snapshot, snapshot.exists,
                      let fbLeague = try? snapshot.data(as: FBLeague.self) else {
                    return
                }

                state.league = fbLeague
                if let members = state.members {
                    continuation.yield((fbLeague, members))
                }
            }

            // Listen to members subcollection
            let membersListener = leagueRef.collection("members")
                .addSnapshotListener { snapshot, error in
                    if let error {
                        continuation.finish(throwing: LeagueError.firestoreError(error))
                        return
                    }

                    guard let docs = snapshot?.documents else { return }

                    let members = docs.compactMap { try? $0.data(as: FBLeagueMember.self) }
                    state.members = members

                    if let league = state.league {
                        continuation.yield((league, members))
                    }
                }

            continuation.onTermination = { _ in
                leagueListener.remove()
                membersListener.remove()
                #if DEBUG
                print("[LeagueService] Stopped league observation for \(leagueId)")
                #endif
            }
        }
    }

    // MARK: - Fetch League History

    /// Fetches past league seasons the user participated in.
    func fetchLeagueHistory(userId: String) async throws -> [(FBLeague, [FBLeagueMember])] {
        _ = try verifyAuthentication()

        #if DEBUG
        print("[LeagueService] Fetching league history for user \(userId)")
        #endif

        let leaguesSnapshot = try await db.collection("leagues")
            .whereField("memberUserIds", arrayContains: userId)
            .order(by: "seasonWeek", descending: true)
            .getDocuments()

        var results: [(FBLeague, [FBLeagueMember])] = []

        for leagueDoc in leaguesSnapshot.documents {
            let fbLeague = try leagueDoc.data(as: FBLeague.self)

            let membersSnapshot = try await leagueDoc.reference
                .collection("members")
                .getDocuments()

            let members = try membersSnapshot.documents.map { doc in
                try doc.data(as: FBLeagueMember.self)
            }

            results.append((fbLeague, members))
        }

        #if DEBUG
        print("[LeagueService] Found \(results.count) past leagues")
        #endif

        return results
    }
}

// MARK: - Observation State

/// Holds the latest snapshot values from league and members listeners.
/// Used only within snapshot listener callbacks on the main Firestore callback queue.
private final class LeagueObservationState: @unchecked Sendable {
    var league: FBLeague?
    var members: [FBLeagueMember]?
}
