//
//  FBLeague.swift
//  FitToday
//

import FirebaseFirestore
import Foundation

// MARK: - FBLeague

struct FBLeague: Codable, Sendable {
    @DocumentID var id: String?
    let tier: String
    let seasonWeek: Int
    let startDate: Timestamp?
    let endDate: Timestamp?
}

// MARK: - FBLeagueMember

struct FBLeagueMember: Codable, Sendable {
    @DocumentID var id: String?
    let userId: String
    let displayName: String
    let avatarURL: String?
    let weeklyXP: Int
}
