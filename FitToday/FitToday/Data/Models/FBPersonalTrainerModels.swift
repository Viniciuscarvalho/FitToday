//
//  FBPersonalTrainerModels.swift
//  FitToday
//
//  Created by Claude on 04/02/26.
//

import Foundation
import FirebaseFirestore

// MARK: - Firebase Personal Trainer DTO

/// Firebase DTO for personal trainer data.
///
/// Matches Firestore collection: `/personalTrainers/{id}`
struct FBPersonalTrainer: Codable {
    /// Document ID (populated by Firestore).
    @DocumentID var id: String?

    /// Display name shown to students.
    var displayName: String

    /// Trainer's email address.
    var email: String?

    /// URL string to the trainer's profile photo.
    var photoURL: String?

    /// Areas of expertise (e.g., ["strength", "weight_loss"]).
    var specializations: [String]?

    /// Short biography or description.
    var bio: String?

    /// Whether the trainer is currently accepting new students.
    var isActive: Bool?

    /// Unique invite code students can use to connect.
    var inviteCode: String?

    /// Maximum number of students this trainer can manage.
    var maxStudents: Int?

    /// Current number of connected students.
    var currentStudentCount: Int?

    /// When the trainer profile was created.
    @ServerTimestamp var createdAt: Timestamp?

    /// When the trainer profile was last updated.
    @ServerTimestamp var updatedAt: Timestamp?
}

// MARK: - Firebase Trainer Student DTO

/// Firebase DTO for trainer-student relationship data.
///
/// Matches Firestore collection: `/trainerStudents/{id}`
struct FBTrainerStudent: Codable {
    /// Document ID (populated by Firestore).
    @DocumentID var id: String?

    /// The personal trainer's identifier.
    var trainerId: String

    /// The student's identifier (app user).
    var studentId: String

    /// Current status of the connection (pending, active, paused, cancelled).
    var status: String

    /// Who initiated the request (student, trainer).
    var requestedBy: String?

    /// When the connection was requested.
    @ServerTimestamp var requestedAt: Timestamp?

    /// When the connection was accepted.
    var acceptedAt: Timestamp?

    /// Current subscription status (trial, active, expired).
    var subscriptionStatus: String?

    /// When the subscription expires.
    var subscriptionExpiresAt: Timestamp?

    /// When this relationship record was created.
    @ServerTimestamp var createdAt: Timestamp?
}
